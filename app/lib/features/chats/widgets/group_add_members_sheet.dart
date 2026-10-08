import 'package:flutter/material.dart';
import '../../../core/widgets/avatar_circle.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';
import '../../../core/utils/titlecase_function.dart';
import '../../../models/friend_model.dart';

/// Sheet listing friends who aren't already in the group, letting the caller
/// multi-select and confirm additions via [onAddMembers].
void showGroupAddMembersSheet({
  required BuildContext context,
  required bool isDark,
  required List<FriendModel> friends,
  required List<dynamic> members,
  required ValueChanged<List<String>> onAddMembers,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _GroupAddMembersSheetBody(
      isDark: isDark,
      friends: friends,
      members: members,
      onAddMembers: onAddMembers,
    ),
  );
}

class _GroupAddMembersSheetBody extends StatefulWidget {
  final bool isDark;
  final List<FriendModel> friends;
  final List<dynamic> members;
  final ValueChanged<List<String>> onAddMembers;

  const _GroupAddMembersSheetBody({
    required this.isDark,
    required this.friends,
    required this.members,
    required this.onAddMembers,
  });

  @override
  State<_GroupAddMembersSheetBody> createState() =>
      _GroupAddMembersSheetBodyState();
}

class _GroupAddMembersSheetBodyState extends State<_GroupAddMembersSheetBody> {
  final Set<String> _selectedToAdd = {};

  @override
  Widget build(BuildContext context) {
    final existingMemberIds = widget.members.map((m) {
      final user = (m is Map && m['userId'] is Map)
          ? m['userId'] as Map<String, dynamic>
          : (m is Map<String, dynamic> ? m : <String, dynamic>{});
      return (user['_id'] ?? user['id'] ?? m['_id'] ?? m['id'] ?? '')
          .toString();
    }).toSet();
    final eligibleFriends = widget.friends
        .where((f) => !existingMemberIds.contains(f.id))
        .toList();

    final isDark = widget.isDark;
    final sheetBg = isDark ? const Color(0xFF000814) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF000000);
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final primary = Theme.of(context).primaryColor;
    final l10n = AppLocalizations.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.groupProfileScreenAddMembersTitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              TextButton(
                onPressed: _selectedToAdd.isEmpty
                    ? null
                    : () {
                        Navigator.pop(context);
                        widget.onAddMembers(_selectedToAdd.toList());
                      },
                child: Text(
                  l10n.groupProfileScreenAddButtonLabel(_selectedToAdd.length),
                  style: TextStyle(
                    color: _selectedToAdd.isEmpty ? subColor : primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: eligibleFriends.isEmpty
                ? Center(
                    child: Text(
                      l10n.groupProfileScreenNoMoreContacts,
                      style: TextStyle(color: subColor, fontSize: 14),
                    ),
                  )
                : ListView.builder(
                    itemCount: eligibleFriends.length,
                    itemBuilder: (_, i) {
                      final friend = eligibleFriends[i];
                      final isSelected = _selectedToAdd.contains(friend.id);
                      return ListTile(
                        dense: true,
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedToAdd.remove(friend.id);
                            } else {
                              _selectedToAdd.add(friend.id);
                            }
                          });
                        },
                        leading: AvatarCircle(
                          imageUrl: friend.avatarUrl,
                          radius: 18,
                          backgroundColor: primary.withValues(alpha: 0.12),
                          fallback: Text(
                            friend.name.isNotEmpty
                                ? friend.name[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          toTitleCase(friend.name),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: textColor,
                          ),
                        ),
                        trailing: Icon(
                          isSelected
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: isSelected ? primary : subColor,
                          size: 22,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
