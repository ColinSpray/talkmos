part of 'chat_service.dart';

extension ChatServiceSetConversationPreferences on ChatService {
  Future<Map<String, dynamic>> setConversationPreferences(
    String chatId, {
    bool? isPinned,
    bool? isMuted,
    bool? isArchived,
    bool? hidden,
  }) async {
    final payload = {
      if (isPinned != null) 'isPinned': isPinned,
      if (isMuted != null) 'isMuted': isMuted,
      if (isArchived != null) 'isArchived': isArchived,
      if (hidden != null) 'hidden': hidden,
    };
    try {
      final response = await HttpService.patch(
        ApiEndpoints.conversationPreferences(chatId),
        body: payload,
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && body['success'] == true) {
        return Map<String, dynamic>.from(body['data']);
      }
      throw Exception(body['message'] ?? 'Failed to update preferences');
    } catch (e) {
      rethrow;
    }
  }
}
