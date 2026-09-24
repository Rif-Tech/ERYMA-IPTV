import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../app/config.dart';
import '../../app/router.dart';
import '../../core/db/database.dart';
import '../../core/device/device_identity.dart';
import '../../core/settings/settings.dart';
import '../../core/sync/progress_sync.dart';
import '../../l10n/generated/app_localizations.dart';
import '../playlists/playlists_provider.dart';
import 'session_gate.dart';

/// Boots the app from the local database; the portal sync runs in the background and
/// [SessionGate] applies its verdict (maintenance, update, expiry, unpaired) whenever it lands.
///
/// State machine: UNPAIRED → PAIRING → (NO_PLAYLIST | PROFILE_PICK → PLAYLIST_PICK → IMPORT → HOME).
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    try {
      await _boot();
    } catch (e, st) {
      debugPrint('Splash failed: $e\n$st');
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _boot() async {
    // Last known portal URL first: the pairing QR code must never point at a build-time default.
    DeviceSessionNotifier.restorePortalUrl(ref.read(sharedPreferencesProvider));
    // Install identity next: every device call attaches it. No secret = never paired (or revoked).
    final identity = await ref.read(deviceIdentityProvider.future);
    // Lets a native crash (see player_screen.dart's decode ladder) be found by device_uuid, the
    // same id the app_logs/Supabase pipeline is keyed on. No-op when no DSN is configured.
    if (AppConfig.sentryDsn.isNotEmpty) {
      Sentry.configureScope((scope) => scope.setTag('device_uuid', identity.uuid));
    }
    final secret = await ref.read(installSecretProvider.future);
    if (!mounted) return;
    ref.read(profileControllerProvider.notifier).restore();

    final db = ref.read(databaseProvider);
    // Riverpod 3 pauses unlistened StreamProviders, so `.future` would never resolve here.
    final playlists = await db.watchPlaylists().first.timeout(const Duration(seconds: 15));
    if (!mounted) return;

    if (secret == null) {
      // Never paired (or revoked). Legacy installs keep their local playlists reachable from the
      // pairing screen ("continue without an account"), but pairing is the way forward.
      context.go(Routes.pairing);
      return;
    }

    // Kick off the account session (status, profiles, playlist mirror) without waiting for it.
    final sessionFuture = ref.read(deviceSessionProvider.future);

    // Housekeeping off the critical path, once a day: the purge scans the whole guide table and
    // would otherwise queue in front of the first home-screen queries on every launch.
    final prefs = ref.read(sharedPreferencesProvider);
    final lastPurge = prefs.getInt('epgPurgedAt') ?? 0;
    if (DateTime.now().millisecondsSinceEpoch - lastPurge > const Duration(hours: 24).inMilliseconds) {
      unawaited(Future<void>.delayed(const Duration(seconds: 20), () async {
        try {
          await db.purgeEpg();
          await prefs.setInt('epgPurgedAt', DateTime.now().millisecondsSinceEpoch);
        } catch (e) {
          debugPrint('purgeEpg: $e');
        }
      }));
    }

    // Nothing usable offline (no playlist, or no profile picked yet): wait for the server.
    final needsServer = playlists.isEmpty || ref.read(activeProfileProvider) == null;
    if (needsServer) {
      final session = await sessionFuture.timeout(
        const Duration(seconds: 20),
        onTimeout: () => const DeviceSession(phase: SessionPhase.offline),
      );
      if (!mounted) return;
      if (session.unpaired) {
        context.go(Routes.pairing);
        return;
      }
      if (session.blocked) {
        context.go(Routes.noPlaylist);
        return;
      }
    }
    if (!mounted) return;
    await resumeNavigation(context, ref);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    if (_error != null) {
      return BlockingScreen(
        message: _error!,
        onRetry: () {
          setState(() => _error = null);
          ref.invalidate(deviceSessionProvider);
          _run();
        },
      );
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.play_circle_fill_rounded, size: 88, color: Colors.white),
            const SizedBox(height: 18),
            Text(l10n.appName, style: text.displaySmall),
            const SizedBox(height: 40),
            const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5)),
          ],
        ),
      ),
    );
  }
}

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
