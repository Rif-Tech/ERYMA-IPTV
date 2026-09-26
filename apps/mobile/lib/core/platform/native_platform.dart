import 'package:flutter/services.dart';

/// Bridges native-only APIs (storage stats, Picture-in-Picture) not covered by existing plugins.
class NativePlatform {
  const NativePlatform._();

  static const _channel = MethodChannel('multiptv/platform');

  /// Free/total bytes for the filesystem containing [path]. Throws on non-Android platforms.
  static Future<({int freeBytes, int totalBytes})> statFs(String path) async {
    final result = await _channel.invokeMapMethod<String, dynamic>('statFs', {'path': path});
    return (freeBytes: result!['freeBytes'] as int, totalBytes: result['totalBytes'] as int);
  }

  static Future<bool> enterPip({int width = 16, int height = 9}) async {
    final ok = await _channel.invokeMethod<bool>('enterPip', {'width': width, 'height': height});
    return ok ?? false;
  }

  static Future<bool> isInPipMode() async {
    final ok = await _channel.invokeMethod<bool>('isInPipMode');
    return ok ?? false;
  }

  /// Asks for the display mode whose refresh rate [fps] divides evenly (25 → 50 Hz); returns the
  /// rate chosen (possibly the current one), or null when the display offers none.
  static Future<double?> matchFrameRate(double fps) => _channel.invokeMethod<double>('matchFrameRate', {'fps': fps});

  /// Gives the display mode back to the system (the one in use before playback).
  static Future<void> resetFrameRate() => _channel.invokeMethod<void>('resetFrameRate');

  /// Current refresh rate, display mode, supported modes and HDR types, for measurements.
  static Future<Map<String, Object?>> displayInfo() async =>
      (await _channel.invokeMapMethod<String, Object?>('displayInfo')) ?? const {};

  /// Refresh rates ("59.940") the display offers at its current resolution, from [displayInfo]
  /// (`mode`/`modes` as `WIDTHxHEIGHT@RATE`). Empty when unknown (Android < 6, not Android).
  static Set<String> refreshRatesAtCurrentSize(Map<String, Object?> info) {
    final mode = info['mode'];
    final modes = info['modes'];
    if (mode is! String || modes is! List) return const {};
    final size = mode.split('@').first;
    return {
      for (final m in modes.whereType<String>())
        if (m.split('@').first == size) m.split('@').last,
    };
  }
}
