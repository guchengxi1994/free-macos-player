import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../core/widgets/app_controls.dart';
import '../../core/widgets/media_artwork.dart';
import '../../data/models/favorite_folder.dart';
import '../../data/models/media_item.dart';
import '../../providers.dart';

class FavoritesView extends ConsumerWidget {
  const FavoritesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppPalette.of(context);
    final theme = Theme.of(context);
    final folders = ref
        .watch(favoriteFoldersProvider)
        .maybeWhen(
          data: (value) => value,
          orElse: () => const <FavoriteFolder>[],
        );
    final mediaItems = ref
        .watch(mediaLibraryProvider)
        .maybeWhen(data: (value) => value, orElse: () => const <MediaItem>[]);
    final currentMedia = ref.watch(currentMediaProvider);
    final mediaById = {for (final item in mediaItems) item.mediaId: item};

    return ColoredBox(
      color: palette.panelBackground,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 26, 28, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '收藏夹',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '文件夹、片单、临时归档。',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: palette.softText,
                        ),
                      ),
                    ],
                  ),
                ),
                AppPillButton(
                  onPressed: () => _showCreateFolderDialog(context, ref),
                  icon: Icons.create_new_folder_outlined,
                  label: '新建收藏夹',
                ),
              ],
            ),
            const SizedBox(height: 22),
            if (folders.isEmpty)
              Expanded(
                child: _EmptyFavoritesState(
                  onCreate: () => _showCreateFolderDialog(context, ref),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: folders.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final folder = folders[index];
                    final folderMedia = folder.mediaIds
                        .map((mediaId) => mediaById[mediaId])
                        .whereType<MediaItem>()
                        .toList();
                    return _FavoriteFolderRow(
                      folder: folder,
                      mediaItems: folderMedia,
                      currentMedia: currentMedia,
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

Future<void> _showCreateFolderDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  final controller = TextEditingController();
  final title = await showDialog<String>(
    context: context,
    builder: (context) {
      return AppDialogPanel(
        title: '新建收藏夹',
        actions: [
          AppPillButton(
            onPressed: () => Navigator.of(context).pop(),
            label: '取消',
            tone: AppButtonTone.ghost,
          ),
          AppPillButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            label: '创建',
          ),
        ],
        child: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '例如：周末电影、学习资料、待重看'),
          onSubmitted: (value) {
            Navigator.of(context).pop(value);
          },
        ),
      );
    },
  );
  controller.dispose();

  final trimmedTitle = title?.trim();
  if (trimmedTitle == null || trimmedTitle.isEmpty) {
    return;
  }

  final repository = await ref.read(libraryRepositoryProvider.future);
  await repository.createFavoriteFolder(trimmedTitle);
}

class _FavoriteFolderRow extends ConsumerWidget {
  const _FavoriteFolderRow({
    required this.folder,
    required this.mediaItems,
    required this.currentMedia,
  });

  final FavoriteFolder folder;
  final List<MediaItem> mediaItems;
  final MediaItem? currentMedia;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppPalette.of(context);
    final theme = Theme.of(context);
    final current = currentMedia;
    final currentInFolder =
        current != null && folder.mediaIds.contains(current.mediaId);

    return Row(
      children: [
        _FolderPreview(mediaItems: mediaItems),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                folder.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                folder.description ?? '未命名分组',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: palette.softText,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '${mediaItems.length} 个视频',
          style: theme.textTheme.bodySmall?.copyWith(
            color: palette.softText,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 12),
        if (current == null)
          Text(
            '先打开视频',
            style: theme.textTheme.bodySmall?.copyWith(color: palette.softText),
          )
        else
          AppPillButton(
            onPressed: () async {
              final repository = await ref.read(
                libraryRepositoryProvider.future,
              );
              if (currentInFolder) {
                await repository.removeMediaFromFavoriteFolder(
                  folderId: folder.folderId,
                  mediaId: current.mediaId,
                );
              } else {
                await repository.addMediaToFavoriteFolder(
                  folderId: folder.folderId,
                  mediaId: current.mediaId,
                );
              }
            },
            icon: currentInFolder ? Icons.check_rounded : Icons.add_rounded,
            label: currentInFolder ? '已加入' : '加入当前',
            tone: currentInFolder
                ? AppButtonTone.primary
                : AppButtonTone.secondary,
            compact: true,
          ),
      ],
    );
  }
}

class _FolderPreview extends StatelessWidget {
  const _FolderPreview({required this.mediaItems});

  final List<MediaItem> mediaItems;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final previewItems = mediaItems.take(3).toList();

    return ClipRRect(
      borderRadius: BorderRadius.circular(7),
      child: SizedBox(
        width: 108,
        height: 66,
        child: previewItems.isEmpty
            ? DecoratedBox(
                decoration: BoxDecoration(color: palette.primarySoft),
                child: Icon(
                  Icons.folder_special_outlined,
                  color: palette.primary,
                  size: 28,
                ),
              )
            : Row(
                children: [
                  for (final item in previewItems)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 2),
                        child: MediaArtwork(source: item.artworkUrl),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _EmptyFavoritesState extends StatelessWidget {
  const _EmptyFavoritesState({required this.onCreate});

  final VoidCallback onCreate;

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
              Icons.create_new_folder_outlined,
              size: 30,
              color: palette.primary,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            '还没有收藏夹',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '创建一个文件夹。',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: palette.softText,
            ),
          ),
          const SizedBox(height: 24),
          AppPillButton(
            onPressed: onCreate,
            icon: Icons.add_rounded,
            label: '新建收藏夹',
          ),
        ],
      ),
    );
  }
}
