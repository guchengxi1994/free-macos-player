enum AppSection {
  nowPlaying('正在播放'),
  history('历史记录'),
  favorites('收藏夹'),
  playlists('播放列表'),
  settings('设置');

  const AppSection(this.label);

  final String label;
}
