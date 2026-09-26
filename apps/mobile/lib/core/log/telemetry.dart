import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/config.dart';
import 'telemetry_budget.dart';

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

  /// Set once at start-up ([main.dart]), once `SharedPreferences` is ready: backs the daily send
  /// budget below. `capture` called before this is set (breadcrumbs and `trace` never need it)
  /// simply skips budget enforcement rather than block or throw.
  static TelemetryBudget? _budget;
  static void init(SharedPreferences prefs) => _budget = TelemetryBudget(prefs);

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
    // A view hierarchy runs ~800 KB: on the free plan's 1 GB attachment quota, joining it to every
    // one of the diagnostics below (dpad-stuck, degraded playback…) would empty it in a handful of
    // sessions. Only layout events — what it exists to diagnose — and native crashes get one.
    // ignore: experimental_member_use
    options.beforeCaptureViewHierarchy = (event, hint, debounce) async =>
        event.tags?['category'] == 'layout' || (event.exceptions?.isNotEmpty ?? false);
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
  static const _loggedCategories = {'navigation', 'player', 'dns', 'layout', 'mpv', 'scroll', 'focus', 'import', 'categories'};

  static void breadcrumb(String category, String message, {Map<String, Object?>? data, SentryLevel level = SentryLevel.info, String? type}) {
    if (!enabled) return;
    unawaited(Sentry.addBreadcrumb(Breadcrumb(category: category, message: message, data: data, level: level, type: type)));
    // Breadcrumbs are cheap and capped at 200 by the SDK; Sentry Logs count against the plan's own
    // quota. `debug` marks the high-frequency, low-value ones (periodic stats, seeks…) that are
    // only ever worth reading as part of an event's trail, never searched for on their own.
    if (level != SentryLevel.debug && _loggedCategories.contains(category)) trace(category, message, {...?data, 'level': level.name});
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

  // ---- Daily send budget -----------------------------------------------
  //
  // A handful of testers on the free Sentry plan (5 000 events/month) must never be able to flood
  // it: on top of the per-fingerprint [throttle] above, [TelemetryBudget] resets a budget of its
  // own every day, persisted so it survives a restart. Diagnostics
  // (dpad/layout/scroll/categories/import) get 1 send per fingerprint per day; logged errors get
  // 3; both count against a shared 15/day total. Measurements ("Mesures", user-triggered) have
  // their own, separate 10/day budget instead, since they are opt-in and already rare. Crashes
  // ([exception]) and reports ([feedback]) are never throttled or budgeted — a plan can pin its
  // rules to only govern automatic diagnostics.
  static const _dailyTotalCap = 15;
  static const _dailyMeasurementCap = 10;

  /// Sends an event (with the breadcrumb trail, tags and contexts). The same [fingerprint]
  /// (default: category + message) is sent at most once per [throttle], so a problem repeating on
  /// every frame or every HLS segment cannot flood the quota — then the daily budget above applies.
  /// [measurement] is a user-triggered "Mesures" report: its own budget, no per-fingerprint cap,
  /// [errorBudget] widens a diagnostic's 1/day cap to 3 (an actual logged error, see [log]).
  static Future<SentryId?> capture(
    String category,
    String message, {
    SentryLevel level = SentryLevel.warning,
    Map<String, Object?>? data,
    List<String>? fingerprint,
    Duration throttle = const Duration(minutes: 5),
    List<SentryAttachment> attachments = const [],
    bool measurement = false,
    bool errorBudget = false,
  }) async {
    if (!enabled) return null;
    final key = (fingerprint ?? [category, message]).join('|');
    final now = DateTime.now();
    final last = _lastSent[key];
    if (last != null && now.difference(last) < throttle) return null;
    final budget = _budget;
    final allowed = budget == null ||
        (measurement
            ? budget.allows(key, totalKey: 'measure_total', totalCap: _dailyMeasurementCap)
            : budget.allows(key, cap: errorBudget ? 3 : 1, totalKey: 'total', totalCap: _dailyTotalCap));
    if (!allowed) return null;
    _lastSent[key] = now;
    final suppressed = budget?.takeSuppressed() ?? 0;
    return Sentry.captureMessage(
      message,
      level: level,
      withScope: (scope) async {
        await scope.setTag('category', category);
        if (data != null || suppressed > 0) {
          final details = <String, Object?>{...?data, if (suppressed > 0) 'budget.suppressed': suppressed};
          await scope.setContexts('details', _scrubValue(details));
        }
        if (fingerprint != null) scope.fingerprint = fingerprint;
        for (final attachment in attachments) {
          scope.addAttachment(attachment);
        }
      },
    );
  }

  /// A user report ("Signaler un problème"), as a plain event rather than Sentry's separate User
  /// Feedback API: that API needs a paid plan to even show up, and drops breadcrumbs from the
  /// event, which this app carried around as a `breadcrumbs.txt` attachment instead. A regular
  /// `captureMessage` gets the trail for free (native to every event) and works on every plan; a
  /// timestamp-unique [fingerprint] keeps each report its own issue instead of merging into one
  /// (every report shares the same call site, so Sentry's default stack-based grouping would
  /// otherwise fold them together) — the point being an email alert per report, not per user.
  static Future<SentryId?> feedback(String message, {Map<String, Object?>? data}) async {
    if (!enabled) return null;
    return Sentry.captureMessage(
      scrub(message),
      level: SentryLevel.warning,
      withScope: (scope) async {
        await scope.setTag('category', 'user_report');
        if (data != null) await scope.setContexts('details', _scrubValue(data));
        scope.fingerprint = ['user-report', DateTime.now().toIso8601String()];
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
      unawaited(capture(category, message, level: sentryLevel, data: context, fingerprint: ['log', category, messageKind(message)], errorBudget: true));
    }
  }

  /// [message] without URLs or numbers, so one kind of problem groups into one issue. Every
  /// [AppLogger] event is sent from the same call stack: without an explicit fingerprint Sentry
  /// grouped them by that stack, merging unrelated problems (FLUTTER-E held decoder fallbacks and a
  /// hero playback failure).
  static String messageKind(String message) {
    final kind = scrub(message).replaceAll(RegExp(r'\d+'), '#').trim();
    return kind.length > 120 ? kind.substring(0, 120) : kind;
  }
}
