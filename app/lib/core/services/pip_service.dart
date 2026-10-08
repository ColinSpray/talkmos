import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class PipService {
  PipService._();
  static final PipService instance = PipService._();

  static const MethodChannel _channel = MethodChannel('com.talkmos.app/pip');

  final ValueNotifier<bool> isInPipMode = ValueNotifier(false);

  final _actionController = StreamController<String>.broadcast();
  Stream<String> get onAction => _actionController.stream;

  bool _handlerSet = false;

  void _ensureHandler() {
    if (_handlerSet) return;
    _handlerSet = true;
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onPipModeChanged':
          isInPipMode.value = call.arguments as bool;
        case 'onPipAction':
          _actionController.add(call.arguments as String);
      }
    });
  }

  Future<void> updateCallState({
    required bool active,
    required bool isVideo,
    bool isMicMuted = false,
    bool isSpeakerOn = false,
  }) async {
    _ensureHandler();
    try {
      await _channel.invokeMethod('updateCallState', {
        'active': active,
        'isVideo': isVideo,
        'isMicMuted': isMicMuted,
        'isSpeakerOn': isSpeakerOn,
      });
    } catch (_) {
      // MissingPluginException on iOS/unsupported platforms — no PiP there.
    }
  }

  Future<bool> enterPip() async {
    _ensureHandler();
    try {
      final result = await _channel.invokeMethod<bool>('enterPip');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }
}
