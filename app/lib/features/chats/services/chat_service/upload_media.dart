part of 'chat_service.dart';

extension ChatServiceUploadMedia on ChatService {
  /// Mock endpoint returning a configured CDN upload path.
  Future<Map<String, dynamic>> uploadMedia({
    required String fileName,
    required String mimeType,
  }) async {
    try {
      final response = await HttpService.post(
        ApiEndpoints.mediaUpload,
        body: {'fileName': fileName, 'mimeType': mimeType},
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          body['success'] == true) {
        return body;
      }
      throw Exception(body['message'] ?? 'Failed to upload media');
    } catch (e) {
      rethrow;
    }
  }
}
