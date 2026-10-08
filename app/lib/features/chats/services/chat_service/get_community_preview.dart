part of 'chat_service.dart';

extension ChatServiceGetCommunityPreview on ChatService {
  Future<CommunityModel> getCommunityPreview(String communityId) async {
    final response = await HttpService.get(
      ApiEndpoints.communityPreview(communityId),
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 && body['success'] == true) {
      return CommunityModel.fromJson(Map<String, dynamic>.from(body['data']));
    }
    throw body['message'] ?? 'Community not found';
  }
}
