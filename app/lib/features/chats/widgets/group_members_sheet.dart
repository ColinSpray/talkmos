import 'package:flutter/material.dart';
import '../../../core/widgets/avatar_circle.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';
import '../../../core/utils/titlecase_function.dart';

void showGroupMembersSheet({
  required BuildContext context,
  required List<dynamic> members,
  required bool isDark,
  required Color textColor,
  bool adminsOnly = false,
  void Function(String userId, String name)? onRemoveMember,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: isDark ? const Color(0xFF111827) : Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _GroupMembersSheetBody(
      members: members,
      isDark: isDark,
      textColor: textColor,
      adminsOnly: adminsOnly,
      onRemoveMember: onRemoveMember,
    ),
  );
}

class _GroupMembersSheetBody extends StatelessWidget {
  final List<dynamic> members;
  final bool isDark;
  final Color textColor;
  final bool adminsOnly;
  final void Function(String userId, String name)? onRemoveMember;

  const _GroupMembersSheetBody({
    required this.members,
    required this.isDark,
    required this.textColor,
    required this.adminsOnly,
    this.onRemoveMember,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final l10n = AppLocalizations.of(context);
    final shown = adminsOnly
        ? members.where((m) {
            final role = (m is Map ? m['role'] : null)?.toString() ?? 'member';
            return role == 'admin' || role == 'owner';
          }).toList()
        : members;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.92,
      builder: (_, controller) => Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 38,
            height: 4,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                adminsOnly
                    ? l10n.commonAdmins
                    : l10n.groupProfileScreenMembersCountTitle(shown.length),
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
          ),
          Expanded(
            child: shown.isEmpty
                ? Center(
                    child: Text(
                      adminsOnly
                          ? l10n.groupProfileScreenNoAdminsYet
                          : l10n.groupProfileScreenNoMembersYet,
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: controller,
                    itemCount: shown.length,
                    itemBuilder: (_, i) {
                      final m = shown[i];
                      final user = (m is Map && m['userId'] is Map)
                          ? Map<String, dynamic>.from(m['userId'] as Map)
                          : <String, dynamic>{};
                      final id = user['_id']?.toString() ?? '';
                      final name =
                          user['name']?.toString() ?? l10n.commonMember;
                      final avatar = user['avatarUrl']?.toString() ?? '';
                      final role =
                          (m is Map ? m['role'] : null)?.toString() ?? 'member';

                      return ListTile(
                        leading: AvatarCircle(
                          imageUrl: avatar,
                          radius: 22,
                          backgroundColor: primary.withValues(alpha: 0.12),
                          fallback: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: TextStyle(
                              color: primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          toTitleCase(name),
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: role == 'member'
                            ? null
                            : Text(
                                role == 'owner'
                                    ? l10n.groupProfileScreenOwnerRole
                                    : l10n.commonAdmin,
                                style: TextStyle(
                                  color: primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                        trailing: role == 'owner' || onRemoveMember == null
                            ? null
                            : IconButton(
                                icon: const Icon(
                                  Icons.person_remove_rounded,
                                  color: Colors.redAccent,
                                  size: 20,
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                  onRemoveMember!(id, name);
                                },
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
