import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show AppLifecycleListener, AppLifecycleState;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../device/device_identity.dart';
import 'log_sync.dart';
import 'telemetry.dart';

/// Buffers diagnostic log entries and flushes them to `device-logs` (Supabase), so a real device's
/// failures (decoder fallback, import/pairing errors, ...) are visible to an admin/Claude session
/// querying the `app_logs` table, without the user having to report them by hand. Retained 48h
/// server-side (see the `app_logs` migration).
///
/// This does NOT cover native crashes (a 4K decode segfault never reaches Dart at all) — that is
/// Sentry's job (see main.dart / AppConfig.sentryDsn). The two are complementary: this table is
/// for "the app kept running but something failed", Sentry is for "the app stopped running".
class AppLogger {
  AppLogger(this.ref);
  final Ref ref;

  static const _flushDelay = Duration(seconds: 15);
  // Bounded so a long offline stretch cannot grow this unboundedly; oldest entries are dropped
  // first (a rolling window of recent activity is far more useful for diagnosis than the very
  // first thing that went wrong hours ago).
  static const _maxBuffered = 500;

  final _buffer = <LogEntry>[];
  Timer? _timer;
  int _seq = 0;

  void debug(String category, String message, {Map<String, dynamic>? context}) => _log('debug', category, message, context);
  void info(String category, String message, {Map<String, dynamic>? context}) => _log('info', category, message, context);
  void warn(String category, String message, {Map<String, dynamic>? context}) => _log('warn', category, message, context);
  void error(String category, String message, {Map<String, dynamic>? context}) => _log('error', category, message, context);

  void _log(String level, String category, String message, Map<String, dynamic>? context) {
    // Always visible locally too, exactly like the debugPrint calls this complements.
    debugPrint('[$level/$category] $message');
    Telemetry.log(level, category, message, context);
    final uuid = ref.read(deviceIdentityProvider).value?.uuid;
    final entry = LogEntry(
      level: level,
      category: category,
      message: message,
      context: context,
      clientId: '${uuid ?? 'unknown'}-${DateTime.now().microsecondsSinceEpoch}-${_seq++}',
      createdAt: DateTime.now(),
    );
    _buffer.add(entry);
    if (_buffer.length > _maxBuffered) _buffer.removeRange(0, _buffer.length - _maxBuffered);
    _timer?.cancel();
    _timer = Timer(_flushDelay, flush);
  }

  /// Uploads the buffer now (called on schedule, and best-effort when the app backgrounds).
  Future<void> flush() async {
    _timer?.cancel();
    _timer = null;
    if (_buffer.isEmpty) return;
    final batch = List<LogEntry>.of(_buffer);
    final ok = await ref.read(logSyncProvider).push(batch);
    // Only drop what was actually sent: entries logged during the network round-trip must stay.
    if (ok) _buffer.removeRange(0, batch.length);
  }
}

final logSyncProvider = Provider<LogSync>((ref) {
  return LogSync(auth: () {
    final uuid = ref.read(deviceIdentityProvider).value?.uuid;
    if (uuid == null) return null;
    return (uuid: uuid, secret: ref.read(installSecretProvider).value);
  });
});

final appLoggerProvider = Provider<AppLogger>((ref) {
  final logger = AppLogger(ref);
  ref.onDispose(() {
    logger._timer?.cancel();
    unawaited(logger.flush());
  });
  return logger;
});

/// The debounce alone would leave anything logged in the last [AppLogger._flushDelay] stranded
/// when the app is killed in the background (the common case on Android, unlike the provider
/// dispose above, which effectively never runs). Watched once at the app root (see app.dart) to
/// flush on every backgrounding, not just app exit.
final appLogLifecycleProvider = Provider<void>((ref) {
  final listener = AppLifecycleListener(
    onStateChange: (state) {
      if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
        unawaited(ref.read(appLoggerProvider).flush());
      }
    },
  );
  ref.onDispose(listener.dispose);
});
