import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';
import 'group_settings_widgets.dart';

/// Placeholder shown on [GroupProfileScreen] while group details are loading,
/// mirroring the loaded layout's section shape so nothing jumps on arrival.
class GroupProfileLoadingSkeleton extends StatelessWidget {
  final bool isDark;
  final Color primary;

  const GroupProfileLoadingSkeleton({
    super.key,
    required this.isDark,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Skeletonizer(
      enabled: true,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Column(
            children: [
              const Bone.circle(size: 92),
              const SizedBox(height: 14),
              const Bone.text(width: 140, fontSize: 22),
              const SizedBox(height: 6),
              const Bone.text(width: 90, fontSize: 15),
            ],
          ),
          const SizedBox(height: 24),
          GroupSettingsSection(
            icon: Icons.groups_rounded,
            title: l10n.commonMembers,
            accent: primary,
            isDark: isDark,
            children: [
              GroupSettingsRow(
                icon: Icons.people_alt_rounded,
                label: l10n.commonMembers,
                value: '0',
                isDark: isDark,
              ),
              GroupSettingsRow(
                icon: Icons.shield_rounded,
                label: l10n.commonAdmins,
                value: '0',
                isDark: isDark,
              ),
              GroupSettingsRow(
                icon: Icons.person_add_alt_1_rounded,
                label: l10n.groupProfileScreenInviteMembers,
                isDark: isDark,
              ),
            ],
          ),
          GroupSettingsSection(
            icon: Icons.lock_rounded,
            title: l10n.groupProfileScreenPrivacy,
            accent: primary,
            isDark: isDark,
            children: [
              GroupSettingsRow(
                icon: Icons.verified_user_rounded,
                label: l10n.commonPermissions,
                isDark: isDark,
              ),
            ],
          ),
          GroupSettingsSection(
            icon: Icons.chat_bubble_rounded,
            title: l10n.commonChat,
            accent: primary,
            isDark: isDark,
            children: [
              GroupSettingsRow(
                icon: Icons.edit_rounded,
                label: l10n.groupProfileScreenEditGroupInfo,
                isDark: isDark,
              ),
            ],
          ),
          GroupSettingsSection(
            icon: Icons.notifications_rounded,
            title: l10n.commonNotifications,
            accent: primary,
            isDark: isDark,
            children: [
              GroupSettingsRow(
                icon: Icons.notifications_active_rounded,
                label: l10n.groupProfileScreenMuteNotifications,
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
