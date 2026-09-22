import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../app/config.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/db/database.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/common.dart';
import '../../widgets/format.dart';
import '../splash/splash_screen.dart';
import 'playlists_provider.dart';

/// Paired device without any accessible playlist (or with a lapsed subscription).
///
/// Playlists are only added from the web: this screen guides the user to the account's playlists
/// page (QR + short URL) and polls the account until a list shows up.
class NoPlaylistScreen extends ConsumerStatefulWidget {
  const NoPlaylistScreen({super.key});

  @override
  ConsumerState<NoPlaylistScreen> createState() => _NoPlaylistScreenState();
}

class _NoPlaylistScreenState extends ConsumerState<NoPlaylistScreen> {
  static const _autoRefresh = Duration(seconds: 15);
  Timer? _timer;
  bool _checking = false;
  bool _manualMiss = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_autoRefresh, (_) => _refresh(manual: false));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  child: PillButton(primary: true, autofocus: true, icon: Icons.refresh_rounded, label: l10n.retry, onPressed: _refresh),
                ),
              ] else if (!hasVisible && hasAnyPortal && profile != null) ...[
                // The account has playlists, this profile just cannot see them.
                Text(l10n.noProfileAccess, style: theme.textTheme.bodyLarge),
                const SizedBox(height: 12),
                Wrap(spacing: 12, runSpacing: 12, children: [
                  PillButton(primary: true, autofocus: true, icon: Icons.switch_account_rounded, label: l10n.switchProfile, onPressed: () => context.go(Routes.profiles)),
                  PillButton(icon: Icons.refresh_rounded, label: l10n.refreshPlaylists, onPressed: _refresh),
                ]),
              ] else
                _Guide(checking: _checking, miss: _manualMiss, onDone: _refresh),
              const SizedBox(height: 28),
              Text(l10n.disclaimer, style: theme.textTheme.bodySmall?.copyWith(color: context.tokens.textFaint), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _refresh({bool manual = true}) async {
    if (_checking) return;
    setState(() {
      _checking = true;
      if (manual) _manualMiss = false;
    });
    try {
      final session = await ref.read(deviceSessionProvider.notifier).refresh();
      if (!mounted) return;
      if (session.unpaired) {
        context.go(Routes.pairing);
        return;
      }
      if (session.blocked) return;
      final all = await ref.read(databaseProvider).watchPlaylists().first;
      if (!mounted) return;
      if (visibleForProfile(all, ref.read(activeProfileProvider)).isNotEmpty) {
        _timer?.cancel();
        await resumeNavigation(context, ref);
        return;
      }
      if (manual) setState(() => _manualMiss = true);
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }
}

/// Three numbered steps, a QR code to the account's playlists page and one obvious action button.
class _Guide extends StatelessWidget {
  const _Guide({required this.checking, required this.miss, required this.onDone});
  final bool checking;
  final bool miss;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 700;
    final url = AppConfig.playlistsPageUrl;

    final qr = Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.all(12),
      child: QrImageView(data: url, size: wide ? 220 : 170, errorCorrectionLevel: QrErrorCorrectLevel.M),
    );

    final steps = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.noPlaylistDescription, style: theme.textTheme.bodyLarge),
        const SizedBox(height: 18),
        _Step(n: 1, child: Text(l10n.addPlaylistWebStep1, style: theme.textTheme.bodyMedium)),
        Padding(
          padding: const EdgeInsets.only(left: 38, bottom: 10),
          child: SelectableText(
            AppConfig.playlistsPageLabel,
            style: theme.textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
        _Step(n: 2, child: Text(l10n.addPlaylistWebStep2, style: theme.textTheme.bodyMedium)),
        _Step(n: 3, child: Text(l10n.addPlaylistWebStep3, style: theme.textTheme.bodyMedium)),
        const SizedBox(height: 18),
        PillButton(
          primary: true,
          autofocus: true,
          icon: checking ? Icons.hourglass_top_rounded : Icons.refresh_rounded,
          label: checking ? l10n.addPlaylistChecking : l10n.addPlaylistDone,
          onPressed: checking ? null : onDone,
        ),
        const SizedBox(height: 10),
        if (miss)
          Row(children: [
            Icon(Icons.info_outline_rounded, size: 16, color: theme.colorScheme.tertiary),
            const SizedBox(width: 6),
            Expanded(child: Text(l10n.addPlaylistNotYet, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.tertiary))),
          ])
        else
          Text(l10n.addPlaylistAutoRefresh(_NoPlaylistScreenState._autoRefresh.inSeconds), style: theme.textTheme.bodySmall?.copyWith(color: context.tokens.textMuted)),
      ],
    );

    return GlassPanel(
      padding: const EdgeInsets.all(24),
      child: wide
          ? Row(crossAxisAlignment: CrossAxisAlignment.center, children: [qr, const SizedBox(width: 28), Expanded(child: steps)])
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Center(child: qr), const SizedBox(height: 18), steps]),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.n, required this.child});
  final int n;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: context.tokens.glass, borderRadius: BorderRadius.circular(13)),
            child: Text('$n', style: Theme.of(context).textTheme.labelLarge),
          ),
          const SizedBox(width: 12),
          Expanded(child: Padding(padding: const EdgeInsets.only(top: 3), child: child)),
        ],
      ),
    );
  }
}
