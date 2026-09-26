import 'dart:async';

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'telemetry.dart';
import 'trace_tag.dart';

/// Traces every remote key press to Sentry (breadcrumb + a structured Sentry Log per key):
/// focused element before/after as a readable path (`home/new-movies/h#3`, see [TraceTag]), its
/// position once scrolling has settled, the scroll offsets, and which custom handler acted on the
/// key ([note]). Reports, as events:
/// - focus lost: once the screen has settled after a key, nothing (or only a bare FocusScope)
///   holds the primary focus, or the key found the focus already lost (something dropped it);
/// - stuck: the same arrow pressed [_stuckThreshold] times in a row without focus moving, no
///   handler acting on it ([note]) and the list not already at its end in that direction;
/// - off-screen: the focused element is still outside the screen once scrolling has settled and
///   the remote is idle (a check overtaken by the next key or a held key is dropped: the focus
///   is then legitimately mid-way, and the last key of the burst gets its own check);
/// - row change: Left/Right moved focus out of the horizontal list it was in (see [leftRow]).
///
/// Observes only: the handler always returns false, so key dispatch is unchanged.
abstract final class RemoteKeyTracker {
  /// Current location, kept up to date by `telemetryRouteProvider`.
  static String route = '/';

  /// Called once the remote has been idle for [_idleDelay] (layout audit of the settled screen).
  static VoidCallback? onIdle;

  static const _stuckThreshold = 4;
  static const _idleDelay = Duration(seconds: 2);
  // Covers the 220-250 ms scroll animations used across the app (ensureVisible, shelf scroll).
  static const _settleDelay = Duration(milliseconds: 450);
  // The focus zoom (x1.08) legitimately pushes a card a few pixels past the screen edge.
  static const _offscreenTolerance = 12.0;

  // A settle check waits at most this many extra rounds for a scroll still animating.
  static const _maxSettleRetries = 3;
  static const _settleRetryDelay = Duration(milliseconds: 200);

  static bool _installed = false;
  static LogicalKeyboardKey? _heldKey;
  static int _repeats = 0;
  static String? _stuckSignature;
  static int _stuckCount = 0;
  static Timer? _idle;
  static int _seq = 0;
  // Bumped by every key event (repeats included): a settle check from an older generation is
  // stale, the focus has moved on since.
  static int _generation = 0;
  static final _notes = <String>[];

