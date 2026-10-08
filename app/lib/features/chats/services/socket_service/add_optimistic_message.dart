part of 'socket_service.dart';

extension SocketServiceAddOptimisticMessage on SocketService {
  void addOptimisticMessage(ChatMessageModel message) {
    _messages.add(message);
    _notify();
  }
}
