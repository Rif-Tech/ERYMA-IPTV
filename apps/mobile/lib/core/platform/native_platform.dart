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
}
