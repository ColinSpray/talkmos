part of 'socket_service.dart';

extension SocketServiceHandleUserOnlineStatus on SocketService {
  void _handleUserOnlineStatus(dynamic data) {
    debugPrint('Socket user_online_status data: $data');
    final userId = data['userId'] as String?;
    final online = data['online'] as bool? ?? false;
    // Absent while they are online, and withheld entirely when their privacy
    // setting hides it.
    final lastSeenAt = const LocalDateTimeConverterNullable().fromJson(
      data['lastSeenAt'] as String?,
    );
    if (userId != null && onUserOnlineStatus != null) {
      onUserOnlineStatus!(userId, online, lastSeenAt);
    }
  }
}
