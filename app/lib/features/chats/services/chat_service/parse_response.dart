part of 'chat_service.dart';

extension ChatServiceParseResponse on ChatService {
  Map<String, dynamic> _parseResponse(http.Response response) {
    final text = response.body.trim();
    if (text.isEmpty || text.startsWith('<') || text.startsWith('<!DOCTYPE')) {
      throw Exception(
        'Server returned invalid response (${response.statusCode})',
      );
    }
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      throw Exception('Unexpected response format');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to parse response: $e');
    }
  }
}
