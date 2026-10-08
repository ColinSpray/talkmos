part of 'socket_service.dart';

extension SocketServiceDisconnect on SocketService {
  void disconnect() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;
    _currentUserId = null;
    _currentToken = null;
    if (_socket != null) {
      try {
        _socket!.disconnect();
      } catch (e) {
        debugPrint('[SocketService] disconnect: $e');
      }
      _socket = null;
    }
    _isConnected = false;
    _messages.clear();
    _notify();
  }
}
