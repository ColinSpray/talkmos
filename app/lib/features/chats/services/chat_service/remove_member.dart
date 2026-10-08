part of 'chat_service.dart';

extension ChatServiceRemoveMember on ChatService {
  Future<void> removeMember(String chatId, String userId) async {
    try {
      final response = await HttpService.delete(
        ApiEndpoints.conversationMember(chatId, userId),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode != 200 || body['success'] != true) {
        throw Exception(body['message'] ?? 'Failed to remove member');
      }
    } catch (e) {
      rethrow;
    }
  }
}
