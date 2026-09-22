import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/settings/settings.dart';

enum FormFactor { mobile, tablet, tv }

/// Set at startup from platform info (Android `uiMode` TELEVISION, no touchscreen).
final isTelevisionProvider = Provider<bool>((ref) => false);

/// True on Android emulators, whose EGL stack rejects mpv's GL renderer.
final isEmulatorProvider = Provider<bool>((ref) => false);

/// Hardware class detected at startup (TV box, 32-bit or low-RAM device).
final isLowEndDeviceProvider = Provider<bool>((ref) => false);

/// Whether to trade eye-candy for frame time: forced by the user setting, else auto from hardware.
final performanceModeProvider = Provider<bool>((ref) {
  final mode = ref.watch(settingsProvider.select((s) => s.performanceMode));
  return switch (mode) {
    PerformanceMode.on => true,
    PerformanceMode.off => false,
    PerformanceMode.auto => ref.watch(isLowEndDeviceProvider),
  };
});

abstract final class Breakpoints {
  static const tablet = 600.0;
  static const desktop = 1100.0;
}

FormFactor formFactorOf(BuildContext context, {bool isTv = false}) {
  if (isTv) return FormFactor.tv;
  final size = MediaQuery.sizeOf(context);
  if (size.shortestSide >= Breakpoints.tablet) return FormFactor.tablet;
  return FormFactor.mobile;
}

extension FormFactorX on FormFactor {
  bool get isTv => this == FormFactor.tv;
  bool get isMobile => this == FormFactor.mobile;
  bool get isTablet => this == FormFactor.tablet;

  /// Number of poster columns for a grid of the given width.
  int posterColumns(double width) {
    final target = switch (this) {
      FormFactor.mobile => 120.0,
      FormFactor.tablet => 150.0,
      FormFactor.tv => 105.0,
    };
    return (width / target).floor().clamp(2, 12);
  }
}

/// Convenience accessor combining the TV flag and the current window size.
class Responsive extends ConsumerWidget {
  const Responsive({super.key, required this.builder});

  final Widget Function(BuildContext context, FormFactor formFactor) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTv = ref.watch(isTelevisionProvider);
    return builder(context, formFactorOf(context, isTv: isTv));
  }
}
