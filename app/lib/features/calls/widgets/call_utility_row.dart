import 'package:flutter/material.dart';
import 'call_reactions.dart';
import 'call_theme_colors.dart';

/// Raise Hand / Participants / Reactions row (group calls), or just
/// Reactions (1:1 — raising a hand / listing 2 participants is moot).
class CallUtilityRow extends StatelessWidget {
  final bool isDark;
  final bool isGroup;
  final bool isHandRaised;
  final int raisedHandCount;
  final int participantCount;
  final bool showReactionPicker;
  final VoidCallback onToggleRaiseHand;
  final VoidCallback onShowParticipants;
  final VoidCallback onToggleReactionPicker;
  final ValueChanged<String> onPickReaction;

  const CallUtilityRow({
    super.key,
    required this.isDark,
    required this.isGroup,
    required this.isHandRaised,
    required this.raisedHandCount,
    required this.participantCount,
    required this.showReactionPicker,
    required this.onToggleRaiseHand,
    required this.onShowParticipants,
    required this.onToggleReactionPicker,
    required this.onPickReaction,
  });

  @override
  Widget build(BuildContext context) {
    final reactionsButton = UtilityButton(
      icon: Icons.emoji_emotions_outlined,
      label: 'Reactions',
      isDark: isDark,
      active: showReactionPicker,
      onTap: onToggleReactionPicker,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showReactionPicker) ...[
          ReactionPickerRow(isDark: isDark, onPick: onPickReaction),
          const SizedBox(height: 8),
        ],
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: callPillBg(isDark),
            borderRadius: BorderRadius.circular(20),
          ),
          child: isGroup
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    UtilityButton(
                      icon: Icons.back_hand_rounded,
                      label: 'Raise Hand',
                      isDark: isDark,
                      active: isHandRaised,
                      badgeCount: raisedHandCount,
                      onTap: onToggleRaiseHand,
                    ),
                    UtilityButton(
                      icon: Icons.groups_rounded,
                      label: '$participantCount Participants',
                      isDark: isDark,
                      onTap: onShowParticipants,
                    ),
                    reactionsButton,
                  ],
                )
              : Center(child: reactionsButton),
        ),
      ],
    );
  }
}

class UtilityButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;
  final bool active;
  final int badgeCount;

  const UtilityButton({
    super.key,
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
    this.active = false,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final color = active
        ? Theme.of(context).primaryColor
        : callTextPrimary(isDark);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: color, size: 22),
                if (badgeCount > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: callErrorColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
