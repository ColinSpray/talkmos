part of 'chat_service.dart';

extension ChatServiceGetConversations on ChatService {
  Future<List<dynamic>> getConversations({bool archivedOnly = false}) async {
    try {
      final response = await HttpService.get(
        archivedOnly
            ? ApiEndpoints.archivedConversations
            : ApiEndpoints.conversations,
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && body['success'] == true) {
        return body['data'] as List<dynamic>;
      }
      throw Exception(body['message'] ?? 'Failed to fetch conversations');
    } catch (e) {
      rethrow;
    }
  }
}
