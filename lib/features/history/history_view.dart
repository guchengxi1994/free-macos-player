import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_controls.dart';
import '../../core/widgets/media_artwork.dart';
import '../../data/models/media_item.dart';
import '../../providers.dart';
import '../app/app_nav.dart';

class HistoryView extends ConsumerWidget {
  const HistoryView({super.key, required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppPalette.of(context);
    final theme = Theme.of(context);
    final items = ref.watch(filteredHistoryProvider);

    return ColoredBox(
      color: palette.panelBackground,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          compact ? 16 : 22,
          compact ? 16 : 22,
          compact ? 16 : 18,
          compact ? 16 : 18,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '历史记录',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                const AppToolButton(icon: Icons.fit_screen_outlined),
                const SizedBox(width: 8),
                const AppToolButton(icon: Icons.fullscreen_outlined),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) {
                      ref.read(historyQueryProvider.notifier).state = value;
                    },
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search_rounded),
                      hintText: '搜索历史记录',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const AppToolButton(icon: Icons.filter_alt_outlined),
                const SizedBox(width: 14),
                InkWell(
                  onTap: () {
                    ref
                        .read(libraryRepositoryProvider.future)
                        .then((repo) => repo.clearHistory());
                  },
                  child: Text(
                    '清空',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: palette.softText,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  _HistoryGroup(
                    title: '今天',
                    items: items.where(_isToday).toList(),
                    compact: compact,
                  ),
                  const SizedBox(height: 14),
                  _HistoryGroup(
                    title: '昨天',
                    items: items.where(_isYesterday).toList(),
                    compact: compact,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isToday(MediaItem item) {
    final time = item.lastPlayedAt;
    if (time == null) return false;
    final now = DateTime.now();
    return time.year == now.year &&
        time.month == now.month &&
        time.day == now.day;
  }

  bool _isYesterday(MediaItem item) {
    final time = item.lastPlayedAt;
    if (time == null) return false;
    final now = DateTime.now().subtract(const Duration(days: 1));
    return time.year == now.year &&
        time.month == now.month &&
        time.day == now.day;
  }
}

class _HistoryGroup extends StatelessWidget {
  const _HistoryGroup({
    required this.title,
    required this.items,
    required this.compact,
  });

  final String title;
  final List<MediaItem> items;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        for (final item in items) ...[
          _HistoryRow(item: item, compact: compact),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _HistoryRow extends ConsumerWidget {
  const _HistoryRow({required this.item, required this.compact});

  final MediaItem item;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppPalette.of(context);
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        ref.read(currentMediaIdProvider.notifier).state = item.mediaId;
        ref.read(playerControllerProvider.notifier).openMedia(item);
        context.go(AppSection.nowPlaying.path);
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              width: compact ? 92 : 102,
              height: compact ? 58 : 64,
              child: MediaArtwork(source: item.artworkUrl),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(
                        Icons.more_horiz_rounded,
                        size: 18,
                        color: palette.softText,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      minHeight: 2,
                      value: item.watchedRatio,
                      backgroundColor: palette.stroke,
                      valueColor: AlwaysStoppedAnimation(palette.primary),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        item.isCompleted
                            ? '已观看 100%'
                            : formatProgressLabel(item.progress, item.duration),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: palette.softText,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        formatDuration(item.duration),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: palette.softText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
