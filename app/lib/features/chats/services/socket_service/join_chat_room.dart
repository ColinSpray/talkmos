part of 'socket_service.dart';

extension SocketServiceJoinChatRoom on SocketService {
  void joinChatRoom(String chatId) {
    if (_socket == null || !_socket!.connected) return;
    _socket!.emit('join_chat', {'chatId': chatId});
  }
}
