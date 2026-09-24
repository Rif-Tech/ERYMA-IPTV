import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../app/config.dart';

/// Sentry-side diagnostics: breadcrumbs (the trail of D-pad keys, screens, player and DNS steps
/// leading up to a problem), throttled events for problems worth a notification, and Sentry Logs.
///
/// Every call is a no-op without `SENTRY_DSN`, so call sites never need their own guard.
///
/// Privacy: playlist content never leaves the device (see the root CLAUDE.md). Every string that
/// reaches Sentry goes through [scrub], which keeps only scheme + host + extension of a URL (Xtream
/// URLs carry the username and password in their path or query). Titles are never passed here.
abstract final class Telemetry {
  static bool get enabled => AppConfig.sentryDsn.isNotEmpty;

  /// Applied to every [SentryFlutter.init] (see main.dart).
  static void configure(SentryFlutterOptions options) {
    options.dsn = AppConfig.sentryDsn;
    options.environment = kReleaseMode ? 'production' : 'debug';
    // Lets Sentry record the client IP of each event (asked for to correlate with ISP/DNS issues).
    options.sendDefaultPii = true;
    // A D-pad session produces a breadcrumb per key; 100 is barely a minute of browsing.
    options.maxBreadcrumbs = 200;
    options.enableLogs = true;
    // Layout only (rects, widget keys), never on-screen text: key to diagnosing clipped layouts.
    // ignore: experimental_member_use
    options.attachViewHierarchy = true;
    // Screenshots do show playlist content (titles, posters): opt-in per build.
    options.attachScreenshot = AppConfig.sentryScreenshots;
    options.screenshotQuality = SentryScreenshotQuality.low;
    // Performance tracing costs CPU on 2 GB boxes for little benefit next to breadcrumbs.
    options.tracesSampleRate = 0;
    options.beforeBreadcrumb = (crumb, _) {
      if (crumb == null) return null;
      crumb.message = crumb.message == null ? null : scrub(crumb.message!);
      crumb.data = _scrubMap(crumb.data);
      return crumb;
    };
    options.beforeSend = (event, _) {
      final message = event.message;
      if (message != null) message.formatted = scrub(message.formatted);
      for (final e in event.exceptions ?? const <SentryException>[]) {
        if (e.value != null) e.value = scrub(e.value!);
      }
      return event;
    };
    options.beforeSendLog = (log) {
      log.body = scrub(log.body);
      log.attributes = {
        for (final MapEntry(:key, :value) in log.attributes.entries)
          key: value.value is String ? SentryAttribute.string(scrub(value.value as String)) : value,
      };
      return log;
    };
  }

  // ---- Scrubbing -----------------------------------------------------------

  // Trailing punctuation belongs to the surrounding sentence, not to the URL.
  static final _url = RegExp(r'''\b(?:https?|rtmps?|rtsp|udp|rtp|mms)://[^\s"'<>]*[^\s"'<>.,;:!?)\]]''', caseSensitive: false);
  static final _ext = RegExp(r'\.([a-z0-9]{1,5})$', caseSensitive: false);

  /// Replaces each URL in [text] with `scheme://host[:port]/…[.ext]`: enough to tell which panel
  /// and which container failed, without the credentials or the stream path.
  static String scrub(String text) => text.replaceAllMapped(_url, (m) {
        final uri = Uri.tryParse(m[0]!);
        if (uri == null || uri.host.isEmpty) return '<url>';
        final last = uri.pathSegments.isEmpty ? '' : uri.pathSegments.last;
        final ext = _ext.firstMatch(last)?.group(0) ?? '';
        return '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}/…$ext';
      });

  static Object? _scrubValue(Object? v) => switch (v) {
        String s => scrub(s),
        Map m => {for (final e in m.entries) '${e.key}': _scrubValue(e.value)},
        Iterable l => [for (final e in l) _scrubValue(e)],
        _ => v,
      };

  static Map<String, dynamic>? _scrubMap(Map<String, dynamic>? m) =>
      m == null ? null : {for (final e in m.entries) e.key: _scrubValue(e.value)};

