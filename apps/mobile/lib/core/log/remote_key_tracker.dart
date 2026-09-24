import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'telemetry.dart';

/// Records every remote key press as a Sentry breadcrumb, with the focus before and after, and
/// reports the two D-pad failures users describe as "the remote stopped working":
/// - focus lost: after a key, nothing (or only a bare FocusScope) holds the primary focus;
/// - stuck: the same arrow pressed [_stuckThreshold] times in a row without focus moving.
///
/// Observes only: the handler always returns false, so key dispatch is unchanged.
abstract final class RemoteKeyTracker {
  /// Current location, kept up to date by `telemetryRouteProvider`.
  static String route = '/';

  /// Called once the remote has been idle for [_idleDelay] (layout audit of the settled screen).
  static VoidCallback? onIdle;

  static const _stuckThreshold = 4;
  static const _idleDelay = Duration(seconds: 2);

  static bool _installed = false;
  static LogicalKeyboardKey? _heldKey;
  static int _repeats = 0;
  static String? _stuckSignature;
  static int _stuckCount = 0;
  static Timer? _idle;

  static void install() {
    if (_installed) return;
    _installed = true;
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  static bool _onKey(KeyEvent event) {
    if (event is KeyRepeatEvent) {
      _repeats++;
      return false;
    }
    if (event is KeyUpEvent) {
      if (_repeats > 0 && event.logicalKey == _heldKey) {
        Telemetry.breadcrumb('dpad', '${_label(event.logicalKey)} held', data: {'repeats': _repeats, 'route': route, 'focus': describe(FocusManager.instance.primaryFocus)}, type: 'user');
      }
      _repeats = 0;
      return false;
    }
    _heldKey = event.logicalKey;
    _repeats = 0;
    final before = FocusManager.instance.primaryFocus;
    final beforeDescription = describe(before);
    final routeBefore = route;
    // Focus traversal runs synchronously in the handlers after this one; the next event-loop turn
    // sees its outcome (and any navigation it triggered).
    Timer.run(() => _afterKey(event.logicalKey, before, beforeDescription, routeBefore));
    _idle?.cancel();
    _idle = Timer(_idleDelay, () => onIdle?.call());
    return false;
  }

  static void _afterKey(LogicalKeyboardKey key, FocusNode? before, String beforeDescription, String routeBefore) {
    final after = FocusManager.instance.primaryFocus;
    final moved = after != before || route != routeBefore;
    final label = _label(key);
    final data = {
      'key': label,
      'key_id': '0x${key.keyId.toRadixString(16)}',
      'route': route,
      'from': beforeDescription,
      'to': describe(after),
      if (route != routeBefore) 'route_before': routeBefore,
    };
    Telemetry.breadcrumb('dpad', moved ? label : '$label (focus unchanged)', data: data, type: 'user');

    final focusLost = after == null || (after is FocusScopeNode && after.focusedChild == null);
    if (focusLost) {
      unawaited(Telemetry.capture('dpad', 'D-pad focus lost on $route', data: data, fingerprint: ['dpad-focus-lost', route]));
    }

    // The player remaps arrows (seek, zap, show controls) without moving focus: not "stuck" there.
    final isArrow = key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.arrowRight;
    if (!isArrow || moved || route.startsWith('/player')) {
      _stuckSignature = null;
      _stuckCount = 0;
      return;
    }
    final signature = '$route|$label|$beforeDescription';
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

  static String _label(LogicalKeyboardKey key) => key.keyLabel.isNotEmpty ? key.keyLabel : '0x${key.keyId.toRadixString(16)}';

  /// `Type#key@x,y wxh` for a focus node. Widget types are obfuscated in release builds, so the
  /// on-screen rectangle (and the route) is what actually locates the element.
  static String describe(FocusNode? node) {
    if (node == null) return 'none';
    final widget = node.context?.widget;
    final key = widget?.key;
    Rect? rect;
    try {
      rect = node.context == null ? null : node.rect;
    } catch (_) {
      // Not laid out yet (focus requested during a build).
    }
    final where = rect == null ? '' : '@${rect.left.round()},${rect.top.round()} ${rect.width.round()}x${rect.height.round()}';
    return '${node is FocusScopeNode ? 'scope:' : ''}${widget?.runtimeType ?? '?'}${key == null ? '' : '#$key'}$where';
  }
}
