import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/media_item.dart';
import '../../providers.dart';

class FavoritesView extends ConsumerWidget {
  const FavoritesView({super.key, required this.media});

  final MediaItem media;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppPalette.of(context);

    return Stack(
      children: [
        Positioned.fill(
          child: media.backdropUrl == null
              ? DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        palette.panelBackground,
                        palette.panelSecondaryBackground,
                      ],
                    ),
                  ),
                )
              : Image.network(media.backdropUrl!, fit: BoxFit.cover),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  palette.panelBackground.withValues(alpha: 0.96),
                  palette.panelBackground.withValues(alpha: 0.82),
                  palette.overlay.withValues(alpha: 0.54),
                ],
              ),
            ),
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 52,
                ),
                child: _DetailContent(media: media),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _DetailContent extends ConsumerWidget {
  const _DetailContent({required this.media});

  final MediaItem media;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppPalette.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Poster(media: media),
            const SizedBox(width: 28),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      media.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      media.metaLine ??
                          '${media.year ?? ''} · ${formatDuration(media.duration)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: palette.softText,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _Tag(text: media.qualityLabel ?? '1080p'),
                        _Tag(text: media.audioLabel ?? 'DDP 5.1'),
                        _Tag(text: media.languageLabel ?? 'ENG'),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _PrimaryActionButton(
                          icon: Icons.play_arrow_rounded,
                          label: '继续播放',
                          onTap: () {
                            ref.read(currentMediaIdProvider.notifier).state =
                                media.mediaId;
                            ref
                                .read(playerControllerProvider.notifier)
                                .openMedia(media);
                          },
                        ),
                        _GhostActionButton(
                          icon: Icons.schedule_rounded,
                          label: '从头播放',
                          onTap: () async {
                            ref.read(currentMediaIdProvider.notifier).state =
                                media.mediaId;
                            await ref
                                .read(playerControllerProvider.notifier)
                                .openMedia(media);
                            await ref
                                .read(playerControllerProvider.notifier)
                                .resetAndPlayCurrent();
                          },
                        ),
                        _GhostActionButton(
                          icon: media.isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          label: media.isFavorite ? '已收藏' : '收藏',
                          onTap: () {
                            ref
                                .read(libraryRepositoryProvider.future)
                                .then(
                                  (repo) => repo.toggleFavorite(media.mediaId),
                                );
                          },
                        ),
                        _GhostActionButton(
                          icon: Icons.more_horiz_rounded,
                          label: '更多',
                          onTap: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),
        Row(
          children: [
            Text(
              '章节',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text(
              '查看全部',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: palette.softText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 132,
          child: media.chapters.isEmpty
              ? _EmptyChapters(message: media.synopsis ?? '暂无章节信息')
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: media.chapters.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 14),
                  itemBuilder: (context, index) {
                    return _ChapterCard(
                      chapter: media.chapters[index],
                      index: index,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _Poster extends StatelessWidget {
  const _Poster({required this.media});

  final MediaItem media;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            width: 178,
            height: 234,
            child: media.artworkUrl != null
                ? Image.network(media.artworkUrl!, fit: BoxFit.cover)
                : Container(color: palette.panelSecondaryBackground),
          ),
        ),
        Positioned(
          right: 12,
          bottom: 12,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: palette.overlay.withValues(alpha: 0.82),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.play_arrow_rounded, color: palette.primary),
          ),
        ),
      ],
    );
  }
}

class _ChapterCard extends StatelessWidget {
  const _ChapterCard({required this.chapter, required this.index});

  final ChapterCue chapter;
  final int index;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final theme = Theme.of(context);

    return SizedBox(
      width: 148,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: 82,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  chapter.thumbnailUrl != null
                      ? Image.network(chapter.thumbnailUrl!, fit: BoxFit.cover)
                      : Container(color: palette.panelSecondaryBackground),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.keyboard_double_arrow_right_rounded,
                        size: 16,
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${index + 1}. ${chapter.title}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formatDuration(Duration(milliseconds: chapter.startMillis)),
            style: theme.textTheme.bodySmall?.copyWith(color: palette.softText),
          ),
        ],
      ),
    );
  }
}

class _EmptyChapters extends StatelessWidget {
  const _EmptyChapters({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.panelSecondaryBackground.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.stroke),
      ),
      child: Text(
        message,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: palette.softText),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9),
        color: palette.panelSecondaryBackground.withValues(alpha: 0.82),
        border: Border.all(color: palette.stroke),
      ),
      child: Text(text, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return FilledButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: palette.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class _GhostActionButton extends StatelessWidget {
  const _GhostActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        backgroundColor: palette.panelSecondaryBackground.withValues(
          alpha: 0.86,
        ),
        side: BorderSide(color: palette.stroke),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
