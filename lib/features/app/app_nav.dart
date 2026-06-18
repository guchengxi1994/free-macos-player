enum AppSection {
  nowPlaying('正在播放', '/now-playing'),
  history('历史记录', '/history'),
  favorites('收藏夹', '/favorites'),
  playlists('网络资源', '/playlists'),
  settings('设置', '/settings');

  const AppSection(this.label, this.path);

  final String label;
  final String path;

  static AppSection fromLocation(String location) {
    final path = location == '/' ? nowPlaying.path : location;
    return values.firstWhere(
      (section) => section.path == path,
      orElse: () => nowPlaying,
    );
  }
}
