part of 'chat_service.dart';

extension ChatServiceJoinCommunity on ChatService {
  Future<void> joinCommunity(String communityId) async {
    try {
      final response = await HttpService.post(
        ApiEndpoints.joinCommunity(communityId),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode != 200 || body['success'] != true) {
        throw Exception(body['message'] ?? 'Failed to join community');
      }
    } catch (e) {
      rethrow;
    }
  }
}
