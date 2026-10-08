part of 'socket_service.dart';

extension SocketServiceLeaveChat on SocketService {
  void leaveChat() {
    currentChatId = null;
    currentPeerId = null;
    clearMessages();
  }
}
