part of 'call_signaling_service.dart';

extension CallSignalingToggleSpeakerphone on CallSignalingService {
  Future<void> toggleSpeakerphone() async {
    _isSpeakerOn = !_isSpeakerOn;
    try {
      await AudioManager.instance.setSpeakerOutputPreferred(_isSpeakerOn);
    } catch (e) {
      debugPrint('Error toggling speakerphone: $e');
    }
    _notify();
  }
}
