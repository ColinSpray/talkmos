import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../core/notifications/message_notifier.dart';
import '../../../core/notifications/notification_sounds.dart';
import '../../../core/notifications/sound_selector_row.dart';
import '../../calls/services/call_notification_service.dart';
import '../widgets/settings_section.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';

class NotificationsSettingsScreen extends StatelessWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final enabled = settings.receiveNotifications;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : const Color(0xFFFAF9FF),
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.darkBg : const Color(0xFFFAF9FF),
        elevation: 0,
        scrolledUnderElevation: 0,
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
        titleSpacing: 0,
        title: Text(
          l10n.commonNotifications,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? AppTheme.darkText : AppTheme.lightText,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SettingsSectionHeader(
                title: l10n.notificationsSettingsScreenAlertChannels,
                isDark: isDark,
              ),

              SettingsCard(
                isDark: isDark,
                children: [
                  SettingsToggleRow(
                    title: l10n.notificationsSettingsScreenReceiveNotifications,
                    subtitle: l10n
                        .notificationsSettingsScreenReceiveNotificationsDesc,
                    value: settings.receiveNotifications,
                    isDark: isDark,
                    onChanged: settings.setReceiveNotifications,
                  ),

                  // Everything below depends on notifications being on, so it
                  // dims and stops responding as a group when they're off.
                  _DependentGroup(
                    enabled: enabled,
                    children: [
                      SoundSelectorRow(
                        title: l10n.notificationsSettingsScreenMessageSound,
                        store: NotificationSoundStore.messages,
                        channel: MessageNotifier.channel,
                        allowSilent: true,
                      ),
                      SettingsToggleRow(
                        title: l10n.notificationsSettingsScreenVibrationAlerts,
                        subtitle:
                            l10n.notificationsSettingsScreenVibrationAlertsDesc,
                        value: settings.vibrate,
                        isDark: isDark,
                        onChanged: enabled ? settings.setVibrate : null,
                      ),
                      SettingsToggleRow(
                        title: l10n.notificationsSettingsScreenMessagePreviews,
                        subtitle:
                            l10n.notificationsSettingsScreenMessagePreviewsDesc,
                        value: settings.showPreview,
                        isDark: isDark,
                        onChanged: enabled ? settings.setShowPreview : null,
                      ),
                      SoundSelectorRow(
                        title: l10n.notificationsSettingsScreenCallRingtone,
                        store: NotificationSoundStore.calls,
                        channel: CallNotificationService.incomingChannel,
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 28),
              const _PrivacyCard(),
              const SizedBox(height: 28),

              SettingsInfoBanner(
                title: l10n.notificationsSettingsScreenAudioToneNoticeTitle,
                message: l10n.notificationsSettingsScreenAudioToneNoticeDesc,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dims and disables a run of rows together, mirroring how the master toggle
/// gates everything under it.
class _DependentGroup extends StatelessWidget {
  final bool enabled;
  final List<Widget> children;

  const _DependentGroup({required this.enabled, required this.children});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final divider = Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Divider(
        height: 1,
        thickness: 1,
        color: isDark
            ? Colors.white.withValues(alpha: 0.07)
            : const Color(0xFFE8E8F2),
      ),
    );

    final rows = <Widget>[];
    for (final child in children) {
      rows.add(divider);
      rows.add(child);
    }

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: enabled ? 1.0 : 0.5,
      child: IgnorePointer(
        ignoring: !enabled,
        child: Column(children: rows),
      ),
    );
  }
}

/// Decorative card reusing a bundled chat wallpaper as artwork.
class _PrivacyCard extends StatelessWidget {
  const _PrivacyCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 150,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              isDark
                  ? 'assets/wallpapers/cosmic_dark.png'
                  : 'assets/wallpapers/breeze_light.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: Theme.of(context).primaryColor),
            ),
            // Keeps the caption legible over whatever the artwork is doing.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                  colors: [
                    Colors.black.withValues(alpha: isDark ? 0.75 : 0.6),
                    Colors.black.withValues(alpha: 0.05),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppLocalizations.of(
                      context,
                    ).notificationsSettingsScreenPrivateByDefaultTitle,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppLocalizations.of(
                      context,
                    ).notificationsSettingsScreenPrivateByDefaultDesc,
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
