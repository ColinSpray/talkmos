part of 'socket_service.dart';

extension SocketServiceEditMessage on SocketService {
  void editMessage(String chatId, String messageId, String content) {
    if (_socket == null || !_socket!.connected) return;
    _socket!.emit('edit_message', {
      'chatId': chatId,
      'messageId': messageId,
      'content': content,
    });
  }
}
