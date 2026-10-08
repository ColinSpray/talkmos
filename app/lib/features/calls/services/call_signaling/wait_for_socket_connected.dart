part of 'call_signaling_service.dart';

extension CallSignalingWaitForSocketConnected on CallSignalingService {
  /// Waits (bounded) for the call socket to be connected. Returns true as soon
  /// as it is, or false if it never connects within [timeout].
  Future<bool> _waitForSocketConnected({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final sock = _socket;
    if (sock == null) return false;
    if (sock.connected) return true;

    final completer = Completer<bool>();
    void onConnect(dynamic _) {
      if (!completer.isCompleted) completer.complete(true);
    }

    sock.once('connect', onConnect);
    Future.delayed(timeout, () {
      if (!completer.isCompleted) completer.complete(sock.connected);
    });
    return completer.future;
  }
}
