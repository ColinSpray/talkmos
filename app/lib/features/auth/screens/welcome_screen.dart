import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/auth_hero_tag.dart';
import '../widgets/auth_pulsing_logo.dart';
import '../widgets/auth_wordmark.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    final primary = theme.primaryColor;
    // Dark surfaces need a lighter tint of the accent to stay legible, derived
    // from the accent rather than hardcoded so it tracks the user's choice.
    final accent = isDark ? Color.lerp(primary, Colors.white, 0.35)! : primary;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF000000), const Color(0xFF1E1E38)]
                : [const Color(0xFFFAF9FF), const Color(0xFFF5F4FA)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: Column(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AuthPulsingLogo(
                                areaSize: 250,
                                ringBaseSize: 120,
                                ringMaxSize: 244,
                                accent: accent,
                                isDark: isDark,
                                child: Hero(
                                  tag: authLogoHeroTag,
                                  child: Image.asset(
                                    "assets/images/logo.png",
                                    width: 120,
                                    excludeFromSemantics: true,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              AuthWordmark(isDark: isDark, primary: primary),
                              const SizedBox(height: 8),
                              _buildTitleDivider(primary),
                              const SizedBox(height: 14),
                              Text(
                                l10n.welcomeScreenTagline,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: accent,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                ),
                                child: Text(
                                  l10n.welcomeScreenDescription,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF64748B),
                                    height: 1.4,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 22),
                              _buildFeatureIcons(isDark, accent),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                _buildStartButton(context, l10n, primary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitleDivider(Color primary) {
    return Container(
      width: 40,
      height: 3,
      decoration: BoxDecoration(
        color: primary,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildFeatureIcons(bool isDark, Color accent) {
    return ExcludeSemantics(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline_rounded, color: accent, size: 22),
          _buildIconDivider(isDark),
          Icon(Icons.videocam_outlined, color: accent, size: 22),
          _buildIconDivider(isDark),
          const Icon(Icons.call_rounded, color: Color(0xFF10B981), size: 22),
          _buildIconDivider(isDark),
          const Icon(
            Icons.groups_outlined,
            color: AppTheme.secondary,
            size: 22,
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton(
    BuildContext context,
    AppLocalizations l10n,
    Color primary,
  ) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        // Flat, matching the now-gradient-free logo.
        color: primary,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
        ),
        onPressed: () => context.replace(AppRoutes.phoneLogin),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                l10n.welcomeScreenLetsStart,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildIconDivider(bool isDark) {
    return Container(
      width: 1,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 18),
      color: isDark
          ? Colors.white.withValues(alpha: 0.12)
          : const Color(0xFFE2E2EA),
    );
  }
}
