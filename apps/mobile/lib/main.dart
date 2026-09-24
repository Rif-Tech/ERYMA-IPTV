import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/config.dart';
import 'app/responsive.dart';
import 'core/device/device_identity.dart';
import 'core/log/remote_key_tracker.dart';
import 'core/log/telemetry.dart';
import 'core/net/dns_http_overrides.dart';
import 'core/settings/settings.dart';

Future<void> main() async {
  // No DSN configured (no account provisioned by default, see AppConfig.sentryDsn): run normally,
  // without Sentry's native crash hooks or network activity.
  if (AppConfig.sentryDsn.isEmpty) return _bootstrap();
  await SentryFlutter.init(Telemetry.configure, appRunner: _bootstrap);
}

Future<void> _bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  HttpOverrides.global = AppHttpOverrides();

  final prefs = await SharedPreferences.getInstance();
  final isTv = await isAndroidTelevision();
  final isEmulator = await isAndroidEmulator();
  final lowEnd = isTv || await isLowEndDevice();

  // Decoded artwork is the main heap consumer; 2 GB boxes cannot afford Flutter's 100 MB default.
  PaintingBinding.instance.imageCache.maximumSizeBytes = (lowEnd ? 40 : 80) << 20;
  PaintingBinding.instance.imageCache.maximumSize = lowEnd ? 300 : 600;

  if (isTv) {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  Telemetry.tags({'is_tv': isTv, 'low_end': lowEnd, 'emulator': isEmulator});
  if (Telemetry.enabled) RemoteKeyTracker.install();

  final app = ProviderScope(
    // Riverpod 3 retries failing providers forever by default, which hides errors as endless loading.
    retry: (retryCount, error) => null,
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      isTelevisionProvider.overrideWithValue(isTv),
      isEmulatorProvider.overrideWithValue(isEmulator),
      isLowEndDeviceProvider.overrideWithValue(lowEnd),
    ],
    child: const MultIptvApp(),
  );
  // SentryWidget is what lets events carry a screenshot / view hierarchy.
  runApp(Telemetry.enabled ? SentryWidget(child: app) : app);
}
