import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/db/database.dart';
import '../../l10n/generated/app_localizations.dart';
import '../splash/splash_screen.dart';
import 'device_info_card.dart';
import 'playlists_provider.dart';

/// Shown when the device has no playlist, or when its trial/activation has expired.
class NoPlaylistScreen extends ConsumerWidget {
  const NoPlaylistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final session = ref.watch(deviceSessionProvider).value;
    final playlists = ref.watch(playlistsProvider).value ?? const [];
    final blocked = session != null && session.online && session.status.expired;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(blocked ? l10n.activationRequired : l10n.noPlaylistTitle),
        actions: [
          IconButton(
            tooltip: l10n.refreshPlaylists,
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await ref.read(deviceSessionProvider.notifier).refresh();
              if (!context.mounted) return;
              final list = await ref.read(databaseProvider).watchPlaylists().first;
              final s = ref.read(deviceSessionProvider).value;
              if (!context.mounted) return;
              if (list.isNotEmpty && !(s?.status.expired ?? false)) {
                await openPlaylist(context, ref, list.first);
              }
            },
          ),
          IconButton(
            tooltip: l10n.settings,
            icon: const Icon(Icons.settings),
            onPressed: () => context.push(Routes.settings),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                blocked ? l10n.trialEnded : l10n.noPlaylistDescription,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              Text(l10n.scanQr, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 16),
              const DeviceInfoCard(),
              const SizedBox(height: 16),
              if (!blocked)
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.icon(
                      autofocus: true,
                      onPressed: () => context.push(Routes.addXtream),
                      icon: const Icon(Icons.vpn_key),
                      label: Text(l10n.addXtream),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () => context.push(Routes.addM3u),
                      icon: const Icon(Icons.link),
                      label: Text(l10n.addM3u),
                    ),
                    if (playlists.isNotEmpty)
                      OutlinedButton.icon(
                        onPressed: () => context.go(Routes.playlists),
                        icon: const Icon(Icons.playlist_play),
                        label: Text(l10n.myPlaylists),
                      ),
                  ],
                ),
              const SizedBox(height: 24),
              Text(l10n.disclaimer, style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
