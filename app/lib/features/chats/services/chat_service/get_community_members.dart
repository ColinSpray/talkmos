part of 'chat_service.dart';

extension ChatServiceGetCommunityMembers on ChatService {
  Future<List<dynamic>> getCommunityMembers(String communityId) async {
    try {
      final response = await HttpService.get(
        ApiEndpoints.communityMembers(communityId),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && body['success'] == true) {
        return body['data'] as List<dynamic>;
      }
      throw Exception(body['message'] ?? 'Failed to fetch community members');
    } catch (e) {
      rethrow;
    }
  }
}
