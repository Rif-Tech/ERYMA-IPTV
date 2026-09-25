import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/config.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/db/database.dart';
import '../../core/playlist/playlist_importer.dart';
import '../../core/settings/settings.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/common.dart';
import '../../widgets/format.dart';
import '../splash/session_navigation.dart';
import 'playlists_provider.dart';

class ChangePlaylistScreen extends ConsumerWidget {
  const ChangePlaylistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final playlists = ref.watch(playlistsProvider);
    final activeId = ref.watch(settingsProvider.select((s) => s.activePlaylistId));
    final syncing = ref.watch(deviceSessionProvider).isLoading;
    final profile = ref.watch(activeProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(profile == null ? l10n.myPlaylists : '${l10n.myPlaylists} · ${profile.name}'),
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
          IconButton(
            tooltip: l10n.addPlaylistTitle,
            icon: const Icon(Icons.add),
            onPressed: () => context.push(Routes.noPlaylist),
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
              action: FilledButton(onPressed: () => context.go(Routes.noPlaylist), child: Text(l10n.addPlaylistTitle)),
            );
          }
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: ListView.separated(
                padding: const EdgeInsets.all(20),
                // Row 0 reminds where playlists are managed; playlists follow.
                itemCount: list.length + 1,
                separatorBuilder: (_, i) => SizedBox(height: i == 0 ? 20 : 10),
                itemBuilder: (context, row) {
                  if (row == 0) return const _ManagedOnWebHint();
                  final i = row - 1;
                  final p = list[i];
                  final account = decodeAccountInfo(p.accountInfo);
                  final exp = account['exp_date'] != null && account['exp_date'] != 'null'
                      ? DateTime.tryParse(account['exp_date']!)
                      : p.expiresAt;
                  final active = p.id == activeId;
                  return FocusableCard(
                    autofocus: i == 0,
                    selected: active,
                    scale: 1.01,
                    onTap: () => openPlaylist(context, ref, p),
                    onLongPress: () => _showActions(context, ref, p),
                    child: GlassPanel(
                      strong: active,
                      radius: 12,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(color: active ? Colors.white : context.tokens.glass, borderRadius: BorderRadius.circular(10)),
                            alignment: Alignment.center,
                            child: Icon(p.type == PlaylistType.xtream ? Icons.vpn_key_rounded : Icons.link_rounded, size: 22, color: active ? Colors.black : Colors.white),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.name, style: Theme.of(context).textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 2),
                                Text(
                                  [
                                    p.source == PlaylistSource.portal ? l10n.playlistFromPortal : l10n.playlistLocal,
                                    if (exp != null) l10n.playlistExpires(formatDate(context, exp)),
                                  ].join(' · '),
                                  style: Theme.of(context).textTheme.bodySmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          if (p.isProtected) Padding(padding: const EdgeInsets.only(left: 8), child: Icon(Icons.lock_rounded, size: 16, color: context.tokens.textMuted)),
                          if (active) const Padding(padding: EdgeInsets.only(left: 8), child: Icon(Icons.check_circle_rounded, color: Color(0xFF30D158))),
                          IconButton(
                            tooltip: l10n.edit,
                            icon: const Icon(Icons.more_horiz_rounded),
                            onPressed: () => _showActions(context, ref, p),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  /// Actions menu. Portal playlists are edited on the web; only legacy local ones can be deleted here.
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
            if (p.source == PlaylistSource.portal)
              ListTile(
                leading: const Icon(Icons.open_in_browser_rounded),
                title: Text(l10n.editPlaylist),
                subtitle: Text(l10n.managePlaylistsOnline),
                onTap: () {
                  Navigator.pop(sheet);
                  launchUrl(Uri.parse('${AppConfig.accountUrl}/playlists'), mode: LaunchMode.externalApplication);
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

/// Playlists are account-owned and edited on the portal; this row says where.
class _ManagedOnWebHint extends StatelessWidget {
  const _ManagedOnWebHint();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final host = AppConfig.portalHost;
    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Icon(Icons.cloud_done_rounded, color: context.tokens.textMuted),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l10n.managePlaylistsOnline, style: theme.textTheme.titleSmall),
            Text(l10n.accountManageOnline(host), style: theme.textTheme.bodySmall?.copyWith(color: context.tokens.textMuted)),
          ]),
        ),
      ]),
    );
  }
}
