import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The native service that keeps a call alive while the app has no UI.
///
/// Started and stopped alongside the ongoing-call notification, which it
/// shares an id with — one entry in the shade, drawn by Dart, kept in the
/// foreground by the service.
class CallForegroundService {
  const CallForegroundService._();

  static const MethodChannel _channel = MethodChannel(
    'com.talkmos.apps/call_service',
  );

  static Future<void> start() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod('start');
    } catch (e) {
      // A call that cannot hold the process up still runs, for as long as the
      // app is on screen.
      debugPrint('[CallService] could not start: $e');
    }
  }

  static Future<void> stop() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod('stop');
    } catch (e) {
      debugPrint('[CallService] could not stop: $e');
    }
  }
}
