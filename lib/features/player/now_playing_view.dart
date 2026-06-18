import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_controls.dart';
import '../../core/widgets/media_artwork.dart';
import '../../data/models/media_item.dart';
import '../../providers.dart';
import 'local_file_opener.dart';
import 'player_controller.dart';
import 'player_state.dart';

class NowPlayingView extends ConsumerWidget {
  const NowPlayingView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final media = ref.watch(currentMediaProvider);
    final playback = ref.watch(playerControllerProvider);
    final playerController = ref.read(playerControllerProvider.notifier);

    if (media == null) {
      return _EmptyPlayerState(
        onOpenFile: () => pickAndOpenVideo(ref, GoRouter.of(context)),
      );
    }

    final duration = playback.duration == Duration.zero
        ? media.duration
        : playback.duration;
    final sliderMax = duration.inMilliseconds <= 0
        ? 1.0
        : duration.inMilliseconds / 1000;
    final sliderValue = playback.position.inMilliseconds <= 0
        ? 0.0
        : (playback.position.inMilliseconds / 1000).clamp(0.0, sliderMax);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
      child: Column(
        children: [
          _HeaderBar(
            title: media.title,
            subtitle: media.subtitle,
            onOpenFile: () => pickAndOpenVideo(ref, GoRouter.of(context)),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: _VideoStage(
              media: media,
              playback: playback,
              duration: duration,
              sliderValue: sliderValue,
              sliderMax: sliderMax,
              playerController: playerController,
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoStage extends ConsumerStatefulWidget {
  const _VideoStage({
    required this.media,
    required this.playback,
    required this.duration,
    required this.sliderValue,
    required this.sliderMax,
    required this.playerController,
  });

  final MediaItem media;
  final PlaybackSnapshot playback;
  final Duration duration;
  final double sliderValue;
  final double sliderMax;
  final PlayerController playerController;

  @override
  ConsumerState<_VideoStage> createState() => _VideoStageState();
}

class _VideoStageState extends ConsumerState<_VideoStage> {
  Timer? _hideTimer;
  bool _controlsVisible = true;

  @override
  void initState() {
    super.initState();
    _scheduleAutoHide();
  }

  @override
  void didUpdateWidget(covariant _VideoStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.playback.isPlaying != widget.playback.isPlaying ||
        oldWidget.playback.isBuffering != widget.playback.isBuffering ||
        oldWidget.playback.isOpening != widget.playback.isOpening ||
        oldWidget.playback.errorText != widget.playback.errorText ||
        oldWidget.media.mediaId != widget.media.mediaId) {
      _showControls();
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  bool get _canAutoHide =>
      widget.playback.isPlaying &&
      !widget.playback.isBuffering &&
      !widget.playback.isOpening &&
      widget.playback.errorText == null;

  void _showControls() {
    if (!_controlsVisible && mounted) {
      setState(() {
        _controlsVisible = true;
      });
    }
    _scheduleAutoHide();
  }

  void _scheduleAutoHide() {
    _hideTimer?.cancel();
    if (!_canAutoHide) {
      if (!_controlsVisible && mounted) {
        setState(() {
          _controlsVisible = true;
        });
      }
      return;
    }

    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted || !_canAutoHide) {
        return;
      }
      setState(() {
        _controlsVisible = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return MouseRegion(
      onEnter: (_) => _showControls(),
      onHover: (_) => _showControls(),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: palette.shadow,
              blurRadius: 28,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (widget.media.backdropUrl != null ||
                  widget.media.artworkUrl != null)
                Positioned.fill(
                  child: MediaArtwork(
                    source: widget.media.backdropUrl ?? widget.media.artworkUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              Positioned.fill(
                child: Video(
                  controller: widget.playerController.videoController,
                  controls: NoVideoControls,
                  fit: BoxFit.contain,
                ),
              ),
              Positioned.fill(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  opacity: _controlsVisible ? 1 : 0,
                  child: const _VideoChromeGradient(),
                ),
              ),
              if (widget.playback.isBuffering || widget.playback.isOpening)
                const Center(child: CircularProgressIndicator()),
              if (widget.playback.errorText != null)
                Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 420),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: palette.overlay,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      widget.playback.errorText!,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              Positioned(
                left: 26,
                right: 26,
                bottom: 18,
                child: IgnorePointer(
                  ignoring: !_controlsVisible,
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    offset: _controlsVisible
                        ? Offset.zero
                        : const Offset(0, 0.1),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      opacity: _controlsVisible ? 1 : 0,
                      child: _PlayerControls(
                        media: widget.media,
                        playback: widget.playback,
                        duration: widget.duration,
                        sliderValue: widget.sliderValue,
                        sliderMax: widget.sliderMax,
                        playerController: widget.playerController,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VideoChromeGradient extends StatelessWidget {
  const _VideoChromeGradient();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.48, 0.78, 1],
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.20),
            Colors.black.withValues(alpha: 0.70),
          ],
        ),
      ),
    );
  }
}

class _PlayerControls extends StatelessWidget {
  const _PlayerControls({
    required this.media,
    required this.playback,
    required this.duration,
    required this.sliderValue,
    required this.sliderMax,
    required this.playerController,
  });

  final MediaItem media;
  final PlaybackSnapshot playback;
  final Duration duration;
  final double sliderValue;
  final double sliderMax;
  final PlayerController playerController;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final theme = Theme.of(context);
    final currentMediaLoaded = playback.loadedMediaId == media.mediaId;
    final playingCurrentMedia = currentMediaLoaded && playback.isPlaying;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            inactiveTrackColor: const Color.fromRGBO(255, 255, 255, 0.20),
            activeTrackColor: palette.primary,
            thumbColor: palette.primary,
            trackHeight: 2,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
          ),
          child: Slider(
            value: sliderValue,
            max: sliderMax,
            onChanged: (value) {
              playerController.seek(
                Duration(milliseconds: (value * 1000).round()),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              Text(
                formatDuration(playback.position),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.72),
                ),
              ),
              const Spacer(),
              Text(
                formatDuration(duration),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.72),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 50,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ControlIconButton(
                        icon: Icons.skip_previous_rounded,
                        onPressed: () => playerController.seekRelative(
                          const Duration(seconds: -10),
                        ),
                      ),
                      _ControlIconButton(
                        icon: Icons.fast_rewind_rounded,
                        onPressed: () => playerController.seekRelative(
                          const Duration(seconds: -5),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _PlayButton(
                        playing: playingCurrentMedia,
                        onTap: () => playerController.playOrOpen(media),
                      ),
                      const SizedBox(width: 12),
                      _ControlIconButton(
                        icon: Icons.fast_forward_rounded,
                        onPressed: () => playerController.seekRelative(
                          const Duration(seconds: 5),
                        ),
                      ),
                      _ControlIconButton(
                        icon: Icons.skip_next_rounded,
                        onPressed: () => playerController.seekRelative(
                          const Duration(seconds: 10),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 270),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.volume_up_rounded,
                        color: Colors.white.withValues(alpha: 0.74),
                        size: 20,
                      ),
                      SizedBox(
                        width: 118,
                        child: Slider(
                          value: playback.volume.clamp(0, 100),
                          max: 100,
                          onChanged: playerController.setVolume,
                        ),
                      ),
                      _ControlIconButton(
                        icon: Icons.fullscreen_rounded,
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeaderBar extends StatelessWidget {
  const _HeaderBar({
    required this.title,
    required this.onOpenFile,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final VoidCallback onOpenFile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        const SizedBox(width: 104),
        Expanded(
          child: Column(
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
        SizedBox(
          width: 104,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AppToolButton(
                icon: Icons.folder_open_rounded,
                onPressed: onOpenFile,
                filled: true,
              ),
              const SizedBox(width: 8),
              const AppToolButton(
                icon: Icons.fit_screen_outlined,
                filled: true,
              ),
              const SizedBox(width: 8),
              const AppToolButton(icon: Icons.more_horiz_rounded, filled: true),
            ],
          ),
        ),
      ],
    );
  }
}

class _ControlIconButton extends StatelessWidget {
  const _ControlIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPressed,
      child: SizedBox(
        width: 38,
        height: 38,
        child: Icon(
          icon,
          color: Colors.white.withValues(alpha: 0.74),
          size: 22,
        ),
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.playing, required this.onTap});

  final bool playing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(32),
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: palette.primary,
          boxShadow: [
            BoxShadow(
              color: palette.primary.withValues(alpha: 0.32),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(
          playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }
}

class _EmptyPlayerState extends StatelessWidget {
  const _EmptyPlayerState({required this.onOpenFile});

  final VoidCallback onOpenFile;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: palette.primarySoft,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Icon(
              Icons.video_file_outlined,
              size: 42,
              color: palette.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '打开一个本地视频',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '选择 mp4、mov、mkv 等文件后即可开始播放。',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: palette.softText,
            ),
          ),
          const SizedBox(height: 24),
          AppPillButton(
            onPressed: onOpenFile,
            icon: Icons.folder_open_rounded,
            label: '选择视频文件',
          ),
        ],
      ),
    );
  }
}
