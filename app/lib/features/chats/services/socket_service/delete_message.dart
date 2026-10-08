part of 'socket_service.dart';

extension SocketServiceDeleteMessage on SocketService {
  void deleteMessage(String chatId, String messageId, bool forEveryone) {
    if (_socket == null || !_socket!.connected) return;
    _socket!.emit('delete_message', {
      'chatId': chatId,
      'messageId': messageId,
      'forEveryone': forEveryone,
    });
  }
}
