part of 'socket_service.dart';

extension SocketServiceHandleMessageEdited on SocketService {
  void _handleMessageEditedEvent(dynamic data) {
    debugPrint('Socket message_edited data: $data');
    final messageId = data['messageId'] as String?;
    final chatId = data['chatId'] as String?;
    final content = data['content'] as String?;
    final editedAtStr = data['editedAt'] as String?;
    final editedAt = editedAtStr != null
        ? DateTime.tryParse(editedAtStr)
        : null;
    if (messageId != null && chatId != null && content != null) {
      onMessageEdited?.call(chatId, messageId, content, editedAt);
    }
  }
}
