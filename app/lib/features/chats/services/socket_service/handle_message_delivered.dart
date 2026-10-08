part of 'socket_service.dart';

extension SocketServiceHandleMessageDelivered on SocketService {
  /// Receiver device acknowledged the message ('delivered' ✓✓ grey).
  void _handleMessageDelivered(dynamic data) {
    final messageId = (data['clientMessageId'] ?? data['messageId']) as String?;
    if (messageId != null) {
      _updateMessageStatus(messageId, MessageStatus.delivered, data['content']);
    }
  }
}
