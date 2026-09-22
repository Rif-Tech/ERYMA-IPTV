import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/config.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/common.dart';
import '../playlists/playlists_provider.dart';
import 'pairing_panel.dart';
import 'pairing_provider.dart';

/// First-run / unpaired screen: links this install to an account via QR code or short code.
class PairingScreen extends ConsumerWidget {
  const PairingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final hasLocal = (ref.watch(allPlaylistsProvider).value ?? const []).isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.pairTitle),
        actions: [
          IconButton(tooltip: l10n.settings, icon: const Icon(Icons.settings), onPressed: () => context.push(Routes.settings)),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _Steps(l10n: l10n),
              const SizedBox(height: 20),
              PairingPanel(
                kind: PairingKind.device,
                intro: l10n.pairStep3,
                onConfirmed: () async {
                  // Session reload was kicked off by the notifier; the splash routes to the right place.
                  await ref.read(deviceSessionProvider.future);
                  if (context.mounted) context.go(Routes.splash);
                },
              ),
              if (hasLocal) ...[
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: PillButton(icon: Icons.playlist_play_rounded, label: l10n.pairLater, onPressed: () => context.go(Routes.playlists)),
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
}

class _Steps extends StatelessWidget {
  const _Steps({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final steps = [l10n.pairStep1(AppConfig.portalHost), l10n.pairStep2];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: context.tokens.glass, borderRadius: BorderRadius.circular(13)),
                  child: Text('${i + 1}', style: theme.textTheme.labelLarge),
                ),
                const SizedBox(width: 12),
                Expanded(child: Padding(padding: const EdgeInsets.only(top: 3), child: Text(steps[i].trim(), style: theme.textTheme.bodyLarge))),
              ],
            ),
          ),
      ],
    );
  }
}
