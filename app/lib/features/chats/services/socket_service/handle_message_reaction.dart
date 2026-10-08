part of 'socket_service.dart';

extension SocketServiceHandleMessageReaction on SocketService {
  void _handleMessageReactionEvent(dynamic data) {
    debugPrint('Socket message_reaction data: $data');
    final chatId = data['chatId'] as String?;
    final messageId = data['messageId'] as String?;
    final userId = data['userId'] as String?;
    final emoji = data['emoji'] as String?;
    if (chatId != null && messageId != null && userId != null) {
      onMessageReacted?.call(chatId, messageId, userId, emoji);
    }
  }
}
