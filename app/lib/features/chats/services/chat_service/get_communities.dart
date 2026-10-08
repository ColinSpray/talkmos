part of 'chat_service.dart';

extension ChatServiceGetCommunities on ChatService {
  Future<List<dynamic>> getCommunities({String? category}) async {
    final queryParams = {if (category != null) 'category': category};
    final uri = ApiEndpoints.communities.replace(queryParameters: queryParams);
    try {
      final response = await HttpService.get(uri);
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && body['success'] == true) {
        return body['data'] as List<dynamic>;
      }
      throw Exception(body['message'] ?? 'Failed to fetch communities');
    } catch (e) {
      rethrow;
    }
  }
}
