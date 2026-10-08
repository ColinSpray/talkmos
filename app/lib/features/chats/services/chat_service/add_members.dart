part of 'chat_service.dart';

extension ChatServiceAddMembers on ChatService {
  Future<void> addMembers(String chatId, List<String> userIds) async {
    try {
      final response = await HttpService.post(
        ApiEndpoints.conversationMembers(chatId),
        body: {'userIds': userIds},
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if ((response.statusCode != 200 && response.statusCode != 201) ||
          body['success'] != true) {
        throw Exception(body['message'] ?? 'Failed to add members');
      }
    } catch (e) {
      rethrow;
    }
  }
}
