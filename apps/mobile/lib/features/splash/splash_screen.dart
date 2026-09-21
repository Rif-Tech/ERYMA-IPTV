import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/router.dart';
import '../../core/db/database.dart';
import '../../core/device/device_identity.dart';
import '../../core/settings/settings.dart';
import '../../l10n/generated/app_localizations.dart';
import '../playlists/playlists_provider.dart';

/// Boots the app: device registration, portal sync, then routes to the right screen.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  String? _blockingMessage;
  String? _updateLink;

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
      if (mounted) setState(() => _blockingMessage = e.toString());
    }
  }

  Future<void> _boot() async {
    // Never let a hung provider keep the splash spinning forever.
    final session = await ref.read(deviceSessionProvider.future).timeout(const Duration(seconds: 45));
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);

    final info = session.appInfo;
    if (info != null) {
      if (info.status == 'maintenance') {
        setState(() => _blockingMessage = info.message ?? l10n.maintenance);
        return;
      }
      final device = await ref.read(deviceIdentityProvider.future);
      if (info.requiresUpdate(device.appVersion)) {
        setState(() {
          _blockingMessage = l10n.updateDescription;
          _updateLink = info.apkLink;
        });
        return;
      }
    }

    // Riverpod 3 pauses unlistened StreamProviders, so `.future` would never resolve here.
    final playlists = await ref.read(databaseProvider).watchPlaylists().first.timeout(const Duration(seconds: 15));
    if (!mounted) return;

    if (playlists.isEmpty || (session.online && session.status.expired)) {
      context.go(Routes.noPlaylist);
      return;
    }

    final settings = ref.read(settingsProvider);
    final active = playlists.firstWhere((p) => p.id == settings.activePlaylistId, orElse: () => playlists.first);
    if (active.id != settings.activePlaylistId) {
      await ref.read(settingsProvider.notifier).setActivePlaylistId(active.id);
    }
    if (!mounted) return;
    await openPlaylist(context, ref, active);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.live_tv_rounded, size: 96, color: scheme.primary),
              const SizedBox(height: 16),
              Text(l10n.appName, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 32),
              if (_blockingMessage == null) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 12),
                Text(l10n.loading),
              ] else ...[
                Text(_blockingMessage!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  children: [
                    if (_updateLink != null)
                      FilledButton.icon(
                        autofocus: true,
                        onPressed: () => launchUrl(Uri.parse(_updateLink!), mode: LaunchMode.externalApplication),
                        icon: const Icon(Icons.system_update),
                        label: Text(l10n.updateNow),
                      ),
                    OutlinedButton.icon(
                      autofocus: _updateLink == null,
                      onPressed: () {
                        setState(() => _blockingMessage = null);
                        ref.invalidate(deviceSessionProvider);
                        _run();
                      },
                      icon: const Icon(Icons.refresh),
                      label: Text(l10n.retry),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Selects [playlist] as active and routes to import or home. The PIN only guards editing, not playback.
Future<void> openPlaylist(BuildContext context, WidgetRef ref, Playlist playlist) async {
  await ref.read(settingsProvider.notifier).setActivePlaylistId(playlist.id);
  if (!context.mounted) return;
  final policy = ref.read(settingsProvider).autoUpdate;
  if (needsImport(playlist, policy)) {
    context.go(Routes.import(playlist.id));
  } else {
    context.go(Routes.home);
  }
}
