import 'dart:async';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers.dart';
import '../app/app_nav.dart';

const _videoTypeGroup = XTypeGroup(
  label: 'Video',
  extensions: ['mp4', 'm4v', 'mov', 'mkv', 'avi', 'webm'],
  mimeTypes: ['video/mp4', 'video/quicktime', 'video/x-matroska'],
  uniformTypeIdentifiers: ['public.movie', 'public.video', 'public.mpeg-4'],
);

const _openFileChannel = MethodChannel('free_macos_player/open_file');

Future<void> pickAndOpenVideo(WidgetRef ref, GoRouter router) async {
  final file = await openFile(acceptedTypeGroups: const [_videoTypeGroup]);
  final path = file?.path;
  if (path == null || path.isEmpty) {
    return;
  }

  await openVideoPath(ref, router, path);
}

Future<void> openVideoPath(WidgetRef ref, GoRouter router, String path) async {
  final repository = await ref.read(libraryRepositoryProvider.future);
  final media = await repository.upsertLocalFile(path);
  ref.read(currentMediaIdProvider.notifier).state = media.mediaId;
  await ref.read(playerControllerProvider.notifier).openMedia(media);
  router.go(AppSection.nowPlaying.path);
}

class MacosOpenFileListener {
  MacosOpenFileListener({required this.ref, required this.router});

  final WidgetRef ref;
  final GoRouter router;

  bool _started = false;

  void start() {
    if (!Platform.isMacOS) {
      return;
    }

    if (_started) {
      return;
    }

    _started = true;
    _openFileChannel.setMethodCallHandler((call) async {
      if (call.method != 'openFile') {
        return;
      }

      final path = call.arguments as String?;
      if (path == null || path.isEmpty) {
        return;
      }

      await openVideoPath(ref, router, path);
    });

    unawaited(_drainPendingOpenFiles());
  }

  Future<void> _drainPendingOpenFiles() async {
    final pendingPaths = await _openFileChannel.invokeListMethod<String>(
      'takePendingOpenFiles',
    );
    if (pendingPaths == null) {
      return;
    }

    for (final path in pendingPaths) {
      if (path.isNotEmpty) {
        await openVideoPath(ref, router, path);
      }
    }
  }
}
