part of 'chat_service.dart';

extension ChatServiceGetConversationDetails on ChatService {
  Future<Map<String, dynamic>> getConversationDetails(String chatId) async {
    if (chatId.isEmpty) return {};
    try {
      final response = await HttpService.get(ApiEndpoints.conversation(chatId));
      final body = _parseResponse(response);
      if (response.statusCode == 200 && body['success'] == true) {
        return Map<String, dynamic>.from(body['data']);
      }
      throw Exception(
        body['message'] ?? 'Failed to fetch conversation details',
      );
    } catch (e) {
      rethrow;
    }
  }
}
