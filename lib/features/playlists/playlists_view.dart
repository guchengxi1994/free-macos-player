import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../data/models/playlist_entry.dart';
import '../../providers.dart';

class PlaylistsView extends ConsumerWidget {
  const PlaylistsView({super.key, required this.expanded});

  final bool expanded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppPalette.of(context);
    final theme = Theme.of(context);
    final playlists = ref
        .watch(playlistsProvider)
        .maybeWhen(
          data: (value) => value,
          orElse: () => const <PlaylistEntry>[],
        );

    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '播放列表',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () {
                  ref
                      .read(libraryRepositoryProvider.future)
                      .then((repo) => repo.createPlaylist('新建播放列表'));
                },
                child: Row(
                  children: [
                    const Icon(Icons.add_rounded, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      '新建列表',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: palette.softText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (playlists.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: palette.primarySoft,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Icon(
                        Icons.video_library_outlined,
                        size: 36,
                        color: palette.primary,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      '还没有播放列表',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '创建一个播放列表，收藏你喜欢的视频',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: palette.softText,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () {
                        ref
                            .read(libraryRepositoryProvider.future)
                            .then((repo) => repo.createPlaylist('新建播放列表'));
                      },
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('新建播放列表'),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: playlists.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final playlist = playlists[index];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: palette.panelSecondaryBackground,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: palette.primarySoft,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.queue_music_rounded,
                            color: palette.primary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                playlist.title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                playlist.description ?? '',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: palette.softText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${playlist.mediaIds.length} 项',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: palette.softText,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
