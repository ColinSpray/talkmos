import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceInfoService {
  static const _keyDeviceId = 'device_session_id';
  static const _channel = MethodChannel('com.talkmos.apps/device_id');

  /// Held as one future so concurrent callers on a first run can't each
  /// generate an id and register two sessions for the one device.
  static Future<String>? _idFuture;

  static Future<String> getDeviceId() => _idFuture ??= _resolveDeviceId();

  static Future<String> _resolveDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    // An install that already registered under a UUID keeps it — switching
    // it now would itself create the duplicate this is meant to prevent.
    final stored = prefs.getString(_keyDeviceId);
    if (stored != null && stored.isNotEmpty) return stored;

    final id = await _platformDeviceId() ?? const Uuid().v4();
    await prefs.setString(_keyDeviceId, id);
    return id;
  }

  static Future<String?> _platformDeviceId() async {
    if (kIsWeb) return null;
    try {
      if (Platform.isAndroid) {
        final id = await _channel.invokeMethod<String>('getInstallId');
        return (id == null || id.isEmpty) ? null : id;
      }
      if (Platform.isIOS) {
        final id = (await DeviceInfoPlugin().iosInfo).identifierForVendor;
        return (id == null || id.isEmpty) ? null : id;
      }
    } catch (_) {
      // Falls back to the generated UUID below.
    }
    return null;
  }

  static Future<String> getDeviceName() async {
    final plugin = DeviceInfoPlugin();
    try {
      if (kIsWeb) {
        final info = await plugin.webBrowserInfo;
        return info.browserName.name.isNotEmpty
            ? '${info.browserName.name} on Web'
            : 'Web Browser';
      }
      if (Platform.isAndroid) {
        final info = await plugin.androidInfo;
        return info.model.isNotEmpty ? info.model : 'Android Device';
      }
      if (Platform.isIOS) {
        final info = await plugin.iosInfo;
        return info.name.isNotEmpty ? info.name : (info.utsname.machine);
      }
      if (Platform.isMacOS) {
        final info = await plugin.macOsInfo;
        return info.model.isNotEmpty ? info.model : 'Mac';
      }
      if (Platform.isWindows) {
        final info = await plugin.windowsInfo;
        return info.productName.isNotEmpty ? info.productName : 'Windows PC';
      }
      if (Platform.isLinux) {
        final info = await plugin.linuxInfo;
        return info.prettyName.isNotEmpty ? info.prettyName : 'Linux Device';
      }
    } catch (_) {
      // Falls through to the platform-name default below.
    }
    return defaultTargetPlatform.name;
  }

  /// One of the enum values the backend's DeviceSession schema accepts
  /// ('ios' | 'android' | 'web' | 'other').
  static String getPlatform() {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'other';
  }

  static Future<Map<String, dynamic>> buildDevicePayload({
    String? fcmToken,
  }) async {
    return {
      'deviceId': await getDeviceId(),
      'deviceName': await getDeviceName(),
      'platform': getPlatform(),
      if (fcmToken != null && fcmToken.isNotEmpty) 'fcmToken': fcmToken,
    };
  }
}
