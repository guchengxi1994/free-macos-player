import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/app_settings.dart';
import '../../data/models/favorite_folder.dart';
import '../../data/models/media_item.dart';
import '../../data/models/playlist_entry.dart';
import '../../providers.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppPalette.of(context);
    final theme = Theme.of(context);
    final darkMode = ref.watch(darkModeProvider);
    final autoPlay = ref.watch(autoPlayOnOpenProvider);
    final resumeRecent = ref.watch(resumeRecentOnLaunchProvider);
    final playback = ref.watch(playerControllerProvider);
    final media = ref.watch(currentMediaProvider);
    final mediaItems = ref
        .watch(mediaLibraryProvider)
        .maybeWhen(data: (value) => value, orElse: () => const <MediaItem>[]);
    final playlists = ref
        .watch(playlistsProvider)
        .maybeWhen(
          data: (value) => value,
          orElse: () => const <PlaylistEntry>[],
        );
    final favoriteFolders = ref
        .watch(favoriteFoldersProvider)
        .maybeWhen(
          data: (value) => value,
          orElse: () => const <FavoriteFolder>[],
        );
    final historyCount = mediaItems.where((item) => item.hasHistory).length;

    return ColoredBox(
      color: palette.panelBackground,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(30, 28, 30, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '设置',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '管理外观、播放行为和本地资料库。',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: palette.softText,
              ),
            ),
            const SizedBox(height: 26),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                _StatCard(
                  icon: Icons.movie_creation_outlined,
                  label: '媒体库',
                  value: '${mediaItems.length}',
                  helper: '部视频',
                ),
                _StatCard(
                  icon: Icons.history_rounded,
                  label: '历史记录',
                  value: '$historyCount',
                  helper: '条记录',
                ),
                _StatCard(
                  icon: Icons.favorite_border_rounded,
                  label: '收藏夹',
                  value: '${favoriteFolders.length}',
                  helper: '个文件夹',
                ),
                _StatCard(
                  icon: Icons.queue_music_rounded,
                  label: '播放列表',
                  value: '${playlists.length}',
                  helper: '个列表',
                ),
              ],
            ),
            const SizedBox(height: 22),
            _SectionCard(
              title: '外观',
              subtitle: '把主题切换放在设置里，而不是塞在侧边栏按钮上。',
              child: Row(
                children: [
                  Expanded(
                    child: _ThemeChoice(
                      icon: Icons.light_mode_outlined,
                      title: '浅色模式',
                      selected: !darkMode,
                      onTap: () {
                        ref.read(darkModeProvider.notifier).state = false;
                        _saveSettings(ref, (settings) {
                          settings.darkMode = false;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ThemeChoice(
                      icon: Icons.dark_mode_outlined,
                      title: '深色模式',
                      selected: darkMode,
                      onTap: () {
                        ref.read(darkModeProvider.notifier).state = true;
                        _saveSettings(ref, (settings) {
                          settings.darkMode = true;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: '播放',
              subtitle: media == null ? '当前没有选中的媒体。' : '当前媒体: ${media.title}',
              child: Column(
                children: [
                  _VolumeTile(
                    volume: playback.volume,
                    onChanged: (value) {
                      ref
                          .read(playerControllerProvider.notifier)
                          .setVolume(value);
                    },
                    onChangeEnd: (value) {
                      _saveSettings(ref, (settings) {
                        settings.defaultVolume = value;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  _SwitchTile(
                    icon: Icons.play_circle_outline_rounded,
                    title: '自动播放打开的视频',
                    subtitle: '从历史、详情页打开视频时立即开始播放。',
                    value: autoPlay,
                    onChanged: (value) {
                      ref.read(autoPlayOnOpenProvider.notifier).state = value;
                      _saveSettings(ref, (settings) {
                        settings.autoPlayOnOpen = value;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  _SwitchTile(
                    icon: Icons.restore_rounded,
                    title: '启动时优先显示最近播放',
                    subtitle: '没有手动选择媒体时，默认展示最近看过的视频。',
                    value: resumeRecent,
                    onChanged: (value) {
                      ref.read(resumeRecentOnLaunchProvider.notifier).state =
                          value;
                      _saveSettings(ref, (settings) {
                        settings.resumeRecentOnLaunch = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: '本地数据',
              subtitle: '媒体信息、播放进度、收藏夹和播放列表都保存在本机 Isar 数据库。',
              child: Column(
                children: [
                  _InfoTile(
                    icon: Icons.storage_rounded,
                    title: '数据库',
                    subtitle: '~/Library/Application Support/free_macos_player',
                  ),
                  const SizedBox(height: 10),
                  _InfoTile(
                    icon: Icons.timer_outlined,
                    title: '当前播放进度',
                    subtitle:
                        '${formatDuration(playback.position)} / ${formatDuration(playback.duration)}',
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: historyCount == 0
                          ? null
                          : () {
                              ref
                                  .read(libraryRepositoryProvider.future)
                                  .then((repo) => repo.clearHistory());
                            },
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text('清空历史记录'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _saveSettings(
  WidgetRef ref,
  void Function(AppSettings settings) update,
) async {
  final repository = await ref.read(libraryRepositoryProvider.future);
  final settings = await repository.getSettings();
  update(settings);
  await repository.saveSettings(settings);
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.helper,
  });

  final IconData icon;
  final String label;
  final String value;
  final String helper;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final theme = Theme.of(context);

    return Container(
      width: 168,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.panelSecondaryBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: palette.primary),
          const SizedBox(height: 16),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(color: palette.softText),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  helper,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.softText,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.panelSecondaryBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: palette.softText,
            ),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _ThemeChoice extends StatelessWidget {
  const _ThemeChoice({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? palette.primarySoft : palette.panelBackground,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? palette.primary : palette.stroke,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? palette.primary : null),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: selected ? palette.primary : null,
                ),
              ),
            ),
            if (selected)
              Icon(
                Icons.check_circle_rounded,
                color: palette.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

class _VolumeTile extends StatelessWidget {
  const _VolumeTile({
    required this.volume,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final double volume;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.panelBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.stroke),
      ),
      child: Row(
        children: [
          Icon(Icons.volume_up_rounded, color: palette.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '默认音量',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Slider(
                  value: volume.clamp(0, 100),
                  max: 100,
                  onChanged: onChanged,
                  onChangeEnd: onChangeEnd,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${volume.round()}%',
            style: theme.textTheme.titleSmall?.copyWith(
              color: palette.softText,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return _TileShell(
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailing: Switch.adaptive(value: value, onChanged: onChanged),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return _TileShell(
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}

class _TileShell extends StatelessWidget {
  const _TileShell({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.panelBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.stroke),
      ),
      child: Row(
        children: [
          Icon(icon, color: palette.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.softText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          trailing,
        ],
      ),
    );
  }
}
