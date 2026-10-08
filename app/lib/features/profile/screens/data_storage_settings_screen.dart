import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../core/services/data_usage_store.dart';
import '../../../core/services/media_cache_service.dart';
import '../../../core/utils/format_bytes.dart';
import '../../../providers/settings_provider.dart';
import '../widgets/settings_section.dart';
import 'privacy_settings_screen.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';

class DataStorageSettingsScreen extends StatefulWidget {
  const DataStorageSettingsScreen({super.key});

  @override
  State<DataStorageSettingsScreen> createState() =>
      _DataStorageSettingsScreenState();
}

class _DataStorageSettingsScreenState extends State<DataStorageSettingsScreen> {
  /// Null while being measured, so the row shows a placeholder rather than a
  /// wrong "0 B" before the real figure lands.
  int? _cacheBytes;

  bool _sizeUnavailable = false;

  bool _isClearing = false;

  @override
  void initState() {
    super.initState();
    _measureCache();
  }

  Future<void> _measureCache() async {
    try {
      final bytes = await MediaCacheService().getCacheSize();
      if (mounted) {
        setState(() {
          _cacheBytes = bytes;
          _sizeUnavailable = false;
        });
      }
    } catch (e) {
      // Clearing is still offered — it's the useful action, and it doesn't
      // depend on knowing the size first.
      debugPrint('Could not measure the media cache: $e');
      if (mounted) setState(() => _sizeUnavailable = true);
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
          l10n.dataStorageSettingsScreenTitle,
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
              SettingsSectionHeader(
                title: l10n.dataStorageSettingsScreenStorageHeader,
                isDark: isDark,
              ),
              SettingsCard(
                isDark: isDark,
                children: [
                  SettingsNavigationRow(
                    leadingIcon: Icons.folder_outlined,
                    title: l10n.dataStorageSettingsScreenCachedMedia,
                    value: switch ((
                      _isClearing,
                      _sizeUnavailable,
                      _cacheBytes,
                    )) {
                      (true, _, _) => l10n.dataStorageSettingsScreenClearing,
                      (_, true, _) => l10n.dataStorageSettingsScreenTapToClear,
                      (_, _, final int bytes) => formatBytes(bytes),
                      _ => l10n.dataStorageSettingsScreenMeasuring,
                    },
                    isDark: isDark,
                    // Enabled once the size is known *or* known to be
                    // unavailable — only the measuring state blocks the tap.
                    onTap:
                        _isClearing ||
                            (_cacheBytes == null && !_sizeUnavailable)
                        ? null
                        : _confirmClearCache,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SettingsInfoBanner(
                isDark: isDark,
                icon: Icons.info_outline_rounded,
                title: l10n.dataStorageSettingsScreenClearingSafeTitle,
                message: l10n.dataStorageSettingsScreenClearingSafeDesc,
              ),

              const SizedBox(height: 28),

              SettingsSectionHeader(
                title: l10n.dataStorageSettingsScreenMediaUpload,
                isDark: isDark,
              ),
              SettingsCard(
                isDark: isDark,
                children: [
                  SettingsNavigationRow(
                    leadingIcon: Icons.high_quality_outlined,
                    title: l10n.dataStorageSettingsScreenUploadQuality,
                    value: settings.mediaUploadQuality.label,
                    isDark: isDark,
                    showValueAsPill: true,
                    onTap: _pickUploadQuality,
                  ),
                ],
              ),

              const SizedBox(height: 28),

              SettingsSectionHeader(
                title: l10n.dataStorageSettingsScreenAutomaticDownloads,
                isDark: isDark,
              ),
              SettingsCard(
                isDark: isDark,
                children: [
                  SettingsToggleRow(
                    leadingIcon: Icons.wifi_rounded,
                    title: l10n.dataStorageSettingsScreenAutoSaveWifiOnly,
                    subtitle:
                        l10n.dataStorageSettingsScreenAutoSaveWifiOnlyDesc,
                    value: settings.autoSaveWifiOnly,
                    isDark: isDark,
                    onChanged: (val) => context
                        .read<SettingsProvider>()
                        .setAutoSaveWifiOnly(val),
                  ),
                  SettingsNavigationRow(
                    leadingIcon: Icons.photo_library_outlined,
                    title: l10n.dataStorageSettingsScreenSaveToPhotos,
                    value: settings.saveToPhotos
                        ? l10n.dataStorageSettingsScreenOn
                        : l10n.dataStorageSettingsScreenOff,
                    isDark: isDark,
                    showValueAsPill: true,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PrivacySettingsScreen(),
                      ),
                    ),
                  ),
                ],
              ),
              if (!settings.saveToPhotos) ...[
                const SizedBox(height: 10),
                SettingsInfoBanner(
                  isDark: isDark,
                  icon: Icons.lightbulb_outline_rounded,
                  title: l10n.dataStorageSettingsScreenNothingAutoSavedTitle,
                  message: l10n.dataStorageSettingsScreenNothingAutoSavedDesc,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickUploadQuality() async {
    final l10n = AppLocalizations.of(context);
    final settings = context.read<SettingsProvider>();
    final current = settings.mediaUploadQuality;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subColor = isDark
        ? AppTheme.darkTextSecondary
        : AppTheme.lightTextSecondary;

    final selected = await showModalBottomSheet<MediaUploadQuality>(
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
                  l10n.dataStorageSettingsScreenPhotoUploadQualityTitle,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF000000),
                  ),
                ),
              ),
            ),
            for (final option in MediaUploadQuality.values)
              ListTile(
                title: Text(
                  option.label +
                      (option == MediaUploadQuality.standard
                          ? '  (${l10n.dataStorageSettingsScreenRecommended})'
                          : ''),
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF000000),
                  ),
                ),
                subtitle: Text(switch (option) {
                  MediaUploadQuality.dataSaver =>
                    l10n.dataStorageSettingsScreenQualityDataSaverDesc,
                  MediaUploadQuality.standard =>
                    l10n.dataStorageSettingsScreenQualityStandardDesc,
                  MediaUploadQuality.high =>
                    l10n.dataStorageSettingsScreenQualityHighDesc,
                }, style: TextStyle(fontSize: 12, color: subColor)),
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

    if (selected != null && selected != current) {
      await settings.setMediaUploadQuality(selected);
    }
  }

  Future<void> _confirmClearCache() async {
    final l10n = AppLocalizations.of(context);
    final size = _cacheBytes == null ? '' : ' (${formatBytes(_cacheBytes!)})';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.dataStorageSettingsScreenClearCacheTitle),
        content: Text(l10n.dataStorageSettingsScreenClearCacheDesc(size)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.dataStorageSettingsScreenClear),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isClearing = true);
    try {
      await MediaCacheService().clearCache();
    } finally {
      // Re-measure rather than assuming zero — eviction is the cache manager's
      // call, and a file still open for playback can survive the sweep.
      if (mounted) {
        setState(() => _isClearing = false);
        await _measureCache();
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.dataStorageSettingsScreenCacheCleared),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
