part of 'socket_service.dart';

extension SocketServiceMarkMessagesRead on SocketService {
  void markMessagesRead(String chatId, String currentUserId, String peerId) {
    if (_socket == null || !_socket!.connected) return;
    if (chatId.isEmpty) return;

    _socket!.emit('messages_read', {'chatId': chatId, 'senderId': peerId});

    // Optimistic local update, scoped to the chat we just opened.
    _markAllMessagesReadBy(currentUserId, chatId);
  }
}
