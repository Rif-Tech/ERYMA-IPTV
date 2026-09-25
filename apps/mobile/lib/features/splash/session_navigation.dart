import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/db/database.dart';
import '../../core/settings/settings.dart';
import '../../core/sync/progress_sync.dart';
import '../playlists/playlists_provider.dart';

// Post-pairing navigation shared by the splash screen and the profile/playlist pickers. Session
// entry points are wired in three places: SplashScreen._boot, this file and SessionGate.

/// Routes to the next step once the install is paired: profile → playlist → import/home.
///
/// A single profile / single playlist is picked automatically (no useless screen); several of them
/// show the corresponding picker. Falls back gracefully when offline with cached data.
Future<void> resumeNavigation(BuildContext context, WidgetRef ref) async {
  if (redirectedBySession(context, ref)) return;
  final db = ref.read(databaseProvider);
  final profiles = ref.read(profilesProvider);
  var profile = ref.read(activeProfileProvider);
  if (profile == null && profiles.isNotEmpty) {
    if (profiles.length == 1) {
      profile = profiles.first;
      await ref.read(profileControllerProvider.notifier).select(profile);
      if (!context.mounted) return;
    } else {
      context.go(Routes.profiles);
      return;
    }
  }

  final all = await db.watchPlaylists().first;
  if (!context.mounted) return;
  final visible = visibleForProfile(all, profile);
  if (visible.isEmpty) {
    context.go(Routes.noPlaylist);
    return;
  }
  final savedId = ref.read(settingsProvider).activePlaylistId;
  final saved = visible.where((p) => p.id == savedId).firstOrNull;
  final active = saved ?? (visible.length == 1 ? visible.first : null);
  if (active == null) {
    context.go(Routes.playlists);
    return;
  }
  await openPlaylist(context, ref, active);
}

/// The session may have answered while we were reading the database: honour its verdict instead of
/// racing [SessionGate] to the home screen.
bool redirectedBySession(BuildContext context, WidgetRef ref) {
  final session = ref.read(deviceSessionProvider).value;
  if (session == null) return false;
  if (session.unpaired) {
    context.go(Routes.pairing);
    return true;
  }
  if (session.blocked) {
    context.go(Routes.noPlaylist);
    return true;
  }
  return false;
}

/// Selects [playlist] as active and routes to import or home. The PIN only guards editing, not playback.
Future<void> openPlaylist(BuildContext context, WidgetRef ref, Playlist playlist) async {
  await ref.read(settingsProvider.notifier).setActivePlaylistId(playlist.id);
  if (!context.mounted || redirectedBySession(context, ref)) return;
  ref.read(profileControllerProvider.notifier).rememberPlaylist();
  // Server-side progress of this profile for this playlist, merged in the background.
  unawaited(ref.read(progressSyncProvider).pull(playlist.id));
  final policy = ref.read(settingsProvider).autoUpdate;
  if (needsImport(playlist, policy)) {
    context.go(Routes.import(playlist.id));
  } else {
    context.go(Routes.home);
  }
}
