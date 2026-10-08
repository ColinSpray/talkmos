import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';
import '../../../core/config/legal_links.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/three_dot_loader.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/locale_provider.dart';
import '../widgets/auth_hero_tag.dart';
import '../widgets/auth_pulsing_logo.dart';
import '../widgets/auth_wordmark.dart';
import 'otp_verification_screen.dart';

/// Phone-number entry — the primary login/registration entry point.
class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _phoneController = TextEditingController();
  final _phoneFocusNode = FocusNode();
  final _countrySearchController = TextEditingController();

  bool _loading = false;
  bool _socialLoading = false;
  bool _agreedToTerms = false;
  bool _showTermsHint = false;
  String? _phoneError;
  // Disambiguates the selected country when several share a dial code (e.g.
  // United States and Canada are both +1) now that flags no longer do.
  String _selectedCountryName = 'India';
  String _selectedCode = '+91';

  // Held as fields (not created in build) so they're disposed rather than
  // leaked on every rebuild.
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  static const _countries = [
    {'name': 'India', 'code': '+91'},
    {'name': 'United States', 'code': '+1'},
    {'name': 'United Kingdom', 'code': '+44'},
    {'name': 'Bangladesh', 'code': '+880'},
    {'name': 'United Arab Emirates', 'code': '+971'},
    {'name': 'Saudi Arabia', 'code': '+966'},
    {'name': 'Singapore', 'code': '+65'},
    {'name': 'Australia', 'code': '+61'},
    {'name': 'Canada', 'code': '+1'},
    {'name': 'Germany', 'code': '+49'},
  ];

  @override
  void initState() {
    super.initState();
    _phoneFocusNode.addListener(_onFocusChange);
    _phoneController.addListener(_onPhoneChanged);
    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () => LegalLinks.open(LegalLinks.terms);
    _privacyRecognizer = TapGestureRecognizer()
      ..onTap = () => LegalLinks.open(LegalLinks.privacyPolicy);
  }

  @override
  void dispose() {
    _phoneFocusNode.removeListener(_onFocusChange);
    _phoneController.removeListener(_onPhoneChanged);
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    _countrySearchController.dispose();
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  void _onFocusChange() => setState(() {});

  void _onPhoneChanged() {
    // Clear the inline error as soon as the person starts fixing it,
    // rather than making them wait for the next submit attempt.
    if (_phoneError != null) {
      setState(() => _phoneError = null);
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _showCountryPicker() {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
    final textColor = isDark ? Colors.white : const Color(0xFF000000);
    final sheetBg = isDark ? const Color(0xFF000814) : Colors.white;
    final fieldBg = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : const Color(0xFFF1F5F9);

    _countrySearchController.clear();
    List<Map<String, String>> filtered = List.of(_countries);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          void filter(String query) {
            final q = query.trim().toLowerCase();
            setSheetState(() {
              filtered = q.isEmpty
                  ? List.of(_countries)
                  : _countries
                        .where(
                          (c) =>
                              c['name']!.toLowerCase().contains(q) ||
                              c['code']!.contains(q),
                        )
                        .toList();
            });
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: SafeArea(
              top: false,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.75,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white24
                            : const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.phoneLoginScreenSelectCountryCode,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: TextField(
                        controller: _countrySearchController,
                        onChanged: filter,
                        autofocus: false,
                        style: TextStyle(color: textColor, fontSize: 15),
                        decoration: InputDecoration(
                          hintText: l10n.phoneLoginScreenSelectCountryCode,
                          hintStyle: TextStyle(color: mutedColor, fontSize: 15),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: mutedColor,
                            size: 20,
                          ),
                          filled: true,
                          fillColor: fieldBg,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: filtered.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              child: Text(
                                l10n.phoneLoginScreenInvalidPhone,
                                style: TextStyle(
                                  color: mutedColor,
                                  fontSize: 14,
                                ),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => Divider(
                                height: 1,
                                indent: 20,
                                endIndent: 20,
                                color: isDark
                                    ? Colors.white10
                                    : const Color(0xFFF1F5F9),
                              ),
                              itemBuilder: (ctx, i) {
                                final c = filtered[i];
                                final isSelected =
                                    c['code'] == _selectedCode &&
                                    c['name'] == _selectedCountryName;
                                return ListTile(
                                  title: Text(
                                    c['name']!,
                                    style: TextStyle(
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: textColor,
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        c['code']!,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? Theme.of(context).primaryColor
                                              : mutedColor,
                                        ),
                                      ),
                                      if (isSelected) ...[
                                        const SizedBox(width: 8),
                                        Icon(
                                          Icons.check_circle_rounded,
                                          size: 18,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                      ],
                                    ],
                                  ),
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(() {
                                      _selectedCountryName = c['name']!;
                                      _selectedCode = c['code']!;
                                    });
                                    Navigator.pop(ctx);
                                  },
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _continue() async {
    if (_loading || _socialLoading) return;
    final l10n = AppLocalizations.of(context);
    final digits = _phoneController.text.trim();

    if (digits.length != 10) {
      HapticFeedback.mediumImpact();
      setState(() => _phoneError = l10n.phoneLoginScreenInvalidPhone);
      return;
    }
    if (!_agreedToTerms) {
      HapticFeedback.mediumImpact();
      setState(() => _showTermsHint = true);
      return;
    }

    final phone = '$_selectedCode$digits';
    setState(() {
      _loading = true;
      _phoneError = null;
    });
    try {
      final devCode = await context.read<AuthProvider>().sendPhoneOtp(phone);
      if (!mounted) return;
      FocusScope.of(context).unfocus();
      // Awaited so the loader keeps running for the whole forward
      // transition and only resets if they come back to this screen.
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              OtpVerificationScreen(phone: phone, prefillCode: devCode),
        ),
      );
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _toast(e.toString());
    }
  }

  Future<void> _google() async {
    if (_loading || _socialLoading) return;
    if (!_agreedToTerms) {
      HapticFeedback.mediumImpact();
      setState(() => _showTermsHint = true);
      return;
    }
    setState(() => _socialLoading = true);
    final auth = context.read<AuthProvider>();
    final ok = await auth.signInWithGoogle();
    if (!mounted) return;
    if (ok) {
      context.go(AppRoutes.root);
      return;
    }
    setState(() => _socialLoading = false);
    if (auth.errorMessage != null) _toast(auth.errorMessage!);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF000000), const Color(0xFF1E1E38)]
                : [const Color(0xFFFAF9FF), const Color(0xFFF1F0FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Main Content — scrolls on its own so a tall logo/form
              // never squeezes the language footer below off-screen. ────
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    24,
                    0,
                    24,
                    MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 12),
                      AuthPulsingLogo(
                        areaSize: 250,
                        ringBaseSize: 120,
                        ringMaxSize: 244,
                        accent: theme.primaryColor,
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
                      AuthWordmark(
                        isDark: isDark,
                        primary: theme.primaryColor,
                        fontSize: 30,
                      ),
                      const SizedBox(height: 6),

                      // Header Subtitle
                      Text(
                        l10n.phoneLoginScreenSubtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF475569),
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 28),
                      _buildPhoneField(isDark, l10n),
                      const SizedBox(height: 18),
                      _buildTerms(isDark),
                      const SizedBox(height: 20),
                      _buildContinueButton(),
                      const SizedBox(height: 8),
                      _buildOrDivider(isDark),
                      const SizedBox(height: 8),

                      // Social Logins: Only show Apple login on Apple devices (iOS/macOS), otherwise show Google login.
                      if (Theme.of(context).platform == TargetPlatform.iOS ||
                          Theme.of(context).platform == TargetPlatform.macOS)
                        _buildSocialButton(
                          isDark: isDark,
                          label: l10n.phoneLoginScreenContinueWithApple,
                          loading: false,
                          onTap: (_loading || _socialLoading)
                              ? null
                              : () => _toast(
                                  l10n.phoneLoginScreenAppleComingSoon,
                                ),
                          leading: Icon(
                            Icons.apple,
                            size: 24,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF000000),
                          ),
                        )
                      else
                        _buildSocialButton(
                          isDark: isDark,
                          label: l10n.phoneLoginScreenContinueWithGoogle,
                          loading: _socialLoading,
                          onTap: (_loading || _socialLoading) ? null : _google,
                          leading: const _GoogleLogo(),
                        ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: _buildLanguageRow(isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneField(bool isDark, AppLocalizations l10n) {
    final isFocused = _phoneFocusNode.hasFocus;
    final hasError = _phoneError != null;
    final mutedColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            l10n.phoneLoginScreenPhoneNumberLabel,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
              color: mutedColor,
            ),
          ),
        ),
        _buildPhoneFieldBox(isDark, isFocused, hasError),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          alignment: Alignment.topLeft,
          child: hasError
              ? Padding(
                  padding: const EdgeInsets.only(left: 4, top: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 15,
                        color: Color(0xFFEF4444),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _phoneError!,
                        style: const TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildPhoneFieldBox(bool isDark, bool isFocused, bool hasError) {
    final errorColor = const Color(0xFFEF4444);
    final borderColor = hasError
        ? errorColor
        : isFocused
        ? Theme.of(context).primaryColor
        : isDark
        ? Colors.white12
        : const Color(0xFFE2E8F0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 56,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColor,
          width: (isFocused || hasError) ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: (hasError ? errorColor : Theme.of(context).primaryColor)
                .withValues(alpha: (isFocused || hasError) ? 0.12 : 0.02),
            blurRadius: (isFocused || hasError) ? 8 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Semantics(
            button: true,
            label: AppLocalizations.of(
              context,
            ).phoneLoginScreenSelectCountryCode,
            child: InkWell(
              onTap: _showCountryPicker,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: Text(
                  _selectedCode,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: isDark ? Colors.white : const Color(0xFF000000),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 1,
            height: 24,
            color: isFocused
                ? Theme.of(context).primaryColor.withValues(alpha: 0.3)
                : isDark
                ? Colors.white12
                : const Color(0xFFE2E8F0),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: TextField(
              controller: _phoneController,
              focusNode: _phoneFocusNode,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              textAlignVertical: TextAlignVertical.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : const Color(0xFF000000),
              ),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(
                  context,
                ).phoneLoginScreenPhoneHint,
                hintStyle: TextStyle(
                  color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onSubmitted: (_) => _continue(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: (_loading || _socialLoading) ? null : _continue,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          disabledBackgroundColor: Theme.of(
            context,
          ).primaryColor.withValues(alpha: 0.4),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: const StadiumBorder(),
        ),
        child: _loading
            ? const ThreeDotLoader(color: Colors.white)
            : Text(
                AppLocalizations.of(context).phoneLoginScreenContinue,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildOrDivider(bool isDark) {
    final lineColor = isDark ? Colors.white12 : const Color(0xFFE2E8F0);
    return Row(
      children: [
        Expanded(child: Divider(color: lineColor)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            AppLocalizations.of(context).phoneLoginScreenOr.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
        ),
        Expanded(child: Divider(color: lineColor)),
      ],
    );
  }

  Widget _buildSocialButton({
    required bool isDark,
    required String label,
    required bool loading,
    required VoidCallback? onTap,
    required Widget leading,
  }) {
    final foregroundColor = isDark ? Colors.white : const Color(0xFF000814);
    return SizedBox(
      height: 56,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? Colors.white : const Color(0xFF000000),
          side: BorderSide(
            color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
          ),
          backgroundColor: isDark
              ? Colors.white.withValues(alpha: 0.02)
              : Colors.white,
          shape: const StadiumBorder(),
        ),
        child: loading
            ? ThreeDotLoader(color: foregroundColor)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  leading,
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: foregroundColor,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTerms(bool isDark) {
    final l10n = AppLocalizations.of(context);
    final mutedColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
    final hintColor = const Color(0xFFEF4444);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: Checkbox(
                value: _agreedToTerms,
                onChanged: (v) => setState(() {
                  _agreedToTerms = v ?? false;
                  if (_agreedToTerms) _showTermsHint = false;
                }),
                activeColor: Theme.of(context).primaryColor,
                side: _showTermsHint
                    ? BorderSide(color: hintColor, width: 1.5)
                    : null,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => setState(() {
                  _agreedToTerms = !_agreedToTerms;
                  if (_agreedToTerms) _showTermsHint = false;
                }),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${l10n.phoneLoginScreenAgreeTerms} ',
                        style: TextStyle(color: mutedColor, fontSize: 13),
                      ),
                      TextSpan(
                        text: l10n.phoneLoginScreenTermsOfService,
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          decoration: TextDecoration.underline,
                          decorationColor: Theme.of(
                            context,
                          ).primaryColor.withValues(alpha: 0.4),
                        ),
                        recognizer: _termsRecognizer,
                      ),
                      TextSpan(
                        text: ' ${l10n.phoneLoginScreenAnd} ',
                        style: TextStyle(color: mutedColor, fontSize: 13),
                      ),
                      TextSpan(
                        text: l10n.phoneLoginScreenPrivacyPolicy,
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          decoration: TextDecoration.underline,
                          decorationColor: Theme.of(
                            context,
                          ).primaryColor.withValues(alpha: 0.4),
                        ),
                        recognizer: _privacyRecognizer,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          alignment: Alignment.topLeft,
          child: _showTermsHint
              ? Padding(
                  padding: const EdgeInsets.only(left: 32, top: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 14,
                        color: hintColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n.phoneLoginScreenAgreeTerms,
                        style: TextStyle(
                          color: hintColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildLanguageRow(bool isDark) {
    const languages = [('English', 'en'), ('বাংলা', 'bn'), ('हिन्दी', 'hi')];
    final mutedColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
    final dividerColor = isDark ? Colors.white24 : const Color(0xFFCBD5E1);
    // null locale means "follow the device" — fall back to the resolved
    // locale so the matching label still shows as active.
    final currentCode =
        context.watch<LocaleProvider>().locale?.languageCode ??
        Localizations.localeOf(context).languageCode;

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 6,
      children: [
        for (var i = 0; i < languages.length; i++) ...[
          if (i > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(width: 1, height: 12, color: dividerColor),
            ),
          _buildLanguageLabel(
            label: languages[i].$1,
            code: languages[i].$2,
            isActive: currentCode == languages[i].$2,
            mutedColor: mutedColor,
          ),
        ],
      ],
    );
  }

  Widget _buildLanguageLabel({
    required String label,
    required String code,
    required bool isActive,
    required Color mutedColor,
  }) {
    return GestureDetector(
      onTap: () {
        if (!isActive) {
          HapticFeedback.selectionClick();
          context.read<LocaleProvider>().setLocale(Locale(code));
        }
      },
      child: Text(
        label,
        style: TextStyle(
          color: isActive ? Theme.of(context).primaryColor : mutedColor,
          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          fontSize: 13.5,
        ),
      ),
    );
  }
}

/// Google logo rendered from assets/svg/google_logo.svg
class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/svg/google_logo.svg',
      width: 22,
      height: 22,
    );
  }
}
