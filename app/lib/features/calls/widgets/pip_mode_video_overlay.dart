import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:provider/provider.dart';
import '../../../core/services/pip_service.dart';
import '../services/call_signaling/call_signaling_service.dart';

class PipModeVideoOverlay extends StatefulWidget {
  const PipModeVideoOverlay({super.key});

  @override
  State<PipModeVideoOverlay> createState() => _PipModeVideoOverlayState();
}

class _PipModeVideoOverlayState extends State<PipModeVideoOverlay> {
  VideoTrack? _cachedTrack;
  Widget? _cachedRenderer;

  Widget? _videoWidget(VideoTrack? track) {
    if (track == null) {
      _cachedTrack = null;
      _cachedRenderer = null;
      return null;
    }
    if (!identical(_cachedTrack, track) || _cachedRenderer == null) {
      _cachedTrack = track;
      _cachedRenderer = VideoTrackRenderer(track, fit: VideoViewFit.cover);
    }
    return _cachedRenderer;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: PipService.instance.isInPipMode,
      builder: (context, isInPip, _) {
        if (!isInPip) return const SizedBox.shrink();
        return Consumer<CallSignalingService>(
          builder: (context, sig, _) {
            final track = sig.remoteVideoTrack ?? sig.localVideoTrack;
            return Positioned.fill(
              child: ColoredBox(
                color: const Color(0xFF000814),
                child: _videoWidget(track) ?? const SizedBox.shrink(),
              ),
            );
          },
        );
      },
    );
  }
}
