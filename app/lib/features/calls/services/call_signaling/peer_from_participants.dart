part of 'call_signaling_service.dart';

extension CallSignalingPeerFromParticipants on CallSignalingService {
  /// Returns the other participant's user id from a `call_initiated`
  /// participants list (the one that isn't the current user), or null.
  String? _peerFromParticipants(dynamic participants) {
    if (participants is! List || _currentUserId == null) return null;
    for (final p in participants) {
      if (p is! Map) continue;
      final rawUserId = p['userId'];
      final uid = (rawUserId is Map ? rawUserId['_id'] : rawUserId)?.toString();
      if (uid != null && uid.isNotEmpty && uid != _currentUserId) {
        return uid;
      }
    }
    return null;
  }
}
