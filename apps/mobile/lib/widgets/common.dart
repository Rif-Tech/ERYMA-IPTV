import 'dart:ui' show ImageFilter;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/theme.dart';

/// Focus-aware card: scales up and shows a white ring when focused (D-pad) or hovered.
class FocusableCard extends StatefulWidget {
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
  State<FocusableCard> createState() => _FocusableCardState();
}

class _FocusableCardState extends State<FocusableCard> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final radius = BorderRadius.circular(widget.borderRadius);
    final ringColor = _focused && widget.ring
        ? Colors.white
        : widget.selected
            ? const Color(0x66FFFFFF)
            : Colors.transparent;
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
              boxShadow: _focused
                  ? const [BoxShadow(color: Color(0x99000000), blurRadius: 24, offset: Offset(0, 10))]
                  : null,
            ),
            child: ClipRRect(borderRadius: radius, child: RepaintBoundary(child: widget.child)),
          ),
        ),
      ),
    );
  }
}

/// Network image with a neutral placeholder; safe for missing/invalid URLs.
class AppImage extends StatelessWidget {
  const AppImage(
    this.url, {
    super.key,
    this.fit = BoxFit.cover,
    this.icon = Icons.tv,
    this.width,
    this.height,
    this.decodeWidth = 480,
    this.alignment = Alignment.center,
  });

  final String? url;
  final BoxFit fit;
  final IconData icon;
  final double? width;
  final double? height;

  /// Decode target width in physical pixels; keep close to the displayed size.
  final int decodeWidth;
  final Alignment alignment;

  static bool isValid(String? u) => u != null && u.startsWith('http');

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final placeholder = Container(
      width: width,
      height: height,
      color: scheme.surfaceContainer,
      alignment: Alignment.center,
      child: Icon(icon, color: scheme.onSurfaceVariant.withValues(alpha: 0.4), size: 28),
    );
    final u = url;
    if (!isValid(u)) return placeholder;
    return CachedNetworkImage(
      imageUrl: u!,
      fit: fit,
      width: width,
      height: height,
      alignment: alignment,
      memCacheWidth: decodeWidth,
      filterQuality: FilterQuality.low,
      placeholder: (_, _) => placeholder,
      errorWidget: (_, _, _) => placeholder,
      fadeInDuration: const Duration(milliseconds: 150),
      fadeOutDuration: const Duration(milliseconds: 100),
    );
  }
}

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

/// Wide artwork for heroes and detail headers: the provider backdrop when it loads, otherwise the
/// poster enlarged and blurred (many panels return dead backdrop links).
class BackdropArt extends StatelessWidget {
  const BackdropArt({super.key, this.backdrop, this.poster, this.showPoster = true});
  final String? backdrop;
  final String? poster;

  /// Also draw the sharp poster on the right when falling back to the blurred version.
  final bool showPoster;

  @override
  Widget build(BuildContext context) {
    final fallback = _BlurredPoster(url: poster, showPoster: showPoster);
    // ImageFiltered blur bleeds past its bounds; clip so it never washes over the content below.
    if (!AppImage.isValid(backdrop)) return ClipRect(child: fallback);
    return ClipRect(
      child: CachedNetworkImage(
        imageUrl: backdrop!,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        memCacheWidth: 1280,
        filterQuality: FilterQuality.low,
        fadeInDuration: const Duration(milliseconds: 200),
        placeholder: (_, _) => const ColoredBox(color: Color(0xFF141416)),
        errorWidget: (_, _, _) => fallback,
      ),
    );
  }
}

class _BlurredPoster extends StatelessWidget {
  const _BlurredPoster({required this.url, required this.showPoster});
  final String? url;
  final bool showPoster;

  @override
  Widget build(BuildContext context) {
    if (!AppImage.isValid(url)) return const ColoredBox(color: Color(0xFF141416));
    return Stack(
      fit: StackFit.expand,
      children: [
        // Blur a tiny decode: cheap even on TV GPUs, and it only re-renders on item change.
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 28, sigmaY: 28, tileMode: TileMode.mirror),
          child: Transform.scale(
            scale: 1.15,
            child: AppImage(url, fit: BoxFit.cover, decodeWidth: 240, icon: Icons.image_outlined),
          ),
        ),
        const DecoratedBox(decoration: BoxDecoration(color: Color(0x4D000000))),
        if (showPoster)
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: EdgeInsets.only(right: context.tokens.pageGutter, top: 24, bottom: 24),
              child: AspectRatio(
                aspectRatio: 2 / 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AppImage(url, fit: BoxFit.cover, decodeWidth: 600, icon: Icons.movie_outlined),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Thin progress strip drawn along the bottom edge of a card.
class ProgressStrip extends StatelessWidget {
  const ProgressStrip(this.value, {super.key, this.height = 3});
  final double value;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: const BoxDecoration(color: Color(0x4DFFFFFF)),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: value.clamp(0, 1).toDouble(),
            child: const DecoratedBox(decoration: BoxDecoration(color: AppTheme.accent)),
          ),
        ),
      ),
    );
  }
}

/// Horizontal shelf with a title and fixed-extent items; the backbone of the Apple TV-style layout.
class Shelf extends StatelessWidget {
  const Shelf({
    super.key,
    required this.title,
    required this.itemCount,
    required this.itemBuilder,
    required this.height,
    required this.itemWidth,
    this.gap = 16,
    this.action,
    this.onAction,
    this.padding,
  });

