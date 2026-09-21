import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Focus-aware card: scales up and shows a border when focused (D-pad) or hovered.
class FocusableCard extends StatefulWidget {
  const FocusableCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.autofocus = false,
    this.borderRadius = 12,
    this.scale = 1.06,
    this.focusNode,
    this.selected = false,
    this.onFocus,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool autofocus;
  final double borderRadius;
  final double scale;
  final FocusNode? focusNode;
  final bool selected;

  /// Called when the card gains focus (D-pad); lets lists react without pressing OK.
  final VoidCallback? onFocus;

  @override
  State<FocusableCard> createState() => _FocusableCardState();
}

class _FocusableCardState extends State<FocusableCard> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(widget.borderRadius);
    return AnimatedScale(
      scale: _focused ? widget.scale : 1,
      duration: const Duration(milliseconds: 120),
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
          borderRadius: radius,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: _focused
                    ? scheme.primary
                    : widget.selected
                        ? scheme.primary.withValues(alpha: 0.5)
                        : Colors.transparent,
                width: 3,
              ),
              boxShadow: _focused
                  ? [BoxShadow(color: scheme.primary.withValues(alpha: 0.4), blurRadius: 16)]
                  : null,
            ),
            child: ClipRRect(borderRadius: radius, child: widget.child),
          ),
        ),
      ),
    );
  }
}

/// Network image with a neutral placeholder; safe for missing/invalid URLs.
class AppImage extends StatelessWidget {
  const AppImage(this.url, {super.key, this.fit = BoxFit.cover, this.icon = Icons.tv, this.width, this.height});

  final String? url;
  final BoxFit fit;
  final IconData icon;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final placeholder = Container(
      width: width,
      height: height,
      color: scheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(icon, color: scheme.onSurfaceVariant, size: 32),
    );
    final u = url;
    if (u == null || u.isEmpty || !u.startsWith('http')) return placeholder;
    return CachedNetworkImage(
      imageUrl: u,
      fit: fit,
      width: width,
      height: height,
      // Posters/logos are small on screen: decode at a bounded size to keep scrolling smooth.
      memCacheWidth: 480,
      filterQuality: FilterQuality.low,
      placeholder: (_, _) => placeholder,
      errorWidget: (_, _, _) => placeholder,
      fadeInDuration: const Duration(milliseconds: 150),
    );
  }
}

/// Poster tile used for movies and series.
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FocusableCard(
      onTap: onTap,
      onLongPress: onLongPress,
      autofocus: autofocus,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                AppImage(imageUrl, icon: Icons.movie),
                if (badge != null) Positioned(top: 6, right: 6, child: badge!),
                if (progress != null && progress! > 0)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: LinearProgressIndicator(value: progress!.clamp(0, 1), minHeight: 4),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 6, 6, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium),
                if (subtitle != null)
                  Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Channel tile: logo + name, optional now-playing line.
class ChannelTile extends StatelessWidget {
  const ChannelTile({
    super.key,
    required this.name,
    this.logo,
    this.number,
    this.nowPlaying,
    this.locked = false,
    this.favorite = false,
    this.onTap,
    this.onLongPress,
    this.autofocus = false,
    this.selected = false,
    this.dense = false,
  });

  final String name;
  final String? logo;
  final int? number;
  final String? nowPlaying;
  final bool locked;
  final bool favorite;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool autofocus;
  final bool selected;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FocusableCard(
      onTap: onTap,
      onLongPress: onLongPress,
      autofocus: autofocus,
      selected: selected,
      scale: 1.02,
      child: Container(
        color: selected ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4) : theme.colorScheme.surfaceContainer,
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: dense ? 6 : 10),
        child: Row(
          children: [
            if (number != null)
              SizedBox(
                width: 36,
                child: Text('$number', style: theme.textTheme.labelLarge, textAlign: TextAlign.center),
              ),
            SizedBox(
              width: dense ? 40 : 56,
              height: dense ? 40 : 56,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: AppImage(logo, fit: BoxFit.contain, icon: Icons.live_tv),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall),
                  if (nowPlaying != null && nowPlaying!.isNotEmpty)
                    Text(nowPlaying!, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            if (favorite) const Padding(padding: EdgeInsets.only(left: 6), child: Icon(Icons.star, size: 18, color: Colors.amber)),
            if (locked) const Padding(padding: EdgeInsets.only(left: 6), child: Icon(Icons.lock, size: 18)),
          ],
        ),
      ),
    );
  }
}

/// Section header with optional "see all" action.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
          if (action != null) TextButton(onPressed: onAction, child: Text(action!)),
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
