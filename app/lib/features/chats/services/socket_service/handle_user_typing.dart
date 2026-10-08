part of 'socket_service.dart';

extension SocketServiceHandleUserTyping on SocketService {
  void _handleUserTyping(dynamic data) {
    debugPrint('Socket user_typing data: $data');
    final conversationId = data['conversationId'] as String?;
    final userId = data['userId'] as String?;
    if (conversationId != null && userId != null && onUserTyping != null) {
      onUserTyping!(conversationId, userId);
    }
  }
}
