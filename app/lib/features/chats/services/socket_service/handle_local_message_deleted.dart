part of 'socket_service.dart';

extension SocketServiceHandleLocalMessageDeleted on SocketService {
  void _handleLocalMessageDeleted(
    String chatId,
    String messageId,
    bool forEveryone,
  ) {
    bool changed = false;
    for (int i = 0; i < _messages.length; i++) {
      if (_messages[i].id == messageId) {
        if (forEveryone) {
          _messages[i] = _messages[i].copyWith(
            content: 'This message was deleted',
            deletedForEveryone: true,
          );
        } else {
          _messages.removeAt(i);
        }
        changed = true;
        break;
      }
    }
    if (changed) _notify();
  }
}
