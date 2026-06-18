import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../favorites/favorites_view.dart';
import '../history/history_view.dart';
import '../player/now_playing_view.dart';
import '../playlists/playlists_view.dart';
import '../settings/settings_view.dart';
import 'app_nav.dart';
import 'app_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppSection.nowPlaying.path,
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          return AppShell(location: state.uri.path, child: child);
        },
        routes: [
          GoRoute(path: '/', redirect: (_, _) => AppSection.nowPlaying.path),
          GoRoute(
            path: AppSection.nowPlaying.path,
            pageBuilder: (_, _) => _fadePage(const NowPlayingView()),
          ),
          GoRoute(
            path: AppSection.history.path,
            pageBuilder: (_, _) => _fadePage(const HistoryView(compact: false)),
          ),
          GoRoute(
            path: AppSection.favorites.path,
            pageBuilder: (_, _) => _fadePage(const FavoritesView()),
          ),
          GoRoute(
            path: AppSection.playlists.path,
            pageBuilder: (_, _) =>
                _fadePage(const PlaylistsView(expanded: true)),
          ),
          GoRoute(
            path: AppSection.settings.path,
            pageBuilder: (_, _) => _fadePage(const SettingsView()),
          ),
        ],
      ),
    ],
  );
});

CustomTransitionPage<void> _fadePage(Widget child) {
  return CustomTransitionPage<void>(
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        child: child,
      );
    },
  );
}
