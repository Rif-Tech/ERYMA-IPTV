import 'package:shared_preferences/shared_preferences.dart';

/// Persisted daily send budget backing [Telemetry.capture]: survives a restart, resets at UTC
/// midnight. Kept separate from Telemetry so the counting logic is testable without a live Sentry
/// SDK (`Telemetry.enabled` is false in every test, since no `SENTRY_DSN` is defined there).
class TelemetryBudget {
  TelemetryBudget(this._prefs, {DateTime Function()? now}) : _now = now ?? DateTime.now;

  final SharedPreferences _prefs;
  final DateTime Function() _now;

  static const _prefix = 'telemetry_budget_';
  static const _suppressedKey = '${_prefix}suppressed';

  String get _today => _now().toUtc().toIso8601String().substring(0, 10);

  /// Cheap: only a handful of keys exist at once (one per fingerprint sent today).
  void _roll() {
    if (_prefs.getString('${_prefix}date') == _today) return;
    for (final k in _prefs.getKeys().where((k) => k.startsWith(_prefix)).toList()) {
      _prefs.remove(k);
    }
    _prefs.setString('${_prefix}date', _today);
  }

  /// True (and books it) if [key] may still send today; false suppresses it (counted, see
  /// [takeSuppressed]). [cap] is the fingerprint's own daily limit — null skips the
  /// per-fingerprint check entirely (measurements, which are already rare and user-triggered).
  /// [totalKey] names the shared pool [key] counts against, so unrelated pools (diagnostics vs.
  /// measurements) never interact.
  bool allows(String key, {int? cap, required String totalKey, required int totalCap}) {
    _roll();
    final total = _prefs.getInt(totalKey) ?? 0;
    if (total >= totalCap) {
      _noteSuppressed();
      return false;
    }
    if (cap != null) {
      final fpKey = '$_prefix$key';
      final fpCount = _prefs.getInt(fpKey) ?? 0;
      if (fpCount >= cap) {
        _noteSuppressed();
        return false;
      }
      _prefs.setInt(fpKey, fpCount + 1);
    }
    _prefs.setInt(totalKey, total + 1);
    return true;
  }

  void _noteSuppressed() => _prefs.setInt(_suppressedKey, (_prefs.getInt(_suppressedKey) ?? 0) + 1);

  /// How many sends [allows] silently dropped since the last one that got through — attached to
  /// that next event so a spike is visible instead of the trail just going quiet.
  int takeSuppressed() {
    _roll();
    final n = _prefs.getInt(_suppressedKey) ?? 0;
    if (n > 0) _prefs.remove(_suppressedKey);
    return n;
  }
}
