import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/responsive.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/db/database.dart' show ContentKind;
import '../../l10n/generated/app_localizations.dart';
import '../content/content_providers.dart' show SpecialCategory;
import '../content/category_browser.dart' show selectedCategoryProvider;
import '../search/search_screen.dart' show resetSearch;
import '../../core/log/remote_key_tracker.dart';
import '../../core/log/telemetry.dart';
import '../../core/log/trace_tag.dart';

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

/// Height of the top tab bar (TV/tablet); content below it is inset through MediaQuery padding.
const kTopBarHeight = 72.0;

/// First focusable descendant in reading order (top row, then left), for entering a scope.
FocusNode? topLeftFocusable(FocusScopeNode scope) {
  FocusNode? best;
  for (final n in scope.traversalDescendants) {
    if (best == null || n.rect.top < best.rect.top - 1 || (n.rect.top < best.rect.top + 1 && n.rect.left < best.rect.left)) {
      best = n;
    }
  }
  return best;
}

/// One stable, never-recreated node per tab (so content panes can jump back to the active one on
/// D-pad up, and OK on a tab keeps the cursor on it once the page has loaded).
final _tabFocusNodesProvider = Provider<List<FocusNode>>((ref) {
  final nodes = [for (final d in _destinations) TraceTag.name(FocusNode(debugLabel: 'tab-${d.route}'), 'tab${d.route}')];
  ref.onDispose(() {
    for (final n in nodes) {
      n.dispose();
    }
  });
  return nodes;
});

/// Scope of the content area; remembers the last focused item so Down from the tabs returns to it.
final bodyScopeProvider = Provider<FocusScopeNode>((ref) {
  final node = FocusScopeNode(debugLabel: 'body');
  ref.onDispose(node.dispose);
  return node;
});

/// Bumped whenever a page is opened from the tab bar: pages holding their own focus memory (home
/// rows) listen to it and start over, as if never visited.
final pageResetProvider = NotifierProvider<PageReset, int>(PageReset.new);

class PageReset extends Notifier<int> {
  @override
  int build() => 0;
  void bump() => state++;
}

/// Jumps every scrollable of the visible page back to its start (page, rows, grids, lists).
/// Offstage tabs are skipped: only the page being opened is reset.
int _resetScrollables(Element root) {
  var count = 0;
  void visit(Element e) {
    final w = e.widget;
    if (w is Offstage && w.offstage) return;
    if (e is StatefulElement && e.state is ScrollableState) {
      final position = (e.state as ScrollableState).position;
      if (position.hasPixels && position.pixels != position.minScrollExtent) {
        position.jumpTo(position.minScrollExtent);
        count++;
      }
    }
    e.visitChildElements(visit);
  }

  root.visitChildElements(visit);
  return count;
}

/// Scope of the tab bar; keeps directional traversal from leaking into the page below.
final _barScopeProvider = Provider<FocusScopeNode>((ref) {
  final node = FocusScopeNode(debugLabel: 'topbar-scope');
  ref.onDispose(node.dispose);
  return node;
});

/// Whether the top bar is currently shown (it hides while the content is scrolled down).
final _barVisibleProvider = NotifierProvider<_BarVisible, bool>(_BarVisible.new);

class _BarVisible extends Notifier<bool> {
  @override
  bool build() => true;
  void set(bool v) {
    if (state != v) state = v;
  }
}

