import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/media_item.dart';
import '../../providers.dart';

class NowPlayingView extends ConsumerWidget {
  const NowPlayingView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppPalette.of(context);
    final media = ref.watch(currentMediaProvider);
    final playback = ref.watch(playerControllerProvider);
    final playerController = ref.read(playerControllerProvider.notifier);

    if (media == null) {
      return const Center(child: Text('没有可播放内容'));
    }

    final sliderMax = playback.duration.inMilliseconds <= 0
        ? 1.0
        : playback.duration.inMilliseconds / 1000;
    final sliderValue = playback.position.inMilliseconds <= 0
        ? 0.0
        : (playback.position.inMilliseconds / 1000).clamp(0.0, sliderMax);

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      child: Column(
        children: [
          _HeaderBar(
            title: media.title,
            subtitle: media.subtitle,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(24),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned.fill(
                      child: media.backdropUrl != null
                          ? Image.network(
                              media.backdropUrl!,
                              fit: BoxFit.cover,
                            )
                          : const SizedBox.shrink(),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              palette.overlay,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Video(
                        controller: playerController.videoController,
                        controls: NoVideoControls,
                        fit: BoxFit.contain,
                      ),
                    ),
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
                          child: Text(
                            playback.errorText!,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    Positioned(
                      left: 28,
                      right: 28,
                      bottom: 20,
                      child: Column(
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              inactiveTrackColor:
                                  const Color.fromRGBO(255, 255, 255, 0.20),
                              activeTrackColor: palette.primary,
                              thumbColor: palette.primary,
                            ),
                            child: Slider(
                              value: sliderValue,
                              max: sliderMax,
                              onChanged: (value) {
                                ref
                                    .read(playerControllerProvider.notifier)
                                    .seek(
                                      Duration(
                                        milliseconds: (value * 1000).round(),
                                      ),
                                    );
                              },
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                formatDuration(playback.position),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const Spacer(),
                              Text(
                                formatDuration(
                                  playback.duration == Duration.zero
                                      ? media.duration
                                      : playback.duration,
                                ),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.tv_rounded, size: 20),
                              const Spacer(),
                              IconButton(
                                onPressed: () => playerController.seekRelative(
                                  const Duration(seconds: -10),
                                ),
                                icon: const Icon(Icons.skip_previous_rounded),
                              ),
                              IconButton(
                                onPressed: () => playerController.seekRelative(
                                  const Duration(seconds: -5),
                                ),
                                icon: const Icon(Icons.fast_rewind_rounded),
                              ),
                              const SizedBox(width: 4),
                              _PlayButton(
                                playing: playback.isPlaying,
                                onTap: playerController.togglePlayback,
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                onPressed: () => playerController.seekRelative(
                                  const Duration(seconds: 5),
                                ),
                                icon: const Icon(Icons.fast_forward_rounded),
                              ),
                              IconButton(
                                onPressed: () => playerController.seekRelative(
                                  const Duration(seconds: 10),
                                ),
                                icon: const Icon(Icons.skip_next_rounded),
                              ),
                              const Spacer(),
                              const Icon(Icons.volume_up_rounded, size: 20),
                              SizedBox(
                                width: 120,
                                child: Slider(
                                  value: playback.volume.clamp(0, 100),
                                  max: 100,
                                  onChanged: (value) {
                                    ref
                                        .read(playerControllerProvider.notifier)
                                        .setVolume(value);
                                  },
                                ),
                              ),
                              IconButton(
                                onPressed: () {},
                                icon: const Icon(Icons.fullscreen_rounded),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderBar extends StatelessWidget {
  const _HeaderBar({
    required this.title,
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall,
                ),
            ],
          ),
        ),
        const _HeaderIcon(icon: Icons.cast_outlined),
        const SizedBox(width: 8),
        const _HeaderIcon(icon: Icons.fit_screen_outlined),
        const SizedBox(width: 8),
        const _HeaderIcon(icon: Icons.more_horiz_rounded),
      ],
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: const Color.fromRGBO(255, 255, 255, 0.04),
      ),
      child: Icon(icon, size: 16),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({
    required this.playing,
    required this.onTap,
  });

  final bool playing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: Container(
        width: 54,
        height: 54,
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
          size: 30,
        ),
      ),
    );
  }
}
