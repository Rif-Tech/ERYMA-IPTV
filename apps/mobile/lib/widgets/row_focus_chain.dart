import 'dart:async';

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../core/log/remote_key_tracker.dart';
import '../core/log/telemetry.dart';
import '../core/log/trace_tag.dart';
import '../features/shell/app_shell.dart' show topLeftFocusable;

/// Space kept above/below a section scrolled into view, so its title and focus ring breathe.
const _revealMargin = 24.0;

/// Target of a [revealSection] animation still in flight for a given [ScrollPosition], so a burst
/// of calls at the same target (a loading row settling in below the focused one fires a
/// [ScrollMetricsNotification] on every frame of its own layout, see [RowFocusChain]) neither
/// re-logs nor restarts the ease-out curve on each one — which was visibly janky, and flooded
/// Sentry Logs on a slow page load (Sentry: many identical "reveal row N after the page changed"
/// lines a session).
final _revealing = Expando<double>('reveal-target');

/// Scrolls the page just enough for the whole section at [context] (title + cards) to be on
/// screen: never centred, never scrolled when already fully visible, so Left/Right inside a row
/// never moves the page and Down lands on a section shown in full. A section taller than the
/// screen is aligned on its top.
void revealSection(BuildContext context, {String reason = 'section'}) {
  final object = context.findRenderObject();
  final scrollable = Scrollable.maybeOf(context, axis: Axis.vertical);
  if (object == null || !object.attached || scrollable == null) return;
  final viewport = RenderAbstractViewport.maybeOf(object);
  if (viewport == null) return;
  final position = scrollable.position;
  if (!position.hasPixels || !position.hasContentDimensions) return;
  final target = _minimalOffset(viewport, object, position, _revealMargin);
  if (target == null) {
    _revealing[position] = null;
    return;
  }
  if (_revealing[position] == target) return;
  _revealing[position] = target;
  Telemetry.breadcrumb('scroll', 'reveal $reason: page ${position.pixels.round()} → ${target.round()}', data: {'route': RemoteKeyTracker.route});
  unawaited(position.animateTo(target, duration: const Duration(milliseconds: 220), curve: Curves.easeOutCubic).whenComplete(() {
    if (_revealing[position] == target) _revealing[position] = null;
  }));
}

/// Horizontal counterpart of [revealSection] for one card of a row: scrolls the row just enough
/// for the card at [context] to be fully visible, [margin] away from the row's edges (the page
/// gutter: the first card then rests where the row starts). [context] must be the card's own: a
/// ListView item builder receives the list's context, which reveals the whole list and throws the
/// row back to its start on every focus (Sentry FLUTTER-1Z/P: cards stuck off-screen).
///
/// Reveals in quick succession (a held key) jump instead of animating, so the row never lags
/// behind the focus and the next card is always laid out for the next key.
void revealInRow(BuildContext context, {double margin = 0}) {
  final object = context.findRenderObject();
  final scrollable = Scrollable.maybeOf(context, axis: Axis.horizontal);
  if (object == null || !object.attached || scrollable == null) return;
  final viewport = RenderAbstractViewport.maybeOf(object);
  if (viewport == null) return;
  final position = scrollable.position;
  if (!position.hasPixels || !position.hasContentDimensions) return;
  final target = _minimalOffset(viewport, object, position, margin);
  if (target == null) return;
  final now = DateTime.now();
  final last = _lastRowReveal[position];
  _lastRowReveal[position] = now;
  if (last != null && now.difference(last) < _rapidReveal) {
    position.jumpTo(target);
  } else {
    position.animateTo(target, duration: const Duration(milliseconds: 160), curve: Curves.easeOutCubic);
  }
}

final _lastRowReveal = Expando<DateTime>('row-reveal');
const _rapidReveal = Duration(milliseconds: 250);

/// Scroll offset that brings [object] fully inside the viewport (plus [margin]) with the least
/// movement, its start first when it is larger than the viewport; null when already visible.
double? _minimalOffset(RenderAbstractViewport viewport, RenderObject object, ScrollPosition position, double margin) {
  final alignStart = viewport.getOffsetToReveal(object, 0).offset - margin;
  final alignEnd = viewport.getOffsetToReveal(object, 1).offset + margin;
  var target = position.pixels;
  if (alignEnd > alignStart) {
    target = alignStart; // larger than the viewport: show its start
  } else if (position.pixels > alignStart) {
    target = alignStart; // start cut off: scroll back just enough
  } else if (position.pixels < alignEnd) {
    target = alignEnd; // end cut off: scroll forward just enough
  }
  target = target.clamp(position.minScrollExtent, position.maxScrollExtent);
  return (target - position.pixels).abs() < 1 ? null : target;
}

