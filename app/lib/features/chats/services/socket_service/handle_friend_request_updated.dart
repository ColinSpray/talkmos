part of 'socket_service.dart';

extension SocketServiceHandleFriendRequestUpdated on SocketService {
  void _handleFriendRequestUpdated(dynamic data) {
    debugPrint('Socket friend_request_updated data: $data');
    if (onFriendRequestUpdated != null) {
      try {
        onFriendRequestUpdated!(Map<String, dynamic>.from(data));
      } catch (e) {
        debugPrint('Error parsing friend_request_updated: $e');
      }
    }
  }
}
