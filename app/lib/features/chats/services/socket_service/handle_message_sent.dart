part of 'socket_service.dart';

extension SocketServiceHandleMessageSent on SocketService {
  /// Server confirmed our message — full message object returned.
  void _handleMessageSent(dynamic data) {
    debugPrint('Socket message_sent data: $data');
    try {
      final clientMessageId =
          (data['clientMessageId'] ?? data['tempId']) as String? ?? '';
      final message = ChatMessageModel.fromJson(
        Map<String, dynamic>.from(data),
      );
      if (onMessageSent != null) {
        onMessageSent!(message, clientMessageId);
      }
    } catch (e) {
      debugPrint('Error parsing message_sent: $e');
    }
  }
}
