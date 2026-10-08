part of 'chat_service.dart';

extension ChatServiceUpdateConversation on ChatService {
  Future<Map<String, dynamic>> updateConversation(
    String chatId, {
    String? name,
    String? imageUrl,
    String? description,
  }) async {
    final payload = {
      if (name != null) 'name': name,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (description != null) 'description': description,
    };
    try {
      final response = await HttpService.patch(
        ApiEndpoints.conversation(chatId),
        body: payload,
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && body['success'] == true) {
        return Map<String, dynamic>.from(body['data']);
      }
      throw Exception(body['message'] ?? 'Failed to update conversation');
    } catch (e) {
      rethrow;
    }
  }
}
