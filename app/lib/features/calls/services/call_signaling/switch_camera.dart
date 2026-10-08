part of 'call_signaling_service.dart';

extension CallSignalingSwitchCamera on CallSignalingService {
  Future<void> switchCamera() async {
    final track = localVideoTrack;
    if (track is! LocalVideoTrack) return;
    _frontCamera = !_frontCamera;
    try {
      await track.setCameraPosition(
        _frontCamera ? CameraPosition.front : CameraPosition.back,
      );
    } catch (e) {
      debugPrint('switchCamera error: $e');
    }
  }
}
