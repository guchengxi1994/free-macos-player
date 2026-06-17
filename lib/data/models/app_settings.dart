import 'package:isar_community/isar.dart';

part 'app_settings.g.dart';

@collection
class AppSettings {
  AppSettings({this.id = Isar.autoIncrement});

  static const singletonId = 'app-settings';

  factory AppSettings.defaults() {
    return AppSettings()
      ..settingsId = singletonId
      ..darkMode = true
      ..autoPlayOnOpen = true
      ..resumeRecentOnLaunch = true
      ..defaultVolume = 100
      ..updatedAt = DateTime.now();
  }

  Id id;

  @Index(unique: true, replace: true)
  late String settingsId;

  bool darkMode = true;
  bool autoPlayOnOpen = true;
  bool resumeRecentOnLaunch = true;
  double defaultVolume = 100;
  DateTime updatedAt = DateTime.now();
}
