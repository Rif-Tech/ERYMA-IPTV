import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/settings/settings.dart';
import '../l10n/generated/app_localizations.dart';
import 'router.dart';
import 'theme.dart';

class MultIptvApp extends ConsumerWidget {
  const MultIptvApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final router = ref.watch(routerProvider);

    final (theme, darkTheme, mode) = switch (settings.themeMode) {
      AppThemeMode.system => (AppTheme.light(), AppTheme.dark(), ThemeMode.system),
      AppThemeMode.light => (AppTheme.light(), AppTheme.dark(), ThemeMode.light),
      AppThemeMode.dark => (AppTheme.light(), AppTheme.dark(), ThemeMode.dark),
      AppThemeMode.amoled => (AppTheme.light(), AppTheme.dark(amoled: true), ThemeMode.dark),
    };

    return MaterialApp.router(
      title: 'MultIPTV',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: theme,
      darkTheme: darkTheme,
      themeMode: mode,
      locale: settings.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
