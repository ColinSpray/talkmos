part of 'socket_service.dart';

extension SocketServiceUpdateMessageStatus on SocketService {
  void _updateMessageStatus(
    String messageId,
    MessageStatus newStatus,
    String? content,
  ) {
    print(content);
    if (_messages.any((m) => m.id == '')) {
      final index = _messages.indexWhere(
        (m) => m.id == '' && m.content == content,
      );
      if (index != -1) {
        final current = _messages[index].status;
        final shouldUpgrade = newStatus.index > current.index;
        if (shouldUpgrade) {
          _messages[index] = _messages[index].copyWith(status: newStatus);
          _notify();
          return;
        }
      }
    }
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      final current = _messages[index].status;
      final shouldUpgrade = newStatus.index > current.index;
      if (shouldUpgrade) {
        _messages[index] = _messages[index].copyWith(status: newStatus);
        _notify();
      }
    }
    if (onMessageStatusChanged != null) {
      onMessageStatusChanged!(messageId, newStatus);
    }
  }
}
