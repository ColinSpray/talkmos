import 'package:flutter/services.dart';

class ScreenShareService {
  ScreenShareService._();
  static final ScreenShareService instance = ScreenShareService._();

  static const MethodChannel _channel = MethodChannel(
    'com.talkmos.app/screen_share',
  );

  /// Completes once the foreground service is actually running. Throws if it
  /// never gets there — capture started anyway is refused by Android 14+.
  Future<void> start() => _channel.invokeMethod('start');

  Future<void> stop() async {
    try {
      await _channel.invokeMethod('stop');
    } catch (_) {}
  }
}
