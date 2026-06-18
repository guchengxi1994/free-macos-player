import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_palette.dart';
import '../../core/widgets/app_controls.dart';
import '../../data/models/media_item.dart';
import '../../providers.dart';
import '../app/app_nav.dart';

class PlaylistsView extends ConsumerWidget {
  const PlaylistsView({super.key, required this.expanded});

  final bool expanded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppPalette.of(context);
    final theme = Theme.of(context);
    final items = ref.watch(networkMediaProvider);

    return ColoredBox(
      color: palette.panelBackground,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '网络资源',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                AppPillButton(
                  onPressed: () => _showAddNetworkSourceDialog(
                    context,
                    ref,
                    playAfterSave: true,
                  ),
                  icon: Icons.add_link_rounded,
                  label: '添加链接',
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (items.isEmpty)
              Expanded(
                child: _EmptyNetworkState(
                  onAdd: () => _showAddNetworkSourceDialog(
                    context,
                    ref,
                    playAfterSave: true,
                  ),
                ),
              )
            else
              Expanded(
                child: GridView.builder(
                  itemCount: items.length,
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 310,
                    mainAxisExtent: 206,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                  ),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _NetworkSourceCard(
                      item: item,
                      onPlay: () => _playNetworkSource(context, ref, item),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showAddNetworkSourceDialog(
  BuildContext context,
  WidgetRef ref, {
  required bool playAfterSave,
}) async {
  final titleController = TextEditingController();
  final urlController = TextEditingController();
  final result = await showDialog<_NetworkSourceInput>(
    context: context,
    builder: (context) {
      return AppDialogPanel(
        title: '添加网络资源',
        actions: [
          AppPillButton(
            onPressed: () => Navigator.of(context).pop(),
            label: '取消',
            tone: AppButtonTone.ghost,
          ),
          AppPillButton(
            onPressed: () {
              Navigator.of(context).pop(
                _NetworkSourceInput(
                  title: titleController.text,
                  url: urlController.text,
                ),
              );
            },
            label: '添加',
          ),
        ],
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: urlController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'https://example.com/video.m3u8',
              ),
              onSubmitted: (_) {
                Navigator.of(context).pop(
                  _NetworkSourceInput(
                    title: titleController.text,
                    url: urlController.text,
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(hintText: '名称（可选）'),
            ),
          ],
        ),
      );
    },
  );
  titleController.dispose();
  urlController.dispose();

  final input = result;
  if (input == null) {
    return;
  }

  final url = input.url.trim();
  final uri = Uri.tryParse(url);
  final valid =
      uri != null &&
      uri.hasScheme &&
      (uri.scheme == 'http' ||
          uri.scheme == 'https' ||
          uri.scheme == 'rtmp' ||
          uri.scheme == 'rtsp');
  if (!valid) {
    return;
  }

  final repository = await ref.read(libraryRepositoryProvider.future);
  final media = await repository.upsertNetworkSource(
    url: url,
    title: input.title,
  );

  if (playAfterSave && context.mounted) {
    await _playNetworkSource(context, ref, media);
  }
}

Future<void> _playNetworkSource(
  BuildContext context,
  WidgetRef ref,
  MediaItem item,
) async {
  ref.read(currentMediaIdProvider.notifier).state = item.mediaId;
  await ref.read(playerControllerProvider.notifier).openMedia(item);
  if (context.mounted) {
    context.go(AppSection.nowPlaying.path);
  }
}

class _NetworkSourceInput {
  const _NetworkSourceInput({required this.title, required this.url});

  final String title;
  final String url;
}

class _EmptyNetworkState extends StatelessWidget {
  const _EmptyNetworkState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: palette.primarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.add_link_rounded,
              size: 30,
              color: palette.primary,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            '暂无网络资源',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 22),
          AppPillButton(
            onPressed: onAdd,
            icon: Icons.add_rounded,
            label: '添加链接',
          ),
        ],
      ),
    );
  }
}

class _NetworkSourceCard extends StatelessWidget {
  const _NetworkSourceCard({required this.item, required this.onPlay});

  final MediaItem item;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final theme = Theme.of(context);
    final uri = Uri.tryParse(item.source);
    final host = uri?.host.isNotEmpty == true ? uri!.host : item.source;
    final scheme = uri?.scheme.toUpperCase() ?? 'URL';

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPlay,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: palette.panelSecondaryBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: palette.stroke),
            boxShadow: [
              BoxShadow(
                color: palette.shadow.withValues(alpha: 0.38),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [palette.primarySoft, palette.panelBackground],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        left: 14,
                        top: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: palette.overlay,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            scheme,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: palette.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: palette.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: palette.primary.withValues(alpha: 0.28),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                host,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: palette.softText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
