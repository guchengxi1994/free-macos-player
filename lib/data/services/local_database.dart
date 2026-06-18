import 'dart:io';

import 'package:isar_community/isar.dart';
// ignore: unused_import
import 'package:isar_community_flutter_libs/isar_flutter_libs.dart';

import '../models/app_settings.dart';
import '../models/favorite_folder.dart';
import '../models/media_item.dart';
import '../models/playlist_entry.dart';

class LocalDatabase {
  LocalDatabase._(this.isar);

  final Isar isar;

  static Future<LocalDatabase> open() async {
    final existing = Isar.getInstance();
    if (existing != null) {
      return LocalDatabase._(existing);
    }

    final directory = await _resolveDirectory();
    final isar = await Isar.open([
      AppSettingsSchema,
      FavoriteFolderSchema,
      MediaItemSchema,
      PlaylistEntrySchema,
    ], directory: directory);

    final database = LocalDatabase._(isar);
    await database._prepareDefaults();
    return database;
  }

  static Future<String> _resolveDirectory() async {
    final home = Platform.environment['HOME'];
    if (home == null || home.isEmpty) {
      final fallback = Directory.systemTemp.createTempSync('free_macos_player');
      return fallback.path;
    }

    final support = Directory(
      '$home/Library/Application Support/free_macos_player',
    );
    if (!support.existsSync()) {
      support.createSync(recursive: true);
    }
    return support.path;
  }

  Future<void> _prepareDefaults() async {
    final settingsCount = await isar.collection<AppSettings>().count();
    if (settingsCount == 0) {
      await isar.writeTxn(() async {
        await isar.collection<AppSettings>().put(AppSettings.defaults());
      });
    }

    await _removeLegacySeedData();
  }

  Future<void> _removeLegacySeedData() async {
    const legacySeedIds = {
      'blue-planet-one-ocean',
      'interstellar-2014',
      'your-name-2016',
      'shawshank-redemption-1994',
      'planet-earth-fresh-water',
    };

    final mediaItems = await isar.collection<MediaItem>().where().findAll();
    final idsToDelete = mediaItems
        .where((item) => legacySeedIds.contains(item.mediaId))
        .map((item) => item.id)
        .toList();

    if (idsToDelete.isEmpty) {
      return;
    }

    await isar.writeTxn(() async {
      await isar.collection<MediaItem>().deleteAll(idsToDelete);
    });
  }
}
