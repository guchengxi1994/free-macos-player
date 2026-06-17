import 'dart:io';

import 'package:isar_community/isar.dart';
// ignore: unused_import
import 'package:isar_community_flutter_libs/isar_flutter_libs.dart';

import '../models/app_settings.dart';
import '../models/media_item.dart';
import '../models/media_item_seed.dart';
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
      MediaItemSchema,
      PlaylistEntrySchema,
    ], directory: directory);

    final database = LocalDatabase._(isar);
    await database._seedIfNeeded();
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

  Future<void> _seedIfNeeded() async {
    final settingsCount = await isar.collection<AppSettings>().count();
    if (settingsCount == 0) {
      await isar.writeTxn(() async {
        await isar.collection<AppSettings>().put(AppSettings.defaults());
      });
    }

    final count = await isar.collection<MediaItem>().count();
    if (count > 0) {
      return;
    }

    final seed = buildSeedBundle();
    await isar.writeTxn(() async {
      await isar.collection<MediaItem>().putAll(seed.mediaItems);
      await isar.collection<PlaylistEntry>().putAll(seed.playlists);
    });
  }
}
