part of 'chat_service.dart';

extension ChatServiceMarkDelivered on ChatService {
  Future<void> markDelivered(String messageId) async {
    try {
      if (TokenManager.token == null) await TokenManager.init();
      if (TokenManager.token == null) {
        debugPrint('[ChatService] markDelivered skipped — no auth token');
        return;
      }

      final response = await HttpService.post(
        ApiEndpoints.deliverMessage(messageId),
      );
      if (response.statusCode != 200 && response.statusCode != 204) {
        debugPrint(
          '[ChatService] markDelivered failed (${response.statusCode}): ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('[ChatService] markDelivered error: $e');
    }
  }
}
