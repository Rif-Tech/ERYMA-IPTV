import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Names a region of the UI (a home row, a pane) for the D-pad trace. Widget types and
/// FocusNode.debugLabel are obfuscated or stripped in release builds, so without this Sentry only
/// sees screen coordinates. Costs nothing at runtime: build returns [child] unchanged.
class TraceTag extends StatelessWidget {
  const TraceTag(this.label, {super.key, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => child;

  static final _nodeNames = Expando<String>('traceName');

  /// Names a specific focus node (a button, a tab), for nodes without a surrounding widget to tag.
  static FocusNode name(FocusNode node, String label) {
    _nodeNames[node] = label;
    return node;
  }

  /// `home/new-movies/h#3` for [node]: tagged regions (outermost first), then the index of the
  /// item inside every lazy list or grid around it (`h` horizontal, `v` vertical), then the
  /// node's own name if it has one.
  static String? pathOf(FocusNode? node) {
    final context = node?.context;
    if (node == null || context == null) return null;
    final parts = <String>[];
    // List/grid indices, read from the render tree: works for every ListView/GridView unchanged.
    try {
      final indices = <String>[];
      RenderObject? r = context.findRenderObject();
      while (r != null) {
        final data = r.parentData;
        final parent = r.parent;
        if (data is SliverMultiBoxAdaptorParentData && data.index != null && parent is RenderSliver) {
          indices.add('${parent.constraints.axis == Axis.horizontal ? 'h' : 'v'}#${data.index}');
        }
        r = parent;
      }
      parts.addAll(indices);
    } catch (_) {
      // Detached mid-layout: the tagged path below is still useful.
    }
    final tags = <String>[];
    if (context.widget is TraceTag) tags.add((context.widget as TraceTag).label);
    context.visitAncestorElements((e) {
      final w = e.widget;
      if (w is TraceTag) tags.add(w.label);
      return true;
    });
    final own = _nodeNames[node];
    final path = [...tags.reversed, ...parts.reversed, ?own];
    return path.isEmpty ? null : path.join('/');
  }
}
