import 'package:isar_community/isar.dart';

part 'media_item.g.dart';

@embedded
class ChapterCue {
  ChapterCue({this.title = '', this.startMillis = 0, this.thumbnailUrl});

  String title;
  int startMillis;
  String? thumbnailUrl;
}

@collection
class MediaItem {
  MediaItem({this.id = Isar.autoIncrement});

  Id id;

  @Index(unique: true, replace: true)
  late String mediaId;

  late String title;
  String? subtitle;
  late String source;
  String? bookmark;
  String? artworkUrl;
  String? backdropUrl;
  String? metaLine;
  String? genreLine;
  String? synopsis;
  String? qualityLabel;
  String? audioLabel;
  String? languageLabel;
  int? year;
  int durationMillis = 0;
  int progressMillis = 0;
  DateTime? lastPlayedAt;
  bool isFavorite = false;
  bool isCompleted = false;
  bool spotlight = false;
  int sortOrder = 0;
  List<ChapterCue> chapters = [];
}

extension MediaItemX on MediaItem {
  Duration get duration => Duration(milliseconds: durationMillis);

  Duration get progress => Duration(milliseconds: progressMillis);

  bool get hasHistory => lastPlayedAt != null;

  bool get canResume => progressMillis > 0 && !isCompleted;

  double get watchedRatio {
    if (durationMillis <= 0) {
      return 0;
    }
    return (progressMillis / durationMillis).clamp(0.0, 1.0);
  }
}
