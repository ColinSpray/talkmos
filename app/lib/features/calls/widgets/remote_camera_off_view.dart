import 'package:flutter/material.dart';
import 'audio_call_center_content.dart' show BlurredAvatarBackdrop;
import 'call_avatar_circle.dart';
import 'call_theme_colors.dart';
import 'pulsing_avatar.dart';

/// Stands in for the remote video in a 1:1 video call while the other side
/// isn't sending any — usually because their camera is simply off, which a
/// spinner misreports as a call that is still connecting.
class RemoteCameraOffView extends StatelessWidget {
  final bool isDark;
  final String? avatarUrl;
  final String initials;
  final String statusText;
  final bool isSpeakingNow;
  final bool showAvatarPulse;
  final Color avatarGlowColor;
  final Animation<double> pulseAnimation;

  const RemoteCameraOffView({
    super.key,
    required this.isDark,
    required this.avatarUrl,
    required this.initials,
    required this.statusText,
    required this.isSpeakingNow,
    required this.showAvatarPulse,
    required this.avatarGlowColor,
    required this.pulseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        BlurredAvatarBackdrop(isDark: isDark, avatarUrl: avatarUrl),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PulsingAvatar(
                animation: pulseAnimation,
                showPulse: showAvatarPulse,
                glowColor: avatarGlowColor,
                avatar: CallAvatarCircle(
                  isDark: isDark,
                  avatarUrl: avatarUrl,
                  initials: initials,
                  borderColor: isSpeakingNow
                      ? callSuccessColor
                      : (isDark
                            ? Colors.white.withValues(alpha: 0.15)
                            : const Color(0xFFE0EDFF)),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: callPillBg(isDark),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: callTileBorder(isDark)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.videocam_off_rounded,
                      size: 15,
                      color: callTextSecondary(isDark),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        statusText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: callTextSecondary(isDark),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
