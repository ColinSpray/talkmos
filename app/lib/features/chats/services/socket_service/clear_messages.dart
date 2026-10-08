part of 'socket_service.dart';

extension SocketServiceClearMessages on SocketService {
  void clearMessages() {
    _messages.clear();
    _notify();
  }
}