  static void install() {
    if (_installed) return;
    _installed = true;
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  /// Called by custom key handlers (home chain, tab bridge, hero, player…) so the trace says which
  /// code acted on the current key and what it decided, e.g. `home-chain: down → new-movies`.
  static void note(String what) {
    if (_notes.length < 8) _notes.add(what);
  }

  static bool _onKey(KeyEvent event) {
    if (event is KeyRepeatEvent) {
      _repeats++;
      _generation++;
      return false;
    }
    if (event is KeyUpEvent) {
      if (_repeats > 0 && event.logicalKey == _heldKey) {
        final label = _label(event.logicalKey);
        final data = <String, Object?>{'repeats': _repeats, 'route': route, 'focus': describe(FocusManager.instance.primaryFocus)};
        Telemetry.breadcrumb('dpad', '$label held', data: data, type: 'user');
        Telemetry.trace('dpad', '$label held', data);
        // Where a held key finally left the focus gets the settle check its repeats skipped.
        final generation = ++_generation;
        final node = FocusManager.instance.primaryFocus;
        Timer(_settleDelay, () => _settled(generation, '$label held', node, {...data, 'key': label, 'seq': _seq}));
      }
      _repeats = 0;
      return false;
    }
    _heldKey = event.logicalKey;
    _repeats = 0;
    // Handlers after this one (focus dispatch) run synchronously: collect their notes from here.
    _notes.clear();
    final before = FocusManager.instance.primaryFocus;
    final snapshot = _Snapshot.of(before);
    final routeBefore = route;
    final seq = ++_seq;
    final generation = ++_generation;
    Timer.run(() => _afterKey(seq, generation, event.logicalKey, before, snapshot, routeBefore, List.of(_notes)));
    _idle?.cancel();
    _idle = Timer(_idleDelay, () => onIdle?.call());
    return false;
  }

  /// Nothing usable holds the focus: no node at all, or a scope with no focused child (content
  /// emptied or rebuilt under the cursor, a text field dropped by the keyboard).
  static bool isLost(FocusNode? node) => node == null || (node is FocusScopeNode && node.focusedChild == null);

  static void _afterKey(int seq, int generation, LogicalKeyboardKey key, FocusNode? before, _Snapshot from, String routeBefore, List<String> notes) {
    final after = FocusManager.instance.primaryFocus;
    final moved = after != before || route != routeBefore;
    final label = _label(key);
    final to = _Snapshot.of(after);
    final data = <String, Object?>{
      'seq': seq,
      'key': label,
      'key_id': '0x${key.keyId.toRadixString(16)}',
      'route': route,
      if (route != routeBefore) 'route_before': routeBefore,
      'from': from.path,
      'to': to.path,
      'from_rect': from.rect,
      'to_rect': to.rect,
      if (notes.isNotEmpty) 'handled_by': notes.join(' | '),
    };
    Telemetry.breadcrumb('dpad', moved ? '$label: ${from.path} → ${to.path}' : '$label: ${from.path} (focus unchanged)', data: data, type: 'user');

    // The focus was already gone when the key came: whatever dropped it is the bug, even when a
    // handler recovered it on this key. Only on real screens (not before the first focus).
    if (before != null && isLost(before) && seq > 1) {
      unawaited(Telemetry.capture('dpad', 'D-pad focus lost on $route', data: {...data, 'lost_before_key': true}, fingerprint: ['dpad-focus-lost', route]));
    }

    final horizontal = key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.arrowRight;
    final isArrow = horizontal || key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.arrowDown;
    if (horizontal && moved && after != null && !route.startsWith('/player') && leftRow(from.path, to.path)) {
      unawaited(Telemetry.capture(
        'dpad',
        '$label left its row on ${Telemetry.routeTemplate(route)}',
        data: data,
        fingerprint: ['dpad-row-change', Telemetry.routeTemplate(route), label, '${from.row}', '${to.row}'],
        throttle: const Duration(minutes: 30),
      ));
    }

    // Settled position: where the element really ended up once scroll animations are done.
    Timer(_settleDelay, () => _settled(generation, label, after, data));

    // The player remaps arrows (seek, zap, show controls) without moving focus: not "stuck" there.
    // Neither is a key a handler acted on (the hero switching slides) nor one pressed against the
    // end of a list (the last card of a shelf, the top of a page).
    if (!isArrow || moved || route.startsWith('/player') || notes.isNotEmpty || from.atEdge(key)) {
      _stuckSignature = null;
      _stuckCount = 0;
      return;
    }
    final signature = '$route|$label|${from.path}';
    _stuckCount = signature == _stuckSignature ? _stuckCount + 1 : 1;
    _stuckSignature = signature;
    if (_stuckCount == _stuckThreshold) {
      unawaited(Telemetry.capture(
        'dpad',
        'D-pad stuck: $label does nothing on $route',
        level: SentryLevel.warning,
        data: {...data, 'presses': _stuckCount},
        fingerprint: ['dpad-stuck', route, label],
        throttle: const Duration(minutes: 30),
      ));
    }
  }

  static void _settled(int generation, String label, FocusNode? node, Map<String, Object?> data, [int retries = 0]) {
    // Another key came since: the focus is mid-way through a burst, which gets its own check.
    if (generation != _generation) return;
    final current = FocusManager.instance.primaryFocus;
    if (retries < _maxSettleRetries && _scrolling(current)) {
      Timer(_settleRetryDelay, () => _settled(generation, label, node, data, retries + 1));
      return;
    }
    final settled = _Snapshot.of(current);
    final full = {
      ...data,
      'settled_on': settled.path,
      'settled_rect': settled.rect,
      if (current != node) 'focus_changed_after_key': true,
      if (settled.scrollV != null) 'scroll_v': settled.scrollV,
      if (settled.scrollH != null) 'scroll_h': settled.scrollH,
      if (settled.offscreen != null) 'offscreen': settled.offscreen,
    };
    Telemetry.trace('dpad', '$label → ${settled.path}', full);
    if (isLost(current) && !route.startsWith('/player')) {
      unawaited(Telemetry.capture('dpad', 'D-pad focus lost on $route', data: full, fingerprint: ['dpad-focus-lost', route]));
      return;
    }
    if (settled.offscreen != null && !route.startsWith('/player')) {
      unawaited(Telemetry.capture(
        'dpad',
        'Focused element off-screen on ${Telemetry.routeTemplate(route)} (${settled.offscreen})',
        data: full,
        fingerprint: ['dpad-offscreen', Telemetry.routeTemplate(route), '${settled.row}', '${settled.offscreen}'],
        throttle: const Duration(minutes: 10),
      ));
    }
  }

  /// Whether a list holding [node] is still scrolling (a reveal animation not finished yet).
  static bool _scrolling(FocusNode? node) {
    var context = node?.context;
    while (context != null && context.mounted) {
      final scrollable = Scrollable.maybeOf(context);
      if (scrollable == null) return false;
      if (scrollable.position.isScrollingNotifier.value) return true;
      context = scrollable.context;
    }
    return false;
  }

  /// Whether a Left/Right from [from] to [to] left the horizontal list the focus was in (a shelf
  /// row, `…/h#3`). Moving between side-by-side panes (categories rail ↔ content grid) or out of
  /// a button group is the intended layout, not a bug.
  @visibleForTesting
  static bool leftRow(String from, String to) {
    final cut = from.lastIndexOf('/');
    if (cut <= 0 || !from.startsWith('h#', cut + 1)) return false;
    final toCut = to.lastIndexOf('/');
    return toCut <= 0 || to.substring(0, toCut) != from.substring(0, cut);
  }

  static String _label(LogicalKeyboardKey key) => key.keyLabel.isNotEmpty ? key.keyLabel : '0x${key.keyId.toRadixString(16)}';

  /// Readable path of [node] (see [TraceTag.pathOf]) with its on-screen rectangle.
  static String describe(FocusNode? node) {
    final s = _Snapshot.of(node);
    return '${s.path}@${s.rect}';
  }
}

/// What the trace knows about one focused node at one instant.
class _Snapshot {
  _Snapshot({required this.path, this.rect, this.row, this.scrollV, this.scrollH, this.offscreen, this.edges = const {}});

