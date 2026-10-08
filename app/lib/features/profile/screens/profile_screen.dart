import 'package:flutter/material.dart';
import '../../../core/widgets/avatar_circle.dart';
import 'package:talkmos/core/utils/titlecase_function.dart';
import '../../../providers/providers.dart';
import '../../chats/services/socket_service/socket_service.dart';
import '../../calls/services/call_signaling/call_signaling_service.dart';
import 'edit_profile_screen.dart';
import 'privacy_settings_screen.dart';
import 'data_storage_settings_screen.dart';
import 'notifications_settings_screen.dart';
import 'appearance_settings_screen.dart';
import 'devices_screen.dart';
import 'help_support_screen.dart';
import 'about_screen.dart';
import 'language_settings_screen.dart';
import '../../system/services/app_update_service.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<void> _manualCheckUpdate() async {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.profileScreenCheckingForUpdates),
        duration: const Duration(seconds: 1),
      ),
    );
    final updating = await AppUpdateService.startIfAvailable();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          updating
              ? l10n.commonUpdateReady
              : l10n.profileScreenLatestVersion(l10n.commonAppName),
        ),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: updating ? 8 : 4),
        action: updating
            ? SnackBarAction(
                label: l10n.commonUpdateRestart,
                onPressed: AppUpdateService.install,
              )
            : null,
      ),
    );
  }

  void _onSettingsItemTap(String title) {
    if (title == 'Account') {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditProfileScreen(user: user),
          ),
        );
      }
    } else if (title == 'Privacy & Security') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PrivacySettingsScreen()),
      );
    } else if (title == 'Notifications') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const NotificationsSettingsScreen(),
        ),
      );
    } else if (title == 'Data and Storage') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const DataStorageSettingsScreen(),
        ),
      );
    } else if (title == 'Chat Settings') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AppearanceSettingsScreen(),
        ),
      );
    } else if (title == 'Devices') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const DevicesScreen()),
      );
    } else if (title == 'Language') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LanguageSettingsScreen()),
      );
    } else if (title == 'Help & Support') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const HelpSupportScreen()),
      );
    } else if (title == 'About') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AboutScreen()),
      );
    } else if (title == 'Log Out') {
      _logout();
    } else {
      // Every settings tile has an explicit branch above — this is only
      // reachable if a new tile is added without one.
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.profileScreenComingSoon(title))),
      );
    }
  }

  void _logout() {
    context.read<SocketService>().disconnect();
    context.read<CallSignalingService>().disconnect();
    context.read<BlockProvider>().reset();
    context.read<AuthProvider>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = context.watch<AuthProvider>().user;

    final name = currentUser?.name ?? '';
    final phone = currentUser?.phone ?? '';
    final avatarUrl = currentUser?.avatarUrl;

    final email = currentUser?.email ?? '';

    final bg = isDark ? const Color(0xFF000000) : Colors.white;
    final dividerColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : const Color(0xFFF1F5F9);
    final textPrimary = isDark ? Colors.white : const Color(0xFF000000);
    final textSecondary = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          l10n.commonSettings,
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 26,
          ),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.only(
          bottom: 62 + MediaQuery.of(context).padding.bottom + 16,
        ),
        children: [
          // ── Profile Header Tile ────────────────────────────────────
          InkWell(
            onTap: () => _onSettingsItemTap('Account'),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  AvatarCircle(
                    imageUrl: avatarUrl,
                    radius: 28,
                    backgroundColor: isDark
                        ? const Color(0xFF000E23)
                        : Theme.of(
                            context,
                          ).primaryColor.withValues(alpha: 0.12),
                    fallback: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'U',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.isNotEmpty
                              ? toTitleCase(name)
                              : (email.isNotEmpty
                                    ? email
                                    : l10n.profileScreenUserFallback),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        if (phone.isNotEmpty || email.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            phone.isNotEmpty ? phone : email,
                            style: TextStyle(
                              fontSize: 14,
                              color: textSecondary,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: isDark
                        ? const Color(0xFF64748B)
                        : const Color(0xFF94A3B8),
                    size: 22,
                  ),
                ],
              ),
            ),
          ),

          Divider(height: 1, indent: 0, color: dividerColor),

          // ── Settings List Items ──────────────────────────────────
          _tile(
            icon: Icons.shield_outlined,
            label: l10n.commonAccount,
            subtitle: l10n.profileScreenAccountDesc,
            isDark: isDark,
            dividerColor: dividerColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            onTap: () => _onSettingsItemTap('Account'),
          ),
          _tile(
            icon: Icons.lock_outline_rounded,
            label: l10n.profileScreenPrivacySecurity,
            subtitle: l10n.profileScreenPrivacySecurityDesc,
            isDark: isDark,
            dividerColor: dividerColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            onTap: () => _onSettingsItemTap('Privacy & Security'),
          ),
          _tile(
            icon: Icons.notifications_none_rounded,
            label: l10n.commonNotifications,
            subtitle: l10n.profileScreenNotificationsDesc,
            isDark: isDark,
            dividerColor: dividerColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            onTap: () => _onSettingsItemTap('Notifications'),
          ),
          _tile(
            icon: Icons.pie_chart_outline_rounded,
            label: l10n.profileScreenDataAndStorage,
            subtitle: l10n.profileScreenDataAndStorageDesc,
            isDark: isDark,
            dividerColor: dividerColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            onTap: () => _onSettingsItemTap('Data and Storage'),
          ),
          _tile(
            icon: Icons.palette_outlined,
            label: l10n.appearanceSettingsScreenTitle,
            subtitle: l10n.profileScreenChatSettingsDesc,
            isDark: isDark,
            dividerColor: dividerColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            onTap: () => _onSettingsItemTap('Chat Settings'),
          ),
          _tile(
            icon: Icons.desktop_windows_outlined,
            label: l10n.commonDevices,
            subtitle: l10n.profileScreenDevicesDesc,
            isDark: isDark,
            dividerColor: dividerColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            onTap: () => _onSettingsItemTap('Devices'),
          ),
          _tile(
            icon: Icons.language_rounded,
            label: l10n.profileScreenLanguage,
            subtitle: l10n.profileScreenLanguageDesc,
            isDark: isDark,
            dividerColor: dividerColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            onTap: () => _onSettingsItemTap('Language'),
          ),
          _tile(
            icon: Icons.help_outline_rounded,
            label: l10n.profileScreenHelpSupport,
            subtitle: l10n.aboutScreenHelpSupportDesc,
            isDark: isDark,
            dividerColor: dividerColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            onTap: () => _onSettingsItemTap('Help & Support'),
          ),
          _tile(
            icon: Icons.system_update_rounded,
            label: l10n.profileScreenCheckForUpdates,
            subtitle: l10n.profileScreenCheckForUpdatesDesc,
            isDark: isDark,
            dividerColor: dividerColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            onTap: _manualCheckUpdate,
          ),
          _tile(
            icon: Icons.info_outline_rounded,
            label: l10n.commonAbout,
            subtitle: l10n.profileScreenAboutDesc,
            isDark: isDark,
            dividerColor: dividerColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            onTap: () => _onSettingsItemTap('About'),
          ),

          const SizedBox(height: 8),

          // ── Log Out button ───────────────────────────────────────
          InkWell(
            onTap: _logout,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.logout_rounded,
                      color: Colors.redAccent,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      l10n.profileScreenLogOut,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String label,
    required String subtitle,
    required bool isDark,
    required Color dividerColor,
    required Color textPrimary,
    required Color textSecondary,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    // Derived from the primary colour so the tint tracks the
                    // icon it sits behind when the brand colour changes.
                    color: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: isDark ? 0.28 : 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: Theme.of(context).primaryColor,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.3,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark
                      ? const Color(0xFF64748B)
                      : const Color(0xFF94A3B8),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        Divider(height: 1, indent: 66, color: dividerColor),
      ],
    );
  }
}
