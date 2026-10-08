part of 'chat_service.dart';

extension ChatServiceStarMessage on ChatService {
  Future<Map<String, dynamic>> starMessage(String messageId, bool star) async {
    try {
      final response = await HttpService.post(
        ApiEndpoints.starMessage(messageId),
        body: {'star': star},
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && body['success'] == true) {
        return body;
      }
      throw Exception(body['message'] ?? 'Failed to star message');
    } catch (e) {
      rethrow;
    }
  }
}
