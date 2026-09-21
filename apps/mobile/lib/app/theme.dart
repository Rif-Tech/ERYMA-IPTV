import 'package:flutter/material.dart';

enum AppThemeMode { dark, amoled }

/// Design tokens shared by the widgets (motion, radii, focus feel).
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.focusScale,
    required this.motion,
    required this.curve,
    required this.radius,
    required this.pageGutter,
    required this.glass,
    required this.glassStrong,
    required this.textMuted,
    required this.textFaint,
  });

  final double focusScale;
  final Duration motion;
  final Curve curve;
  final double radius;
  final double pageGutter;

  /// Translucent surfaces layered over content (panes, pills, tiles).
  final Color glass;
  final Color glassStrong;
  final Color textMuted;
  final Color textFaint;

  static const tv = AppTokens(
    focusScale: 1.08,
    motion: Duration(milliseconds: 150),
    curve: Curves.easeOutCubic,
    radius: 12,
    pageGutter: 48,
    glass: Color(0x14FFFFFF),
    glassStrong: Color(0x24FFFFFF),
    textMuted: Color(0xB3FFFFFF),
    textFaint: Color(0x66FFFFFF),
  );

  static const touch = AppTokens(
    focusScale: 1.0,
    motion: Duration(milliseconds: 150),
    curve: Curves.easeOutCubic,
    radius: 12,
    pageGutter: 16,
    glass: Color(0x14FFFFFF),
    glassStrong: Color(0x24FFFFFF),
    textMuted: Color(0xB3FFFFFF),
    textFaint: Color(0x66FFFFFF),
  );

  @override
  AppTokens copyWith({double? focusScale, double? pageGutter}) => AppTokens(
        focusScale: focusScale ?? this.focusScale,
        motion: motion,
        curve: curve,
        radius: radius,
        pageGutter: pageGutter ?? this.pageGutter,
        glass: glass,
        glassStrong: glassStrong,
        textMuted: textMuted,
        textFaint: textFaint,
      );

  @override
  AppTokens lerp(covariant AppTokens? other, double t) => t < 0.5 ? this : (other ?? this);
}

extension AppTokensX on BuildContext {
  AppTokens get tokens => Theme.of(this).extension<AppTokens>() ?? AppTokens.touch;
}

abstract final class AppTheme {
  static const accent = Color(0xFF0A84FF);
  static const _surface = Color(0xFF0A0A0A);
  static const _font = 'Inter';

  static ThemeData dark({bool amoled = false, bool tv = false}) {
    final surface = amoled ? Colors.black : _surface;
    const white = Colors.white;
    final scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: white,
      onPrimary: Colors.black,
      primaryContainer: const Color(0xFF2A2A2E),
      onPrimaryContainer: white,
      secondary: accent,
      onSecondary: white,
      secondaryContainer: accent.withValues(alpha: 0.25),
      onSecondaryContainer: white,
      tertiary: const Color(0xFFFF9F0A),
      onTertiary: Colors.black,
      error: const Color(0xFFFF453A),
      onError: white,
      surface: surface,
      onSurface: white,
      onSurfaceVariant: const Color(0xB3FFFFFF),
      surfaceContainerLowest: Colors.black,
      surfaceContainerLow: const Color(0xFF121214),
      surfaceContainer: const Color(0xFF1C1C1E),
      surfaceContainerHigh: const Color(0xFF2C2C2E),
      surfaceContainerHighest: const Color(0xFF3A3A3C),
      outline: const Color(0x33FFFFFF),
      outlineVariant: const Color(0x1AFFFFFF),
      inverseSurface: white,
      onInverseSurface: Colors.black,
      inversePrimary: Colors.black,
      shadow: Colors.black,
      scrim: Colors.black,
    );

