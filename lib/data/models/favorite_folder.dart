import 'package:isar_community/isar.dart';

part 'favorite_folder.g.dart';

@collection
class FavoriteFolder {
  FavoriteFolder({this.id = Isar.autoIncrement});

  Id id;

  @Index(unique: true, replace: true)
  late String folderId;

  late String title;
  String? description;
  List<String> mediaIds = [];
  DateTime createdAt = DateTime.now();
  int sortOrder = 0;
}

extension FavoriteFolderX on FavoriteFolder {
  bool contains(String mediaId) => mediaIds.contains(mediaId);
}
