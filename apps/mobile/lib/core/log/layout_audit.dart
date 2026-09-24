import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'remote_key_tracker.dart';
import 'telemetry.dart';

/// Finds clipped layouts on the settled screen and reports them to Sentry. Release builds strip
/// Flutter's "RenderFlex overflowed" check (it is an assert), so without this a description cut
/// off at the bottom, or an episode row pushed off-screen, is invisible outside a debug run.
///
/// Detected, on what is actually on screen (offstage tabs/routes are skipped):
/// - `flex_overflow`: a Row/Column whose children exceed its size (the release-mode yellow stripes);
/// - `text_truncated`: multi-line text cut by `maxLines` (single-line ellipsised titles are by design);
/// - `offscreen_clip`: text or an image extending past the screen edge on an axis that does not scroll.
///
/// Only sizes, positions and text lengths are reported, never the text itself.
abstract final class LayoutAudit {
  static const _settleDelay = Duration(milliseconds: 1500);
  static const _minInterval = Duration(seconds: 5);
  static const _maxNodes = 30000;

  static Timer? _timer;
  static DateTime? _lastRun;
  static final _reported = <String>{};

  /// Audits the screen once it has had time to load (images, async lists) and settle.
  static void schedule() {
    if (!Telemetry.enabled) return;
    _timer?.cancel();
    _timer = Timer(_settleDelay, run);
  }

  static void run() {
    final now = DateTime.now();
    if (_lastRun != null && now.difference(_lastRun!) < _minInterval) return;
    _lastRun = now;
    final views = RendererBinding.instance.renderViews;
    if (views.isEmpty) return;
    final view = views.first;
    final screen = view.size;
    final findings = <Map<String, Object?>>[];
    var visited = 0;

    void visit(RenderObject node, bool vScroll, bool hScroll) {
      if (++visited > _maxNodes) return;
      var v = vScroll;
      var h = hScroll;
      if (node is RenderViewportBase) {
        if (node.axis == Axis.vertical) {
          v = true;
        } else {
          h = true;
        }
      }
      if (node is RenderBox && node.hasSize) {
        try {
          if (node is RenderFlex) _checkFlex(node, findings);
          if (node is RenderParagraph) _checkParagraph(node, findings);
          if (node is RenderParagraph || node is RenderImage) _checkEdges(node, screen, v, h, findings);
        } catch (_) {
          // A node detached mid-walk (async list update): skip it, never break the app for a probe.
        }
      }
      // The semantics walk skips what is not on screen: offstage tabs, covered routes, Offstage.
      node.visitChildrenForSemantics((child) => visit(child, v, h));
    }

    visit(view, false, false);
    if (findings.isEmpty) return;

    final route = Telemetry.routeTemplate(RemoteKeyTracker.route);
    final fresh = findings.where((f) => _reported.add('$route|${f['kind']}|${f['rect']}')).toList();
    if (fresh.isEmpty) return;
    final kinds = {for (final f in fresh) f['kind'] as String}.toList()..sort();
    Telemetry.breadcrumb('layout', 'layout issues on $route: ${kinds.join(', ')}', data: {'count': fresh.length}, level: SentryLevel.warning);
    unawaited(Telemetry.capture(
      'layout',
      'Layout clipped on $route (${kinds.join(', ')})',
      data: {
        'route': RemoteKeyTracker.route,
        'screen': '${screen.width.round()}x${screen.height.round()}',
        'count': fresh.length,
        'findings': fresh.take(20).toList(),
        'focus': RemoteKeyTracker.describe(FocusManager.instance.primaryFocus),
      },
      fingerprint: ['layout', route, ...kinds],
      throttle: const Duration(hours: 1),
    ));
  }

  static String _rect(RenderBox box) {
    final r = MatrixUtils.transformRect(box.getTransformTo(null), Offset.zero & box.size);
    return '${r.left.round()},${r.top.round()} ${r.width.round()}x${r.height.round()}';
  }

  static void _checkFlex(RenderFlex flex, List<Map<String, Object?>> out) {
    final vertical = flex.direction == Axis.vertical;
    var total = 0.0;
    var count = 0;
    flex.visitChildren((child) {
      if (child is RenderBox && child.hasSize) {
        total += vertical ? child.size.height : child.size.width;
        count++;
      }
    });
    total += flex.spacing * math.max(0, count - 1);
    final available = vertical ? flex.size.height : flex.size.width;
    final overflow = total - available;
    if (overflow > 1) {
      out.add({'kind': 'flex_overflow', 'axis': vertical ? 'vertical' : 'horizontal', 'overflow_px': overflow.round(), 'rect': _rect(flex)});
    }
  }

  static void _checkParagraph(RenderParagraph p, List<Map<String, Object?>> out) {
    final maxLines = p.maxLines;
    if (maxLines == null || maxLines < 2 || !p.didExceedMaxLines) return;
    out.add({
      'kind': 'text_truncated',
      'max_lines': maxLines,
      'text_length': p.text.toPlainText(includeSemanticsLabels: false).length,
      'font_size': p.text.style?.fontSize,
      'rect': _rect(p),
    });
  }

  static void _checkEdges(RenderBox box, Size screen, bool vScroll, bool hScroll, List<Map<String, Object?>> out) {
    final r = MatrixUtils.transformRect(box.getTransformTo(null), Offset.zero & box.size);
    final bottom = !vScroll && r.bottom > screen.height + 1 && r.top < screen.height;
    final right = !hScroll && r.right > screen.width + 1 && r.left < screen.width;
    if (!bottom && !right) return;
    out.add({
      'kind': 'offscreen_clip',
      'element': box is RenderImage ? 'image' : 'text',
      if (bottom) 'bottom_overflow_px': (r.bottom - screen.height).round(),
      if (right) 'right_overflow_px': (r.right - screen.width).round(),
      'rect': _rect(box),
    });
  }
}
