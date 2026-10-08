part of 'socket_service.dart';

extension SocketServiceHandleSocketConnected on SocketService {
  void _handleSocketConnected() {
    debugPrint('Connected to Socket Server');
    _isConnected = true;
    _notify();

    if (currentChatId != null) {
      joinChatRoom(currentChatId!);
    }
    onConnected?.call();
  }
}
