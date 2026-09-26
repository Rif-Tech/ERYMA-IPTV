import 'package:flutter_test/flutter_test.dart';
import 'package:multiptv/core/log/telemetry_budget.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Testers on the free Sentry plan (5 000 events/month) must never be able to flood it: the
/// per-fingerprint daily cap and the shared daily total this backs.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<TelemetryBudget> budget({DateTime Function()? now}) async {
    SharedPreferences.setMockInitialValues({});
    return TelemetryBudget(await SharedPreferences.getInstance(), now: now);
  }

  test('a fingerprint sends up to its own cap, then is suppressed', () async {
    final b = await budget();
    expect(b.allows('a', cap: 1, totalKey: 'total', totalCap: 15), isTrue);
    expect(b.allows('a', cap: 1, totalKey: 'total', totalCap: 15), isFalse);
    expect(b.allows('a', cap: 3, totalKey: 'other-total', totalCap: 15), isTrue); // a different fingerprint key
  });

  test('the shared total caps every fingerprint together', () async {
    final b = await budget();
    for (var i = 0; i < 2; i++) {
      expect(b.allows('fp$i', cap: 3, totalKey: 'total', totalCap: 2), isTrue);
    }
    // The total is now at its cap: a fresh fingerprint (still under its own per-fingerprint cap)
    // is suppressed anyway.
    expect(b.allows('fp2', cap: 3, totalKey: 'total', totalCap: 2), isFalse);
  });

  test('measurements (no per-fingerprint cap) only count against their own total', () async {
    final b = await budget();
    for (var i = 0; i < 10; i++) {
      expect(b.allows('measure', totalKey: 'measure_total', totalCap: 10), isTrue);
    }
    expect(b.allows('measure', totalKey: 'measure_total', totalCap: 10), isFalse);
    // A diagnostic's own pool is untouched by the measurement pool above.
    expect(b.allows('diag', cap: 1, totalKey: 'total', totalCap: 15), isTrue);
  });

  test('suppressed sends are counted and cleared once read', () async {
    final b = await budget();
    b.allows('a', cap: 1, totalKey: 'total', totalCap: 15);
    b.allows('a', cap: 1, totalKey: 'total', totalCap: 15); // suppressed
    b.allows('a', cap: 1, totalKey: 'total', totalCap: 15); // suppressed
    expect(b.takeSuppressed(), 2);
    expect(b.takeSuppressed(), 0); // consumed
  });

  test('the budget resets on a new UTC day', () async {
    var day = DateTime.utc(2026, 9, 26, 23);
    final b = await budget(now: () => day);
    expect(b.allows('a', cap: 1, totalKey: 'total', totalCap: 15), isTrue);
    expect(b.allows('a', cap: 1, totalKey: 'total', totalCap: 15), isFalse);
    day = DateTime.utc(2026, 9, 27, 1);
    expect(b.allows('a', cap: 1, totalKey: 'total', totalCap: 15), isTrue);
  });
}
