part of 'socket_service.dart';

extension SocketServiceCheckUserOnline on SocketService {
  void checkUserOnline(String userId) {
    if (_socket == null || !_socket!.connected) return;
    _socket!.emit('is_user_online', {'userId': userId});
  }
}
