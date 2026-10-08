import 'package:flutter/material.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';
import 'call_theme_colors.dart';

class CallControlHud extends StatelessWidget {
  final bool isDark;
  final bool isVideo;
  final bool isMicMuted;
  final bool isCameraOff;
  final bool isSpeakerOn;
  final bool isScreenSharing;
  final bool isHangingUp;
  final VoidCallback onToggleMic;
  final VoidCallback onToggleCamera;
  final VoidCallback onUpgradeToVideo;
  final VoidCallback onToggleSpeaker;
  final VoidCallback onToggleScreenShare;
  final VoidCallback onHangUp;

  const CallControlHud({
    super.key,
    required this.isDark,
    required this.isVideo,
    required this.isMicMuted,
    required this.isCameraOff,
    required this.isSpeakerOn,
    required this.isScreenSharing,
    required this.isHangingUp,
    required this.onToggleMic,
    required this.onToggleCamera,
    required this.onUpgradeToVideo,
    required this.onToggleSpeaker,
    required this.onToggleScreenShare,
    required this.onHangUp,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final effectiveDark = isDark || isVideo;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        LabeledCallButton(
          icon: isMicMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
          label: l10n.commonMute,
          active: isMicMuted,
          isDark: effectiveDark,
          onTap: onToggleMic,
        ),
        if (isVideo)
          LabeledCallButton(
            icon: isCameraOff
                ? Icons.videocam_off_rounded
                : Icons.videocam_rounded,
            label: isCameraOff
                ? l10n.activeCallScreenStartVideo
                : l10n.activeCallScreenStopVideo,
            active: !isCameraOff,
            isDark: effectiveDark,
            onTap: onToggleCamera,
          )
        else
          LabeledCallButton(
            icon: Icons.videocam_rounded,
            label: l10n.activeCallScreenStartVideo,
            isDark: effectiveDark,
            onTap: onUpgradeToVideo,
          ),
        LabeledCallButton(
          icon: isSpeakerOn
              ? Icons.volume_up_rounded
              : Icons.volume_up_outlined,
          label: l10n.commonSpeaker,
          active: isSpeakerOn,
          isDark: effectiveDark,
          onTap: onToggleSpeaker,
        ),
        LabeledCallButton(
          icon: isScreenSharing
              ? Icons.stop_screen_share_rounded
              : Icons.screen_share_rounded,
          label: isScreenSharing
              ? l10n.activeCallScreenStopSharingScreen
              : l10n.activeCallScreenShareScreen,
          active: isScreenSharing,
          isDark: effectiveDark,
          onTap: onToggleScreenShare,
        ),
        LabeledCallButton(
          icon: Icons.call_end_rounded,
          label: l10n.activeCallScreenEndCall,
          isRed: true,
          isDark: effectiveDark,
          onTap: isHangingUp ? null : onHangUp,
        ),
      ],
    );
  }
}

class LabeledCallButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isDark;
  final bool active;
  final bool isRed;

  const LabeledCallButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
    this.active = false,
    this.isRed = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color bgColor = isRed
        ? callErrorColor
        : (active
              ? Theme.of(context).primaryColor
              : (isDark ? const Color(0xFF000E23) : Colors.white));

    final Color iconColor = (isRed || active)
        ? Colors.white
        : (isDark ? Colors.white : Theme.of(context).primaryColor);

    final Color labelColor = callTextSecondary(isDark);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
              boxShadow: !isDark && !isRed && !active
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: labelColor,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
