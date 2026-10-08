part of 'chat_service.dart';

extension ChatServiceMarkRead on ChatService {
  Future<void> markRead(String chatId) async {
    try {
      final response = await HttpService.patch(
        ApiEndpoints.conversationRead(chatId),
      );
      if (response.statusCode != 200 && response.statusCode != 204) {
        debugPrint('[ChatService] markRead failed: ${response.body}');
      }
    } catch (e) {
      debugPrint('[ChatService] markRead error: $e');
    }
  }
}
