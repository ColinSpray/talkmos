part of 'chat_service.dart';

extension ChatServiceReactToMessage on ChatService {
  /// An empty [emoji] removes the caller's reaction.
  Future<Map<String, dynamic>> reactToMessage(
    String messageId,
    String emoji,
  ) async {
    try {
      final response = await HttpService.post(
        ApiEndpoints.reactToMessage(messageId),
        body: {'emoji': emoji},
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && body['success'] == true) {
        return body;
      }
      throw Exception(body['message'] ?? 'Failed to react to message');
    } catch (e) {
      rethrow;
    }
  }
}
