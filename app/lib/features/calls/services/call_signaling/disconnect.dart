part of 'call_signaling_service.dart';

extension CallSignalingDisconnect on CallSignalingService {
  void disconnect() {
    cleanUp();
    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;
    _currentUserId = null;
    _currentToken = null;
    _currentUserName = null;
    try {
      _socket?.disconnect();
    } catch (e) {
      debugPrint('[CallSignalingService] disconnect: $e');
    }
    _socket = null;
  }
}
