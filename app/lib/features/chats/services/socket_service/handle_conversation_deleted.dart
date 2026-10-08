part of 'socket_service.dart';

extension SocketServiceHandleConversationDeleted on SocketService {
  void _handleConversationDeleted(dynamic data) {
    try {
      final map = Map<String, dynamic>.from(data as Map);
      final chatId = map['chatId']?.toString() ?? '';
      if (chatId.isEmpty) return;
      onConversationDeleted?.call(chatId, map['deletedBy']?.toString() ?? '');
    } catch (e) {
      debugPrint('Error parsing conversation_deleted: $e');
    }
  }
}
