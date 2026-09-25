import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/responsive.dart';
import '../../app/router.dart';
import '../../core/db/database.dart';
import '../../core/settings/settings.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/common.dart';
import '../../widgets/format.dart';
import '../../widgets/pin_dialog.dart';
import '../content/category_browser.dart';
import '../content/content_providers.dart';
import '../player/play.dart';
import '../playlists/playlists_provider.dart';

class LiveScreen extends ConsumerWidget {
  const LiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final playlist = ref.watch(activePlaylistProvider);
    if (playlist == null) {
      if (ref.watch(playlistsProvider).isLoading) return const SizedBox.shrink();
      return EmptyState(icon: Icons.live_tv, message: l10n.noChannels);
    }
    final selected = ref.watch(selectedCategoryProvider(ContentKind.live));
    final query = ContentQuery(playlist.id, ContentKind.live, selected);
    final channels = ref.watch(channelsProvider(query));

    return Responsive(
      builder: (context, form) => BrowserScaffold(
        kind: ContentKind.live,
        form: form,
        child: AsyncView(
          value: channels,
          builder: (page) => _ChannelList(
            query: query,
            channels: page.items,
            form: form,
            onNearEnd: () => ref.read(channelsProvider(query).notifier).loadMore(),
          ),
        ),
      ),
    );
  }
}

class _ChannelList extends ConsumerWidget {
  const _ChannelList({required this.query, required this.channels, required this.form, required this.onNearEnd});
  final ContentQuery query;
  final List<Channel> channels;
  final FormFactor form;
  final VoidCallback onNearEnd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    if (channels.isEmpty) return EmptyState(icon: Icons.live_tv, message: l10n.noChannels);
    final playlistId = query.playlistId;
    final locked = ref.watch(lockedChannelsProvider(playlistId)).value ?? const {};
    final favs = ref.watch(favoriteIdsProvider(CategoryQuery(playlistId, ContentKind.live))).value ?? const {};
    final use24h = ref.watch(settingsProvider.select((s) => s.use24hClock));
    // The channel last played on this profile gets the "playing" marker so the user knows where they are.
    final lastPlayed = ref.watch(historyProvider(CategoryQuery(playlistId, ContentKind.live)).select((h) => h.value?.firstOrNull?.itemId));

    return FocusTraversalGroup(
      child: ListView.builder(
        // Horizontal room on TV too: the focused row scales up (FocusableCard) and clips against a
        // zero-padding viewport otherwise.
        padding: EdgeInsets.fromLTRB(form.isMobile ? 12 : 16, 0, form.isMobile ? 12 : 16, 24 + MediaQuery.paddingOf(context).bottom),
        itemCount: channels.length,
        // Taller on TV to always reserve room for the "next" line (now shown inside the row).
        itemExtent: form.isTv ? 96 : 70,
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: false,
        itemBuilder: (context, i) {
          if (i >= channels.length - 40) onNearEnd();
          final c = channels[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _ChannelRow(
              query: query,
              channel: c,
              use24h: use24h,
              locked: locked.contains(c.streamId),
              favorite: favs.contains(c.streamId),
              playing: c.streamId == lastPlayed,
              onTap: () => playChannels(context, ref, channels, i),
              onLongPress: () => showChannelMenu(context, ref, playlistId, c),
            ),
          );
        },
      ),
    );
  }
}

class _ChannelRow extends ConsumerWidget {
  const _ChannelRow({
    required this.query,
    required this.channel,
    required this.use24h,
    required this.locked,
    required this.favorite,
    this.playing = false,
    required this.onTap,
    required this.onLongPress,
  });
  final ContentQuery query;
  final Channel channel;
  final bool use24h;
  final bool locked;
  final bool favorite;
  final bool playing;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    String? now;
    String? next;
    double? progress;
    final epgId = channel.epgChannelId;
    if (epgId != null && epgId.isNotEmpty) {
      // One shared query for the whole list; this row only rebuilds when its own entry changes.
      final programs = ref.watch(nowNextMapProvider(query).select((m) => m.value?[epgId]));
      if (programs != null && programs.isNotEmpty) {
        final p = programs.first;
        now = p.title;
        final total = p.end.difference(p.start).inSeconds;
        if (total > 0) progress = (DateTime.now().difference(p.start).inSeconds / total).clamp(0.0, 1.0);
        if (programs.length > 1) {
          final n = programs[1];
          next = '${l10n.nextLabel} : ${n.title} · ${formatTime(context, n.start, use24h: use24h)}';
        }
      }
    }
    return ChannelTile(
      name: channel.name,
      logo: channel.logo,
      number: channel.number,
      nowPlaying: now,
      nextPlaying: next,
      progress: progress,
      locked: locked,
      favorite: favorite,
      selected: playing,
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}

/// Context menu: favorite, lock (parental), add to group.
Future<void> showChannelMenu(BuildContext context, WidgetRef ref, String playlistId, Channel c) async {
  final l10n = AppLocalizations.of(context);
  final db = ref.read(databaseProvider);
  final locked = ref.read(lockedChannelsProvider(playlistId)).value ?? const {};
  final favs = ref.read(favoriteIdsProvider(CategoryQuery(playlistId, ContentKind.live))).value ?? const {};
  final groups = ref.read(channelGroupsProvider(playlistId)).value ?? const [];
  final isLocked = locked.contains(c.streamId);

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheet) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(title: Text(c.name, style: Theme.of(sheet).textTheme.titleMedium)),
          ListTile(
            autofocus: true,
            leading: Icon(favs.contains(c.streamId) ? Icons.star : Icons.star_border),
            title: Text(favs.contains(c.streamId) ? l10n.removeFromFavorites : l10n.addToFavorites),
            onTap: () {
              db.toggleFavorite(playlistId, ContentKind.live, c.streamId);
              Navigator.pop(sheet);
            },
          ),
          ListTile(
            leading: Icon(isLocked ? Icons.lock_open : Icons.lock),
            title: Text(isLocked ? l10n.unlockChannel : l10n.lockChannel),
            onTap: () async {
              Navigator.pop(sheet);
              final pin = ref.read(settingsProvider).parentalPin;
              if (pin == null || pin.isEmpty) {
                context.push(Routes.parental);
                return;
              }
              if (await requirePin(context, pin)) await db.toggleLockedChannel(playlistId, c.streamId);
            },
          ),
          if (groups.isNotEmpty)
            ExpansionTile(
              leading: const Icon(Icons.folder_special),
              title: Text(l10n.myGroups),
              children: [
                for (final g in groups)
                  ListTile(
                    title: Text(g.name),
                    onTap: () async {
                      final existing = await db.getGroupChannels(playlistId, g.id);
                      final ids = existing.map((e) => e.streamId).toList();
                      if (!ids.contains(c.streamId)) ids.add(c.streamId);
                      await db.setGroupChannels(g.id, ids);
                      if (sheet.mounted) Navigator.pop(sheet);
                    },
                  ),
              ],
            )
          else
            ListTile(
              leading: const Icon(Icons.create_new_folder_outlined),
              title: Text(l10n.addGroup),
              onTap: () {
                Navigator.pop(sheet);
                context.push(Routes.groups);
              },
            ),
        ],
      ),
    ),
  );
}
