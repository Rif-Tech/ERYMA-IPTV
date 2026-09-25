import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/responsive.dart';

/// "Now" badge with a pulsing red dot, for events that are about to start or running.
class LiveBadge extends ConsumerStatefulWidget {
  const LiveBadge(this.label, {super.key});
  final String label;

  @override
  ConsumerState<LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends ConsumerState<LiveBadge> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // A perpetual ticker keeps the whole hero repainting; static dot on weak hardware.
    final lite = ref.watch(performanceModeProvider);
    if (lite) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700, letterSpacing: 0.6);
    final dot = Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle));
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 3, 9, 3),
      decoration: BoxDecoration(color: const Color(0xFFE5323C), borderRadius: BorderRadius.circular(4)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (lite)
            dot
          else
            FadeTransition(
              opacity: CurvedAnimation(parent: _c, curve: Curves.easeInOut).drive(Tween(begin: 0.25, end: 1)),
              child: dot,
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
