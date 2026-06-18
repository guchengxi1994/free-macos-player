import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/formatters.dart';
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
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
      child: Column(
        children: [
          _HeaderBar(
            title: media.title,
            subtitle: media.subtitle,
            onOpenFile: () => pickAndOpenVideo(ref, GoRouter.of(context)),
          ),
          const SizedBox(height: 18),
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

class _VideoStage extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppPalette.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(24),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (media.backdropUrl != null || media.artworkUrl != null)
              Positioned.fill(
                child: MediaArtwork(
                  source: media.backdropUrl ?? media.artworkUrl,
                  fit: BoxFit.cover,
                ),
              ),
            Positioned.fill(
              child: Video(
                controller: playerController.videoController,
                controls: NoVideoControls,
                fit: BoxFit.contain,
              ),
            ),
            const Positioned.fill(child: _VideoChromeGradient()),
            if (playback.isBuffering || playback.isOpening)
              const Center(child: CircularProgressIndicator()),
            if (playback.errorText != null)
              Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 420),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: palette.overlay,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(playback.errorText!, textAlign: TextAlign.center),
                ),
              ),
            Positioned(
              left: 30,
              right: 30,
              bottom: 24,
              child: _PlayerControls(
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
          stops: const [0.45, 0.78, 1],
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.26),
            Colors.black.withValues(alpha: 0.78),
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
        const SizedBox(height: 14),
        SizedBox(
          height: 64,
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
                        width: 132,
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
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
            ],
          ),
        ),
        SizedBox(
          width: 104,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _HeaderIcon(icon: Icons.folder_open_rounded, onTap: onOpenFile),
              const SizedBox(width: 8),
              const _HeaderIcon(icon: Icons.fit_screen_outlined),
              const SizedBox(width: 8),
              const _HeaderIcon(icon: Icons.more_horiz_rounded),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: const Color.fromRGBO(255, 255, 255, 0.05),
        ),
        child: Icon(icon, size: 17),
      ),
    );
  }
}

class _ControlIconButton extends StatelessWidget {
  const _ControlIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon),
      color: Colors.white.withValues(alpha: 0.74),
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
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: palette.primary,
          boxShadow: [
            BoxShadow(
              color: palette.primary.withValues(alpha: 0.32),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(
          playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
          color: Colors.white,
          size: 34,
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
          FilledButton.icon(
            onPressed: onOpenFile,
            icon: const Icon(Icons.folder_open_rounded),
            label: const Text('选择视频文件'),
          ),
        ],
      ),
    );
  }
}
