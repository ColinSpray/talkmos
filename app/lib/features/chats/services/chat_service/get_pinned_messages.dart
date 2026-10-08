part of 'chat_service.dart';

extension ChatServiceGetPinnedMessages on ChatService {
  Future<List<ChatMessageModel>> getPinnedMessages(String chatId) async {
    if (chatId.isEmpty) return [];
    try {
      final response = await HttpService.get(
        ApiEndpoints.conversationPinnedMessages(chatId),
      );
      final body = _parseResponse(response);
      if (response.statusCode == 200 && body['success'] == true) {
        final list = body['data'] as List;
        return list
            .map(
              (item) =>
                  ChatMessageModel.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList();
      }
      throw Exception(body['message'] ?? 'Failed to fetch pinned messages');
    } catch (e) {
      rethrow;
    }
  }
}
