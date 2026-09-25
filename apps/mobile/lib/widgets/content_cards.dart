import 'package:flutter/material.dart';

import '../app/theme.dart';
import 'app_image.dart';
import 'focusable_card.dart';

/// Poster tile used for movies and series (image only; the caption sits below the ring).
class PosterCard extends StatelessWidget {
  const PosterCard({
    super.key,
    required this.title,
    this.imageUrl,
    this.subtitle,
    this.onTap,
    this.onLongPress,
    this.autofocus = false,
    this.progress,
    this.badge,
    this.showTitle = true,
  });

  final String title;
  final String? imageUrl;
  final String? subtitle;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool autofocus;

  /// 0..1 watched fraction.
  final double? progress;
  final Widget? badge;
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: FocusableCard(
            onTap: onTap,
            onLongPress: onLongPress,
            autofocus: autofocus,
            scale: 1.05,
            child: Stack(
              fit: StackFit.expand,
              children: [
                AppImage(imageUrl, icon: Icons.movie_outlined, decodeWidth: 360),
                if (badge != null) Positioned(top: 8, right: 8, child: badge!),
                if (progress != null && progress! > 0) Positioned(left: 0, right: 0, bottom: 0, child: ProgressStrip(progress!)),
              ],
            ),
          ),
        ),
        if (showTitle)
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 8, 2, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(color: t.textMuted)),
                if (subtitle != null)
                  Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.labelSmall?.copyWith(color: t.textFaint)),
              ],
            ),
          ),
      ],
    );
  }
}

/// 16:9 card with a bottom gradient caption; used for resume items and episodes.
class LandscapeCard extends StatelessWidget {
  const LandscapeCard({
    super.key,
    required this.title,
    this.imageUrl,
    this.subtitle,
    this.overline,
    this.onTap,
    this.onLongPress,
    this.autofocus = false,
    this.progress,
    this.icon = Icons.movie_outlined,
    this.imageFit = BoxFit.cover,
    this.trailing,
  });

  final String title;
  final String? imageUrl;
  final String? subtitle;
  final String? overline;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool autofocus;
  final double? progress;
  final IconData icon;
  final BoxFit imageFit;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final t = context.tokens;
    return FocusableCard(
      onTap: onTap,
      onLongPress: onLongPress,
      autofocus: autofocus,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AppImage(imageUrl, icon: icon, fit: imageFit, decodeWidth: 640, alignment: Alignment.topCenter),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.4, 1],
                colors: [Colors.transparent, Color(0xD9000000)],
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: progress != null && progress! > 0 ? 12 : 10,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (overline != null)
                        Text(overline!, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.labelSmall?.copyWith(color: t.textMuted)),
                      Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.titleSmall),
                      if (subtitle != null)
                        Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.labelSmall?.copyWith(color: t.textMuted)),
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
          if (progress != null && progress! > 0) Positioned(left: 0, right: 0, bottom: 0, child: ProgressStrip(progress!)),
        ],
      ),
    );
  }
}

/// Thin progress strip drawn along the bottom edge of a card.
class ProgressStrip extends StatelessWidget {
  const ProgressStrip(this.value, {super.key, this.height = 3, this.color});
  final double value;
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(color: color == null ? const Color(0x4DFFFFFF) : color!.withValues(alpha: 0.25)),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: value.clamp(0, 1).toDouble(),
            child: DecoratedBox(decoration: BoxDecoration(color: color ?? AppTheme.accent)),
          ),
        ),
      ),
    );
  }
}
