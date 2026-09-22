import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/player/playback.dart';
import '../features/home/home_screen.dart';
import '../features/live/live_screen.dart';
import '../features/movies/movie_detail_screen.dart';
import '../features/movies/movies_screen.dart';
import '../features/pairing/pairing_screen.dart';
import '../features/player/player_screen.dart';
import '../features/playlists/change_playlist_screen.dart';
import '../features/playlists/import_screen.dart';
import '../features/playlists/no_playlist_screen.dart';
import '../features/profiles/profile_picker_screen.dart';
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
  static const pairing = '/pairing';
  static const profiles = '/profiles';
  static const noPlaylist = '/no-playlist';
  static const playlists = '/playlists';
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
      GoRoute(path: Routes.pairing, builder: (_, _) => const PairingScreen()),
      GoRoute(path: Routes.profiles, builder: (_, _) => const ProfilePickerScreen()),
      GoRoute(path: Routes.noPlaylist, builder: (_, _) => const NoPlaylistScreen()),
      GoRoute(path: Routes.playlists, builder: (_, _) => const ChangePlaylistScreen()),
      GoRoute(path: '/import/:id', builder: (_, s) => ImportScreen(playlistId: s.pathParameters['id']!)),
      GoRoute(
        path: Routes.player,
        pageBuilder: (_, s) => NoTransitionPage(child: PlayerScreen(request: s.extra as PlaybackRequest)),
      ),
      // Tabs stay mounted (like a native TV app) so switching back is instant and keeps scroll/focus.
      StatefulShellRoute(
        builder: (context, state, shell) => AppShell(location: state.uri.path, shell: shell),
        navigatorContainerBuilder: (context, shell, children) => _BranchStack(index: shell.currentIndex, children: children),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.home, pageBuilder: (_, _) => const NoTransitionPage(child: HomeScreen())),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.live, pageBuilder: (_, _) => const NoTransitionPage(child: LiveScreen())),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.movies,
              pageBuilder: (_, _) => const NoTransitionPage(child: MoviesScreen()),
              routes: [
                GoRoute(path: ':id', builder: (_, s) => MovieDetailScreen(streamId: s.pathParameters['id']!)),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.series,
              pageBuilder: (_, _) => const NoTransitionPage(child: SeriesScreen()),
              routes: [
                GoRoute(path: ':id', builder: (_, s) => SeriesDetailScreen(seriesId: s.pathParameters['id']!)),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.search, pageBuilder: (_, _) => const NoTransitionPage(child: SearchScreen())),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.settings,
              pageBuilder: (_, _) => const NoTransitionPage(child: SettingsScreen()),
              routes: [
                GoRoute(path: 'parental', builder: (_, _) => const ParentalScreen()),
                GoRoute(path: 'groups', builder: (_, _) => const GroupsScreen()),
              ],
            ),
          ]),
        ],
      ),
    ],
  );
});

/// Offstage branches must neither animate nor be reachable by D-pad traversal.
class _BranchStack extends StatelessWidget {
  const _BranchStack({required this.index, required this.children});
  final int index;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        for (final (i, child) in children.indexed)
          Offstage(
            offstage: i != index,
            child: TickerMode(
              enabled: i == index,
              child: ExcludeFocus(excluding: i != index, child: child),
            ),
          ),
      ],
    );
  }
}
