import 'package:isar_community/isar.dart';
import 'package:path/path.dart' as p;

import '../models/app_settings.dart';
import '../models/favorite_folder.dart';
import '../models/media_item.dart';
import '../models/playlist_entry.dart';

class LibraryRepository {
  const LibraryRepository(this.isar);

  final Isar isar;

  IsarCollection<AppSettings> get _settings => isar.collection<AppSettings>();
  IsarCollection<FavoriteFolder> get _favoriteFolders =>
      isar.collection<FavoriteFolder>();
  IsarCollection<MediaItem> get _items => isar.collection<MediaItem>();
  IsarCollection<PlaylistEntry> get _playlists =>
      isar.collection<PlaylistEntry>();

  Stream<AppSettings> watchSettings() async* {
    final existing = await getSettings();
    yield existing;

    yield* _settings
        .where()
        .settingsIdEqualTo(AppSettings.singletonId)
        .watch(fireImmediately: false)
        .map((items) => items.isEmpty ? AppSettings.defaults() : items.first);
  }

  Future<AppSettings> getSettings() async {
    final settings = await _settings
        .filter()
        .settingsIdEqualTo(AppSettings.singletonId)
        .findFirst();
    if (settings != null) {
      return settings;
    }

    final defaults = AppSettings.defaults();
    await isar.writeTxn(() async {
      await _settings.put(defaults);
    });
    return defaults;
  }

  Future<void> saveSettings(AppSettings settings) async {
    settings.settingsId = AppSettings.singletonId;
    settings.updatedAt = DateTime.now();
    await isar.writeTxn(() async {
      await _settings.put(settings);
    });
  }

  Stream<List<MediaItem>> watchAllMedia() {
    return _items.where().sortBySortOrder().watch(fireImmediately: true);
  }

  Stream<List<PlaylistEntry>> watchPlaylists() {
    return _playlists.where().sortBySortOrder().watch(fireImmediately: true);
  }

  Stream<List<FavoriteFolder>> watchFavoriteFolders() {
    return _favoriteFolders.where().sortBySortOrder().watch(
      fireImmediately: true,
    );
  }

  Future<List<MediaItem>> searchHistory(String query) {
    final normalized = query.trim().toLowerCase();
    return _items
        .filter()
        .lastPlayedAtIsNotNull()
        .optional(
          normalized.isNotEmpty,
          (q) => q.group(
            (g) => g
                .titleContains(normalized, caseSensitive: false)
                .or()
                .subtitleContains(normalized, caseSensitive: false)
                .or()
                .genreLineContains(normalized, caseSensitive: false),
          ),
        )
        .sortByLastPlayedAtDesc()
        .findAll();
  }

  Future<MediaItem?> getByMediaId(String mediaId) {
    return _items.filter().mediaIdEqualTo(mediaId).findFirst();
  }

  Future<MediaItem> upsertLocalFile(String path, {String? bookmark}) async {
    final normalizedPath = p.normalize(path);
    final mediaId = 'file:$normalizedPath';
    final existing = await getByMediaId(mediaId);
    final fileName = p.basenameWithoutExtension(normalizedPath);
    final now = DateTime.now();
    final item = existing ?? MediaItem();

    item
      ..mediaId = mediaId
      ..title = fileName.isEmpty ? p.basename(normalizedPath) : fileName
      ..subtitle = p.dirname(normalizedPath)
      ..source = normalizedPath
      ..bookmark = bookmark ?? existing?.bookmark
      ..metaLine = p
          .extension(normalizedPath)
          .replaceFirst('.', '')
          .toUpperCase()
      ..lastPlayedAt = now
      ..sortOrder = existing?.sortOrder ?? now.millisecondsSinceEpoch;

    await isar.writeTxn(() async {
      await _items.put(item);
    });

    return item;
  }

