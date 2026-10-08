part of 'chat_service.dart';

extension ChatServiceTogglePinMessage on ChatService {
  Future<ChatMessageModel> togglePinMessage(
    String messageId,
    bool isPinned,
  ) async {
    try {
      final response = await HttpService.post(
        ApiEndpoints.pinMessage(messageId),
        body: {'isPinned': isPinned},
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && body['success'] == true) {
        return ChatMessageModel.fromJson(
          Map<String, dynamic>.from(body['data']),
        );
      }
      throw Exception(body['message'] ?? 'Failed to toggle pin status');
    } catch (e) {
      rethrow;
    }
  }
}
