import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../core/config/legal_links.dart';
import '../widgets/settings_section.dart';
import 'help_support_screen.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String? _version;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() => _version = '${info.version}+${info.buildNumber}');
    } catch (_) {}
  }

  Future<void> _openLegal(Uri url) async {
    final opened = await LegalLinks.open(url);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).aboutScreenBrowserOpenError,
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: theme.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.aboutScreenTitle,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? AppTheme.darkText : AppTheme.lightText,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            theme.primaryColor.withValues(
                              alpha: isDark ? 0.22 : 0.12,
                            ),
                            theme.primaryColor.withValues(alpha: 0),
                          ],
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(26),
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 92,
                          height: 92,
                          excludeFromSemantics: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      l10n.commonAppName,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                        color: isDark ? AppTheme.darkText : AppTheme.lightText,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.welcomeScreenTagline,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: theme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : const Color(0xFFE2E7FF),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: theme.primaryColor.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        _version != null
                            ? l10n.aboutScreenVersion(_version!)
                            : ' ',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppTheme.darkText
                              : AppTheme.lightText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.07)
                        : const Color(0xFFE3E3EF),
                  ),
                ),
                child: Text(
                  l10n.welcomeScreenDescription,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.6,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              SettingsSectionHeader(
                title: l10n.aboutScreenLegalSectionTitle,
                isDark: isDark,
              ),
              SettingsCard(
                isDark: isDark,
                children: [
                  SettingsNavigationRow(
                    leadingIcon: Icons.gavel_rounded,
                    title: l10n.aboutScreenTermsOfService,
                    value: l10n.privacySettingsScreenTermsDesc,
                    isDark: isDark,
                    onTap: () => _openLegal(LegalLinks.terms),
                  ),
                  SettingsNavigationRow(
                    leadingIcon: Icons.description_outlined,
                    title: l10n.aboutScreenPrivacyPolicy,
                    value: l10n.privacySettingsScreenPrivacyPolicyDesc,
                    isDark: isDark,
                    onTap: () => _openLegal(LegalLinks.privacyPolicy),
                  ),
                  SettingsNavigationRow(
                    leadingIcon: Icons.help_outline_rounded,
                    title: l10n.profileScreenHelpSupport,
                    value: l10n.aboutScreenHelpSupportDesc,
                    isDark: isDark,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HelpSupportScreen(),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              Center(
                child: Container(
                  width: 32,
                  height: 3,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.12)
                        : const Color(0xFFE3E3EF),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                l10n.aboutScreenCopyright(
                  DateTime.now().year.toString(),
                  l10n.commonAppName,
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
