import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/router.dart';
import '../../core/device/device_identity.dart';
import '../../l10n/generated/app_localizations.dart';
import '../playlists/playlists_provider.dart';

/// Applies the portal verdict (maintenance, forced update, expired trial) whenever it arrives,
/// so the app can show local content immediately instead of waiting for the network at boot.
class SessionGate extends ConsumerWidget {
  const SessionGate({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void toPairing() {
      final router = ref.read(routerProvider);
      final location = router.routerDelegate.currentConfiguration.uri.path;
      debugPrint('SessionGate: unpaired at $location');
      if (location != Routes.pairing && location != Routes.settings) router.go(Routes.pairing);
    }

    // The secret is dropped the moment the server answers 401 UNPAIRED: react right away, before
    // the rest of the session reload (playlist cleanup) finishes.
    ref.listen(installSecretProvider, (prev, next) {
      if (prev?.value != null && next.hasValue && next.value == null) toPairing();
    });
    ref.listen(deviceSessionProvider, (_, next) {
      final session = next.value;
      if (session == null) {
        if (next.hasError) debugPrint('SessionGate: session error ${next.error}');
        return;
      }
      if (session.unpaired) {
        toPairing();
      } else if (session.blocked) {
        final router = ref.read(routerProvider);
        final location = router.routerDelegate.currentConfiguration.uri.path;
        if (location != Routes.noPlaylist && location != Routes.splash) router.go(Routes.noPlaylist);
      }
    });

    final session = ref.watch(deviceSessionProvider).value;
    final info = session?.appInfo;
    if (info == null) return child;
    final l10n = AppLocalizations.of(context);
    if (info.status == 'maintenance') {
      return BlockingScreen(message: info.message ?? l10n.maintenance);
    }
    final version = ref.watch(deviceIdentityProvider).value?.appVersion;
    if (version != null && info.requiresUpdate(version)) {
      return BlockingScreen(message: l10n.updateDescription, updateLink: info.apkLink);
    }
    return child;
  }
}

/// Full-screen notice with retry (and an update link when the portal provides one).
class BlockingScreen extends ConsumerWidget {
  const BlockingScreen({super.key, required this.message, this.updateLink, this.onRetry});
  final String message;
  final String? updateLink;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.play_circle_fill_rounded, size: 88, color: Colors.white),
              const SizedBox(height: 18),
              Text(l10n.appName, style: text.displaySmall),
              const SizedBox(height: 40),
              Text(message, textAlign: TextAlign.center, style: text.bodyLarge?.copyWith(color: const Color(0xB3FFFFFF))),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                children: [
                  if (updateLink != null)
                    FilledButton.icon(
                      autofocus: true,
                      onPressed: () => launchUrl(Uri.parse(updateLink!), mode: LaunchMode.externalApplication),
                      icon: const Icon(Icons.system_update_rounded),
                      label: Text(l10n.updateNow),
                    ),
                  OutlinedButton.icon(
                    autofocus: updateLink == null,
                    onPressed: onRetry ?? () => ref.read(deviceSessionProvider.notifier).refresh(),
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(l10n.retry),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
