import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../providers/locale_provider.dart';
import '../widgets/settings_section.dart';

class _LanguageOption {
  final Locale? locale; // null = follow the device
  final String nativeName;
  final String englishName;

  const _LanguageOption({
    required this.locale,
    required this.nativeName,
    required this.englishName,
  });
}

const _languageOptions = [
  _LanguageOption(locale: null, nativeName: '', englishName: ''),
  _LanguageOption(
    locale: Locale('en'),
    nativeName: 'English',
    englishName: 'English',
  ),
  _LanguageOption(
    locale: Locale('hi'),
    nativeName: 'हिन्दी',
    englishName: 'Hindi',
  ),
  _LanguageOption(
    locale: Locale('bn'),
    nativeName: 'বাংলা',
    englishName: 'Bengali',
  ),
];

class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final current = context.watch<LocaleProvider>().locale;

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
          l10n.languageSettingsTitle,
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
                title: l10n.languageSettingsSectionHeader,
                isDark: isDark,
              ),
              SettingsCard(
                isDark: isDark,
                children: [
                  _LanguageRow(
                    title: l10n.languageSettingsFollowDevice,
                    isSelected: current == null,
                    isDark: isDark,
                    onTap: () => context.read<LocaleProvider>().setLocale(null),
                  ),
                  for (final option in _languageOptions.skip(1))
                    _LanguageRow(
                      title: option.nativeName,
                      subtitle: option.englishName,
                      isSelected:
                          current?.languageCode == option.locale!.languageCode,
                      isDark: isDark,
                      onTap: () => context.read<LocaleProvider>().setLocale(
                        option.locale,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              SettingsInfoBanner(
                title: l10n.languageSettingsNoticeTitle,
                message: l10n.languageSettingsNoticeBody,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _LanguageRow({
    required this.title,
    this.subtitle,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).primaryColor;
    final secondary = isDark
        ? AppTheme.darkTextSecondary
        : AppTheme.lightTextSecondary;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w600,
                      color: isSelected
                          ? accent
                          : (isDark ? AppTheme.darkText : AppTheme.lightText),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(fontSize: 12, color: secondary),
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_rounded, color: accent, size: 20),
          ],
        ),
      ),
    );
  }
}
