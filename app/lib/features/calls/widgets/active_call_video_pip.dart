import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:provider/provider.dart';
import '../../../core/router/app_router.dart';
import '../services/call_signaling/call_signaling_service.dart';
import 'call_theme_colors.dart';

class ActiveCallVideoPip extends StatefulWidget {
  const ActiveCallVideoPip({super.key});

  @override
  State<ActiveCallVideoPip> createState() => _ActiveCallVideoPipState();
}

class _ActiveCallVideoPipState extends State<ActiveCallVideoPip> {
  static const _width = 120.0;
  static const _height = 160.0;

  Offset? _position;

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
    return Consumer<CallSignalingService>(
      builder: (context, sig, _) {
        final show =
            sig.state == CallState.connected &&
            !sig.hasActiveCallScreenOpen &&
            sig.isVideoCall;
        if (!show) return const SizedBox.shrink();

        final screenSize = MediaQuery.of(context).size;
        final topPadding = MediaQuery.of(context).padding.top;
        final defaultPos = Offset(
          screenSize.width - _width - 16,
          screenSize.height - _height - 100,
        );
        final pos = _position ?? defaultPos;

        final track = sig.remoteVideoTrack ?? sig.localVideoTrack;

        return Positioned(
          left: pos.dx,
          top: pos.dy,
          child: GestureDetector(
            onPanUpdate: (details) {
              final newX = (pos.dx + details.delta.dx).clamp(
                8.0,
                screenSize.width - _width - 8.0,
              );
              final newY = (pos.dy + details.delta.dy).clamp(
                topPadding + 8.0,
                screenSize.height - _height - 8.0,
              );
              setState(() => _position = Offset(newX, newY));
            },
            onTap: () => AppRouter.router.push(AppRoutes.activeCall),
            child: Container(
              width: _width,
              height: _height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _videoWidget(track) ??
                        Container(color: const Color(0xFF000814)),
                    // Scrim so the buttons stay legible over bright video.
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: IgnorePointer(
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0),
                                Colors.black.withValues(alpha: 0.65),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 6,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _PipButton(
                            icon: sig.isMicMuted
                                ? Icons.mic_off_rounded
                                : Icons.mic_rounded,
                            active: sig.isMicMuted,
                            onTap: sig.toggleMicrophone,
                          ),
                          _PipButton(
                            icon: sig.isSpeakerOn
                                ? Icons.volume_up_rounded
                                : Icons.volume_up_outlined,
                            active: sig.isSpeakerOn,
                            onTap: sig.toggleSpeakerphone,
                          ),
                          _PipButton(
                            icon: Icons.call_end_rounded,
                            backgroundColor: callErrorColor,
                            onTap: sig.cleanUp,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PipButton extends StatelessWidget {
  final IconData icon;
  final bool active;
  final Color? backgroundColor;
  final VoidCallback onTap;

  const _PipButton({
    required this.icon,
    required this.onTap,
    this.active = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor =
        backgroundColor ??
        (active ? Colors.white : Colors.white.withValues(alpha: 0.25));
    final iconColor = active && backgroundColor == null
        ? callErrorColor
        : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
        child: Icon(icon, size: 13, color: iconColor),
      ),
    );
  }
}
