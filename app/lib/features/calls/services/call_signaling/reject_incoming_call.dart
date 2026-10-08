part of 'call_signaling_service.dart';

extension CallSignalingRejectIncomingCall on CallSignalingService {
  void rejectIncomingCall({String? callId}) {
    if (_currentCallId == null && callId != null && callId.isNotEmpty) {
      _currentCallId = callId;
    }
    if (_currentCallId == null) return;
    _socket?.emit('decline_call', {'callId': _currentCallId});
    cleanUp();
  }
}
