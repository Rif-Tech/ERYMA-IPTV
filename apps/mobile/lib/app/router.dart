import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/player/playback.dart';
import '../features/home/home_screen.dart';
import '../features/live/live_screen.dart';
import '../features/movies/movie_detail_screen.dart';
import '../features/movies/movies_screen.dart';
import '../features/player/player_screen.dart';
import '../features/playlists/add_playlist_screen.dart';
import '../features/playlists/change_playlist_screen.dart';
import '../features/playlists/import_screen.dart';
import '../features/playlists/no_playlist_screen.dart';
import '../features/search/search_screen.dart';
import '../features/series/series_detail_screen.dart';
import '../features/series/series_screen.dart';
import '../features/settings/groups_screen.dart';
import '../features/settings/parental_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/shell/app_shell.dart';
import '../features/splash/splash_screen.dart';

abstract final class Routes {
  static const splash = '/';
  static const noPlaylist = '/no-playlist';
  static const playlists = '/playlists';
  static const addM3u = '/playlists/add/m3u';
  static const addXtream = '/playlists/add/xtream';
  static String editPlaylist(String id) => '/playlists/edit/$id';
  static String import(String id) => '/import/$id';
  static const home = '/home';
  static const live = '/live';
  static const movies = '/movies';
  static String movie(String id) => '/movies/$id';
  static const series = '/series';
  static String seriesDetail(String id) => '/series/$id';
  static const search = '/search';
  static const settings = '/settings';
  static const parental = '/settings/parental';
  static const groups = '/settings/groups';
  static const player = '/player';
}

final _rootKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: Routes.splash,
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: Routes.noPlaylist, builder: (_, _) => const NoPlaylistScreen()),
      GoRoute(path: Routes.playlists, builder: (_, _) => const ChangePlaylistScreen()),
      GoRoute(path: Routes.addM3u, builder: (_, _) => const AddPlaylistScreen(xtream: false)),
      GoRoute(path: Routes.addXtream, builder: (_, _) => const AddPlaylistScreen(xtream: true)),
      GoRoute(path: '/playlists/edit/:id', builder: (_, s) => AddPlaylistScreen(xtream: false, editId: s.pathParameters['id'])),
      GoRoute(path: '/import/:id', builder: (_, s) => ImportScreen(playlistId: s.pathParameters['id']!)),
      GoRoute(
        path: Routes.player,
        pageBuilder: (_, s) => NoTransitionPage(child: PlayerScreen(request: s.extra as PlaybackRequest)),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(path: Routes.home, pageBuilder: (_, _) => const NoTransitionPage(child: HomeScreen())),
          GoRoute(path: Routes.live, pageBuilder: (_, _) => const NoTransitionPage(child: LiveScreen())),
          GoRoute(
            path: Routes.movies,
            pageBuilder: (_, _) => const NoTransitionPage(child: MoviesScreen()),
            routes: [
              GoRoute(path: ':id', builder: (_, s) => MovieDetailScreen(streamId: s.pathParameters['id']!)),
            ],
          ),
          GoRoute(
            path: Routes.series,
            pageBuilder: (_, _) => const NoTransitionPage(child: SeriesScreen()),
            routes: [
              GoRoute(path: ':id', builder: (_, s) => SeriesDetailScreen(seriesId: s.pathParameters['id']!)),
            ],
          ),
          GoRoute(path: Routes.search, pageBuilder: (_, _) => const NoTransitionPage(child: SearchScreen())),
          GoRoute(
            path: Routes.settings,
            pageBuilder: (_, _) => const NoTransitionPage(child: SettingsScreen()),
            routes: [
              GoRoute(path: 'parental', builder: (_, _) => const ParentalScreen()),
              GoRoute(path: 'groups', builder: (_, _) => const GroupsScreen()),
            ],
          ),
        ],
      ),
    ],
  );
});
