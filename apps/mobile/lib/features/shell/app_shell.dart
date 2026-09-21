import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/responsive.dart';
import '../../app/router.dart';
import '../../l10n/generated/app_localizations.dart';

class _Destination {
  const _Destination(this.route, this.icon, this.selectedIcon, this.label);
  final String route;
  final IconData icon;
  final IconData selectedIcon;
  final String Function(AppLocalizations) label;
}

final _destinations = [
  _Destination(Routes.home, Icons.home_outlined, Icons.home, (l) => l.home),
  _Destination(Routes.live, Icons.live_tv_outlined, Icons.live_tv, (l) => l.liveTv),
  _Destination(Routes.movies, Icons.movie_outlined, Icons.movie, (l) => l.movies),
  _Destination(Routes.series, Icons.video_library_outlined, Icons.video_library, (l) => l.series),
  _Destination(Routes.search, Icons.search, Icons.search, (l) => l.search),
  _Destination(Routes.settings, Icons.settings_outlined, Icons.settings, (l) => l.settings),
];

/// Focus node attached to the sidebar's current section, so content panes can jump back to it (D-pad left).
final sidebarFocusProvider = Provider<FocusNode>((ref) {
  final node = FocusNode(debugLabel: 'sidebar');
  ref.onDispose(node.dispose);
  return node;
});

/// Scope of the content area; remembers the last focused item so Right from the sidebar returns to it.
final bodyScopeProvider = Provider<FocusScopeNode>((ref) {
  final node = FocusScopeNode(debugLabel: 'body');
  ref.onDispose(node.dispose);
  return node;
});

/// D-pad glue between the sidebar and the content: Flutter's directional traversal does not
/// reliably cross the two columns, so when a move fails we hand focus over explicitly.
class _TvFocusBridge extends ConsumerWidget {
  const _TvFocusBridge({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sidebar = ref.watch(sidebarFocusProvider);
    final body = ref.watch(bodyScopeProvider);
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: (_, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        final current = FocusManager.instance.primaryFocus;
        if (current == null) return KeyEventResult.ignored;
        if (event.logicalKey == LogicalKeyboardKey.arrowLeft && body.hasFocus) {
          if (current.focusInDirection(TraversalDirection.left) && body.hasFocus) return KeyEventResult.handled;
          if (sidebar.context != null) sidebar.requestFocus();
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowRight && !body.hasFocus) {
          if (current.focusInDirection(TraversalDirection.right)) return KeyEventResult.handled;
          body.requestFocus();
          if (body.focusedChild == null) body.nextFocus();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: child,
    );
  }
}

/// Responsive navigation chrome: bottom bar (phone), rail (tablet) or focusable sidebar (TV).
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.location, required this.child});
  final String location;
  final Widget child;

  int get _index {
    final i = _destinations.indexWhere((d) => location == d.route || location.startsWith('${d.route}/'));
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isTv = ref.watch(isTelevisionProvider);
    final form = formFactorOf(context, isTv: isTv);
    final index = _index;

    void go(int i) => context.go(_destinations[i].route);

    final body = Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.select): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.gameButtonA): ActivateIntent(),
      },
      child: child,
    );

    if (form.isMobile) {
      return Scaffold(
        body: body,
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: go,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            for (final d in _destinations)
              NavigationDestination(icon: Icon(d.icon), selectedIcon: Icon(d.selectedIcon), label: d.label(l10n)),
          ],
        ),
      );
    }

    final Widget nav = form.isTv
        ? _TvSidebar(index: index, onSelected: go, sidebarNode: ref.watch(sidebarFocusProvider))
        : NavigationRail(
            selectedIndex: index,
            onDestinationSelected: go,
            extended: MediaQuery.sizeOf(context).width >= Breakpoints.desktop,
            minExtendedWidth: 200,
            labelType: NavigationRailLabelType.none,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Icon(Icons.live_tv_rounded, size: 36, color: Theme.of(context).colorScheme.primary),
            ),
            destinations: [
              for (final d in _destinations)
                NavigationRailDestination(icon: Icon(d.icon), selectedIcon: Icon(d.selectedIcon), label: Text(d.label(l10n))),
            ],
          );

    return Scaffold(
      body: _TvFocusBridge(
        child: Row(
          children: [
            FocusTraversalGroup(child: nav),
            const VerticalDivider(width: 1),
            Expanded(
              child: FocusScope(
                node: ref.watch(bodyScopeProvider),
                child: FocusTraversalGroup(child: body),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Leanback-style sidebar: large focus targets, the current section carries [sidebarNode].
class _TvSidebar extends StatelessWidget {
  const _TvSidebar({required this.index, required this.onSelected, required this.sidebarNode});
  final int index;
  final ValueChanged<int> onSelected;
  final FocusNode sidebarNode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 220,
      color: scheme.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 20),
            child: Row(
              children: [
                Icon(Icons.live_tv_rounded, size: 32, color: scheme.primary),
                const SizedBox(width: 10),
                Text(l10n.appName, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ),
          for (final (i, d) in _destinations.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _SidebarItem(
                icon: i == index ? d.selectedIcon : d.icon,
                label: d.label(l10n),
                selected: i == index,
                focusNode: i == index ? sidebarNode : null,
                onTap: () => onSelected(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  const _SidebarItem({required this.icon, required this.label, required this.selected, required this.onTap, this.focusNode});
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final FocusNode? focusNode;

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  late FocusNode _node = widget.focusNode ?? FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _node.addListener(_onFocus);
  }

  // The shared node moves between items when the route changes: rebind the listener.
  @override
  void didUpdateWidget(covariant _SidebarItem old) {
    super.didUpdateWidget(old);
    final next = widget.focusNode ?? (old.focusNode == null ? _node : FocusNode());
    if (next != _node) {
      _node.removeListener(_onFocus);
      if (old.focusNode == null) _node.dispose();
      _node = next..addListener(_onFocus);
    }
    _onFocus();
  }

  void _onFocus() {
    if (_focused != _node.hasFocus) setState(() => _focused = _node.hasFocus);
  }

  @override
  void dispose() {
    _node.removeListener(_onFocus);
    if (widget.focusNode == null) _node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = _focused
        ? scheme.primary
        : widget.selected
            ? scheme.primaryContainer.withValues(alpha: 0.6)
            : Colors.transparent;
    final fg = _focused ? scheme.onPrimary : scheme.onSurface;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        focusNode: _node,
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(widget.icon, color: fg),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  widget.label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: fg, fontWeight: widget.selected ? FontWeight.w600 : null),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
