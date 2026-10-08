import 'package:flutter/material.dart';
import 'package:talkmos/core/utils/titlecase_function.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';
import '../../../models/friend_model.dart';
import 'friend_avatar.dart';

/// Selectable row in the "add members" list: checkbox-style indicator,
/// avatar with an online badge, and name/username.
class GroupMemberTile extends StatelessWidget {
  final FriendModel friend;
  final bool isSelected;
  final bool isDark;
  final Color textColor;
  final Color primary;
  final VoidCallback onTap;

  const GroupMemberTile({
    super.key,
    required this.friend,
    required this.isSelected,
    required this.isDark,
    required this.textColor,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isOnline = friend.status == 'online';

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : const Color(0xFFEDEFF5),
            ),
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? primary : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? primary
                      : (isDark
                            ? const Color(0xFF475569)
                            : const Color(0xFFCBD5E1)),
                  width: 1.6,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 15, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 14),
            Stack(
              clipBehavior: Clip.none,
              children: [
                FriendAvatar(friend: friend, radius: 24, primary: primary),
                if (isOnline)
                  Positioned(
                    right: -1,
                    bottom: -1,
                    child: Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF060B18)
                              : Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    toTitleCase(friend.name),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if ((friend.username ?? '').isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      '@${friend.username}',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? const Color(0xFF64748B)
                            : const Color(0xFF94A3B8),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown instead of the contact list when there's nothing to display: no
/// friends yet, or none match the current search.
class GroupMembersEmptyState extends StatelessWidget {
  final bool isDark;
  final String searchQuery;

  const GroupMembersEmptyState({
    super.key,
    required this.isDark,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Text(
          searchQuery.isEmpty
              ? l10n.createGroupScreenNoContactsEmpty
              : l10n.createGroupScreenNoContactsMatch(searchQuery),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}
