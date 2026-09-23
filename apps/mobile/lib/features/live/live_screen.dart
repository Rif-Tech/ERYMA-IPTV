import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/responsive.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/db/database.dart';
import '../../core/settings/settings.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/common.dart';
import '../../widgets/format.dart';
import '../../widgets/pin_dialog.dart';
import '../content/content_providers.dart';
import '../player/play.dart';
import '../playlists/playlists_provider.dart';
import '../shell/app_shell.dart' show topLeftFocusable;

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

/// Channel currently highlighted by the D-pad; feeds the now/next header.
class _FocusedChannel extends Notifier<Channel?> {
  @override
  Channel? build() => null;
  void set(Channel? c) {
    if (state?.streamId != c?.streamId) state = c;
  }
}

final _focusedChannelProvider = NotifierProvider<_FocusedChannel, Channel?>(_FocusedChannel.new);

/// Two-column layout shared by Live, Movies and Series: translucent category pane + content.
/// Each column is its own focus scope so D-pad Up/Down never jumps across; Left/Right cross explicitly.
class BrowserScaffold extends StatefulWidget {
  const BrowserScaffold({super.key, required this.kind, required this.form, required this.child});
  final ContentKind kind;
  final FormFactor form;
  final Widget child;

  @override
  State<BrowserScaffold> createState() => _BrowserScaffoldState();
}

class _BrowserScaffoldState extends State<BrowserScaffold> {
  final _pane = FocusScopeNode(debugLabel: 'categories');
  final _content = FocusScopeNode(debugLabel: 'content');

