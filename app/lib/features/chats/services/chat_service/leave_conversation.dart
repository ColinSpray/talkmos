part of 'chat_service.dart';

extension ChatServiceLeaveConversation on ChatService {
  Future<void> leaveConversation(String chatId) async {
    try {
      final response = await HttpService.delete(
        ApiEndpoints.leaveConversation(chatId),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode != 200 || body['success'] != true) {
        throw Exception(body['message'] ?? 'Failed to leave conversation');
      }
    } catch (e) {
      rethrow;
    }
  }
}
