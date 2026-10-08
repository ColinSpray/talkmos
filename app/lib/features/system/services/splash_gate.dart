import 'dart:async';
import 'package:flutter/foundation.dart';

class SplashGate {
  SplashGate._();

  static final ValueNotifier<bool> isFinished = ValueNotifier(false);

  static void markFinished() => isFinished.value = true;

  @visibleForTesting
  static void reset() => isFinished.value = false;

  static Future<void> get whenFinished {
    if (isFinished.value) return Future.value();
    final completer = Completer<void>();
    void onChange() {
      if (!isFinished.value) return;
      isFinished.removeListener(onChange);
      if (!completer.isCompleted) completer.complete();
    }

    isFinished.addListener(onChange);
    return completer.future;
  }
}