/// Where focus lands when entering [row]: the card it last held, else its top-left one, else the
/// row itself when it is a plain node (a button, a text field). Null when the row has nothing to
/// focus (an empty conditional shelf, content still loading): the chain skips it.
FocusNode? rowEntryOf(FocusNode row) {
  if (row is FocusScopeNode) {
    final remembered = row.focusedChild;
    if (remembered != null && remembered.canRequestFocus && row.traversalDescendants.contains(remembered)) return remembered;
    return topLeftFocusable(row);
  }
  return row.canRequestFocus && row.context != null ? row : null;
}

/// Vertical D-pad navigation between stacked rows (home sections, search results), as an explicit
/// chain rather than Flutter's geometric traversal, which across rows of very different heights
/// skipped rows or got stuck. Down/Up go to the next/previous row that has something to focus;
/// the first row brings the page back to its top. Up from the first row is left unhandled, so the
/// shell's bridge takes it to the tab bar. Left/Right are swallowed on [isolated] rows (a lone
/// button must not wander into a neighbouring row). Key repeats are handled like presses, so
/// holding a key walks the whole chain.
class RowFocusChain extends StatelessWidget {
  const RowFocusChain({super.key, required this.name, required this.rows, this.isolated = const {}, required this.child});

  /// Shown in the D-pad trace (`home-chain`, `search-chain`).
  final String name;
  final List<FocusNode> rows;
  final Set<FocusNode> isolated;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Rows still loading change the page's height after the focus has been revealed (at start-up
    // "Continue watching" arrives above the focused row and pushed it under the screen, Sentry
    // FLUTTER-S): show the focused row again whenever the page's extent changes.
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (n) {
        if (n.metrics.axis == Axis.vertical && n.depth == 0) _keepFocusedRowVisible(rows);
        return false;
      },
      child: _keys(child),
    );
  }

  static void _keepFocusedRowVisible(List<FocusNode> rows) {
    // Only for D-pad/keyboard navigation: a layout shift (an image loading in) during a touch
    // drag must not snap the page back to the focused row and fight the user's own scroll.
    if (FocusManager.instance.highlightMode != FocusHighlightMode.traditional) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final current = FocusManager.instance.primaryFocus;
      if (current == null) return;
      final i = rows.indexWhere((r) => r == current || current.ancestors.contains(r));
      final rowContext = i < 0 ? null : rows[i].context;
      if (rowContext != null && rowContext.mounted) revealSection(rowContext, reason: 'row $i after the page changed');
    });
  }

  Widget _keys(Widget child) {
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: (_, event) {
        if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
        final key = event.logicalKey;
        final current = FocusManager.instance.primaryFocus;
        if (current == null) return KeyEventResult.ignored;
        final i = rows.indexWhere((r) => r == current || current.ancestors.contains(r));
        if (i < 0) return KeyEventResult.ignored;
        if ((key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.arrowRight) && isolated.contains(rows[i])) {
          RemoteKeyTracker.note('$name: left/right blocked on row $i');
          return KeyEventResult.handled;
        }
        final down = key == LogicalKeyboardKey.arrowDown;
        if (!down && key != LogicalKeyboardKey.arrowUp) return KeyEventResult.ignored;
        for (var j = down ? i + 1 : i - 1; j >= 0 && j < rows.length; j += down ? 1 : -1) {
          final target = rowEntryOf(rows[j]);
          if (target == null) continue;
          RemoteKeyTracker.note('$name: ${down ? 'down' : 'up'} row $i → row $j (${TraceTag.pathOf(target)})');
          target.requestFocus();
          _reveal(rows, j, target);
          return KeyEventResult.handled;
        }
        RemoteKeyTracker.note(down ? '$name: down on last row, stays' : '$name: up from first row → tab bar');
        return down ? KeyEventResult.handled : KeyEventResult.ignored;
      },
      child: child,
    );
  }

  static void _reveal(List<FocusNode> rows, int j, FocusNode target) {
    // After this frame's layout, so a row that just became visible has its final geometry.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final firstNonEmpty = rows.indexWhere((r) => rowEntryOf(r) != null);
      final ctx = target.context;
      if (ctx == null || !ctx.mounted) return;
      if (j == firstNonEmpty) {
        final position = Scrollable.maybeOf(ctx, axis: Axis.vertical)?.position;
        if (position != null && position.hasPixels && position.pixels > position.minScrollExtent) {
          Telemetry.breadcrumb('scroll', 'reveal first row: page ${position.pixels.round()} → top', data: {'route': RemoteKeyTracker.route});
          position.animateTo(position.minScrollExtent, duration: const Duration(milliseconds: 220), curve: Curves.easeOutCubic);
        }
        return;
      }
      final rowContext = rows[j].context;
      if (rowContext != null && rowContext.mounted) revealSection(rowContext, reason: 'row $j');
    });
  }
}