  Future<void> updateBookmark(String mediaId, String bookmark) async {
    final item = await getByMediaId(mediaId);
    if (item == null) {
      return;
    }

    item.bookmark = bookmark;
    await isar.writeTxn(() async {
      await _items.put(item);
    });
  }

  Future<void> updateArtwork(String mediaId, String artworkPath) async {
    final item = await getByMediaId(mediaId);
    if (item == null) {
      return;
    }

    item.artworkUrl = artworkPath;
    await isar.writeTxn(() async {
      await _items.put(item);
    });
  }

  Future<void> updateProgress({
    required String mediaId,
    required Duration position,
    required Duration duration,
  }) async {
    final item = await getByMediaId(mediaId);
    if (item == null) {
      return;
    }

    item.progressMillis = position.inMilliseconds;
    item.durationMillis = duration.inMilliseconds > 0
        ? duration.inMilliseconds
        : item.durationMillis;
    item.lastPlayedAt = DateTime.now();
    item.isCompleted =
        item.durationMillis > 0 &&
        item.progressMillis >= item.durationMillis * 0.98;

    await isar.writeTxn(() async {
      await _items.put(item);
    });
  }

  Future<void> toggleFavorite(String mediaId) async {
    final item = await getByMediaId(mediaId);
    if (item == null) {
      return;
    }

    item.isFavorite = !item.isFavorite;
    await isar.writeTxn(() async {
      await _items.put(item);
    });
  }

  Future<void> createFavoriteFolder(String title) async {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      return;
    }

    final existingCount = await _favoriteFolders.count();
    final folder = FavoriteFolder()
      ..folderId = 'favorite-${DateTime.now().millisecondsSinceEpoch}'
      ..title = trimmedTitle
      ..description = '用于整理你主动收藏的视频'
      ..sortOrder = existingCount + 1;

    await isar.writeTxn(() async {
      await _favoriteFolders.put(folder);
    });
  }

  Future<void> addMediaToFavoriteFolder({
    required String folderId,
    required String mediaId,
  }) async {
    final folder = await _favoriteFolders
        .filter()
        .folderIdEqualTo(folderId)
        .findFirst();
    if (folder == null || folder.mediaIds.contains(mediaId)) {
      return;
    }

    folder.mediaIds = [...folder.mediaIds, mediaId];
    await isar.writeTxn(() async {
      await _favoriteFolders.put(folder);
    });
  }

  Future<void> removeMediaFromFavoriteFolder({
    required String folderId,
    required String mediaId,
  }) async {
    final folder = await _favoriteFolders
        .filter()
        .folderIdEqualTo(folderId)
        .findFirst();
    if (folder == null || !folder.mediaIds.contains(mediaId)) {
      return;
    }

    folder.mediaIds = folder.mediaIds
        .where((existingMediaId) => existingMediaId != mediaId)
        .toList();
    await isar.writeTxn(() async {
      await _favoriteFolders.put(folder);
    });
  }

  Future<void> resetProgress(String mediaId) async {
    final item = await getByMediaId(mediaId);
    if (item == null) {
      return;
    }

    item.progressMillis = 0;
    item.isCompleted = false;
    item.lastPlayedAt = DateTime.now();
    await isar.writeTxn(() async {
      await _items.put(item);
    });
  }

  Future<void> clearHistory() async {
    final items = await _items.where().findAll();
    for (final item in items) {
      item.progressMillis = 0;
      item.lastPlayedAt = null;
      item.isCompleted = false;
    }
    await isar.writeTxn(() async {
      await _items.putAll(items);
    });
  }

  Future<void> createPlaylist(String title) async {
    final existingCount = await _playlists.count();
    final playlist = PlaylistEntry()
      ..playlistId = 'playlist-${DateTime.now().millisecondsSinceEpoch}'
      ..title = title
      ..description = '新建播放列表'
      ..sortOrder = existingCount + 1;
    await isar.writeTxn(() async {
      await _playlists.put(playlist);
    });
  }
}
