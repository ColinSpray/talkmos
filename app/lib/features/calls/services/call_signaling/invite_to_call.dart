part of 'call_signaling_service.dart';

extension CallSignalingInviteToCall on CallSignalingService {
  void inviteToCall(String calleeId, {String? initiatorName}) {
    if (_socket == null || _currentCallId == null || calleeId.isEmpty) return;
    _socket!.emit('invite_to_call', {
      'callId': _currentCallId,
      'calleeId': calleeId,
      'callType': _callType,
      'initiatorName': initiatorName ?? '',
    });
  }
}
