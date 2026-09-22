import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/config.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/api/portal_api.dart';
import '../../core/device/device_identity.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/common.dart';
import '../../widgets/format.dart';
import '../playlists/playlists_provider.dart';
import '../profiles/profile_picker_screen.dart';

/// Account summary shown in Settings: profile, subscription, device, and the unlink action.
class AccountCard extends ConsumerWidget {
  const AccountCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final session = ref.watch(deviceSessionProvider);
    final device = ref.watch(deviceIdentityProvider).value;
    final profile = ref.watch(activeProfileProvider);
    final profiles = ref.watch(profilesProvider);
    final host = AppConfig.portalHost;
    final s = session.value;

    return GlassPanel(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (profile != null) ...[
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: profileColor(profile.avatar), borderRadius: BorderRadius.circular(12)),
                  child: Text(profile.name.isEmpty ? '?' : profile.name.characters.first.toUpperCase(),
                      style: theme.textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(profile?.name ?? l10n.account, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    session.when(
                      loading: () => const Padding(padding: EdgeInsets.only(top: 6), child: LinearProgressIndicator(minHeight: 2)),
                      error: (e, _) => Text(e.toString(), style: TextStyle(color: theme.colorScheme.error)),
                      data: (s) => _StatusLine(session: s),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (s != null && !s.unpaired) ...[
            _InfoRow(label: l10n.deviceName, value: s.deviceName ?? device?.hardwareLabel ?? '—'),
            if (s.status.planName != null) _InfoRow(label: l10n.accountPlan, value: '${s.status.planName} · ${l10n.accountDevices(s.status.maxDevices)}'),
          ],
          _InfoRow(label: l10n.appVersion, value: device?.appVersion ?? '—'),
          _InfoRow(label: l10n.portalUrl, value: host),
          const SizedBox(height: 6),
          Text(l10n.accountManageOnline(host), style: theme.textTheme.bodySmall?.copyWith(color: context.tokens.textMuted)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (s != null && s.unpaired)
                PillButton(compact: true, primary: true, icon: Icons.qr_code_2_rounded, label: l10n.pairDevice, onPressed: () => context.go(Routes.pairing))
              else ...[
                if (profiles.length > 1)
                  PillButton(compact: true, icon: Icons.switch_account_rounded, label: l10n.switchProfile, onPressed: () => context.push(Routes.profiles)),
                PillButton(
                  compact: true,
                  icon: Icons.open_in_browser_rounded,
                  label: l10n.openPortal,
                  onPressed: () => launchUrl(Uri.parse(AppConfig.accountUrl), mode: LaunchMode.externalApplication),
                ),
                PillButton(compact: true, icon: Icons.link_off_rounded, label: l10n.unpairDevice, onPressed: () => _unpair(context, ref)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _unpair(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.unpairDevice),
        content: Text(l10n.unpairDeviceConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.unpairDevice)),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    // Forget the secret locally; the server row stays and is reused (secret rotated) at the next pairing.
    await ref.read(installSecretProvider.notifier).clear();
    ref.invalidate(deviceSessionProvider);
    if (context.mounted) context.go(Routes.pairing);
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 130, child: Text(label, style: theme.textTheme.bodySmall)),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.session});
  final DeviceSession session;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final (icon, color, text) = switch (session.phase) {
      SessionPhase.unpaired => (Icons.link_off_rounded, scheme.error, l10n.unpaired),
      SessionPhase.offline => (Icons.cloud_off_rounded, scheme.error, l10n.portalUnreachable),
      SessionPhase.ready => _describe(context, l10n, session.status),
    };
    return Row(children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 6),
      Expanded(child: Text(text, style: TextStyle(color: color, fontSize: 13))),
    ]);
  }

  (IconData, Color, String) _describe(BuildContext context, AppLocalizations l10n, DeviceStatus s) {
    final scheme = Theme.of(context).colorScheme;
    if (s.expired) {
      return (Icons.lock_clock, scheme.error, s.expiresAt != null && !s.isTrial ? l10n.deviceExpired(formatDate(context, s.expiresAt!)) : l10n.trialEnded);
    }
    if (s.activated) {
      return (Icons.verified, const Color(0xFF30D158), s.expiresAt != null ? l10n.deviceActiveUntil(formatDate(context, s.expiresAt!)) : l10n.deviceActiveUnlimited);
    }
    return (Icons.hourglass_bottom_rounded, const Color(0xFFFFB340), l10n.trialDaysLeft(s.trialDaysLeft));
  }
}
