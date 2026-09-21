import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/config.dart';
import '../../core/api/portal_api.dart';
import '../../core/device/device_identity.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/common.dart';
import '../../widgets/format.dart';
import 'playlists_provider.dart';

/// MAC / key / QR code panel shared by the onboarding and settings screens.
class DeviceInfoCard extends ConsumerWidget {
  const DeviceInfoCard({super.key, this.showQr = true});
  final bool showQr;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final device = ref.watch(deviceIdentityProvider);
    final session = ref.watch(deviceSessionProvider);
    final theme = Theme.of(context);

    return GlassPanel(
      padding: const EdgeInsets.all(20),
      child: device.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text(e.toString()),
          data: (d) {
            final portalLink = AppConfig.portalLoginUrl(d.mac, d.key);
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showQr)
                  Padding(
                    padding: const EdgeInsets.only(right: 24),
                    child: Container(
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.all(10),
                      child: QrImageView(data: portalLink, size: 168),
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.deviceInfo, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 12),
                      _InfoRow(label: l10n.macAddress, value: d.mac, mono: true),
                      _InfoRow(label: l10n.deviceKey, value: d.key, mono: true),
                      _InfoRow(label: l10n.deviceType, value: d.type.name),
                      _InfoRow(label: l10n.appVersion, value: d.appVersion),
                      _InfoRow(label: l10n.portalUrl, value: AppConfig.portalUrl),
                      const SizedBox(height: 8),
                      session.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (e, _) => Text(e.toString(), style: TextStyle(color: theme.colorScheme.error)),
                        data: (s) => _StatusLine(session: s),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          PillButton(
                            compact: true,
                            icon: Icons.open_in_browser_rounded,
                            label: l10n.openPortal,
                            onPressed: () => launchUrl(Uri.parse(portalLink), mode: LaunchMode.externalApplication),
                          ),
                          PillButton(
                            compact: true,
                            icon: Icons.copy_rounded,
                            label: l10n.macAddress,
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: '${d.mac} / ${d.key}'));
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${d.mac} / ${d.key}')));
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.mono = false});
  final String label;
  final String value;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 130, child: Text(label, style: theme.textTheme.bodySmall)),
          Expanded(
            child: SelectableText(
              value,
              style: mono
                  ? theme.textTheme.titleMedium?.copyWith(fontFamily: 'monospace', fontFamilyFallback: const ['Inter'], letterSpacing: 1.5)
                  : theme.textTheme.bodyMedium,
            ),
          ),
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
    if (!session.online) {
      return Row(children: [
        Icon(session.keyConflict ? Icons.key_off : Icons.cloud_off, size: 18, color: scheme.error),
        const SizedBox(width: 6),
        Expanded(child: Text(session.keyConflict ? l10n.deviceKeyConflict : l10n.portalUnreachable)),
      ]);
    }
    final s = session.status;
    final (icon, color, text) = _describe(context, l10n, s);
    return Row(children: [
      Icon(icon, size: 18, color: color),
      const SizedBox(width: 6),
      Expanded(child: Text(text, style: TextStyle(color: color))),
    ]);
  }

  (IconData, Color, String) _describe(BuildContext context, AppLocalizations l10n, DeviceStatus s) {
    final scheme = Theme.of(context).colorScheme;
    if (s.expired) {
      return (
        Icons.lock_clock,
        scheme.error,
        s.expiresAt != null && !s.isTrial ? l10n.deviceExpired(formatDate(context, s.expiresAt!)) : l10n.trialEnded,
      );
    }
    if (s.activated) {
      return (
        Icons.verified,
        Colors.green,
        s.expiresAt == null ? l10n.deviceActiveUnlimited : l10n.deviceActiveUntil(formatDate(context, s.expiresAt!)),
      );
    }
    return (Icons.hourglass_bottom, scheme.tertiary, l10n.trialDaysLeft(s.trialDaysLeft));
  }
}
