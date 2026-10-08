part of 'call_signaling_service.dart';

extension CallSignalingToggleCamera on CallSignalingService {
  Future<void> toggleCamera() async {
    final lp = _room?.localParticipant;
    if (lp == null) return;

    if (_callType != 'video') {
      debugPrint('[ToggleCamera] callType=audio -> upgrading to video');
      await upgradeToVideo();
      return;
    }

    if (_isCameraOff && _isScreenSharing) {
      debugPrint(
        '[ToggleCamera] camera asked for mid-share — ending the share',
      );
      // Cleared first so the share's own restore doesn't also flip the camera,
      // which would leave it off again a moment later.
      _cameraSuspendedForShare = false;
      await toggleScreenShare();
    }

    _isCameraOff = !_isCameraOff;
    debugPrint('[ToggleCamera] setting camera enabled=${!_isCameraOff}');
    try {
      await lp.setCameraEnabled(!_isCameraOff);
    } catch (e) {
      debugPrint('toggleCamera error: $e');
    }
    _notify();
  }
}
