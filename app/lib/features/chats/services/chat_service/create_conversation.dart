part of 'chat_service.dart';

extension ChatServiceCreateConversation on ChatService {
  Future<Map<String, dynamic>> createConversation({
    required String type,
    List<String>? participantIds,
    String? name,
    String? spaceId,
    String? description,
    String? imageUrl,
  }) async {
    final payload = {
      'type': type,
      if (participantIds != null) 'participantIds': participantIds,
      if (name != null) 'name': name,
      if (spaceId != null) 'spaceId': spaceId,
      if (description != null && description.isNotEmpty)
        'description': description,
      if (imageUrl != null && imageUrl.isNotEmpty) 'imageUrl': imageUrl,
    };

    try {
      final response = await HttpService.post(
        ApiEndpoints.conversations,
        body: payload,
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          body['success'] == true) {
        return body['data'] as Map<String, dynamic>;
      }
      throw Exception(body['message'] ?? 'Failed to create conversation');
    } catch (e) {
      rethrow;
    }
  }
}
