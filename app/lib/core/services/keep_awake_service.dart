import 'package:flutter/services.dart';

/// Holds the display on for as long as a video call is up. Nobody touches the
/// screen during a call, so the system screen timeout would otherwise blank it
/// mid-conversation. Audio calls are left alone — there is nothing to look at.
class KeepAwakeService {
  KeepAwakeService._();
  static final KeepAwakeService instance = KeepAwakeService._();

  static const MethodChannel _channel = MethodChannel(
    'com.talkmos.apps/keep_awake',
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
