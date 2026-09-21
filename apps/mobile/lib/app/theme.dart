import 'package:flutter/material.dart';

enum AppThemeMode { system, dark, light, amoled }

abstract final class AppTheme {
  static const seed = Color(0xFF2563EB);

  static ThemeData dark({bool amoled = false}) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
      surface: amoled ? Colors.black : const Color(0xFF0F172A),
    );
    return _base(scheme).copyWith(
      scaffoldBackgroundColor: amoled ? Colors.black : const Color(0xFF0B1220),
    );
  }

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light);
    return _base(scheme);
  }

  static ThemeData _base(ColorScheme scheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      visualDensity: VisualDensity.standard,
      // Focus feedback is the primary affordance on TV: keep it strong and consistent.
      focusColor: scheme.primary.withValues(alpha: 0.35),
      cardTheme: CardThemeData(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
      navigationRailTheme: NavigationRailThemeData(
        indicatorColor: scheme.primaryContainer,
        selectedIconTheme: IconThemeData(color: scheme.onPrimaryContainer),
      ),
      listTileTheme: const ListTileThemeData(dense: false),
    );
  }
}
