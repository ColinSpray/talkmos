part of 'socket_service.dart';

extension SocketServiceHandleFriendRequestReceived on SocketService {
  void _handleFriendRequestReceived(dynamic data) {
    debugPrint('Socket friend_request_received data: $data');
    if (onFriendRequestReceived != null) {
      try {
        onFriendRequestReceived!(Map<String, dynamic>.from(data));
      } catch (e) {
        debugPrint('Error parsing friend_request_received: $e');
      }
    }
  }
}
