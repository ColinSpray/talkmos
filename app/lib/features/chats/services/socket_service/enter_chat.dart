part of 'socket_service.dart';

extension SocketServiceEnterChat on SocketService {
  void enterChat(String chatId, String peerId) {
    if (chatId.isEmpty) return;
    currentChatId = chatId;
    currentPeerId = peerId;
    clearMessages();
    joinChatRoom(chatId);
  }
}