  @override
  void dispose() {
    _pane.dispose();
    _content.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final current = FocusManager.instance.primaryFocus;
    if (current == null) return KeyEventResult.ignored;
    // Never hand focus to a scope without focusable children: directional traversal from a bare
    // scope reports success without moving, which would trap the remote.
    bool enter(FocusScopeNode scope) {
      final child = scope.focusedChild ?? topLeftFocusable(scope);
      if (child == null) return false;
      child.requestFocus();
      return true;
    }

    final canMove = current is! FocusScopeNode;
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft && _content.hasFocus) {
      if (canMove && current.focusInDirection(TraversalDirection.left)) return KeyEventResult.handled;
      enter(_pane);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight && _pane.hasFocus) {
      enter(_content);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final form = widget.form;
    if (form.isMobile) {
      return Column(
        children: [
          SizedBox(height: top),
          CategoryBar(kind: widget.kind),
          Expanded(child: MediaQuery.removePadding(context: context, removeTop: true, child: widget.child)),
        ],
      );
    }
    final g = context.tokens.pageGutter;
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: _onKey,
      child: Padding(
        padding: EdgeInsets.fromLTRB(g, top + 8, g, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: form.isTv ? 220 : 200, child: FocusScope(node: _pane, child: CategoryPane(kind: widget.kind))),
            const SizedBox(width: 24),
            Expanded(
              child: FocusScope(
                node: _content,
                child: MediaQuery.removePadding(context: context, removeTop: true, child: widget.child),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
        child: Column(
          children: [
            if (!form.isMobile) _NowNextHeader(playlistId: playlist.id),
            Expanded(
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
          ],
        ),
      ),
    );
  }
}

/// Large now/next card for the highlighted channel (TV/tablet).
class _NowNextHeader extends ConsumerWidget {
  const _NowNextHeader({required this.playlistId});
  final String playlistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = ref.watch(_focusedChannelProvider);
    final use24h = ref.watch(settingsProvider.select((s) => s.use24hClock));
    final text = Theme.of(context).textTheme;
    final t = context.tokens;
    final epgId = c?.epgChannelId;
    final programs = c == null || epgId == null || epgId.isEmpty
        ? const <EpgProgram>[]
        : ref.watch(nowNextProvider(NowNextQuery(playlistId, epgId))).value ?? const <EpgProgram>[];
    final now = programs.isNotEmpty ? programs.first : null;
    final next = programs.length > 1 ? programs[1] : null;
    final progress = now == null
        ? null
        : (DateTime.now().difference(now.start).inSeconds / now.end.difference(now.start).inSeconds.clamp(1, 1 << 30)).clamp(0.0, 1.0);

    return AnimatedSize(
      duration: t.motion,
      curve: t.curve,
      alignment: Alignment.topCenter,
      child: c == null
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: GlassPanel(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      width: 128,
                      height: 72,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(10)),
                      child: AppImage(c.logo, fit: BoxFit.contain, icon: Icons.live_tv, decodeWidth: 320),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              if (c.number != null)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: MetaBadge('${c.number}'),
                                ),
                              Expanded(child: Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.titleLarge)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          if (now == null)
                            Text(l10n.noEpgAvailable, style: text.bodyMedium?.copyWith(color: t.textFaint))
                          else ...[
                            Text.rich(
                              TextSpan(children: [
                                TextSpan(text: '${l10n.nowLabel}  ', style: text.labelMedium?.copyWith(color: t.textFaint)),
                                TextSpan(text: now.title, style: text.bodyLarge),
                                TextSpan(
                                  text: '   ${formatTime(context, now.start, use24h: use24h)} – ${formatTime(context, now.end, use24h: use24h)}',
                                  style: text.bodySmall?.copyWith(color: t.textFaint),
                                ),
                              ]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (progress != null)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: ClipRRect(borderRadius: BorderRadius.circular(1.5), child: ProgressStrip(progress, height: 3)),
                              ),
                            if (next != null)
                              Text.rich(
                                TextSpan(children: [
                                  TextSpan(text: '${l10n.nextLabel}  ', style: text.labelMedium?.copyWith(color: t.textFaint)),
                                  TextSpan(text: next.title, style: text.bodyMedium?.copyWith(color: t.textMuted)),
                                  TextSpan(
                                    text: '   ${formatTime(context, next.start, use24h: use24h)}',
                                    style: text.bodySmall?.copyWith(color: t.textFaint),
                                  ),
                                ]),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
    final text = Theme.of(context).textTheme;
    final t = context.tokens;
    return FocusTraversalGroup(
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: entries.length,
        itemExtent: 44,
        addAutomaticKeepAlives: false,
        itemBuilder: (context, i) {
          final e = entries[i];
          final isSelected = e.id == selected;
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: _CategoryItem(
              autofocus: i == 0,
              selected: isSelected,
              icon: e.icon,
              label: categoryLabel(l10n, e),
              onSelect: () => ref.read(selectedCategoryProvider(kind).notifier).select(e.id),
              textStyle: text.bodyMedium!,
              muted: t.textMuted,
            ),
          );
        },
      ),
    );
  }
}

/// Pill-shaped category row: white when focused, translucent when selected.
class _CategoryItem extends StatefulWidget {
  const _CategoryItem({
    required this.autofocus,
    required this.selected,
    required this.label,
    required this.onSelect,
    required this.textStyle,
    required this.muted,
    this.icon,
  });
  final bool autofocus;
  final bool selected;
  final IconData? icon;
  final String label;
  final VoidCallback onSelect;
  final TextStyle textStyle;
  final Color muted;

  @override
  State<_CategoryItem> createState() => _CategoryItemState();
}

class _CategoryItemState extends State<_CategoryItem> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final bg = _focused ? Colors.white : widget.selected ? t.glassStrong : Colors.transparent;
    final fg = _focused ? Colors.black : widget.selected ? Colors.white : widget.muted;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        autofocus: widget.autofocus,
        onTap: widget.onSelect,
        onFocusChange: (f) {
          setState(() => _focused = f);
          if (f) widget.onSelect();
        },
        focusColor: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: t.motion,
          curve: t.curve,
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              if (widget.icon != null) ...[Icon(widget.icon, size: 18, color: fg), const SizedBox(width: 10)],
              Expanded(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: widget.textStyle.copyWith(color: fg, fontWeight: widget.selected || _focused ? FontWeight.w600 : FontWeight.w400),
                ),
              ),
            ],
          ),
        ),
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
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: entries.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final e = entries[i];
          return ChoiceChip(
            avatar: e.icon != null ? Icon(e.icon, size: 16, color: e.id == selected ? Colors.black : Colors.white) : null,
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
        padding: EdgeInsets.fromLTRB(form.isMobile ? 12 : 0, 0, form.isMobile ? 12 : 0, 24 + MediaQuery.paddingOf(context).bottom),
        itemCount: channels.length,
        itemExtent: form.isTv ? 78 : 70,
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
              onFocus: form.isMobile ? null : () => ref.read(_focusedChannelProvider.notifier).set(c),
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
    this.onFocus,
  });
  final ContentQuery query;
  final Channel channel;
  final bool use24h;
  final bool locked;
  final bool favorite;
  final bool playing;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback? onFocus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String? now;
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
      }
    }
    return ChannelTile(
      name: channel.name,
      logo: channel.logo,
      number: channel.number,
      nowPlaying: now,
      progress: progress,
      locked: locked,
      favorite: favorite,
      selected: playing,
      onTap: onTap,
      onLongPress: onLongPress,
      onFocus: onFocus,
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
