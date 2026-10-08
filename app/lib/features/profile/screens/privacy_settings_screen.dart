import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/block_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../core/config/legal_links.dart';
import '../../../core/services/gallery_save_service.dart';
import '../widgets/settings_section.dart';
import 'blocked_contacts_screen.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';

class PrivacySettingsScreen extends StatelessWidget {
  const PrivacySettingsScreen({super.key});

  static const List<String> _visibilityOptions = [
    'Everyone',
    'Contacts',
    'Nobody',
  ];

  static String _visibilityLabel(AppLocalizations l10n, String value) {
    switch (value) {
      case 'Everyone':
        return l10n.commonEveryone;
      case 'Contacts':
        return l10n.privacySettingsScreenVisibilityContacts;
      case 'Nobody':
        return l10n.privacySettingsScreenVisibilityNobody;
      default:
        return value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? AppTheme.darkBg : const Color(0xFFFAF9FF);

    return Scaffold(
      backgroundColor: surface,
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        shape: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : const Color(0xFFE3E3EF),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: theme.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.privacySettingsScreenTitle,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? AppTheme.darkText : AppTheme.lightText,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SecurityBanner(),

              const SizedBox(height: 28),

              SettingsSectionHeader(title: l10n.commonAccount, isDark: isDark),
              Builder(
                builder: (context) {
                  final isPrivate =
                      !(context.watch<AuthProvider>().user?.isPublic ?? true);
                  return SettingsCard(
                    isDark: isDark,
                    children: [
                      SettingsToggleRow(
                        leadingIcon: isPrivate
                            ? Icons.lock_rounded
                            : Icons.public_rounded,
                        // States both modes by name, so "off" can't be misread
                        // as "no setting applied".
                        title: l10n.privacySettingsScreenPrivateAccountTitle,
                        subtitle: isPrivate
                            ? l10n.privacySettingsScreenPrivateAccountDescPrivate
                            : l10n.privacySettingsScreenPrivateAccountDescPublic,
                        value: isPrivate,
                        isDark: isDark,
                        onChanged: (val) => _setPrivateAccount(context, val),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 28),

              SettingsSectionHeader(
                title: l10n.privacySettingsScreenPrivacyControls,
                isDark: isDark,
              ),
              SettingsCard(
                isDark: isDark,
                children: [
                  SettingsToggleRow(
                    leadingIcon: Icons.done_all_rounded,
                    title: l10n.privacySettingsScreenReadReceipts,
                    subtitle: l10n.privacySettingsScreenReadReceiptsDesc,
                    value: settings.readReceipts,
                    isDark: isDark,
                    onChanged: (val) => _setReadReceipts(context, val),
                  ),
                  SettingsNavigationRow(
                    leadingIcon: Icons.visibility_outlined,
                    title: l10n.privacySettingsScreenLastSeenOnline,
                    value: _visibilityLabel(l10n, settings.lastSeenVisibility),
                    isDark: isDark,
                    showValueAsPill: true,
                    onTap: () => _pickVisibility(
                      context: context,
                      sheetTitle: l10n.privacySettingsScreenLastSeenSheetTitle,
                      current: settings.lastSeenVisibility,
                      onSelected: (v) => _setLastSeen(context, v),
                    ),
                  ),
                  SettingsNavigationRow(
                    leadingIcon: Icons.account_circle_outlined,
                    title: l10n.privacySettingsScreenProfilePhotoTitle,
                    value: _visibilityLabel(
                      l10n,
                      settings.profilePhotoVisibility,
                    ),
                    isDark: isDark,
                    showValueAsPill: true,
                    onTap: () => _pickVisibility(
                      context: context,
                      sheetTitle:
                          l10n.privacySettingsScreenProfilePhotoSheetTitle,
                      current: settings.profilePhotoVisibility,
                      onSelected: (v) => _setProfilePhoto(context, v),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              SettingsSectionHeader(
                title: l10n.privacySettingsScreenMedia,
                isDark: isDark,
              ),
              SettingsCard(
                isDark: isDark,
                children: [
                  SettingsToggleRow(
                    leadingIcon: Icons.photo_library_outlined,
                    title: l10n.privacySettingsScreenSaveToPhotos,
                    subtitle: l10n.privacySettingsScreenSaveToPhotosDesc,
                    value: settings.saveToPhotos,
                    isDark: isDark,
                    onChanged: (val) => _setSaveToPhotos(context, val),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              SettingsSectionHeader(
                title: l10n.privacySettingsScreenBlockedContacts,
                isDark: isDark,
              ),
              SettingsCard(
                isDark: isDark,
                children: [
                  Builder(
                    builder: (context) {
                      final count = context
                          .watch<BlockProvider>()
                          .blockedUsers
                          .length;
                      return SettingsNavigationRow(
                        leadingIcon: Icons.block_rounded,
                        title: l10n.privacySettingsScreenBlockedContacts,
                        value: count == 0
                            ? l10n.privacySettingsScreenBlockedCountNone
                            : l10n.privacySettingsScreenBlockedCount(count),
                        isDark: isDark,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BlockedContactsScreen(),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 28),

              SettingsSectionHeader(
                title: l10n.privacySettingsScreenLegalPolicy,
                isDark: isDark,
              ),
              SettingsCard(
                isDark: isDark,
                children: [
                  SettingsNavigationRow(
                    leadingIcon: Icons.description_outlined,
                    title: l10n.privacySettingsScreenPrivacyPolicy,
                    value: l10n.privacySettingsScreenPrivacyPolicyDesc,
                    isDark: isDark,
                    onTap: () => _openLegal(context, LegalLinks.privacyPolicy),
                  ),
                  SettingsNavigationRow(
                    leadingIcon: Icons.gavel_rounded,
                    title: l10n.privacySettingsScreenTermsOfService,
                    value: l10n.privacySettingsScreenTermsDesc,
                    isDark: isDark,
                    onTap: () => _openLegal(context, LegalLinks.terms),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _setPrivateAccount(BuildContext context, bool value) async {
    final auth = context.read<AuthProvider>();
    try {
      await auth.updatePrivacySettings(isPublic: !value);
    } catch (e) {
      if (context.mounted) _showSyncError(context);
    }
  }

  Future<void> _setReadReceipts(BuildContext context, bool value) async {
    final settings = context.read<SettingsProvider>();
    final auth = context.read<AuthProvider>();
    final previous = settings.readReceipts;

    await settings.setReadReceipts(value);
    try {
      await auth.updatePrivacySettings(readReceiptsEnabled: value);
    } catch (e) {
      await settings.setReadReceipts(previous);
      if (context.mounted) _showSyncError(context);
    }
  }

  Future<void> _setLastSeen(BuildContext context, String value) async {
    final settings = context.read<SettingsProvider>();
    final auth = context.read<AuthProvider>();
    final previous = settings.lastSeenVisibility;

    await settings.setLastSeenVisibility(value);
    try {
      await auth.updatePrivacySettings(lastSeenVisibility: value);
    } catch (e) {
      await settings.setLastSeenVisibility(previous);
      if (context.mounted) _showSyncError(context);
    }
  }

  Future<void> _setProfilePhoto(BuildContext context, String value) async {
    final settings = context.read<SettingsProvider>();
    final auth = context.read<AuthProvider>();
    final previous = settings.profilePhotoVisibility;

    await settings.setProfilePhotoVisibility(value);
    try {
      await auth.updatePrivacySettings(profilePhotoVisibility: value);
    } catch (e) {
      await settings.setProfilePhotoVisibility(previous);
      if (context.mounted) _showSyncError(context);
    }
  }

  Future<void> _setSaveToPhotos(BuildContext context, bool value) async {
    final settings = context.read<SettingsProvider>();

    if (!value) {
      await settings.setSaveToPhotos(false);
      return;
    }

    final gallery = GallerySaveService.instance;
    final granted = await gallery.hasAccess() || await gallery.requestAccess();

    if (!granted) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(
                context,
              ).privacySettingsScreenGalleryPermissionNeeded,
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    await settings.setSaveToPhotos(true);
  }

  void _showSyncError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context).privacySettingsScreenSyncError,
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openLegal(BuildContext context, Uri url) async {
    final opened = await LegalLinks.open(url);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).privacySettingsScreenBrowserOpenError,
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _pickVisibility({
    required BuildContext context,
    required String sheetTitle,
    required String current,
    required ValueChanged<String> onSelected,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  sheetTitle,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF000000),
                  ),
                ),
              ),
            ),
            for (final option in _visibilityOptions)
              ListTile(
                title: Text(
                  _visibilityLabel(AppLocalizations.of(ctx), option),
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF000000),
                  ),
                ),
                trailing: current == option
                    ? Icon(
                        Icons.check_rounded,
                        color: Theme.of(ctx).primaryColor,
                      )
                    : null,
                onTap: () => Navigator.pop(ctx, option),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (selected != null && selected != current) onSelected(selected);
  }
}

/// Header card describing how messages are actually protected.
class _SecurityBanner extends StatelessWidget {
  const _SecurityBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : const Color(0xFFE3E3EF),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.shield_rounded, size: 40, color: theme.primaryColor),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context).privacySettingsScreenConnectionSecured,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? AppTheme.darkText : AppTheme.lightText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(
              context,
            ).privacySettingsScreenConnectionSecuredDesc,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
