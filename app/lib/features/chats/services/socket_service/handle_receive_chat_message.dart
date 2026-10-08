part of 'socket_service.dart';

extension SocketServiceHandleReceiveChatMessage on SocketService {
  void _handleReceiveChatMessage(dynamic data) {
    debugPrint('Received socket message data: $data');
    try {
      var message = ChatMessageModel.fromJson(Map<String, dynamic>.from(data));
      final clientMessageId =
          (data['clientMessageId'] ?? data['tempId']) as String?;

      // Deduplicate: if we already added this message optimistically, update
      // its status instead of inserting a duplicate.
      final existingIndex = _messages.indexWhere(
        (m) =>
            m.id == message.id ||
            (clientMessageId != null && m.id == clientMessageId),
      );
      if (existingIndex != -1) {
        final existingStatus = _messages[existingIndex].status;
        if (message.status.index > existingStatus.index) {
          _messages[existingIndex] = _messages[existingIndex].copyWith(
            status: message.status,
          );
          _notify();
        }
        if (onMessageReceived != null) {
          onMessageReceived!(message, clientMessageId);
        }
        return;
      }

      _messages.add(message);
      _notify();

      if (onMessageReceived != null) {
        onMessageReceived!(message, clientMessageId);
      }
      if (onMessageNotification != null) {
        onMessageNotification!(message);
      }
    } catch (e) {
      debugPrint('Error parsing received socket message: $e');
    }
  }
}
