part of 'call_signaling_service.dart';

extension CallSignalingToggleScreenShare on CallSignalingService {
  bool get isScreenSharing => _isScreenSharing;

  Future<void> toggleScreenShare() async {
    final lp = _room?.localParticipant;
    if (lp == null) return;

    final enabling = !_isScreenSharing;
    try {
      if (enabling && defaultTargetPlatform == TargetPlatform.android) {
        final granted = await rtc.Helper.requestCapturePermission();
        if (!granted) {
          throw Exception('Screen capture permission denied');
        }
        await ScreenShareService.instance.start();
      }
      if (enabling) await _suspendCameraForShare(lp);
      await lp.setScreenShareEnabled(enabling);
      _isScreenSharing = enabling;
    } catch (e) {
      debugPrint('toggleScreenShare error: $e');
      if (enabling) {
        await ScreenShareService.instance.stop();
        await _restoreCameraAfterShare(lp);
      }
      rethrow;
    }
    if (!enabling) {
      await ScreenShareService.instance.stop();
      await _restoreCameraAfterShare(lp);
    }
    _notify();
  }

  /// The camera and the screen are one capture each on Android — trying to
  /// publish both gets the share nowhere. The camera stands down for the
  /// length of the share.
  Future<void> _suspendCameraForShare(LocalParticipant lp) async {
    if (_isCameraOff) return;
    try {
      await lp.setCameraEnabled(false);
      _isCameraOff = true;
      _cameraSuspendedForShare = true;
      _notify();
    } catch (e) {
      debugPrint('[ScreenShare] could not stop the camera: $e');
    }
  }

  /// Puts it back, but only where this took it away — a camera the user
  /// switched off themselves stays off.
  Future<void> _restoreCameraAfterShare(LocalParticipant lp) async {
    if (!_cameraSuspendedForShare) return;
    _cameraSuspendedForShare = false;
    if (_callType != 'video') return;
    try {
      await lp.setCameraEnabled(true);
      _isCameraOff = false;
      _notify();
    } catch (e) {
      debugPrint('[ScreenShare] could not restart the camera: $e');
    }
  }
}