  final String title;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double height;
  final double itemWidth;
  final double gap;
  final String? action;
  final VoidCallback? onAction;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final gutter = padding ?? EdgeInsets.symmetric(horizontal: context.tokens.pageGutter);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SectionHeader(title, action: action, onAction: onAction, padding: gutter.copyWith(top: 20, bottom: 10)),
        SizedBox(
          // Leave room for the focus scale so the ring is not clipped by the viewport.
          height: height + 24,
          child: FocusTraversalGroup(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              padding: gutter.copyWith(top: 12, bottom: 12),
              itemCount: itemCount,
              itemExtent: itemWidth + gap,
              scrollCacheExtent: ScrollCacheExtent.pixels(itemWidth * 4),
              addAutomaticKeepAlives: false,
              itemBuilder: (context, i) => Padding(
                padding: EdgeInsets.only(right: gap),
                child: itemBuilder(context, i),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

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

/// "Now" badge with a pulsing red dot, for events that are about to start or running.
class LiveBadge extends StatefulWidget {
  const LiveBadge(this.label, {super.key});
  final String label;

  @override
  State<LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<LiveBadge> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700, letterSpacing: 0.6);
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 3, 9, 3),
      decoration: BoxDecoration(color: const Color(0xFFE5323C), borderRadius: BorderRadius.circular(4)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: CurvedAnimation(parent: _c, curve: Curves.easeInOut).drive(Tween(begin: 0.25, end: 1)),
            child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
          ),
          const SizedBox(width: 6),
          Text(widget.label.toUpperCase(), style: style),
        ],
      ),
    );
  }
}

/// Small bordered label: resolution, rating, year, "LIVE".
class MetaBadge extends StatelessWidget {
  const MetaBadge(this.text, {super.key, this.filled = false, this.icon});
  final String text;
  final bool filled;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(color: filled ? Colors.black : Colors.white);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: filled ? Colors.white : Colors.transparent,
        border: filled ? null : Border.all(color: const Color(0x99FFFFFF)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 12, color: filled ? Colors.black : Colors.white), const SizedBox(width: 3)],
          Text(text, style: style),
        ],
      ),
    );
  }
}

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

/// Animated loading placeholder block (no external package).
class Skeleton extends StatefulWidget {
  const Skeleton({super.key, this.width, this.height, this.radius = 12});
  final double? width;
  final double? height;
  final double radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          gradient: LinearGradient(
            begin: Alignment(-1 + 2 * _c.value, 0),
            end: Alignment(1 + 2 * _c.value, 0),
            colors: const [Color(0xFF1C1C1E), Color(0xFF2C2C2E), Color(0xFF1C1C1E)],
          ),
        ),
      ),
    );
  }
}

/// Channel tile: logo + name, optional now-playing line with programme progress.
class ChannelTile extends StatelessWidget {
  const ChannelTile({
    super.key,
    required this.name,
    this.logo,
    this.number,
    this.nowPlaying,
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

  /// 0..1 progress of the current programme.
  final double? progress;
  final bool locked;
  final bool favorite;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool autofocus;
  final bool selected;
  final bool dense;
  final VoidCallback? onFocus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.tokens;
    final logoH = dense ? 40.0 : 52.0;
    return FocusableCard(
      onTap: onTap,
      onLongPress: onLongPress,
      onFocus: onFocus,
      autofocus: autofocus,
      selected: selected,
      scale: 1.02,
      child: Container(
        color: selected ? t.glassStrong : t.glass,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: dense ? 6 : 8),
        child: Row(
          children: [
            if (number != null)
              SizedBox(
                width: 34,
                child: Text('$number', style: theme.textTheme.labelMedium?.copyWith(color: t.textFaint), textAlign: TextAlign.center),
              ),
            Container(
              width: logoH * 16 / 9,
              height: logoH,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(8)),
              child: AppImage(logo, fit: BoxFit.contain, icon: Icons.live_tv, decodeWidth: 240),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall),
                  if (nowPlaying != null && nowPlaying!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(nowPlaying!, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall),
                  ],
                  if (progress != null) ...[
                    const SizedBox(height: 6),
                    ClipRRect(borderRadius: BorderRadius.circular(1), child: ProgressStrip(progress!, height: 2)),
                  ],
                ],
              ),
            ),
            if (favorite) Padding(padding: const EdgeInsets.only(left: 8), child: Icon(Icons.star_rounded, size: 18, color: t.textMuted)),
            if (locked) Padding(padding: const EdgeInsets.only(left: 8), child: Icon(Icons.lock_rounded, size: 16, color: t.textMuted)),
          ],
        ),
      ),
    );
  }
}

/// Section header with optional "see all" action.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action, this.onAction, this.padding});
  final String title;
  final String? action;
  final VoidCallback? onAction;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.fromLTRB(context.tokens.pageGutter, 20, context.tokens.pageGutter, 10),
      child: Row(
        children: [
          Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
          if (action != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), minimumSize: Size.zero),
              child: Text(action!, style: Theme.of(context).textTheme.labelMedium),
            ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.message, this.action});
  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

/// Renders an AsyncValue with consistent loading/error UI.
class AsyncView<T> extends StatelessWidget {
  const AsyncView({super.key, required this.value, required this.builder, this.onRetry});
  final AsyncValue<T> value;
  final Widget Function(T data) builder;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return value.when(
      skipLoadingOnReload: true,
      data: builder,
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EmptyState(
        icon: Icons.error_outline,
        message: e.toString(),
        action: onRetry == null ? null : FilledButton(onPressed: onRetry, child: const Icon(Icons.refresh)),
      ),
    );
  }
}
