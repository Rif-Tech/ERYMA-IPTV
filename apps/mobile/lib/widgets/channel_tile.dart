import 'package:flutter/material.dart';

import '../app/theme.dart';
import 'app_image.dart';
import 'content_cards.dart';
import 'focusable_card.dart';

/// Channel tile: logo + name, optional now-playing line with programme progress.
class ChannelTile extends StatefulWidget {
  const ChannelTile({
    super.key,
    required this.name,
    this.logo,
    this.number,
    this.nowPlaying,
    this.nextPlaying,
    this.progress,
    this.locked = false,
    this.favorite = false,
    this.onTap,
    this.onLongPress,
    this.autofocus = false,
    this.selected = false,
    this.dense = false,
    this.onFocus,
  });

  final String name;
  final String? logo;
  final int? number;
  final String? nowPlaying;

  /// Title of the programme following [nowPlaying]; shown only when not [dense].
  final String? nextPlaying;

  /// 0..1 progress of the current programme.
  final double? progress;
  final bool locked;
  final bool favorite;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool autofocus;

  /// The channel currently playing (player list): accent bar + label, distinct from focus.
  final bool selected;
  final bool dense;
  final VoidCallback? onFocus;

  @override
  State<ChannelTile> createState() => _ChannelTileState();
}

class _ChannelTileState extends State<ChannelTile> {
  final _node = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _node.addListener(_onFocus);
  }

  void _onFocus() {
    if (_focused != _node.hasFocus) setState(() => _focused = _node.hasFocus);
  }

  @override
  void dispose() {
    _node.removeListener(_onFocus);
    _node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.tokens;
    final dense = widget.dense;
    final logoH = dense ? 40.0 : 52.0;
    // Focused row = white card with dark text (like the category rail): unmistakable from the sofa.
    final fg = _focused ? Colors.black : Colors.white;
    final fgMuted = _focused ? const Color(0x99000000) : t.textMuted;
    final fgFaint = _focused ? const Color(0x73000000) : t.textFaint;
    return FocusableCard(
      focusNode: _node,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onFocus: widget.onFocus,
      autofocus: widget.autofocus,
      selected: widget.selected,
      scale: 1.02,
      ring: false,
      child: Container(
        color: _focused
            ? Colors.white
            : widget.selected
                ? t.glassStrong
                : t.glass,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: dense ? 6 : 8),
        child: Row(
          children: [
            if (widget.selected)
              Container(
                width: 4,
                height: logoH,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(color: _focused ? AppTheme.accent : const Color(0xFF0A84FF), borderRadius: BorderRadius.circular(2)),
              ),
            if (widget.number != null)
              SizedBox(
                width: 34,
                child: Text('${widget.number}', style: theme.textTheme.labelMedium?.copyWith(color: fgFaint), textAlign: TextAlign.center),
              ),
            Container(
              width: logoH * 16 / 9,
              height: logoH,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: _focused ? const Color(0xFFEDEDF0) : const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(8)),
              child: AppImage(widget.logo, fit: BoxFit.contain, icon: Icons.live_tv, decodeWidth: 240),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall?.copyWith(color: fg, fontWeight: _focused ? FontWeight.w700 : null)),
                  if (widget.nowPlaying != null && widget.nowPlaying!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(widget.nowPlaying!, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(color: fgMuted)),
                  ],
                  if (widget.progress != null) ...[
                    const SizedBox(height: 6),
                    ClipRRect(borderRadius: BorderRadius.circular(1), child: ProgressStrip(widget.progress!, height: 2, color: _focused ? Colors.black : null)),
                  ],
                  if (!dense && widget.nextPlaying != null && widget.nextPlaying!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(widget.nextPlaying!, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(color: fgFaint)),
                  ],
                ],
              ),
            ),
            if (widget.selected)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(Icons.play_arrow_rounded, size: 20, color: _focused ? Colors.black : const Color(0xFF0A84FF)),
              ),
            if (widget.favorite) Padding(padding: const EdgeInsets.only(left: 8), child: Icon(Icons.star_rounded, size: 18, color: fgMuted)),
            if (widget.locked) Padding(padding: const EdgeInsets.only(left: 8), child: Icon(Icons.lock_rounded, size: 16, color: fgMuted)),
          ],
        ),
      ),
    );
  }
}
