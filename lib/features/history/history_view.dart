import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/formatters.dart';
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

    return Padding(
      padding: EdgeInsets.all(compact ? 16 : 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '历史记录',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              const _ActionIcon(icon: Icons.fit_screen_outlined),
              const SizedBox(width: 8),
              const _ActionIcon(icon: Icons.fullscreen_outlined),
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
              const _ActionIcon(icon: Icons.filter_alt_outlined),
              const SizedBox(width: 16),
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
          const SizedBox(height: 18),
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
        const SizedBox(height: 12),
        for (final item in items) ...[
          _HistoryRow(item: item, compact: compact),
          const SizedBox(height: 14),
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
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        ref.read(currentMediaIdProvider.notifier).state = item.mediaId;
        ref.read(playerControllerProvider.notifier).openMedia(item);
        context.go(AppSection.nowPlaying.path);
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: compact ? 96 : 112,
              height: compact ? 62 : 74,
              child: item.artworkUrl != null
                  ? Image.network(item.artworkUrl!, fit: BoxFit.cover)
                  : Container(color: palette.panelSecondaryBackground),
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
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.more_horiz_rounded, size: 18),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      minHeight: 3,
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

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: palette.panelSecondaryBackground,
      ),
      child: Icon(icon, size: 18),
    );
  }
}
