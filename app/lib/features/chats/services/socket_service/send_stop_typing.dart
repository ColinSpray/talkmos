part of 'socket_service.dart';

extension SocketServiceSendStopTyping on SocketService {
  void sendStopTyping(String chatId) {
    if (_socket == null || !_socket!.connected) return;
    _socket!.emit('stop_typing', {'conversationId': chatId});
  }
}
