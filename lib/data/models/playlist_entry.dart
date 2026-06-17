import 'package:isar_community/isar.dart';

part 'playlist_entry.g.dart';

@collection
class PlaylistEntry {
  PlaylistEntry({
    this.id = Isar.autoIncrement,
  });

  Id id;

  @Index(unique: true, replace: true)
  late String playlistId;

  late String title;
  String? description;
  List<String> mediaIds = [];
  DateTime createdAt = DateTime.now();
  int sortOrder = 0;
}
