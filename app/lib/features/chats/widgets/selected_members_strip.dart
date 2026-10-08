import 'package:flutter/material.dart';
import 'package:talkmos/core/utils/titlecase_function.dart';
import '../../../models/friend_model.dart';
import 'friend_avatar.dart';

/// Horizontal strip of chosen members. Caps at five avatars with a "+N"
/// overflow bubble so a long selection can't push the list off screen.
class SelectedMembersStrip extends StatelessWidget {
  static const _maxVisible = 5;

  final List<FriendModel> selected;
  final bool isDark;
  final Color textColor;
  final Color primary;
  final ValueChanged<String> onRemove;

  const SelectedMembersStrip({
    super.key,
    required this.selected,
    required this.isDark,
    required this.textColor,
    required this.primary,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final shown = selected.take(_maxVisible).toList();
    final overflow = selected.length - shown.length;

    return SizedBox(
      height: 76,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final f in shown) ...[
            _SelectedMemberChip(
              friend: f,
              isDark: isDark,
              textColor: textColor,
              primary: primary,
              onRemove: () => onRemove(f.id),
            ),
            const SizedBox(width: 14),
          ],
          if (overflow > 0)
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: isDark ? 0.18 : 0.1),
                shape: BoxShape.circle,
              ),
              child: Text(
                '+$overflow',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SelectedMemberChip extends StatelessWidget {
  final FriendModel friend;
  final bool isDark;
  final Color textColor;
  final Color primary;
  final VoidCallback onRemove;

  const _SelectedMemberChip({
    required this.friend,
    required this.isDark,
    required this.textColor,
    required this.primary,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 58,
            height: 54,
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 1),
                  child: FriendAvatar(
                    friend: friend,
                    radius: 25,
                    primary: primary,
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: GestureDetector(
                    onTap: onRemove,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF060B18)
                              : Colors.white,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Text(
            toTitleCase(friend.name.split(' ').first),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: textColor),
          ),
        ],
      ),
    );
  }
}
