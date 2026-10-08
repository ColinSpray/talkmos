part of 'chat_service.dart';

extension ChatServiceCreateCommunity on ChatService {
  Future<Map<String, dynamic>> createCommunity({
    required String name,
    String? description,
    String? category,
    String? imageUrl,
  }) async {
    final payload = {
      'name': name,
      if (description != null) 'description': description,
      if (category != null) 'category': category,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
    try {
      final response = await HttpService.post(
        ApiEndpoints.communities,
        body: payload,
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          body['success'] == true) {
        return body['data'] as Map<String, dynamic>;
      }
      throw Exception(body['message'] ?? 'Failed to create community');
    } catch (e) {
      rethrow;
    }
  }
}
