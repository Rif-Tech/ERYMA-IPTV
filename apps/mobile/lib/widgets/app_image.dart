import 'dart:ui' show ImageFilter;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/responsive.dart';
import '../app/theme.dart';
import '../core/images/artwork_cache.dart';

/// Network image with a neutral placeholder; safe for missing/invalid URLs.
class AppImage extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final lite = ref.watch(performanceModeProvider);
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
      cacheManager: ArtworkCache.instance,
      fit: fit,
      width: width,
      height: height,
      alignment: alignment,
      memCacheWidth: decodeWidth,
      filterQuality: FilterQuality.low,
      placeholder: (_, _) => placeholder,
      errorWidget: (_, _, _) => placeholder,
      // Each fade composites two layers per card while a shelf scrolls in; skip it on weak GPUs.
      fadeInDuration: lite ? Duration.zero : const Duration(milliseconds: 150),
      fadeOutDuration: lite ? Duration.zero : const Duration(milliseconds: 100),
      placeholderFadeInDuration: Duration.zero,
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
        cacheManager: ArtworkCache.instance,
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

class _BlurredPoster extends ConsumerWidget {
  const _BlurredPoster({required this.url, required this.showPoster});
  final String? url;
  final bool showPoster;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!AppImage.isValid(url)) return const ColoredBox(color: Color(0xFF141416));
    final lite = ref.watch(performanceModeProvider);
    return Stack(
      fit: StackFit.expand,
      children: [
        // A gaussian blur over the whole hero is a full-screen GPU pass per frame; on weak boxes a
        // 32 px decode stretched with bilinear filtering gives the same soft wash for free.
        if (lite)
          Transform.scale(
            scale: 1.15,
            child: AppImage(url, fit: BoxFit.cover, decodeWidth: 32, icon: Icons.image_outlined),
          )
        else
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 28, sigmaY: 28, tileMode: TileMode.mirror),
            child: Transform.scale(
              scale: 1.15,
              child: AppImage(url, fit: BoxFit.cover, decodeWidth: 240, icon: Icons.image_outlined),
            ),
          ),
        DecoratedBox(decoration: BoxDecoration(color: lite ? const Color(0x80000000) : const Color(0x4D000000))),
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
