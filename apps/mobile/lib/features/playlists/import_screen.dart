import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/db/database.dart';
import '../../core/playlist/playlist_importer.dart';
import '../../l10n/generated/app_localizations.dart';
import '../splash/session_navigation.dart';
import 'playlists_provider.dart';

/// Runs the playlist import and shows progress; navigates home on success.
class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key, required this.playlistId});
  final String playlistId;

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  Playlist? _playlist;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    final playlist = await ref.read(databaseProvider).getPlaylist(widget.playlistId);
    if (!mounted) return;
    if (playlist == null) {
      context.go(Routes.playlists);
      return;
    }
    setState(() => _playlist = playlist);
    final ok = await ref.read(playlistImportProvider.notifier).import(playlist);
    if (!mounted) return;
    if (ok) {
      ref.read(playlistImportProvider.notifier).reset();
      if (redirectedBySession(context, ref)) return;
      context.go(Routes.home);
    }
  }

  /// Bails out of a stuck or unwanted import (Back, or the button below): this route is reached by
  /// `go()` with nothing to pop to, so without this the hardware Back key would quit the app instead
  /// of returning to the picker (the one screen a slow/frozen import otherwise has no escape from).
  void _cancelAndPickAnother() {
    ref.read(playlistImportProvider.notifier).reset();
    context.go(Routes.playlists);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(playlistImportProvider);
    final theme = Theme.of(context);
    final progress = state.progress;

    String stageLabel(ImportStage s) => switch (s) {
          ImportStage.connecting => l10n.playlistLoading,
          ImportStage.live => l10n.importingLive,
          ImportStage.movies => l10n.importingMovies,
          ImportStage.series => l10n.importingSeries,
          ImportStage.epg => l10n.importingEpg,
          ImportStage.done => l10n.importDone,
        };

    // Reached by go() as the app's start screen (root, nothing to pop): without this, the hardware
    // Back key falls through to Android's own back handling and exits the app instead of returning
    // to the picker — the only escape a stuck import otherwise has (see _cancelAndPickAnother).
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancelAndPickAnother();
      },
      child: Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.playlist_add_check, size: 72, color: theme.colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(_playlist?.name ?? '', style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  if (state.error != null) ...[
                    Icon(Icons.error_outline, color: theme.colorScheme.error, size: 40),
                    const SizedBox(height: 8),
                    Text(state.isAuthError ? l10n.loginFailed : l10n.importFailed, textAlign: TextAlign.center),
                    const SizedBox(height: 4),
                    Text(state.error!, style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 12,
                      children: [
                        FilledButton.icon(
                          autofocus: true,
                          onPressed: _start,
                          icon: const Icon(Icons.refresh),
                          label: Text(l10n.retry),
                        ),
                        OutlinedButton(onPressed: _cancelAndPickAnother, child: Text(l10n.changePlaylist)),
                      ],
                    ),
                  ] else ...[
                    const LinearProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(stageLabel(progress?.stage ?? ImportStage.connecting), style: theme.textTheme.titleMedium),
                    if (progress != null && (progress.total > 0 || progress.done > 0))
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          progress.total > 0 ? l10n.importProgress('${progress.done}', '${progress.total}') : '${progress.done}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    const SizedBox(height: 24),
                    // The only focusable element while an import runs: without it, a slow/stuck
                    // import (unresponsive Xtream panel, network) left the D-pad with nothing to do
                    // and no visible way out short of Back quitting the app (see PopScope above).
                    OutlinedButton(autofocus: true, onPressed: _cancelAndPickAnother, child: Text(l10n.changePlaylist)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
