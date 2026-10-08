import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class CallActivityService {
  static const _activityChannel = MethodChannel(
    'com.talkmos.app/call_activity',
  );
  static const _eventsChannel = MethodChannel('com.talkmos.app/call_events');

  static final StreamController<Map<String, dynamic>> _acceptController =
      StreamController<Map<String, dynamic>>.broadcast();
  static final StreamController<Map<String, dynamic>> _declineController =
      StreamController<Map<String, dynamic>>.broadcast();

  static Stream<Map<String, dynamic>> get onCallAccepted =>
      _acceptController.stream;
  static Stream<Map<String, dynamic>> get onCallDeclined =>
      _declineController.stream;

  static bool _initialized = false;

  static void initialize() {
    if (_initialized) return;
    _initialized = true;

    _eventsChannel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onCallAccepted':
          final args = Map<String, dynamic>.from(call.arguments as Map);
          _acceptController.add(args);
          break;
        case 'onCallDeclined':
          final args = Map<String, dynamic>.from(call.arguments as Map);
          _declineController.add(args);
          break;
      }
    });
  }

  /// Launches the dedicated Kotlin CallActivity over the lock screen.
  static Future<void> launchCallActivity({
    required String callId,
    required String callerId,
    String? callerName,
    String callType = 'audio',
  }) async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        await _activityChannel.invokeMethod('launchCallActivity', {
          'callId': callId,
          'callerId': callerId,
          'callerName': callerName ?? 'Unknown Caller',
          'callType': callType,
        });
      } catch (e) {
        debugPrint('[CallActivityService] launchCallActivity error: $e');
      }
    }
  }

  /// Finishes/closes the dedicated Kotlin CallActivity when call ends.
  static Future<void> finishCallActivity() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        await _activityChannel.invokeMethod('finishCallActivity');
      } catch (e) {
        debugPrint('[CallActivityService] finishCallActivity error: $e');
      }
    }
  }
}
