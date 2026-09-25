import 'package:flutter/material.dart';

/// Pill button (icon + label) with white fill on focus; the primary CTA style.
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.primary = false,
    this.autofocus = false,
    this.focusNode,
    this.compact = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool primary;
  final bool autofocus;
  final FocusNode? focusNode;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final child = icon == null
        ? Text(label)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [Icon(icon, size: compact ? 18 : 20), const SizedBox(width: 8), Text(label)],
          );
    final padding = compact ? const EdgeInsets.symmetric(horizontal: 14, vertical: 8) : null;
    return primary
        ? FilledButton(
            onPressed: onPressed,
            autofocus: autofocus,
            focusNode: focusNode,
            style: padding == null ? null : FilledButton.styleFrom(padding: padding),
            child: child,
          )
        : OutlinedButton(
            onPressed: onPressed,
            autofocus: autofocus,
            focusNode: focusNode,
            style: padding == null ? null : OutlinedButton.styleFrom(padding: padding),
            child: child,
          );
  }
}