/// D-pad glue between the top bar and the content: Flutter's directional traversal does not
/// reliably cross the two regions, so when a move fails we hand focus over explicitly.
class _TvFocusBridge extends ConsumerWidget {
  const _TvFocusBridge({required this.child, required this.currentIndex});
  final Widget child;
  final int currentIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nodes = ref.watch(_tabFocusNodesProvider);
    final bar = nodes[currentIndex];
    final body = ref.watch(bodyScopeProvider);
    final barScope = ref.watch(_barScopeProvider);
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: (_, event) {
        // Repeats too: holding Up must go all the way to the tab bar instead of stopping on the
        // first row of the page and needing one more press.
        if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
        final current = FocusManager.instance.primaryFocus;
        if (current == null) return KeyEventResult.ignored;
        // A bare scope (content emptied under the cursor) reports directional moves as successful
        // without moving; treat it as "nowhere to go".
        final canMove = current is! FocusScopeNode;
        if (barScope.hasFocus) {
          // Tabs form a single row: move between siblings only, never into the page.
          final dir = switch (event.logicalKey) {
            LogicalKeyboardKey.arrowLeft => TraversalDirection.left,
            LogicalKeyboardKey.arrowRight => TraversalDirection.right,
            _ => null,
          };
          if (dir != null) {
            final tabs = barScope.traversalDescendants.toList()..sort((a, b) => a.rect.left.compareTo(b.rect.left));
            final i = tabs.indexOf(current);
            final next = i < 0 ? null : (dir == TraversalDirection.left ? (i > 0 ? tabs[i - 1] : null) : (i < tabs.length - 1 ? tabs[i + 1] : null));
            RemoteKeyTracker.note('tab-bridge: ${dir.name} within tabs${next == null ? ' (edge, stays)' : ''}');
            next?.requestFocus();
            return KeyEventResult.handled;
          }
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowUp && body.hasFocus) {
          if (canMove && current.focusInDirection(TraversalDirection.up) && body.hasFocus) {
            RemoteKeyTracker.note('tab-bridge: up moved within page');
            return KeyEventResult.handled;
          }
          RemoteKeyTracker.note('tab-bridge: up → tab bar');
          ref.read(_barVisibleProvider.notifier).set(true);
          // Like the Apple TV app, reaching the tabs brings the page back to its top. Android lists
          // do not attach to the PrimaryScrollController, so scroll the list holding the focused item.
          final ctx = current.context;
          final position = ctx == null ? null : Scrollable.maybeOf(ctx, axis: Axis.vertical)?.position;
          if (position != null && position.pixels > 0) {
            position.animateTo(0, duration: const Duration(milliseconds: 250), curve: Curves.easeOutCubic);
          }
          if (bar.context != null) bar.requestFocus();
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowDown && !body.hasFocus) {
          // `focusedChild` can point at a node from a tab switched away from since; that subtree is
          // now excluded (ExcludeFocus in _BranchStack), so requestFocus on it would silently no-op.
          final remembered = body.focusedChild;
          final child = (remembered != null && remembered.canRequestFocus) ? remembered : topLeftFocusable(body);
          RemoteKeyTracker.note('tab-bridge: down → page (${remembered != null && remembered.canRequestFocus ? 'remembered' : 'top-left'})');
          (child ?? body).requestFocus();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: child,
    );
  }
}

