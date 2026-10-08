part of 'call_signaling_service.dart';

extension CallSignalingAcceptIncomingCall on CallSignalingService {
  Future<void> acceptIncomingCall(
    String currentUserId, {
    String? callId,
    String? callerId,
    String? callerName,
    String? callType,
  }) async {
    if (_room != null &&
        callId != null &&
        callId.isNotEmpty &&
        callId != _currentCallId) {
      debugPrint(
        '[CallSignaling] Busy — declining accept for a different call $callId',
      );
      _socket?.emit('decline_call', {'callId': callId});
      return;
    }

    _isOutgoing = false;
    if (_currentCallId == null && callId != null && callId.isNotEmpty) {
      _currentCallId = callId;
      _peerId = callerId ?? _peerId;
      _peerName = callerName ?? _peerName;
      _callType = callType ?? _callType ?? 'audio';
    } else if (callerName != null &&
        callerName.isNotEmpty &&
        (_peerName == null || _peerName!.isEmpty)) {
      _peerName = callerName;
    }
    if (_currentCallId == null) return;

    if (_state != CallState.connected) {
      _updateStateToConnected();
    }

    // On a cold start from the call notification the socket may still be
    // connecting; emits would be dropped, so wait (bounded) for it first.
    final connected = await _waitForSocketConnected();
    if (!connected) {
      debugPrint('[CallSignaling] acceptIncomingCall: socket never connected');
      return;
    }

    // Tell the backend we joined (participant tracking + notifies the caller),
    // then join the LiveKit room to start media.
    _joinRejected = false;
    _socket!.emit('join_call_room', {'callId': _currentCallId});
    await _connectToRoom(_currentCallId!);
  }
}
