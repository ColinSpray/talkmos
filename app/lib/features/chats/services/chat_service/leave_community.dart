part of 'chat_service.dart';

extension ChatServiceLeaveCommunity on ChatService {
  Future<void> leaveCommunity(String communityId) async {
    try {
      final response = await HttpService.delete(
        ApiEndpoints.leaveCommunity(communityId),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode != 200 || body['success'] != true) {
        throw Exception(body['message'] ?? 'Failed to leave community');
      }
    } catch (e) {
      rethrow;
    }
  }
}
