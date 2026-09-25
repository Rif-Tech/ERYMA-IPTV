import 'package:flutter/material.dart';

import '../app/theme.dart';

/// Translucent rounded panel ("glass") used for panes and overlays; no blur, gradient-friendly.
class GlassPanel extends StatelessWidget {
  const GlassPanel({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.radius = 16, this.strong = false});
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: padding,
      decoration: BoxDecoration(color: strong ? t.glassStrong : t.glass, borderRadius: BorderRadius.circular(radius)),
      child: child,
    );
  }
}
