part of 'chat_service.dart';

extension ChatServiceDeleteMessage on ChatService {
  Future<void> deleteMessage(String messageId) async {
    try {
      final response = await HttpService.delete(
        ApiEndpoints.message(messageId),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode != 200 || body['success'] != true) {
        throw Exception(body['message'] ?? 'Failed to delete message');
      }
    } catch (e) {
      rethrow;
    }
  }
}
