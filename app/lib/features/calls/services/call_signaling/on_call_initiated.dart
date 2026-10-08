part of 'call_signaling_service.dart';

const Duration _presumedRingingDelay = Duration(seconds: 4);

extension CallSignalingOnCallInitiated on CallSignalingService {
  void _onCallInitiated(dynamic data) {
    debugPrint('Call initiated: $data');
    final call = data['call'] as Map?;
    if (call == null) return;
    _currentCallId = call['_id']?.toString();

    // Trust the server's participant list for the peer id, not the UI-supplied
    // calleeId — that can point at the wrong user (even ourselves).
    final resolvedPeer = _peerFromParticipants(data['participants']);
    if (resolvedPeer != null) _peerId = resolvedPeer;

    // The invite is out; give the push time to land, then say "Ringing…"
    // whether or not the callee's device is in any position to confirm it.
    _presumedRingingTimer?.cancel();
    _presumedRingingTimer = Timer(_presumedRingingDelay, () {
      if (_state != CallState.ringingOutgoing || _presumedRinging) return;
      _presumedRinging = true;
      _notify();
    });

    // Caller joins the LiveKit room now; media starts flowing the moment the
    // callee accepts and joins the same room.
    if (_currentCallId != null) {
      CallNotificationService.showActiveCall(
        callId: _currentCallId!,
        peerName: _peerName ?? '',
        callType: _callType ?? 'audio',
        ringing: true,
      );
      _connectToRoom(_currentCallId!);
    }
  }
}
