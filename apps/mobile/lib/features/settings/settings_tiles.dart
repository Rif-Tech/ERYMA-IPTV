// RadioListTile's per-tile groupValue/onChanged is deprecated in favor of a RadioGroup ancestor —
// deliberately not used here, see the comment on SettingsEnumTile's dialog: RadioGroup binds D-pad
// Up/Down to immediate selection, not just focus.
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';
import '../../core/log/trace_tag.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/common.dart';

// Reusable settings rows (section card, D-pad slider, colour swatches, enum picker).

class SettingsSection extends StatelessWidget {
  const SettingsSection(this.title, this.children, {super.key});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return TraceTag(title.toLowerCase(), child: Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              title.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: context.tokens.textFaint, letterSpacing: 1),
            ),
          ),
          GlassPanel(
            padding: const EdgeInsets.symmetric(vertical: 4),
            // Ink (focus highlight) must paint above the panel background, not on the page Material below it.
            child: Material(
              type: MaterialType.transparency,
              child: Column(
                children: [
                  for (final (i, c) in children.indexed) ...[
                    if (i > 0) Divider(indent: 56, endIndent: 16, color: context.tokens.glass),
                    // The whole settings page is one list item: without these, every row traces
                    // as `settings/v#0`.
                    TraceTag('$i', child: c),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    ));
  }
}

/// Slider row for the D-pad: left/right adjust the value, up/down keep moving through the list.
///
/// Flutter's [Slider] binds all four arrows to value changes, which traps the focus on TV.
class SettingsSliderTile extends StatefulWidget {
  const SettingsSliderTile({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.label,
    required this.onChanged,
  });
  final IconData icon;
  final String title;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String label;
  final ValueChanged<double> onChanged;

  @override
  State<SettingsSliderTile> createState() => _SliderTileState();
}

class _SliderTileState extends State<SettingsSliderTile> {
  late final FocusNode _node = FocusNode(debugLabel: 'slider-tile', onKeyEvent: _onKey);

  @override
  void initState() {
    super.initState();
    _node.addListener(_onFocus);
  }

  @override
  void dispose() {
    _node.removeListener(_onFocus);
    _node.dispose();
    super.dispose();
  }

  void _onFocus() => setState(() {});

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.arrowDown) {
      // Runs before the slider's own shortcuts: hand the key back to focus traversal.
      final moved = node.focusInDirection(key == LogicalKeyboardKey.arrowUp ? TraversalDirection.up : TraversalDirection.down);
      return moved ? KeyEventResult.handled : KeyEventResult.ignored;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(widget.icon),
      title: Text(widget.title),
      trailing: Text(widget.label, style: Theme.of(context).textTheme.labelLarge),
      selected: _node.hasFocus,
      selectedTileColor: scheme.primary.withValues(alpha: 0.12),
      subtitle: Slider(
        value: widget.value,
        min: widget.min,
        max: widget.max,
        divisions: widget.divisions,
        label: widget.label,
        focusNode: _node,
        onChanged: widget.onChanged,
      ),
    );
  }
}

/// Color swatch row for the D-pad, same pattern as [SettingsSliderTile]: the [FocusNode] sits on the
/// whole [ListTile] (a full-width target, like the slider), not on the narrow trailing swatches
/// themselves — a focus node confined to that small trailing area is not reliably reachable by
/// directional traversal from the rows above/below. Left/right immediately picks the next/
/// previous color; up/down keep moving through the list.
class SubtitleColorTile extends StatefulWidget {
  const SubtitleColorTile({super.key, required this.colors, required this.value, required this.onChanged});
  final List<int> colors;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  State<SubtitleColorTile> createState() => _SubtitleColorTileState();
}

class _SubtitleColorTileState extends State<SubtitleColorTile> {
  late final FocusNode _node = FocusNode(debugLabel: 'subtitle-color', onKeyEvent: _onKey);

  @override
  void initState() {
    super.initState();
    _node.addListener(_onFocus);
  }

  @override
  void dispose() {
    _node.removeListener(_onFocus);
    _node.dispose();
    super.dispose();
  }

  void _onFocus() => setState(() {});

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.arrowDown) {
      // Runs before default traversal would even see this node as one stop: hand the key back.
      final moved = node.focusInDirection(key == LogicalKeyboardKey.arrowUp ? TraversalDirection.up : TraversalDirection.down);
      return moved ? KeyEventResult.handled : KeyEventResult.ignored;
    }
    if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.arrowRight) {
      final i = widget.colors.indexOf(widget.value);
      final next = i + (key == LogicalKeyboardKey.arrowRight ? 1 : -1);
      if (next < 0 || next >= widget.colors.length) return KeyEventResult.ignored;
      widget.onChanged(widget.colors[next]);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        focusNode: _node,
        canRequestFocus: true,
        onTap: () {},
        child: ListTile(
      selected: _node.hasFocus,
      selectedTileColor: scheme.primary.withValues(alpha: 0.12),
      leading: const Icon(Icons.color_lens_outlined),
      title: Text(l10n.subtitleColor),
      trailing: Wrap(
        spacing: 12,
        children: [
          for (final c in widget.colors)
            GestureDetector(
              onTap: () => widget.onChanged(c),
              child: Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: widget.value == c && _node.hasFocus ? Border.all(color: Colors.white, width: 2.5) : null,
                ),
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Color(c),
                    shape: BoxShape.circle,
                    border: Border.all(color: widget.value == c ? Colors.white : Colors.transparent, width: 2),
                  ),
                ),
              ),
            ),
        ],
      ),
        ),
      ),
    );
  }
}

/// ListTile opening a radio dialog; works with D-pad and touch alike.
class SettingsEnumTile<T> extends StatelessWidget {
  const SettingsEnumTile({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.values,
    required this.label,
    required this.onChanged,
  });
  final IconData icon;
  final String title;
  final T value;
  final List<T> values;
  final String Function(T) label;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(label(value)),
      onTap: () async {
        final picked = await showDialog<(T,)>(
          context: context,
          builder: (context) => TraceTag('dialog/${title.toLowerCase()}', child: SimpleDialog(
            title: Text(title),
            children: [
              // No RadioGroup ancestor on purpose (hence the deprecated per-tile groupValue/
              // onChanged below, see the ignore_for_file at the top of this file): RadioGroup
              // binds arrow keys to select-and-advance (see radio_group.dart), which would
              // confirm and close the dialog on the first D-pad press instead of just moving
              // focus. Do not "fix" this deprecation warning by migrating to RadioGroup without
              // re-solving that problem first.
              for (final (i, v) in values.indexed)
                TraceTag('$i', child: RadioListTile<T>(
                  autofocus: v == value,
                  value: v,
                  groupValue: value,
                  onChanged: (picked) => Navigator.pop(context, (picked as T,)),
                  title: Text(label(v)),
                )),
            ],
          )),
        );
        if (picked != null) onChanged(picked.$1);
      },
    );
  }
}
