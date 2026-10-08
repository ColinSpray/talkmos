part of 'socket_service.dart';

extension SocketServiceHandleMessageDeleted on SocketService {
  void _handleMessageDeletedEvent(dynamic data) {
    debugPrint('Socket message_deleted data: $data');
    final messageId = data['messageId'] as String?;
    final chatId = data['chatId'] as String?;
    final forEveryone = data['forEveryone'] as bool? ?? false;
    if (messageId != null && chatId != null) {
      _handleLocalMessageDeleted(chatId, messageId, forEveryone);
      if (onMessageDeleted != null) {
        onMessageDeleted!(chatId, messageId, forEveryone);
      }
    }
  }
}
