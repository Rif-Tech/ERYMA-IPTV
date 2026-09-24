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
/// - focus lost: after a key, nothing (or only a bare FocusScope) holds the primary focus;
/// - stuck: the same arrow pressed [_stuckThreshold] times in a row without focus moving;
/// - off-screen: the focused element is still outside the screen once scrolling has settled;
/// - row change: Left/Right moved focus out of the list it was in.
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

  static bool _installed = false;
  static LogicalKeyboardKey? _heldKey;
  static int _repeats = 0;
  static String? _stuckSignature;
  static int _stuckCount = 0;
  static Timer? _idle;
  static int _seq = 0;
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
      return false;
    }
    if (event is KeyUpEvent) {
      if (_repeats > 0 && event.logicalKey == _heldKey) {
        final data = {'repeats': _repeats, 'route': route, 'focus': describe(FocusManager.instance.primaryFocus)};
        Telemetry.breadcrumb('dpad', '${_label(event.logicalKey)} held', data: data, type: 'user');
        Telemetry.trace('dpad', '${_label(event.logicalKey)} held', data);
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
    Timer.run(() => _afterKey(seq, event.logicalKey, before, snapshot, routeBefore, List.of(_notes)));
    _idle?.cancel();
    _idle = Timer(_idleDelay, () => onIdle?.call());
    return false;
  }

  static void _afterKey(int seq, LogicalKeyboardKey key, FocusNode? before, _Snapshot from, String routeBefore, List<String> notes) {
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

    final focusLost = after == null || (after is FocusScopeNode && after.focusedChild == null);
    if (focusLost) {
      unawaited(Telemetry.capture('dpad', 'D-pad focus lost on $route', data: data, fingerprint: ['dpad-focus-lost', route]));
    }

    final horizontal = key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.arrowRight;
    final isArrow = horizontal || key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.arrowDown;
    if (horizontal && moved && after != null && !route.startsWith('/player') && from.row != null && to.row != null && from.row != to.row) {
      unawaited(Telemetry.capture(
        'dpad',
        '$label left its row on ${Telemetry.routeTemplate(route)}',
        data: data,
        fingerprint: ['dpad-row-change', Telemetry.routeTemplate(route), label, '${from.row}', '${to.row}'],
        throttle: const Duration(minutes: 30),
      ));
    }

    // Settled position: where the element really ended up once scroll animations are done.
    Timer(_settleDelay, () => _settled(seq, label, after, data));

    // The player remaps arrows (seek, zap, show controls) without moving focus: not "stuck" there.
    if (!isArrow || moved || route.startsWith('/player')) {
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

  static void _settled(int seq, String label, FocusNode? node, Map<String, Object?> data) {
    final current = FocusManager.instance.primaryFocus;
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

  static String _label(LogicalKeyboardKey key) => key.keyLabel.isNotEmpty ? key.keyLabel : '0x${key.keyId.toRadixString(16)}';

  /// Readable path of [node] (see [TraceTag.pathOf]) with its on-screen rectangle.
  static String describe(FocusNode? node) {
    final s = _Snapshot.of(node);
    return '${s.path}@${s.rect}';
  }
}

/// What the trace knows about one focused node at one instant.
class _Snapshot {
  _Snapshot({required this.path, this.rect, this.row, this.scrollV, this.scrollH, this.offscreen});

  final String path;
  final String? rect;

  /// [path] without its last segment: identifies the row (list, button group) of the node.
  final String? row;
  final int? scrollV;
  final int? scrollH;

  /// `left`/`right`/`top`/`bottom` when the node lies (partly) outside the screen.
  final String? offscreen;

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
    if (context != null && context.mounted) {
      scrollV = Scrollable.maybeOf(context, axis: Axis.vertical)?.position.pixels.round();
      scrollH = Scrollable.maybeOf(context, axis: Axis.horizontal)?.position.pixels.round();
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
    );
  }
}
