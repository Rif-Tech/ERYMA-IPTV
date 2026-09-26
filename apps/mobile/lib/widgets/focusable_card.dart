import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/responsive.dart';
import '../app/theme.dart';
import '../core/log/remote_key_tracker.dart';

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

/// How long OK must be held for [FocusableCard.onLongPress] to fire, mirroring a touch long-press.
const okHoldDuration = Duration(milliseconds: 550);

final _selectKeys = {LogicalKeyboardKey.select, LogicalKeyboardKey.enter, LogicalKeyboardKey.gameButtonA};

class _FocusableCardState extends ConsumerState<FocusableCard> {
  bool _focused = false;
  Timer? _holdTimer;
  bool _longPressFired = false;

  @override
  void dispose() {
    _holdTimer?.cancel();
    super.dispose();
  }

  /// `InkWell.onLongPress` only ever fires from a touch gesture: a remote has no equivalent, so a
  /// held OK stands in for it here (Sentry: no D-pad way to favourite a live channel — the only
  /// entry point was this widget's `onLongPress`, a touch-only callback). Swallowing repeats along
  /// the way also stops a held OK from repeatedly firing `onTap` (`SingleActivator` fires on every
  /// repeat by default), which the exploration for the player's duplicated controls pointed at too.
  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (widget.onLongPress == null || !_selectKeys.contains(event.logicalKey)) return KeyEventResult.ignored;
    if (event is KeyDownEvent) {
      _longPressFired = false;
      _holdTimer?.cancel();
      _holdTimer = Timer(okHoldDuration, () {
        _longPressFired = true;
        RemoteKeyTracker.note('card: OK held → long press');
        widget.onLongPress?.call();
      });
      return KeyEventResult.handled;
    }
    if (event is KeyRepeatEvent) return KeyEventResult.handled;
    if (event is KeyUpEvent) {
      _holdTimer?.cancel();
      if (!_longPressFired) widget.onTap?.call();
      _longPressFired = false;
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

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
    return Focus(
      // Transparent to focus/traversal: only adds the OK-hold handling above the real focus node
      // InkWell owns, the same way RowFocusChain wraps a subtree without becoming a stop itself.
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: _onKeyEvent,
      child: AnimatedScale(
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
      ),
    );
  }
}