    final text = _textTheme(white, scheme.onSurfaceVariant);
    const pill = StadiumBorder();
    const pillPadding = WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 22, vertical: 14));
    Color focusFg(Set<WidgetState> s) => s.contains(WidgetState.focused) ? Colors.black : white;
    Color focusBg(Set<WidgetState> s) => s.contains(WidgetState.focused) ? white : const Color(0x14FFFFFF);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: _font,
      textTheme: text,
      scaffoldBackgroundColor: surface,
      canvasColor: surface,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      hoverColor: const Color(0x14FFFFFF),
      focusColor: const Color(0x38FFFFFF),
      dividerColor: scheme.outlineVariant,
      visualDensity: VisualDensity.standard,
      extensions: [tv ? AppTokens.tv : AppTokens.touch],
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
      }),
      cardTheme: CardThemeData(
        clipBehavior: Clip.antiAlias,
        color: scheme.surfaceContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          shape: const WidgetStatePropertyAll(pill),
          padding: pillPadding,
          textStyle: WidgetStatePropertyAll(text.labelLarge),
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.disabled) ? const Color(0x1FFFFFFF) : white,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.disabled) ? const Color(0x66FFFFFF) : Colors.black,
          ),
          overlayColor: const WidgetStatePropertyAll(Color(0x14000000)),
          elevation: const WidgetStatePropertyAll(0),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          shape: const WidgetStatePropertyAll(pill),
          padding: pillPadding,
          textStyle: WidgetStatePropertyAll(text.labelLarge),
          side: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.focused) ? const BorderSide(color: white, width: 2) : BorderSide(color: scheme.outline),
          ),
          backgroundColor: WidgetStateProperty.resolveWith(focusBg),
          foregroundColor: WidgetStateProperty.resolveWith(focusFg),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          shape: const WidgetStatePropertyAll(pill),
          textStyle: WidgetStatePropertyAll(text.labelLarge),
          foregroundColor: WidgetStateProperty.resolveWith(focusFg),
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.focused) ? white : Colors.transparent,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith(focusFg),
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.focused) ? white : Colors.transparent,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: pill,
        side: BorderSide.none,
        backgroundColor: const Color(0x14FFFFFF),
        selectedColor: white,
        labelStyle: text.labelLarge,
        secondaryLabelStyle: text.labelLarge?.copyWith(color: Colors.black),
        checkmarkColor: Colors.black,
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0x14FFFFFF),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: white, width: 2)),
        labelStyle: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        hintStyle: text.bodyMedium?.copyWith(color: const Color(0x66FFFFFF)),
      ),
      listTileTheme: ListTileThemeData(
        dense: false,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        titleTextStyle: text.bodyLarge,
        subtitleTextStyle: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        iconColor: white,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(white),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? const Color(0xFF30D158) : const Color(0x33FFFFFF),
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: white,
        inactiveTrackColor: Color(0x4DFFFFFF),
        thumbColor: white,
        overlayColor: Color(0x24FFFFFF),
        trackHeight: 4,
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 7),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: white,
        linearTrackColor: const Color(0x4DFFFFFF),
        circularTrackColor: Colors.transparent,
        linearMinHeight: 3,
        borderRadius: BorderRadius.circular(2),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyMedium,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainer,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        showDragHandle: true,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        contentTextStyle: text.bodyMedium,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xF20A0A0A),
        indicatorColor: const Color(0x24FFFFFF),
        indicatorShape: pill,
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => text.labelSmall?.copyWith(color: s.contains(WidgetState.selected) ? white : const Color(0x99FFFFFF)),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(color: s.contains(WidgetState.selected) ? white : const Color(0x99FFFFFF), size: 24),
        ),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 1, space: 1),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: scheme.surfaceContainerHigh, borderRadius: BorderRadius.circular(8)),
        textStyle: text.bodySmall,
      ),
    );
  }

  static TextTheme _textTheme(Color on, Color muted) {
    TextStyle s(double size, FontWeight w, {double? height, double spacing = 0, Color? color}) => TextStyle(
          fontFamily: _font,
          fontSize: size,
          fontWeight: w,
          height: height,
          letterSpacing: spacing,
          color: color ?? on,
        );
    return TextTheme(
      displayLarge: s(48, FontWeight.w700, height: 1.05, spacing: -1.0),
      displayMedium: s(40, FontWeight.w700, height: 1.08, spacing: -0.8),
      displaySmall: s(32, FontWeight.w700, height: 1.1, spacing: -0.5),
      headlineLarge: s(28, FontWeight.w600, height: 1.15, spacing: -0.4),
      headlineMedium: s(24, FontWeight.w600, height: 1.2, spacing: -0.3),
      headlineSmall: s(20, FontWeight.w600, height: 1.25, spacing: -0.2),
      titleLarge: s(20, FontWeight.w600, height: 1.3, spacing: -0.2),
      titleMedium: s(16, FontWeight.w600, height: 1.35),
      titleSmall: s(14, FontWeight.w600, height: 1.35),
      bodyLarge: s(16, FontWeight.w400, height: 1.4),
      bodyMedium: s(14, FontWeight.w400, height: 1.4),
      bodySmall: s(12, FontWeight.w400, height: 1.35, color: muted),
      labelLarge: s(14, FontWeight.w600, height: 1.2),
      labelMedium: s(12, FontWeight.w600, height: 1.2, spacing: 0.2),
      labelSmall: s(11, FontWeight.w500, height: 1.2, spacing: 0.3),
    );
  }
}
