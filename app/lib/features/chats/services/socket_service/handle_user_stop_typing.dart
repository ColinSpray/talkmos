part of 'socket_service.dart';

extension SocketServiceHandleUserStopTyping on SocketService {
  void _handleUserStopTyping(dynamic data) {
    debugPrint('Socket user_stop_typing data: $data');
    final conversationId = data['conversationId'] as String?;
    final userId = data['userId'] as String?;
    if (conversationId != null && userId != null && onUserStopTyping != null) {
      onUserStopTyping!(conversationId, userId);
    }
  }
}
