part of 'chat_service.dart';

extension ChatServiceGetMessages on ChatService {
  Future<List<ChatMessageModel>> getMessages(
    String chatId, {
    int limit = 50,
    DateTime? before,
    String? after,
  }) async {
    if (chatId.isEmpty) return [];
    final queryParams = {
      'limit': '$limit',
      if (before != null) 'before': before.toUtc().toIso8601String(),
      if (after != null && after.isNotEmpty) 'after': after,
    };
    final uri = ApiEndpoints.messages(
      chatId,
    ).replace(queryParameters: queryParams);

    try {
      final response = await HttpService.get(uri);
      final body = _parseResponse(response);
      if (response.statusCode == 200 && body['success'] == true) {
        final List<dynamic> data = body['data'];
        return data
            .map(
              (json) =>
                  ChatMessageModel.fromJson(Map<String, dynamic>.from(json)),
            )
            .toList();
      }
      throw Exception(body['message'] ?? 'Failed to fetch messages');
    } catch (e) {
      rethrow;
    }
  }
}
