import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/services/media_cache_service.dart';
import 'call_avatar_circle.dart';
import 'call_theme_colors.dart';
import 'pulsing_avatar.dart';

class BlurredAvatarBackdrop extends StatelessWidget {
  final bool isDark;
  final String? avatarUrl;
  const BlurredAvatarBackdrop({
    super.key,
    required this.isDark,
    required this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    if (avatarUrl == null || avatarUrl!.isEmpty) {
      return Container(color: callBgColor(isDark));
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: avatarUrl!,
          cacheManager: MediaCacheService.manager,
          fit: BoxFit.cover,
          // Backdrop only — a photo that won't load leaves the plain one.
          errorWidget: (_, _, _) => Container(color: callBgColor(isDark)),
        ),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
          child: Container(
            color: (isDark ? Colors.black : Colors.white).withValues(
              alpha: isDark ? 0.55 : 0.75,
            ),
          ),
        ),
      ],
    );
  }
}

/// 1:1 audio call center content: pulsing avatar, peer name, and either the
/// ringing label or the live call-duration timer.
class AudioCallCenterContent extends StatelessWidget {
  final bool isDark;
  final String? avatarUrl;
  final String initials;
  final String peerName;
  final bool isConnected;
  final String statusText;
  final bool isSpeakingNow;
  final bool showAvatarPulse;
  final Color avatarGlowColor;
  final Animation<double> pulseAnimation;

  const AudioCallCenterContent({
    super.key,
    required this.isDark,
    required this.avatarUrl,
    required this.initials,
    required this.peerName,
    required this.isConnected,
    required this.statusText,
    required this.isSpeakingNow,
    required this.showAvatarPulse,
    required this.avatarGlowColor,
    required this.pulseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          // Avatar with outer ring + breathing pulse while ringing/speaking
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
          const SizedBox(height: 24),
          Text(
            peerName,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              color: callTextPrimary(isDark),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 15,
              color: callTextSecondary(isDark),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
