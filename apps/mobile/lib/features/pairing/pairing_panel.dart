import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../app/config.dart';
import '../../app/theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/common.dart';
import 'pairing_provider.dart';

/// QR code + short code + countdown for a pairing session; shared by the device and playlist flows.
class PairingPanel extends ConsumerStatefulWidget {
  const PairingPanel({super.key, required this.kind, required this.intro, this.onConfirmed});
  final PairingKind kind;

  /// Instructions shown next to the QR code; receives the portal host for display.
  final String intro;

  /// Invoked once when the portal confirmed the session.
  final VoidCallback? onConfirmed;

  @override
  ConsumerState<PairingPanel> createState() => _PairingPanelState();
}

class _PairingPanelState extends ConsumerState<PairingPanel> {
  Timer? _tick;
  bool _notified = false;

  @override
  void initState() {
    super.initState();
    // Countdown refresh; the network polling lives in the notifier.
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final flow = ref.watch(pairingProvider(widget.kind));
    ref.listen(pairingProvider(widget.kind), (_, next) {
      if (next.value?.phase == PairingPhase.confirmed && !_notified) {
        _notified = true;
        widget.onConfirmed?.call();
      }
    });
    final wide = MediaQuery.sizeOf(context).width >= 700;

    return GlassPanel(
      padding: const EdgeInsets.all(24),
      child: flow.when(
        loading: () => const SizedBox(height: 220, child: Center(child: CircularProgressIndicator())),
        error: (e, _) => _Error(message: l10n.pairFailed(e.toString()), onRetry: () => ref.read(pairingProvider(widget.kind).notifier).restart()),
        data: (f) {
          if (f.phase == PairingPhase.error) {
            return _Error(message: l10n.pairFailed(f.error ?? ''), onRetry: () => ref.read(pairingProvider(widget.kind).notifier).restart());
          }
          final ticket = f.ticket!;
          final url = f.url ?? '';
          final remaining = ticket.expiresAt.difference(DateTime.now());
          final expired = f.phase == PairingPhase.expired || remaining.isNegative;

          final qr = Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.all(12),
            child: Opacity(
              opacity: expired ? 0.25 : 1,
              child: QrImageView(data: url, size: wide ? 220 : 170, errorCorrectionLevel: QrErrorCorrectLevel.M),
            ),
          );

          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.intro, style: theme.textTheme.bodyLarge),
              const SizedBox(height: 6),
              Text(_hostOf(url), style: theme.textTheme.titleMedium?.copyWith(color: Colors.white)),
              const SizedBox(height: 18),
              Text(l10n.pairCode.toUpperCase(), style: theme.textTheme.labelMedium?.copyWith(color: context.tokens.textMuted, letterSpacing: 2)),
              const SizedBox(height: 4),
              Text(
                expired ? '——————' : _spaced(ticket.code),
                style: theme.textTheme.displaySmall?.copyWith(
                  fontFamily: 'monospace',
                  fontFamilyFallback: const ['Inter'],
                  fontWeight: FontWeight.w700,
                  letterSpacing: 4,
                  color: expired ? context.tokens.textFaint : Colors.white,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  if (f.phase == PairingPhase.confirmed) ...[
                    const Icon(Icons.check_circle_rounded, color: Color(0xFF30D158), size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(widget.kind == PairingKind.device ? l10n.pairConfirmed : l10n.addPlaylistConfirmed)),
                  ] else if (expired) ...[
                    Icon(Icons.timer_off_rounded, color: theme.colorScheme.error, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(l10n.pairExpired)),
                  ] else ...[
                    const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    const SizedBox(width: 10),
                    Expanded(child: Text('${l10n.pairWaiting}  ·  ${l10n.pairExpiresIn(_fmt(remaining))}', style: theme.textTheme.bodySmall)),
                  ],
                ],
              ),
              if (f.phase != PairingPhase.confirmed) ...[
                const SizedBox(height: 14),
                PillButton(
                  compact: true,
                  primary: expired,
                  autofocus: true,
                  icon: Icons.refresh_rounded,
                  label: l10n.pairNewCode,
                  onPressed: () => ref.read(pairingProvider(widget.kind).notifier).restart(),
                ),
              ],
            ],
          );

          return wide
              ? Row(crossAxisAlignment: CrossAxisAlignment.center, children: [qr, const SizedBox(width: 28), Expanded(child: details)])
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Center(child: qr), const SizedBox(height: 18), details]);
        },
      ),
    );
  }

  static String _spaced(String code) => code.split('').join(' ');

  static String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  static String _hostOf(String url) {
    final u = Uri.tryParse(url);
    if (u == null || u.host.isEmpty) return AppConfig.portalHost;
    return u.hasPort && u.port != 80 && u.port != 443 ? '${u.host}:${u.port}${u.path}' : '${u.host}${u.path}';
  }
}

class _Error extends StatelessWidget {
  const _Error({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(children: [
          Icon(Icons.cloud_off_rounded, color: Theme.of(context).colorScheme.error),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ]),
        const SizedBox(height: 14),
        PillButton(compact: true, primary: true, autofocus: true, icon: Icons.refresh_rounded, label: l10n.retry, onPressed: onRetry),
      ],
    );
  }
}
