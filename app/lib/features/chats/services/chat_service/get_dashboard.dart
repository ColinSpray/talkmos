part of 'chat_service.dart';

extension ChatServiceGetDashboard on ChatService {
  Future<Map<String, dynamic>> getDashboard() async {
    try {
      final response = await HttpService.get(ApiEndpoints.dashboard);
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && body['success'] == true) {
        return body;
      }
      throw Exception(body['message'] ?? 'Failed to fetch conversations');
    } catch (e) {
      rethrow;
    }
  }
}
