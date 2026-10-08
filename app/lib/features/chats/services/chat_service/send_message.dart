part of 'chat_service.dart';

extension ChatServiceSendMessage on ChatService {
  Future<ChatMessageModel> sendMessage({
    required String chatId,
    required String content,
    String messageType = 'text',
    Map<String, dynamic>? media,
    String? replyToId,
  }) async {
    final payload = {
      'messageType': messageType,
      'content': content,
      if (media != null) 'media': media,
      if (replyToId != null) 'replyToId': replyToId,
    };
    try {
      final response = await HttpService.post(
        ApiEndpoints.messages(chatId),
        body: payload,
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 201 && body['success'] == true) {
        final data = Map<String, dynamic>.from(body['data']);
        return ChatMessageModel.fromJson(data);
      }
      throw Exception(body['message'] ?? 'Failed to send message');
    } catch (e) {
      rethrow;
    }
  }
}
