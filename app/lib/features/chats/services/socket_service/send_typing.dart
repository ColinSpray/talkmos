part of 'socket_service.dart';

extension SocketServiceSendTyping on SocketService {
  void sendTyping(String chatId) {
    if (_socket == null || !_socket!.connected) return;
    _socket!.emit('typing', {'conversationId': chatId});
  }
}
