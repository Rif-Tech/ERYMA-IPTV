import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/responsive.dart';
import '../../app/theme.dart';
import '../../core/db/database.dart';
import '../../core/log/trace_tag.dart';
import '../../l10n/generated/app_localizations.dart';
import '../playlists/playlists_provider.dart';
import '../shell/app_shell.dart' show topLeftFocusable;
import 'content_providers.dart';

// Category browser shared by Live, Movies and Series: category entries and selection per kind,
// the two-column BrowserScaffold (category rail + content) and the rail widgets (TV/tablet pane,
// phone chips).

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
            SizedBox(width: form.isTv ? 220 : 200, child: TraceTag('categories', child: FocusScope(node: _pane, child: CategoryPane(kind: widget.kind)))),
            const SizedBox(width: 24),
            Expanded(
              child: TraceTag('content', child: FocusScope(
                node: _content,
                child: MediaQuery.removePadding(context: context, removeTop: true, child: widget.child),
              )),
            ),
          ],
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
