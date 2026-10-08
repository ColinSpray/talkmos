part of 'chat_service.dart';

extension ChatServiceCreateMeeting on ChatService {
  Future<Map<String, dynamic>> createMeeting(
    Map<String, dynamic> meetingData,
  ) async {
    try {
      final response = await HttpService.post(
        ApiEndpoints.meetings,
        body: meetingData,
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          body['success'] == true) {
        return body['data'] as Map<String, dynamic>;
      }
      throw Exception(body['message'] ?? 'Failed to create meeting');
    } catch (e) {
      rethrow;
    }
  }
}
