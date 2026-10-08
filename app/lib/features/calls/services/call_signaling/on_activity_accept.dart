part of 'call_signaling_service.dart';

extension CallSignalingOnActivityAccept on CallSignalingService {
  void _onActivityAccept(Map<String, dynamic> data) {
    final callId = data['callId']?.toString() ?? '';
    final callerId = data['callerId']?.toString() ?? '';
    final callerName = data['callerName']?.toString();
    final callType = data['callType']?.toString() ?? 'audio';

    if (_currentUserId != null && callId.isNotEmpty) {
      acceptIncomingCall(
        _currentUserId!,
        callId: callId,
        callerId: callerId,
        callerName: callerName,
        callType: callType,
      );
    }
  }
}
