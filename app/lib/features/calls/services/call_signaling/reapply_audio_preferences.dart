part of 'call_signaling_service.dart';

extension CallSignalingReapplyAudioPreferences on CallSignalingService {
  /// Pushes the user's mic and speaker choices back onto the hardware.
  ///
  /// LiveKit's AudioSwitch re-picks an output whenever the audio session is
  /// re-evaluated — leaving the call screen and coming back is enough — and it
  /// knows nothing of what the user chose, so the call would come back
  /// unmuted and on the speaker.
  Future<void> reapplyAudioPreferences() async {
    if (!hasActiveCallSession) return;
    try {
      await AudioManager.instance.setSpeakerOutputPreferred(_isSpeakerOn);
    } catch (e) {
      debugPrint('[Hardware] re-applying the speaker choice failed: $e');
    }
    try {
      await _room?.localParticipant?.setMicrophoneEnabled(!_isMicMuted);
    } catch (e) {
      debugPrint('[LiveKit] re-applying the mic choice failed: $e');
    }
  }
}
