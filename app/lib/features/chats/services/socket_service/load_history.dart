part of 'socket_service.dart';

extension SocketServiceLoadHistory on SocketService {
  void loadHistory(List<ChatMessageModel> history) {
    final existingIds = _messages.map((m) => m.id).toSet();
    final newMessages = history
        .where((m) => !existingIds.contains(m.id))
        .toList();
    _messages.insertAll(0, newMessages);
    _notify();
  }
}
