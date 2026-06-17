import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import '../../core/theme/app_palette.dart';
import '../../data/models/media_item.dart';
import '../../providers.dart';
import '../favorites/favorites_view.dart';
import '../history/history_view.dart';
import '../player/now_playing_view.dart';
import '../playlists/playlists_view.dart';
import '../settings/settings_view.dart';
import 'app_nav.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppPalette.of(context);
    final section = ref.watch(appSectionProvider);
    final darkMode = ref.watch(darkModeProvider);
    final library = ref.watch(mediaLibraryProvider);
    final currentMedia = ref.watch(currentMediaProvider);

    if (currentMedia != null && ref.read(currentMediaIdProvider) == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (ref.read(currentMediaIdProvider) == null) {
          ref.read(currentMediaIdProvider.notifier).state =
              currentMedia.mediaId;
        }
      });
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette.pageGradient,
        ),
      ),
      child: library.when(
        data: (_) => ColoredBox(
          color: palette.shellBackground,
          child: Row(
            children: [
              SizedBox(
                width: 232,
                child: _Sidebar(section: section, darkMode: darkMode),
              ),
              Container(width: 1, color: palette.stroke),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: KeyedSubtree(
                    key: ValueKey(section),
                    child: _ActivePage(
                      section: section,
                      currentMedia: currentMedia,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        loading: () => Center(
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: palette.shellBackground,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: palette.stroke),
              boxShadow: [
                BoxShadow(
                  color: palette.shadow,
                  blurRadius: 28,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: const CircularProgressIndicator(),
          ),
        ),
        error: (error, _) => Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: palette.shellBackground,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: palette.stroke),
              boxShadow: [
                BoxShadow(
                  color: palette.shadow,
                  blurRadius: 28,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Text('初始化失败: $error'),
          ),
        ),
      ),
    );
  }
}

class _ActivePage extends StatelessWidget {
  const _ActivePage({required this.section, required this.currentMedia});

  final AppSection section;
  final MediaItem? currentMedia;

  @override
  Widget build(BuildContext context) {
    final media = currentMedia;

    switch (section) {
      case AppSection.nowPlaying:
        return const NowPlayingView();
      case AppSection.history:
        return const HistoryView(compact: false);
      case AppSection.favorites:
        return media == null
            ? const _EmptyPage(
                icon: Icons.star_border_rounded,
                title: '还没有可展示的视频',
                message: '先添加或播放一个视频，这里会展示影片详情与收藏操作。',
              )
            : FavoritesView(media: media);
      case AppSection.playlists:
        return const PlaylistsView(expanded: true);
      case AppSection.settings:
        return const SettingsView();
    }
  }
}

class _Sidebar extends ConsumerWidget {
  const _Sidebar({required this.section, required this.darkMode});

  final AppSection section;
  final bool darkMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppPalette.of(context);
    final theme = Theme.of(context);

    const items = [
      (AppSection.nowPlaying, Icons.play_circle_outline_rounded),
      (AppSection.history, Icons.history_rounded),
      (AppSection.favorites, Icons.star_border_rounded),
      (AppSection.playlists, Icons.tune_rounded),
    ];

    return ColoredBox(
      color: palette.sidebarBackground,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const DragToMoveArea(
              child: SizedBox(
                width: double.infinity,
                height: 34,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _WindowControls(),
                ),
              ),
            ),
            const SizedBox(height: 28),
            DragToMoveArea(
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: palette.stroke),
                ),
                child: const Icon(Icons.hexagon_outlined, size: 18),
              ),
            ),
            const SizedBox(height: 34),
            for (final item in items) ...[
              _SidebarItem(
                icon: item.$2,
                label: item.$1.label,
                selected: section == item.$1,
                onTap: () {
                  ref.read(appSectionProvider.notifier).state = item.$1;
                },
              ),
              const SizedBox(height: 10),
            ],
            const Spacer(),
            _SidebarItem(
              icon: Icons.settings_outlined,
              label: '设置',
              selected: section == AppSection.settings,
              onTap: () {
                ref.read(appSectionProvider.notifier).state =
                    AppSection.settings;
              },
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(
                darkMode ? '深色外观' : '浅色外观',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: palette.softText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
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
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: selected ? palette.primarySoft : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: selected ? palette.primary : theme.iconTheme.color,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: selected ? palette.primary : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WindowControls extends StatelessWidget {
  const _WindowControls();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _WindowControlButton(
          color: const Color(0xFFFF5F57),
          onTap: () {
            windowManager.close();
          },
        ),
        const SizedBox(width: 8),
        _WindowControlButton(
          color: const Color(0xFFFFBD2E),
          onTap: () {
            windowManager.minimize();
          },
        ),
        const SizedBox(width: 8),
        _WindowControlButton(
          color: const Color(0xFF28C840),
          onTap: () async {
            final isMaximized = await windowManager.isMaximized();
            if (isMaximized) {
              await windowManager.unmaximize();
            } else {
              await windowManager.maximize();
            }
          },
        ),
      ],
    );
  }
}

class _WindowControlButton extends StatelessWidget {
  const _WindowControlButton({required this.color, required this.onTap});

  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 18,
        height: 18,
        child: Center(
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }
}

class _EmptyPage extends StatelessWidget {
  const _EmptyPage({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: palette.primarySoft,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, size: 38, color: palette.primary),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: palette.softText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
