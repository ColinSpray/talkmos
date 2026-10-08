part of 'socket_service.dart';

extension SocketServiceHandleLocalMessagePinned on SocketService {
  void _handleLocalMessagePinned(
    String chatId,
    String messageId,
    bool isPinned,
    DateTime? pinnedAt,
    ChatMessageModel? message,
  ) {
    bool changed = false;
    for (int i = 0; i < _messages.length; i++) {
      if (_messages[i].id == messageId) {
        _messages[i] = _messages[i].copyWith(
          isPinned: isPinned,
          pinnedAt: pinnedAt,
        );
        changed = true;
        break;
      }
    }
    if (changed) _notify();
  }
}
