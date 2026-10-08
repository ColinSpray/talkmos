part of 'socket_service.dart';

extension SocketServiceHandleMessagePinned on SocketService {
  void _handleMessagePinnedEvent(dynamic data) {
    debugPrint('Socket message_pinned data: $data');
    final messageId = data['messageId'] as String?;
    final chatId = data['chatId'] as String?;
    final isPinned = data['isPinned'] as bool? ?? false;
    final pinnedAtStr = data['pinnedAt'] as String?;
    final pinnedAt = pinnedAtStr != null
        ? DateTime.tryParse(pinnedAtStr)
        : null;
    ChatMessageModel? msg;
    if (data['message'] != null) {
      try {
        msg = ChatMessageModel.fromJson(
          Map<String, dynamic>.from(data['message']),
        );
      } catch (_) {}
    }
    if (messageId != null && chatId != null) {
      _handleLocalMessagePinned(chatId, messageId, isPinned, pinnedAt, msg);
      if (onMessagePinned != null) {
        onMessagePinned!(chatId, messageId, isPinned, pinnedAt, msg);
      }
    }
  }
}