/// Responsive navigation chrome: bottom bar (phone) or an Apple TV-style top tab bar (tablet/TV).
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.location, required this.shell});
  final String location;
  final StatefulNavigationShell shell;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int get _index => widget.shell.currentIndex;

  // A new page starts scrolled to the top, so the bar must come back even without a scroll event.
  @override
  void didUpdateWidget(covariant AppShell old) {
    super.didUpdateWidget(old);
    if (old.location != widget.location) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(_barVisibleProvider.notifier).set(true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isTv = ref.watch(isTelevisionProvider);
    final form = formFactorOf(context, isTv: isTv);
    final index = _index;

    final tabNodes = ref.watch(_tabFocusNodesProvider);
    final bodyScope = ref.watch(bodyScopeProvider);

    // Opening a page from the tab bar shows it as if never visited: root route (no detail
    // screen), default category, empty search, every list scrolled back to its start, and the
    // D-pad cursor on the page's first element. Post-frame so the page has rebuilt first.
    void resetAndFocusContent(String route) => WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final root = bodyScope.context;
          final jumped = root is Element ? _resetScrollables(root) : 0;
          // A second frame: the lists must lay out at their start before "top-left" means anything.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            final child = topLeftFocusable(bodyScope);
            (child ?? bodyScope).requestFocus();
            Telemetry.breadcrumb('focus', 'page reset: $route', data: {'scrollables_reset': jumped, 'focus': TraceTag.pathOf(child)});
          });
          WidgetsBinding.instance.scheduleFrame();
        });

    void go(int i) {
      final route = _destinations[i].route;
      if (route == Routes.search) resetSearch(ref);
      if (route == Routes.live) ref.read(selectedCategoryProvider(ContentKind.live).notifier).select(SpecialCategory.all);
      if (route == Routes.movies) ref.read(selectedCategoryProvider(ContentKind.vod).notifier).select(SpecialCategory.all);
      if (route == Routes.series) ref.read(selectedCategoryProvider(ContentKind.series).notifier).select(SpecialCategory.all);
      ref.read(pageResetProvider.notifier).bump();
      widget.shell.goBranch(i, initialLocation: true);
      resetAndFocusContent(route);
    }

    // Nested routes (details) pop on their own; this only runs when a root tab is showing.
    Future<void> onBack() async {
      if (widget.location != _destinations[_index].route) return;
      if (_index != 0) {
        go(0);
        return;
      }
      final leave = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.exit),
          content: Text(l10n.exitDescription),
          actions: [
            TextButton(autofocus: true, onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.exit)),
          ],
        ),
      );
      if (leave == true) await SystemNavigator.pop();
    }

    final body = PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) onBack();
      },
      child: Shortcuts(
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.select): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.gameButtonA): ActivateIntent(),
        },
        child: widget.shell,
      ),
    );

    if (form.isMobile) {
      return Scaffold(
        extendBody: true,
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

    final mq = MediaQuery.of(context);
    final visible = ref.watch(_barVisibleProvider);
    return Scaffold(
      body: _TvFocusBridge(
        currentIndex: index,
        child: Stack(
          children: [
            Positioned.fill(
              child: NotificationListener<ScrollUpdateNotification>(
                onNotification: (n) {
                  // Only the outer vertical scroll drives the bar; shelves scroll horizontally.
                  if (n.metrics.axis != Axis.vertical || n.depth != 0) return false;
                  final hide = n.metrics.pixels > 80 && !tabNodes.any((node) => node.hasFocus);
                  ref.read(_barVisibleProvider.notifier).set(!hide);
                  return false;
                },
                child: MediaQuery(
                  data: mq.copyWith(padding: mq.padding.copyWith(top: mq.padding.top + kTopBarHeight)),
                  child: FocusScope(
                    node: ref.watch(bodyScopeProvider),
                    child: FocusTraversalGroup(child: body),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AnimatedSlide(
                offset: visible ? Offset.zero : const Offset(0, -1),
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: AnimatedOpacity(
                  opacity: visible ? 1 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: FocusScope(
                    node: ref.watch(_barScopeProvider),
                    child: _TopTabBar(index: index, onSelected: go, nodes: tabNodes),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Centered pill tabs over a soft black gradient, like the Apple TV app header.
class _TopTabBar extends StatelessWidget {
  const _TopTabBar({required this.index, required this.onSelected, required this.nodes});
  final int index;
  final ValueChanged<int> onSelected;
  final List<FocusNode> nodes;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      height: kTopBarHeight + top,
      padding: EdgeInsets.only(top: top),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xE60A0A0A), Color(0x000A0A0A)],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: context.tokens.pageGutter,
            child: Row(
              children: [
                const Icon(Icons.play_circle_fill_rounded, size: 26, color: Colors.white),
                const SizedBox(width: 8),
                Text(l10n.appName, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ),
          TraceTag('tabs', child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (i, d) in _destinations.indexed)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: _TabItem(
                    icon: d.icon,
                    label: d.label(l10n),
                    iconOnly: d.route == Routes.search || d.route == Routes.settings,
                    selected: i == index,
                    focusNode: nodes[i],
                    onTap: () => onSelected(i),
                  ),
                ),
            ],
          )),
        ],
      ),
    );
  }
}

class _TabItem extends StatefulWidget {
  const _TabItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.focusNode,
    this.iconOnly = false,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final FocusNode focusNode;
  final bool iconOnly;

  @override
  State<_TabItem> createState() => _TabItemState();
}

class _TabItemState extends State<_TabItem> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocus);
  }

  void _onFocus() {
    if (_focused != widget.focusNode.hasFocus) setState(() => _focused = widget.focusNode.hasFocus);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocus);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final bg = _focused ? Colors.white : Colors.transparent;
    final fg = _focused
        ? Colors.black
        : widget.selected
            ? Colors.white
            : t.textMuted;
    final style = Theme.of(context).textTheme.labelLarge?.copyWith(color: fg, fontSize: 15);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        focusNode: widget.focusNode,
        onTap: widget.onTap,
        focusColor: Colors.transparent,
        hoverColor: Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: t.motion,
          curve: t.curve,
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
          padding: EdgeInsets.symmetric(horizontal: widget.iconOnly ? 12 : 18, vertical: 10),
          child: widget.iconOnly
              ? Icon(widget.icon, color: fg, size: 22)
              : Text(widget.label, style: style),
        ),
      ),
    );
  }
}
