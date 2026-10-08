part of 'socket_service.dart';

extension SocketServiceMarkAllMessagesReadBy on SocketService {
  void _markAllMessagesReadBy(String readerId, [String? chatId]) {
    bool changed = false;
    for (int i = 0; i < _messages.length; i++) {
      final msg = _messages[i];
      if (chatId != null && msg.chatId != chatId) continue;
      if (msg.senderId != readerId && msg.status != MessageStatus.read) {
        _messages[i] = msg.copyWith(status: MessageStatus.read);
        changed = true;
      }
    }
    if (changed) _notify();
    onMessagesRead?.call(readerId, chatId);
  }
}
