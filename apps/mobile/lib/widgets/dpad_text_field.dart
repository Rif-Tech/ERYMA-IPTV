import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/log/remote_key_tracker.dart';

/// A text field usable end to end with a remote: OK opens the keyboard (a `TextField` otherwise
/// only opens it from a touch/mouse tap, so a focused field with no keyboard shown did nothing on
/// OK); Down moves to [DpadTextField.keyHandler]'s `onDown` target instead of the field swallowing
/// it as a cursor move; and when the keyboard closes — Back, or the IME's own "done" — the field
/// keeps the focus (Android drops it onto the page's bare scope otherwise, leaving nothing
/// highlighted and stranding the remote there; the first search field had exactly this trio of
/// bugs, Sentry FLUTTER-1W). Up is left unhandled so it bubbles to whatever the page does with it
/// (usually the tab bar).
///
/// The field's own [focusNode] must be built with [DpadTextField.keyHandler] (a plain `FocusNode`
/// constructor argument, same as every other named node in this app — the widget only adds the
/// "keep focus" behaviour, not the key handling, so callers keep control of naming/tracing it).
class DpadTextField extends StatefulWidget {
  const DpadTextField({
    super.key,
    required this.focusNode,
    this.controller,
    this.autofocus = false,
    this.decoration,
    this.style,
    this.textInputAction = TextInputAction.done,
    this.onChanged,
    this.onSubmitted,
  });

  final FocusNode focusNode;

  /// Optional, matching `TextField`'s own default: without one, `TextField` manages its own text
  /// state internally, which a caller that only needs [onChanged] (a live filter, say) should
  /// prefer — a *new* controller built on every rebuild (a `setState` in the parent, one per
  /// keystroke) would otherwise fight the field for its cursor position on every character typed.
  final TextEditingController? controller;
  final bool autofocus;
  final InputDecoration? decoration;
  final TextStyle? style;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// [FocusNode.onKeyEvent] for a [DpadTextField]'s own [focusNode]: Down calls [onDown] (return
  /// true once it moved focus, so the key is consumed instead of also moving the text cursor), and
  /// OK reopens the keyboard when the field has focus but no keyboard is showing.
  static FocusOnKeyEventCallback keyHandler({bool Function()? onDown}) {
    return (node, event) {
      if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
      if (event.logicalKey == LogicalKeyboardKey.arrowDown && onDown != null) {
        final ok = onDown();
        RemoteKeyTracker.note(ok ? 'field: down → target' : 'field: down, no target below');
        return ok ? KeyEventResult.handled : KeyEventResult.ignored;
      }
      if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.select) {
        final editable = node.context?.findAncestorStateOfType<EditableTextState>();
        if (editable != null) {
          RemoteKeyTracker.note('field: OK → keyboard');
          editable.requestKeyboard();
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored;
    };
  }

  @override
  State<DpadTextField> createState() => _DpadTextFieldState();
}

class _DpadTextFieldState extends State<DpadTextField> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFieldFocus);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFieldFocus);
    super.dispose();
  }

  void _onFieldFocus() {
    final node = widget.focusNode;
    if (node.hasFocus) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || node.hasFocus || !node.canRequestFocus) return;
      final current = FocusManager.instance.primaryFocus;
      // Only a scope of this page/dialog: not a route opened above it, not another tab, not the tabs.
      if (current is! FocusScopeNode || !RemoteKeyTracker.isLost(current) || !node.ancestors.contains(current)) return;
      node.requestFocus();
      // requestFocus hands the field a keyboard token: spend it so the keyboard stays closed.
      node.consumeKeyboardToken();
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      focusNode: widget.focusNode,
      controller: widget.controller,
      autofocus: widget.autofocus,
      decoration: widget.decoration,
      style: widget.style,
      textInputAction: widget.textInputAction,
      // Non-null so the IME's action key keeps the field's focus (by default it unfocuses it).
      onEditingComplete: () {},
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
    );
  }
}