  final String path;
  final String? rect;

  /// [path] without its last segment: identifies the row (list, button group) of the node.
  final String? row;
  final int? scrollV;
  final int? scrollH;

  /// `left`/`right`/`top`/`bottom` when the node lies (partly) outside the screen.
  final String? offscreen;

  /// Arrows that would push the enclosing lists past their ends (`up` at the top of a page,
  /// `right` at the end of a shelf).
  final Set<LogicalKeyboardKey> edges;

  bool atEdge(LogicalKeyboardKey key) => edges.contains(key);

  static _Snapshot of(FocusNode? node) {
    if (node == null) return _Snapshot(path: 'none');
    final context = node.context;
    final traced = TraceTag.pathOf(node);
    final fallback = '${node is FocusScopeNode ? 'scope' : 'node'}:${context?.widget.runtimeType ?? '?'}';
    final path = traced ?? fallback;
    // `home/new-movies/h#3` → `home/new-movies`, `home/hero/play` → `home/hero`.
    final cut = traced?.lastIndexOf('/') ?? -1;
    final row = cut > 0 ? traced!.substring(0, cut) : null;
    Rect? rect;
    try {
      rect = context == null ? null : node.rect;
    } catch (_) {
      // Not laid out yet (focus requested during a build).
    }
    int? scrollV;
    int? scrollH;
    final edges = <LogicalKeyboardKey>{};
    if (context != null && context.mounted) {
      final v = Scrollable.maybeOf(context, axis: Axis.vertical)?.position;
      final h = Scrollable.maybeOf(context, axis: Axis.horizontal)?.position;
      scrollV = v?.pixels.round();
      scrollH = h?.pixels.round();
      void edge(ScrollPosition? p, LogicalKeyboardKey back, LogicalKeyboardKey forward) {
        if (p == null || !p.hasPixels || !p.hasContentDimensions) return;
        if (p.pixels <= p.minScrollExtent + 1) edges.add(back);
        if (p.pixels >= p.maxScrollExtent - 1) edges.add(forward);
      }

      edge(v, LogicalKeyboardKey.arrowUp, LogicalKeyboardKey.arrowDown);
      edge(h, LogicalKeyboardKey.arrowLeft, LogicalKeyboardKey.arrowRight);
    }
    String? offscreen;
    final views = RendererBinding.instance.renderViews;
    if (rect != null && views.isNotEmpty) {
      final screen = views.first.size;
      const t = RemoteKeyTracker._offscreenTolerance;
      offscreen = rect.left < -t
          ? 'left'
          : rect.right > screen.width + t
              ? 'right'
              : rect.top < -t
                  ? 'top'
                  : rect.bottom > screen.height + t
                      ? 'bottom'
                      : null;
    }
    return _Snapshot(
      path: path,
      rect: rect == null ? null : '${rect.left.round()},${rect.top.round()} ${rect.width.round()}x${rect.height.round()}',
      row: row,
      scrollV: scrollV,
      scrollH: scrollH,
      offscreen: offscreen,
      edges: edges,
    );
  }
}
