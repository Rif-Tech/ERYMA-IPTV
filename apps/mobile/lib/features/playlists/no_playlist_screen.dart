import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/config.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/db/database.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/common.dart';
import '../../widgets/format.dart';
import '../pairing/pairing_panel.dart';
import '../pairing/pairing_provider.dart';
import '../splash/splash_screen.dart';
import 'playlists_provider.dart';

/// Paired device without any accessible playlist (or with a lapsed subscription).
///
/// Playlists are only added from the web: this screen shows a playlist pairing code/QR that opens
/// the portal's "add playlist" form pre-linked to this device, then waits for the confirmation.
class NoPlaylistScreen extends ConsumerWidget {
  const NoPlaylistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final session = ref.watch(deviceSessionProvider).value;
    final hasVisible = (ref.watch(playlistsProvider).value ?? const []).isNotEmpty;
    final profile = ref.watch(activeProfileProvider);
    final hasAnyPortal = (ref.watch(allPlaylistsProvider).value ?? const []).any((p) => p.source == PlaylistSource.portal);
    final blocked = session?.blocked ?? false;
    final theme = Theme.of(context);
    final host = AppConfig.portalHost;

    return Scaffold(
      appBar: AppBar(
        title: Text(blocked ? l10n.activationRequired : (hasVisible ? l10n.addPlaylistTitle : l10n.noPlaylistTitle)),
        leading: hasVisible && context.canPop() ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()) : null,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: l10n.refreshPlaylists,
            icon: const Icon(Icons.refresh),
            onPressed: () => _refresh(context, ref),
          ),
          IconButton(tooltip: l10n.settings, icon: const Icon(Icons.settings), onPressed: () => context.push(Routes.settings)),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (blocked) ...[
                GlassPanel(
                  padding: const EdgeInsets.all(20),
                  child: Row(children: [
                    Icon(Icons.lock_clock_rounded, color: theme.colorScheme.error, size: 32),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(l10n.accountExpired, style: theme.textTheme.bodyLarge),
                        if (session?.status.expiresAt != null)
                          Text(l10n.deviceExpired(formatDate(context, session!.status.expiresAt!)), style: theme.textTheme.bodySmall),
                        const SizedBox(height: 6),
                        Text(l10n.accountManageOnline(host), style: theme.textTheme.bodySmall?.copyWith(color: context.tokens.textMuted)),
                      ]),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: PillButton(primary: true, autofocus: true, icon: Icons.refresh_rounded, label: l10n.retry, onPressed: () => _refresh(context, ref)),
                ),
              ] else ...[
                if (!hasVisible && hasAnyPortal && profile != null) ...[
                  // The account has playlists, this profile just cannot see them.
                  Text(l10n.noProfileAccess, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: PillButton(icon: Icons.switch_account_rounded, label: l10n.switchProfile, onPressed: () => context.go(Routes.profiles)),
                  ),
                  const SizedBox(height: 24),
                ] else if (!hasVisible) ...[
                  Text(l10n.noPlaylistDescription, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 16),
                ],
                PairingPanel(
                  kind: PairingKind.playlist,
                  intro: l10n.addPlaylistPairIntro(host),
                  onConfirmed: () => _refresh(context, ref),
                ),
              ],
              const SizedBox(height: 28),
              Text(l10n.disclaimer, style: theme.textTheme.bodySmall?.copyWith(color: context.tokens.textFaint), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _refresh(BuildContext context, WidgetRef ref) async {
    final session = await ref.read(deviceSessionProvider.notifier).refresh();
    if (!context.mounted) return;
    if (session.unpaired) {
      context.go(Routes.pairing);
      return;
    }
    if (session.blocked) return;
    final all = await ref.read(databaseProvider).watchPlaylists().first;
    if (!context.mounted) return;
    if (visibleForProfile(all, ref.read(activeProfileProvider)).isNotEmpty) await resumeNavigation(context, ref);
  }
}
