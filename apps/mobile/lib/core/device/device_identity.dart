import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../settings/settings.dart';

enum DeviceType { mobile, tablet, tv }

@immutable
class DeviceIdentity {
  const DeviceIdentity({
    required this.mac,
    required this.key,
    required this.type,
    required this.platform,
    required this.appVersion,
  });

  /// Pseudo MAC address (`AA:BB:CC:DD:EE:FF`), stable per installation.
  final String mac;

  /// Short secret shown to the user; required together with [mac] on the portal.
  final String key;
  final DeviceType type;
  final String platform;
  final String appVersion;

  Map<String, dynamic> toJson() => {
        'mac': mac,
        'device_key': key,
        'device_type': type.name,
        'platform': platform,
        'app_version': appVersion,
      };
}

/// Formats 6 bytes as a locally-administered unicast MAC address.
String macFromBytes(List<int> bytes) {
  assert(bytes.length >= 6);
  final b = List<int>.from(bytes.take(6));
  b[0] = (b[0] | 0x02) & 0xFE;
  return b.map((e) => e.toRadixString(16).padLeft(2, '0').toUpperCase()).join(':');
}

/// Derives a pseudo MAC from any stable identifier.
String macFromSeed(String seed) => macFromBytes(sha256.convert(utf8.encode(seed)).bytes);

String generateDeviceKey([Random? random]) {
  const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final rnd = random ?? Random.secure();
  return List.generate(6, (_) => alphabet[rnd.nextInt(alphabet.length)]).join();
}

/// Stable key for a hardware seed, so a reinstall yields the same MAC/key pair.
String keyFromSeed(String seed) {
  const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final digest = sha256.convert(utf8.encode('key:$seed')).bytes;
  return List.generate(6, (i) => alphabet[digest[i] % alphabet.length]).join();
}

class DeviceIdentityService {
  DeviceIdentityService({FlutterSecureStorage? storage, this.prefs})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _macKey = 'device.mac';
  static const _keyKey = 'device.key';
  final FlutterSecureStorage _storage;

  /// Fallback store: secure storage is unavailable on some TV boxes / emulators.
  final SharedPreferences? prefs;

  Future<String?> _read(String key) async {
    try {
      final v = await _storage.read(key: key);
      if (v != null) return v;
    } catch (e) {
      debugPrint('secure storage read failed: $e');
    }
    return prefs?.getString(key);
  }

  Future<void> _write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      debugPrint('secure storage write failed: $e');
    }
    await prefs?.setString(key, value);
  }

  Future<DeviceIdentity> load() async {
    final info = DeviceInfoPlugin();
    final package = await PackageInfo.fromPlatform();

    var mac = await _read(_macKey);
    var key = await _read(_keyKey);
    var type = DeviceType.mobile;
    var platform = defaultTargetPlatform.name;
    String? seed;

    if (!kIsWeb && Platform.isAndroid) {
      final android = await info.androidInfo;
      platform = 'android';
      seed = 'android:${android.id}:${android.fingerprint}';
      type = await _androidDeviceType(android);
    } else if (!kIsWeb && Platform.isIOS) {
      final ios = await info.iosInfo;
      platform = 'ios';
      final vendorId = ios.identifierForVendor;
      if (vendorId != null) seed = 'ios:$vendorId';
      type = ios.model.toLowerCase().contains('ipad') ? DeviceType.tablet : DeviceType.mobile;
    }
    // With a hardware seed the identity is a pure function of the device: never let a stale or
    // half-decrypted stored value win, otherwise debug/release installs end up with mismatched keys.
    if (seed != null) {
      mac = macFromSeed(seed);
      key = keyFromSeed(seed);
    } else {
      mac ??= macFromBytes(_randomBytes(6));
      key ??= generateDeviceKey();
    }

    await _write(_macKey, mac);
    await _write(_keyKey, key);

    return DeviceIdentity(
      mac: mac,
      key: key,
      type: type,
      platform: platform,
      appVersion: package.version,
    );
  }

  Future<DeviceType> _androidDeviceType(AndroidDeviceInfo android) async {
    if (await isAndroidTelevision()) return DeviceType.tv;
    final view = WidgetsBinding.instance.platformDispatcher.views.firstOrNull;
    if (view != null) {
      final shortest = view.physicalSize.shortestSide / view.devicePixelRatio;
      if (shortest >= 600) return DeviceType.tablet;
    }
    return DeviceType.mobile;
  }

  static List<int> _randomBytes(int n) {
    final r = Random.secure();
    return List.generate(n, (_) => r.nextInt(256));
  }
}

/// Uses Android system features exposed by device_info_plus to detect leanback devices.
Future<bool> isAndroidTelevision() async {
  if (kIsWeb || !Platform.isAndroid) return false;
  try {
    final android = await DeviceInfoPlugin().androidInfo;
    final features = android.systemFeatures;
    return features.contains('android.software.leanback') ||
        features.contains('android.hardware.type.television');
  } on PlatformException {
    return false;
  }
}

Future<bool> isAndroidEmulator() async {
  if (kIsWeb || !Platform.isAndroid) return false;
  try {
    return !(await DeviceInfoPlugin().androidInfo).isPhysicalDevice;
  } on PlatformException {
    return false;
  }
}

final deviceIdentityProvider = FutureProvider<DeviceIdentity>((ref) {
  return DeviceIdentityService(prefs: ref.watch(sharedPreferencesProvider)).load();
});
