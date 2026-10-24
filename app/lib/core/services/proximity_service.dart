import 'package:flutter/services.dart';

/// Blanks the screen while the phone is held to the ear on a voice call, the
/// way the dialler does — which also keeps a cheek off the hang-up button.
///
/// Held only while the call is on the earpiece: on speaker, or on a video
/// call, the user is looking at the screen.
class ProximityService {
  ProximityService._();
  static final ProximityService instance = ProximityService._();

  static const MethodChannel _channel = MethodChannel(
    'com.talkmos.apps/proximity',
  );

  bool _enabled = false;

  Future<void> setEnabled(bool enabled) async {
    if (_enabled == enabled) return;
    try {
      await _channel.invokeMethod('setEnabled', enabled);
      _enabled = enabled;
    } catch (_) {
      // MissingPluginException on platforms without a handler.
    }
  }
}
