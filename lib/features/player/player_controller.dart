import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../data/models/media_item.dart';
import '../../data/services/file_access_service.dart';
import '../../providers.dart';
import 'player_state.dart';

class PlayerController extends Notifier<PlaybackSnapshot> {
  late final Player player;
  late final VideoController videoController;

  StreamSubscription<bool>? _playingSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<double>? _volumeSubscription;
  StreamSubscription<bool>? _bufferingSubscription;
  StreamSubscription<String>? _errorSubscription;
  Timer? _progressPersistTimer;

  @override
  PlaybackSnapshot build() {
    player = Player();
    videoController = VideoController(player);
    ref.onDispose(_dispose);

    _playingSubscription = player.stream.playing.listen((value) {
      state = state.copyWith(isPlaying: value);
    });
    _positionSubscription = player.stream.position.listen((value) {
      state = state.copyWith(position: value);
      _scheduleProgressPersist();
    });
    _durationSubscription = player.stream.duration.listen((value) {
      state = state.copyWith(duration: value);
      _scheduleProgressPersist();
    });
    _volumeSubscription = player.stream.volume.listen((value) {
      state = state.copyWith(volume: value);
    });
    _bufferingSubscription = player.stream.buffering.listen((value) {
      state = state.copyWith(isBuffering: value);
    });
    _errorSubscription = player.stream.error.listen((value) {
      state = state.copyWith(errorText: value);
    });

    return const PlaybackSnapshot();
  }

  Future<void> openMedia(MediaItem item, {bool? play}) async {
    ref.read(currentMediaIdProvider.notifier).state = item.mediaId;
    final bool shouldPlay = play ?? ref.read(autoPlayOnOpenProvider);
    state = state.copyWith(
      isOpening: true,
      position: Duration(milliseconds: item.progressMillis),
      duration: Duration(milliseconds: item.durationMillis),
      clearError: true,
      clearLoadedMedia: true,
    );

    try {
      final source = await _resolvePlayableSource(item);
      if (source == null) {
        state = state.copyWith(
          errorText: '无法访问这个文件。请点击右上角文件夹按钮重新选择一次视频，授权后历史记录就可以继续打开。',
        );
        return;
      }

      if (kDebugMode) {
        debugPrint('Opening media source: $source');
      }

      await player.stop();
      await player.add(Media(source));
      await player.jump(0);
      state = state.copyWith(loadedMediaId: item.mediaId);

      if (item.progressMillis > 0) {
        await player.seek(Duration(milliseconds: item.progressMillis));
      }

      if (shouldPlay) {
        await player.play();
      }
    } catch (error) {
      state = state.copyWith(errorText: '加载失败: $error');
    } finally {
      state = state.copyWith(isOpening: false);
    }
  }

  Future<void> togglePlayback() async {
    if (state.isPlaying) {
      await player.pause();
    } else {
      await player.play();
    }
  }

  Future<void> playOrOpen(MediaItem item) async {
    if (state.loadedMediaId != item.mediaId) {
      await openMedia(item, play: true);
      return;
    }

    await togglePlayback();
  }

  Future<void> seek(Duration target) async {
    await player.seek(target);
  }

  Future<void> seekRelative(Duration offset) async {
    final target = state.position + offset;
    final clamped = target < Duration.zero
        ? Duration.zero
        : state.duration > Duration.zero && target > state.duration
        ? state.duration
        : target;
    await seek(clamped);
  }

  Future<void> setVolume(double value) async {
    await player.setVolume(value);
  }

  Future<void> resetAndPlayCurrent() async {
    await player.seek(Duration.zero);
    await player.play();
  }

  void _scheduleProgressPersist() {
    _progressPersistTimer?.cancel();
    _progressPersistTimer = Timer(const Duration(milliseconds: 450), () async {
      final mediaId = ref.read(currentMediaIdProvider);
      if (mediaId == null) {
        return;
      }

      final repository = await ref.read(libraryRepositoryProvider.future);
      await repository.updateProgress(
        mediaId: mediaId,
        position: state.position,
        duration: state.duration,
      );
    });
  }

  void _dispose() {
    _playingSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _volumeSubscription?.cancel();
    _bufferingSubscription?.cancel();
    _errorSubscription?.cancel();
    _progressPersistTimer?.cancel();
    player.dispose();
  }

  String _normalizeMediaSource(String source) {
    final uri = Uri.tryParse(source);
    if (uri != null && uri.hasScheme) {
      return source;
    }

    return source;
  }

  Future<String?> _resolvePlayableSource(MediaItem item) async {
    final source = item.source;
    final uri = Uri.tryParse(source);
    if (uri != null && uri.hasScheme && uri.scheme != 'file') {
      return source;
    }

    final grant = await const FileAccessService().startAccessing(
      path: source,
      bookmark: item.bookmark,
    );
    if (grant == null) {
      return null;
    }

    if (grant.renewedBookmark != null &&
        grant.renewedBookmark != item.bookmark) {
      final repository = await ref.read(libraryRepositoryProvider.future);
      await repository.updateBookmark(item.mediaId, grant.renewedBookmark!);
    }

    return _normalizeMediaSource(grant.path);
  }
}
