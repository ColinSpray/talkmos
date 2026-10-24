import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../../core/notifications/notification_sounds.dart';

/// Bridge to Android's `RingtoneManager` for reading the phone's default
/// ringtone and opening the system ringtone picker.
class RingtoneService {
  const RingtoneService._();

  static const MethodChannel _channel = MethodChannel(
    'com.talkmos.apps/ringtone',
  );

  static Future<NotificationSoundSetting?> systemRingtone({
    bool forNotification = false,
  }) async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'getSystemRingtone',
        {'type': forNotification ? 'notification' : 'ringtone'},
      );
      final uri = result?['uri']?.toString();
      if (uri == null || uri.isEmpty) return null;
      return NotificationSoundSetting(
        mode: SoundMode.system,
        uri: uri,
        title: result?['title']?.toString(),
      );
    } catch (e) {
      debugPrint('[Ringtone] systemRingtone failed: $e');
      return null;
    }
  }

  /// Opens the OS ringtone picker. Resolves to null if the user backs out.
  static Future<NotificationSoundSetting?> pick({String? currentUri}) async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'pickRingtone',
        {'currentUri': currentUri},
      );
      final uri = result?['uri']?.toString();
      if (uri == null || uri.isEmpty) return null;
      return NotificationSoundSetting(
        mode: SoundMode.custom,
        uri: uri,
        title: result?['title']?.toString(),
      );
    } catch (e) {
      debugPrint('[Ringtone] pick failed: $e');
      return null;
    }
  }
}
