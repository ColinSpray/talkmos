part of 'chat_service.dart';

extension ChatServiceCreateEvent on ChatService {
  Future<Map<String, dynamic>> createEvent(
    String communityId,
    Map<String, dynamic> eventData,
  ) async {
    try {
      final response = await HttpService.post(
        ApiEndpoints.communityEvents(communityId),
        body: eventData,
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          body['success'] == true) {
        return body['data'] as Map<String, dynamic>;
      }
      throw Exception(body['message'] ?? 'Failed to create event');
    } catch (e) {
      rethrow;
    }
  }
}
