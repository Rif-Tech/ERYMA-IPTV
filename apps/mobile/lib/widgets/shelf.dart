import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/responsive.dart';
import '../app/theme.dart';
import 'row_focus_chain.dart';

/// Horizontal shelf with a title and fixed-extent items; the backbone of the Apple TV-style layout.
class Shelf extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final gutter = padding ?? EdgeInsets.symmetric(horizontal: context.tokens.pageGutter);
    final lite = ref.watch(performanceModeProvider);
    final shelfContext = context;
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
              // Off-screen cards each hold a decoded image; keep the prefetch window small on 2 GB boxes.
              scrollCacheExtent: ScrollCacheExtent.pixels(itemWidth * (lite ? 1.5 : 4)),
              addAutomaticKeepAlives: false,
              // FocusableCard already isolates each item in its own layer.
              addRepaintBoundaries: false,
              itemBuilder: (context, i) => Padding(
                padding: EdgeInsets.only(right: gap),
                // Flutter never auto-scrolls a generic focusable into view vertically: show the
                // whole section (title + cards) with minimal page movement. Centring the card here
                // used to scroll on every Left/Right and put the next section in the middle of the
                // screen, then a second correction made the page bounce.
                child: Focus(
                  canRequestFocus: false,
                  skipTraversal: true,
                  onFocusChange: (f) {
                    if (f && shelfContext.mounted) revealSection(shelfContext, reason: 'shelf card $i');
                  },
                  child: itemBuilder(context, i),
                ),
              ),
            ),
          ),
        ),
      ],
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
              // No `color:` here: TextButtonThemeData already flips foreground black-on-focused-white
              // (theme.dart's `focusFg`), an explicit Text color (labelMedium bakes in white) would
              // override it and make the label invisible against the focused white background.
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, height: 1.2, letterSpacing: 0.2),
              ),
              child: Text(action!),
            ),
        ],
      ),
    );
  }
}
