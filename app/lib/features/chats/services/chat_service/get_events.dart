part of 'chat_service.dart';

extension ChatServiceGetEvents on ChatService {
  Future<List<dynamic>> getEvents(String communityId) async {
    try {
      final response = await HttpService.get(
        ApiEndpoints.communityEvents(communityId),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && body['success'] == true) {
        return body['data'] as List<dynamic>;
      }
      throw Exception(body['message'] ?? 'Failed to fetch events');
    } catch (e) {
      rethrow;
    }
  }
}