  /// `https://host:8080/…` → `host:8080`, for tags/contexts (never the path or query).
  static String? hostOf(String? url) {
    final uri = url == null ? null : Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) return null;
    return uri.hasPort ? '${uri.host}:${uri.port}' : uri.host;
  }

  /// Container extension of a stream URL (`ts`, `m3u8`, `mkv`…), or null.
  static String? extensionOf(String? url) {
    final uri = url == null ? null : Uri.tryParse(url);
    if (uri == null || uri.pathSegments.isEmpty) return null;
    return _ext.firstMatch(uri.pathSegments.last)?.group(1)?.toLowerCase();
  }

  static final _idSegment = RegExp(r'^(?:\d+|[0-9a-f-]{16,}|portal-.+)$', caseSensitive: false);

  /// `/movies/12345` → `/movies/:id`, so issues group per screen rather than per title.
  static String routeTemplate(String path) =>
      path.split('/').map((s) => _idSegment.hasMatch(s) ? ':id' : s).join('/');

  // ---- Scope ---------------------------------------------------------------

  // Also sent as Sentry Logs, so a whole session can be searched there (breadcrumbs only travel
  // with an event, 200 at most). `dpad` logs its own, richer line once the focus has settled.
  static const _loggedCategories = {'navigation', 'player', 'dns', 'layout', 'mpv', 'scroll', 'focus'};

  static void breadcrumb(String category, String message, {Map<String, Object?>? data, SentryLevel level = SentryLevel.info, String? type}) {
    if (!enabled) return;
    unawaited(Sentry.addBreadcrumb(Breadcrumb(category: category, message: message, data: data, level: level, type: type)));
    if (_loggedCategories.contains(category)) trace(category, message, {...?data, 'level': level.name});
  }

  /// Structured block shown on every later event (`playback`, `dns`, `media`…); null clears it.
  static void context(String key, Map<String, Object?>? value) {
    if (!enabled) return;
    unawaited(Future.sync(() => Sentry.configureScope((scope) async {
      if (value == null) {
        await scope.removeContexts(key);
      } else {
        await scope.setContexts(key, _scrubValue(value));
      }
    })));
  }

  /// Searchable tags (`route`, `video_codec`, `dns_mode`…); a null value removes the tag.
  static void tags(Map<String, Object?> tags) {
    if (!enabled) return;
    unawaited(Future.sync(() => Sentry.configureScope((scope) async {
      for (final MapEntry(:key, :value) in tags.entries) {
        if (value == null) {
          await scope.removeTag(key);
        } else {
          await scope.setTag(key, scrub('$value'));
        }
      }
    })));
  }

  static void user(SentryUser? user) {
    if (!enabled) return;
    unawaited(Future.sync(() => Sentry.configureScope((scope) => scope.setUser(user))));
  }

  // ---- Events --------------------------------------------------------------

  static final _lastSent = <String, DateTime>{};

  /// Sends an event (with the breadcrumb trail, tags and contexts). The same [fingerprint]
  /// (default: category + message) is sent at most once per [throttle], so a problem repeating on
  /// every frame or every HLS segment cannot flood the quota.
  static Future<SentryId?> capture(
    String category,
    String message, {
    SentryLevel level = SentryLevel.warning,
    Map<String, Object?>? data,
    List<String>? fingerprint,
    Duration throttle = const Duration(minutes: 5),
  }) async {
    if (!enabled) return null;
    final key = (fingerprint ?? [category, message]).join('|');
    final now = DateTime.now();
    final last = _lastSent[key];
    if (last != null && now.difference(last) < throttle) return null;
    _lastSent[key] = now;
    return Sentry.captureMessage(
      message,
      level: level,
      withScope: (scope) async {
        await scope.setTag('category', category);
        if (data != null) await scope.setContexts('details', _scrubValue(data));
        if (fingerprint != null) scope.fingerprint = fingerprint;
      },
    );
  }

  static void exception(Object error, StackTrace? stack, {required String category, Map<String, Object?>? data}) {
    if (!enabled) return;
    unawaited(Sentry.captureException(error, stackTrace: stack, withScope: (scope) async {
      await scope.setTag('category', category);
      if (data != null) await scope.setContexts('details', _scrubValue(data));
    }));
  }

  /// A Sentry Log only (no breadcrumb, no event): a searchable trace line in Sentry → Logs, for
  /// high-volume diagnostics such as every remote key press.
  static void trace(String category, String message, Map<String, Object?> data) {
    if (!enabled) return;
    unawaited(Future.sync(() => Sentry.logger.info(message, attributes: {
          'category': SentryAttribute.string(category),
          for (final MapEntry(:key, :value) in data.entries)
            if (value != null)
              key: switch (value) {
                bool b => SentryAttribute.bool(b),
                int i => SentryAttribute.int(i),
                double d => SentryAttribute.double(d),
                _ => SentryAttribute.string('$value'),
              },
        })));
  }

  /// Mirror of an [AppLogger] entry: breadcrumb + Sentry Log for every level, plus an event for
  /// `warn`/`error` (those already denote something that went wrong for the user).
  static void log(String level, String category, String message, Map<String, dynamic>? context) {
    if (!enabled) return;
    final sentryLevel = switch (level) {
      'error' => SentryLevel.error,
      'warn' => SentryLevel.warning,
      'debug' => SentryLevel.debug,
      _ => SentryLevel.info,
    };
    breadcrumb(category, message, data: context, level: sentryLevel);
    final attributes = {
      'category': SentryAttribute.string(category),
      for (final MapEntry(:key, :value) in (context ?? const <String, dynamic>{}).entries)
        key: switch (value) {
          bool b => SentryAttribute.bool(b),
          int i => SentryAttribute.int(i),
          double d => SentryAttribute.double(d),
          _ => SentryAttribute.string('$value'),
        },
    };
    final logger = Sentry.logger;
    unawaited(Future.sync(() => switch (level) {
          'error' => logger.error(message, attributes: attributes),
          'warn' => logger.warn(message, attributes: attributes),
          'debug' => logger.debug(message, attributes: attributes),
          _ => logger.info(message, attributes: attributes),
        }));
    if (level == 'error' || level == 'warn') {
      unawaited(capture(category, message, level: sentryLevel, data: context));
    }
  }
}
