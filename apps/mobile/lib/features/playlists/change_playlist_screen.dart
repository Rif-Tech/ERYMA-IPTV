import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/db/database.dart';
import '../../core/playlist/playlist_importer.dart';
import '../../core/settings/settings.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/common.dart';
import '../../widgets/format.dart';
import '../../widgets/pin_dialog.dart';
import '../splash/splash_screen.dart';
import 'playlists_provider.dart';

class ChangePlaylistScreen extends ConsumerWidget {
  const ChangePlaylistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final playlists = ref.watch(playlistsProvider);
    final activeId = ref.watch(settingsProvider.select((s) => s.activePlaylistId));
    final syncing = ref.watch(deviceSessionProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myPlaylists),
        leading: activeId != null
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.canPop() ? context.pop() : context.go(Routes.home))
            : null,
        actions: [
          IconButton(
            tooltip: l10n.refreshPlaylists,
            icon: syncing
                ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.sync),
            onPressed: syncing ? null : () => ref.read(deviceSessionProvider.notifier).refresh(),
          ),
          PopupMenuButton<String>(
            onSelected: (v) => context.push(v == 'xtream' ? Routes.addXtream : Routes.addM3u),
            itemBuilder: (_) => [
              PopupMenuItem(value: 'xtream', child: ListTile(leading: const Icon(Icons.vpn_key), title: Text(l10n.addXtream))),
              PopupMenuItem(value: 'm3u', child: ListTile(leading: const Icon(Icons.link), title: Text(l10n.addM3u))),
            ],
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: AsyncView(
        value: playlists,
        builder: (list) {
          if (list.isEmpty) {
            return EmptyState(
              icon: Icons.playlist_remove,
              message: l10n.noPlaylistTitle,
              action: FilledButton(onPressed: () => context.go(Routes.noPlaylist), child: Text(l10n.addPlaylist)),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final p = list[i];
              final account = decodeAccountInfo(p.accountInfo);
              final exp = account['exp_date'] != null && account['exp_date'] != 'null'
                  ? DateTime.tryParse(account['exp_date']!)
                  : p.expiresAt;
              return FocusableCard(
                autofocus: i == 0,
                selected: p.id == activeId,
                scale: 1.01,
                onTap: () => openPlaylist(context, ref, p),
                onLongPress: () => _showActions(context, ref, p),
                child: ListTile(
                  leading: Icon(p.type == PlaylistType.xtream ? Icons.vpn_key : Icons.link),
                  title: Text(p.name),
                  subtitle: Text([
                    p.source == PlaylistSource.portal ? l10n.playlistFromPortal : l10n.playlistLocal,
                    if (exp != null) l10n.playlistExpires(formatDate(context, exp)),
                    if (p.isProtected) l10n.playlistProtected,
                  ].join(' · ')),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (p.id == activeId) const Icon(Icons.check_circle, color: Colors.green),
                      IconButton(
                        tooltip: l10n.edit,
                        icon: const Icon(Icons.more_vert),
                        onPressed: () => _showActions(context, ref, p),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// Actions menu; the PIN only guards editing (credentials), never deletion or playback.
  Future<void> _showActions(BuildContext context, WidgetRef ref, Playlist p) async {
    final l10n = AppLocalizations.of(context);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: Text(p.name, style: Theme.of(sheet).textTheme.titleMedium)),
            ListTile(
              autofocus: true,
              leading: const Icon(Icons.play_arrow),
              title: Text(l10n.play),
              onTap: () {
                Navigator.pop(sheet);
                openPlaylist(context, ref, p);
              },
            ),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: Text(l10n.refreshPlaylists),
              onTap: () async {
                Navigator.pop(sheet);
                await ref.read(settingsProvider.notifier).setActivePlaylistId(p.id);
                if (context.mounted) context.go(Routes.import(p.id));
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(l10n.editPlaylist),
              onTap: () async {
                Navigator.pop(sheet);
                if (p.isProtected && !await requirePin(context, p.pinCode, title: l10n.playlistProtected)) return;
                if (context.mounted) context.push(Routes.editPlaylist(p.id));
              },
            ),
            if (p.source == PlaylistSource.local)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: Text(l10n.deletePlaylist),
                onTap: () {
                  Navigator.pop(sheet);
                  _confirmDelete(context, ref, p);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Playlist p) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deletePlaylist),
        content: Text(l10n.deletePlaylistConfirm(p.name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.delete)),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(databaseProvider).deletePlaylist(p.id);
    final settings = ref.read(settingsProvider);
    if (settings.activePlaylistId == p.id) {
      await ref.read(settingsProvider.notifier).setActivePlaylistId(null);
    }
  }
}
