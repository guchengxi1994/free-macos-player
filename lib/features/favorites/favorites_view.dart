import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
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
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '收藏夹是你主动创建的文件夹，播放视频不会自动加入这里。',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: palette.softText,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _showCreateFolderDialog(context, ref),
                  icon: const Icon(Icons.create_new_folder_outlined),
                  label: const Text('新建收藏夹'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
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
                child: GridView.builder(
                  itemCount: folders.length,
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 360,
                    mainAxisExtent: 236,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                  ),
                  itemBuilder: (context, index) {
                    final folder = folders[index];
                    final folderMedia = folder.mediaIds
                        .map((mediaId) => mediaById[mediaId])
                        .whereType<MediaItem>()
                        .toList();
                    return _FavoriteFolderCard(
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
      return AlertDialog(
        title: const Text('新建收藏夹'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '例如：周末电影、学习资料、待重看'),
          onSubmitted: (value) {
            Navigator.of(context).pop(value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('创建'),
          ),
        ],
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

class _FavoriteFolderCard extends ConsumerWidget {
  const _FavoriteFolderCard({
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.panelSecondaryBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.stroke),
        boxShadow: [
          BoxShadow(
            color: palette.shadow,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FolderPreview(mediaItems: mediaItems),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  folder.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: palette.primarySoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${mediaItems.length} 个视频',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: palette.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            folder.description ?? '主动加入的视频会出现在这里',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(color: palette.softText),
          ),
          const Spacer(),
          if (current == null)
            Text(
              '先打开一个视频，再添加到收藏夹',
              style: theme.textTheme.bodySmall?.copyWith(
                color: palette.softText,
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
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
                icon: Icon(
                  currentInFolder
                      ? Icons.check_circle_rounded
                      : Icons.add_rounded,
                ),
                label: Text(currentInFolder ? '已加入当前视频' : '加入当前视频'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
        ],
      ),
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
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 86,
        width: double.infinity,
        child: previewItems.isEmpty
            ? DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [palette.primarySoft, palette.panelBackground],
                  ),
                ),
                child: Icon(
                  Icons.folder_special_outlined,
                  color: palette.primary,
                  size: 38,
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
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: palette.panelSecondaryBackground,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: palette.stroke),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: palette.primarySoft,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.create_new_folder_outlined,
                size: 38,
                color: palette.primary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              '还没有收藏夹',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '先创建一个收藏夹，再把当前视频主动加入进去。这里不会自动展示播放过的视频。',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: palette.softText,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded),
              label: const Text('新建收藏夹'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
