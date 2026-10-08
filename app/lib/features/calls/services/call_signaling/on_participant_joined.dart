part of 'call_signaling_service.dart';

extension CallSignalingOnParticipantJoined on CallSignalingService {
  void _onParticipantJoined(dynamic data, String userId) {
    final joinedUserId = data['userId']?.toString();
    if (joinedUserId == null || joinedUserId == userId) return;
    // The callee joined the room — flip the caller's ringing UI to connected.
    // (LiveKit's ParticipantConnectedEvent also covers this once media is up.)
    if (_state == CallState.ringingOutgoing) {
      _updateStateToConnected();
    }
  }
}
