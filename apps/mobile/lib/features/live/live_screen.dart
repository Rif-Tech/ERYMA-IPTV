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
import '../content/content_providers.dart';
import '../player/play.dart';
import '../playlists/playlists_provider.dart';

/// Category entry shown in the left pane (special or provider category).
class CategoryEntry {
  const CategoryEntry(this.id, this.name, {this.icon});
  final String id;
  final String name;
  final IconData? icon;
}

/// Builds the category list for a content kind, including the pseudo categories.
final categoryEntriesProvider = FutureProvider.family<List<CategoryEntry>, ContentKind>((ref, kind) async {
  final playlist = ref.watch(activePlaylistProvider);
  if (playlist == null) return const [];
  final cats = await ref.watch(categoriesProvider(CategoryQuery(playlist.id, kind)).future);
  final groups = kind == ContentKind.live ? (ref.watch(channelGroupsProvider(playlist.id)).value ?? const []) : const <ChannelGroup>[];
  return [
    const CategoryEntry(SpecialCategory.all, '', icon: Icons.apps),
    const CategoryEntry(SpecialCategory.favorites, '', icon: Icons.star),
    const CategoryEntry(SpecialCategory.recent, '', icon: Icons.history),
    for (final g in groups) CategoryEntry('${SpecialCategory.groupPrefix}${g.id}', g.name, icon: Icons.folder_special),
    for (final c in cats) CategoryEntry(c.externalId, c.name),
  ];
});

String categoryLabel(AppLocalizations l10n, CategoryEntry e) => switch (e.id) {
      SpecialCategory.all => l10n.all,
      SpecialCategory.favorites => l10n.favorites,
      SpecialCategory.recent => l10n.recentlyViewed,
      _ => e.name,
    };

/// Remembers the selected category per content kind while the app runs.
class SelectedCategory extends Notifier<String> {
  SelectedCategory(this.kind);
  final ContentKind kind;
  @override
  String build() => SpecialCategory.all;
  void select(String id) => state = id;
}

final selectedCategoryProvider = NotifierProvider.family<SelectedCategory, String, ContentKind>(SelectedCategory.new);

class LiveScreen extends ConsumerWidget {
  const LiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final playlist = ref.watch(activePlaylistProvider);
    if (playlist == null) return EmptyState(icon: Icons.live_tv, message: l10n.noChannels);
    final selected = ref.watch(selectedCategoryProvider(ContentKind.live));
    final channels = ref.watch(channelsProvider(ContentQuery(playlist.id, ContentKind.live, selected)));

    return Responsive(
      builder: (context, form) {
        final list = AsyncView(
          value: channels,
          builder: (items) => _ChannelList(playlistId: playlist.id, channels: items, form: form),
        );
        if (form.isMobile) {
          return Column(
            children: [
              CategoryBar(kind: ContentKind.live),
              Expanded(child: list),
            ],
          );
        }
        return Row(
          children: [
            SizedBox(width: form.isTv ? 280 : 240, child: CategoryPane(kind: ContentKind.live)),
            const VerticalDivider(width: 1),
            Expanded(child: list),
          ],
        );
      },
    );
  }
}

/// Vertical category list (tablet / TV).
class CategoryPane extends ConsumerWidget {
  const CategoryPane({super.key, required this.kind});
  final ContentKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final entries = ref.watch(categoryEntriesProvider(kind)).value ?? const [];
    final selected = ref.watch(selectedCategoryProvider(kind));
    return FocusTraversalGroup(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: entries.length,
        itemBuilder: (context, i) {
          final e = entries[i];
          final isSelected = e.id == selected;
          return FocusableCard(
            scale: 1.0,
            borderRadius: 8,
            autofocus: i == 0,
            onTap: () => ref.read(selectedCategoryProvider(kind).notifier).select(e.id),
            onFocus: () => ref.read(selectedCategoryProvider(kind).notifier).select(e.id),
            child: Container(
              color: isSelected ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5) : null,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  if (e.icon != null) ...[Icon(e.icon, size: 20), const SizedBox(width: 8)],
                  Expanded(
                    child: Text(
                      categoryLabel(l10n, e),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: isSelected ? const TextStyle(fontWeight: FontWeight.w600) : null,
                    ),
                  ),
                  if (isSelected) const Icon(Icons.chevron_right, size: 18),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Horizontal chips (phone).
class CategoryBar extends ConsumerWidget {
  const CategoryBar({super.key, required this.kind});
  final ContentKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final entries = ref.watch(categoryEntriesProvider(kind)).value ?? const [];
    final selected = ref.watch(selectedCategoryProvider(kind));
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: entries.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final e = entries[i];
          return ChoiceChip(
            avatar: e.icon != null ? Icon(e.icon, size: 18) : null,
            label: Text(categoryLabel(l10n, e)),
            selected: e.id == selected,
            onSelected: (_) => ref.read(selectedCategoryProvider(kind).notifier).select(e.id),
          );
        },
      ),
    );
  }
}

class _ChannelList extends ConsumerWidget {
  const _ChannelList({required this.playlistId, required this.channels, required this.form});
  final String playlistId;
  final List<Channel> channels;
  final FormFactor form;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    if (channels.isEmpty) return EmptyState(icon: Icons.live_tv, message: l10n.noChannels);
    final locked = ref.watch(lockedChannelsProvider(playlistId)).value ?? const {};
    final favs = ref.watch(favoriteIdsProvider(CategoryQuery(playlistId, ContentKind.live))).value ?? const {};
    final use24h = ref.watch(settingsProvider.select((s) => s.use24hClock));

    return FocusTraversalGroup(
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: channels.length,
        itemExtent: form.isTv ? 76 : 68,
        itemBuilder: (context, i) {
          final c = channels[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: _ChannelRow(
              playlistId: playlistId,
              channel: c,
              use24h: use24h,
              locked: locked.contains(c.streamId),
              favorite: favs.contains(c.streamId),
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
    required this.playlistId,
    required this.channel,
    required this.use24h,
    required this.locked,
    required this.favorite,
    required this.onTap,
    required this.onLongPress,
  });
  final String playlistId;
  final Channel channel;
  final bool use24h;
  final bool locked;
  final bool favorite;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String? now;
    final epgId = channel.epgChannelId;
    if (epgId != null && epgId.isNotEmpty) {
      final programs = ref.watch(nowNextProvider(NowNextQuery(playlistId, epgId))).value;
      if (programs != null && programs.isNotEmpty) {
        final p = programs.first;
        now = '${formatTime(context, p.start, use24h: use24h)}  ${p.title}';
      }
    }
    return ChannelTile(
      name: channel.name,
      logo: channel.logo,
      number: channel.number,
      nowPlaying: now,
      locked: locked,
      favorite: favorite,
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
