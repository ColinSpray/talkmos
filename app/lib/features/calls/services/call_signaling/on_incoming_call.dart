part of 'call_signaling_service.dart';

extension CallSignalingOnIncomingCall on CallSignalingService {
  void _onIncomingCall(dynamic data, String userId) {
    debugPrint('Incoming call: $data');
    final initiatorId = data['initiatorId']?.toString();
    if (initiatorId == userId) {
      // This user is the caller; ignore our own broadcast.
      return;
    }

    if (initiatorId != null && BlockedUsersStore.isBlocked(initiatorId)) {
      debugPrint('[Call] Ignored incoming call from blocked user $initiatorId');
      return;
    }

    final callId = data['callId']?.toString();
    if (callId == null) return;

    if (hasActiveCallSession) {
      debugPrint('[CallSignaling] Busy — auto-declining incoming call $callId');
      _socket?.emit('decline_call', {'callId': callId});
      return;
    }

    _applyIncomingCall(
      callId: callId,
      callerId: initiatorId ?? '',
      callerName: data['initiatorName']?.toString(),
      callerAvatar:
          data['initiatorAvatar']?.toString() ??
          data['callerAvatar']?.toString() ??
          data['avatarUrl']?.toString(),
      callType: data['callType']?.toString() ?? 'audio',
    );
  }
}
