part of 'socket_service.dart';

extension SocketServiceHandleMessagesRead on SocketService {
  void _handleMessagesRead(dynamic data) {
    debugPrint('Socket messages_read data: $data (me: $_currentUserId)');
    final readerId = data['readerId'] as String?;
    final chatId = data['chatId'] as String?;
    if (readerId != null) {
      _markAllMessagesReadBy(readerId, chatId);
    }
  }
}
