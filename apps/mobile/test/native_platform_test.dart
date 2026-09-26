import 'package:flutter_test/flutter_test.dart';
import 'package:multiptv/core/platform/native_platform.dart';

void main() {
  group('refreshRatesAtCurrentSize', () {
    test('the Mi TV box: one rate, nothing to switch to', () {
      expect(NativePlatform.refreshRatesAtCurrentSize({'mode': '1920x1080@59.940', 'modes': ['1920x1080@59.940']}), {'59.940'});
    });

    test('only the modes of the current resolution count', () {
      final rates = NativePlatform.refreshRatesAtCurrentSize({
        'mode': '1920x1080@59.940',
        'modes': ['1920x1080@59.940', '1920x1080@50.000', '1920x1080@23.976', '3840x2160@60.000'],
      });
      expect(rates, {'59.940', '50.000', '23.976'});
    });

    test('unknown display: empty (the setting stays available)', () {
      expect(NativePlatform.refreshRatesAtCurrentSize(const {}), isEmpty);
      expect(NativePlatform.refreshRatesAtCurrentSize({'refreshRate': 60.0}), isEmpty);
    });
  });
}
