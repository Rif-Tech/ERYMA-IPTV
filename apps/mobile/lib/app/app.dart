import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/settings/settings.dart';
import '../core/log/app_logger.dart';
import '../core/net/dns_providers.dart';
import '../features/splash/session_gate.dart';
import '../l10n/generated/app_localizations.dart';
import 'responsive.dart';
import 'router.dart';
import 'theme.dart';

class MultIptvApp extends ConsumerWidget {
  const MultIptvApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(dnsRuntimeSyncProvider);
    ref.watch(dnsProxyProvider);
    ref.watch(appLogLifecycleProvider);
    final settings = ref.watch(settingsProvider);
    final router = ref.watch(routerProvider);
    final isTv = ref.watch(isTelevisionProvider);
    final theme = AppTheme.dark(amoled: settings.themeMode == AppThemeMode.amoled, tv: isTv);

    return MaterialApp.router(
      title: 'MultIPTV',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      builder: (_, child) => SessionGate(child: child ?? const SizedBox.shrink()),
      theme: theme,
      darkTheme: theme,
      themeMode: ThemeMode.dark,
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
