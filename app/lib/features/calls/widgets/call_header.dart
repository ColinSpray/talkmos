import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart' show ConnectionQuality;
import 'package:talkmos/core/utils/titlecase_function.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';
import '../services/call_signaling/call_signaling_service.dart' show CallState;
import 'call_theme_colors.dart';

class CallHeader extends StatelessWidget {
  final bool isDark;
  final bool isVideo;
  final bool isGroup;
  final CallState callState;
  final String peerName;
  final int participantCount;
  final String? speakingParticipantName;
  final ConnectionQuality connectionQuality;
  final String formattedDuration;
  final VoidCallback onBack;
  final VoidCallback onAddMember;

  const CallHeader({
    super.key,
    required this.isDark,
    required this.isVideo,
    required this.isGroup,
    required this.callState,
    required this.peerName,
    required this.participantCount,
    required this.speakingParticipantName,
    required this.connectionQuality,
    required this.formattedDuration,
    required this.onBack,
    required this.onAddMember,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textColor = callTextPrimary(isDark);
    final subColor = callTextSecondary(isDark);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: textColor,
                size: 30,
              ),
              onPressed: onBack,
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isGroup) ...[
                    Text(
                      toTitleCase(peerName),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$participantCount Participants • ${l10n.activeCallScreenEncryptedCall}',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: subColor, fontSize: 12),
                    ),
                  ] else
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shield_outlined, size: 14, color: subColor),
                        const SizedBox(width: 6),
                        Text(
                          l10n.activeCallScreenEncryptedCall,
                          style: TextStyle(
                            color: subColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.person_add_alt_1_rounded,
                color: textColor,
                size: 22,
              ),
              onPressed: onAddMember,
            ),
          ],
        ),
        if (isGroup) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (speakingParticipantName != null)
                Flexible(
                  child: SpeakingPill(
                    name: speakingParticipantName!,
                    isDark: isDark,
                  ),
                )
              else
                const SizedBox.shrink(),
              const SizedBox(width: 8),
              ConnectionQualityPill(isDark: isDark, quality: connectionQuality),
            ],
          ),
        ] else if (callState == CallState.connected) ...[
          const SizedBox(height: 8),
          Center(
            child: ConnectionQualityPill(
              isDark: isDark,
              quality: connectionQuality,
            ),
          ),
        ],
        if (isVideo && !isGroup) ...[
          const SizedBox(height: 4),
          Text(
            toTitleCase(peerName),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            formattedDuration,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

class SpeakingPill extends StatelessWidget {
  final String name;
  final bool isDark;
  const SpeakingPill({super.key, required this.name, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: callPillBg(isDark),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: callTileBorder(isDark)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.graphic_eq_rounded,
            size: 14,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '${toTitleCase(name)} is speaking',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: callTextPrimary(isDark)),
            ),
          ),
        ],
      ),
    );
  }
}

class ConnectionQualityPill extends StatelessWidget {
  final bool isDark;
  final ConnectionQuality quality;
  const ConnectionQualityPill({
    super.key,
    required this.isDark,
    required this.quality,
  });

  @override
  Widget build(BuildContext context) {
    String label;
    Color color;
    switch (quality) {
      case ConnectionQuality.excellent:
        label = 'Excellent';
        color = callSuccessColor;
      case ConnectionQuality.good:
        label = 'Good';
        color = callSuccessColor;
      case ConnectionQuality.poor:
        label = 'Poor';
        color = const Color(0xFFF59E0B);
      case ConnectionQuality.lost:
        label = 'Lost';
        color = callErrorColor;
      case ConnectionQuality.unknown:
        label = 'Connecting';
        color = callTextMuted(isDark);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.signal_cellular_alt_rounded, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
