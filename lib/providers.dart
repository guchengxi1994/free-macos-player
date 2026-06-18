import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'data/models/app_settings.dart';
import 'data/models/favorite_folder.dart';
import 'data/models/media_item.dart';
import 'data/models/playlist_entry.dart';
import 'data/repositories/library_repository.dart';
import 'data/services/local_database.dart';
import 'features/player/player_controller.dart';
import 'features/player/player_state.dart';

final localDatabaseProvider = FutureProvider<LocalDatabase>((ref) async {
  return LocalDatabase.open();
});

final darkModeProvider = StateProvider<bool>((ref) => true);

final autoPlayOnOpenProvider = StateProvider<bool>((ref) => true);

final resumeRecentOnLaunchProvider = StateProvider<bool>((ref) => true);

final currentMediaIdProvider = StateProvider<String?>((ref) => null);

final playerControllerProvider =
    NotifierProvider<PlayerController, PlaybackSnapshot>(PlayerController.new);

final mediaLibraryProvider = StreamProvider<List<MediaItem>>((ref) async* {
  final database = await ref.watch(localDatabaseProvider.future);
  final repository = LibraryRepository(database.isar);
  yield* repository.watchAllMedia();
});

final playlistsProvider = StreamProvider<List<PlaylistEntry>>((ref) async* {
  final database = await ref.watch(localDatabaseProvider.future);
  final repository = LibraryRepository(database.isar);
  yield* repository.watchPlaylists();
});

final favoriteFoldersProvider = StreamProvider<List<FavoriteFolder>>((
  ref,
) async* {
  final database = await ref.watch(localDatabaseProvider.future);
  final repository = LibraryRepository(database.isar);
  yield* repository.watchFavoriteFolders();
});

final libraryRepositoryProvider = FutureProvider<LibraryRepository>((
  ref,
) async {
  final database = await ref.watch(localDatabaseProvider.future);
  return LibraryRepository(database.isar);
});

final appSettingsProvider = StreamProvider<AppSettings>((ref) async* {
  final repository = await ref.watch(libraryRepositoryProvider.future);
  yield* repository.watchSettings();
});

final currentMediaProvider = Provider<MediaItem?>((ref) {
  final mediaList = ref
      .watch(mediaLibraryProvider)
      .maybeWhen(data: (value) => value, orElse: () => const <MediaItem>[]);
  final currentId = ref.watch(currentMediaIdProvider);
  if (currentId != null) {
    for (final item in mediaList) {
      if (item.mediaId == currentId) {
        return item;
      }
    }
  }

  if (ref.watch(resumeRecentOnLaunchProvider)) {
    final history = mediaList.where((item) => item.hasHistory).toList()
      ..sort((a, b) {
        final aTime = a.lastPlayedAt?.millisecondsSinceEpoch ?? 0;
        final bTime = b.lastPlayedAt?.millisecondsSinceEpoch ?? 0;
        return bTime.compareTo(aTime);
      });
    if (history.isNotEmpty) {
      return history.first;
    }
  }

  for (final item in mediaList) {
    if (item.spotlight) {
      return item;
    }
  }

  return mediaList.isEmpty ? null : mediaList.first;
});

final historyQueryProvider = StateProvider<String>((ref) => '');

final filteredHistoryProvider = Provider<List<MediaItem>>((ref) {
  final mediaList = ref
      .watch(mediaLibraryProvider)
      .maybeWhen(data: (value) => value, orElse: () => const <MediaItem>[]);
  final query = ref.watch(historyQueryProvider).trim().toLowerCase();

  final result = mediaList.where((item) => item.hasHistory).toList()
    ..sort((a, b) {
      final aTime = a.lastPlayedAt?.millisecondsSinceEpoch ?? 0;
      final bTime = b.lastPlayedAt?.millisecondsSinceEpoch ?? 0;
      return bTime.compareTo(aTime);
    });

  if (query.isEmpty) {
    return result;
  }

  return result.where((item) {
    final haystacks = [item.title, item.subtitle ?? '', item.genreLine ?? ''];
    return haystacks.any((value) => value.toLowerCase().contains(query));
  }).toList();
});

final favoriteItemsProvider = Provider<List<MediaItem>>((ref) {
  final mediaList = ref
      .watch(mediaLibraryProvider)
      .maybeWhen(data: (value) => value, orElse: () => const <MediaItem>[]);
  return mediaList.where((item) => item.isFavorite).toList();
});
