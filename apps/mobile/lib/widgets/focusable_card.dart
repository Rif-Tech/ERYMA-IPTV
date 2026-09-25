import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/responsive.dart';
import '../app/theme.dart';

/// Focus-aware card: scales up and shows a white ring when focused (D-pad) or hovered.
class FocusableCard extends ConsumerStatefulWidget {
  const FocusableCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.autofocus = false,
    this.borderRadius = 12,
    this.scale,
    this.focusNode,
    this.selected = false,
    this.onFocus,
    this.ring = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool autofocus;
  final double borderRadius;

  /// Focus scale; defaults to the theme token (1.08 on TV, 1.0 on touch).
  final double? scale;
  final FocusNode? focusNode;
  final bool selected;

  /// Called when the card gains focus (D-pad); lets lists react without pressing OK.
  final VoidCallback? onFocus;

  /// Draw the white focus ring; disable for widgets that render their own focus state.
  final bool ring;

  @override
  ConsumerState<FocusableCard> createState() => _FocusableCardState();
}

class _FocusableCardState extends ConsumerState<FocusableCard> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final lite = ref.watch(performanceModeProvider);
    final radius = BorderRadius.circular(widget.borderRadius);
    final ringColor = _focused && widget.ring
        ? Colors.white
        : widget.selected
            ? const Color(0x66FFFFFF)
            : Colors.transparent;
    // Blurred shadows are rasterised per frame while the scale animates: keep them tight on weak GPUs.
    final shadow = _focused
        ? [BoxShadow(color: const Color(0x99000000), blurRadius: lite ? 6 : 24, offset: Offset(0, lite ? 3 : 10))]
        : null;
    return AnimatedScale(
      scale: _focused ? (widget.scale ?? t.focusScale) : 1,
      duration: t.motion,
      curve: t.curve,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          onFocusChange: (f) {
            setState(() => _focused = f);
            if (f) widget.onFocus?.call();
          },
          focusColor: Colors.transparent,
          borderRadius: radius,
          child: AnimatedContainer(
            duration: t.motion,
            curve: t.curve,
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: ringColor, width: 2.5, strokeAlign: BorderSide.strokeAlignOutside),
              boxShadow: shadow,
            ),
            child: ClipRRect(borderRadius: radius, child: RepaintBoundary(child: widget.child)),
          ),
        ),
      ),
    );
  }
}
