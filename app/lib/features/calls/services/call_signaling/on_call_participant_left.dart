part of 'call_signaling_service.dart';

extension CallSignalingOnCallParticipantLeft on CallSignalingService {
  /// Somebody hung up. Whether that ends the call depends on who else is
  /// still in it, which only the server knows — a 1:1 peer leaving ends it, a
  /// group call carries on — so this asks rather than guesses.
  ///
  /// Until now nothing listened for this at all: the call ended locally only
  /// when LiveKit noticed the peer go, which never happens while the call is
  /// still ringing and no room exists yet.
  void _onCallParticipantLeft(dynamic data) {
    if (data is! Map) return;
    final callId = data['callId']?.toString();
    if (callId == null || callId != _currentCallId) return;
    if (data['userId']?.toString() == _currentUserId) return;
    _requestCallState();
  }
}
