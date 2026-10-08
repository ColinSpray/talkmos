part of 'call_signaling_service.dart';

extension CallSignalingUpdateStateToConnected on CallSignalingService {
  void _updateStateToConnected() {
    _cancelRingTimeout();
    _state = CallState.connected;
    _connectedAt = DateTime.now();
    _notify();
    if (_currentCallId != null) {
      CallNotificationService.showActiveCall(
        callId: _currentCallId!,
        peerName: _peerName ?? '',
        callType: _callType ?? 'audio',
      );
    }
    _activeCallReadyController.add(null);
  }
}
