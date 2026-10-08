part of 'call_signaling_service.dart';

extension CallSignalingToggleMicrophone on CallSignalingService {
  Future<void> toggleMicrophone() async {
    final lp = _room?.localParticipant;
    if (lp == null) return;
    _isMicMuted = !_isMicMuted;
    try {
      await lp.setMicrophoneEnabled(!_isMicMuted);
    } catch (e) {
      debugPrint('toggleMicrophone error: $e');
    }
    _notify();
  }
}
