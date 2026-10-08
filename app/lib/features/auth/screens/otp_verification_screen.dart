import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/three_dot_loader.dart';
import '../widgets/auth_hero_tag.dart';
import '../widgets/auth_pulsing_logo.dart';

const _kCodeLength = 6;

/// Enter the OTP sent to [phone]. On success, an existing user is signed in
/// (AuthGate swaps to the app); a new user is routed to profile completion.
class OtpVerificationScreen extends StatefulWidget {
  final String phone;

  /// Dev-only code echoed by the backend (no SMS provider yet) — pre-filled so
  /// it can be tested without receiving an SMS. Null in production.
  final String? prefillCode;

  const OtpVerificationScreen({
    super.key,
    required this.phone,
    this.prefillCode,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _codeController = TextEditingController();
  final _codeFocusNode = FocusNode();
  bool _loading = false;
  bool _resending = false;

  @override
  void initState() {
    super.initState();
    if (widget.prefillCode != null && widget.prefillCode!.isNotEmpty) {
      _codeController.text = widget.prefillCode!;
    }
    _codeFocusNode.addListener(_onFocusChange);
    _codeController.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _codeFocusNode.removeListener(_onFocusChange);
    _codeController.removeListener(_onFocusChange);
    _codeController.dispose();
    _codeFocusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {});
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _verify() async {
    if (_loading) return;
    final code = _codeController.text.trim();
    if (code.length < 4) {
      _toast(AppLocalizations.of(context).otpVerificationScreenEnterCode);
      return;
    }
    setState(() => _loading = true);
    try {
      await context.read<AuthProvider>().verifyPhoneOtp(widget.phone, code);
      if (!mounted) return;
      FocusScope.of(context).unfocus();
      context.go(AppRoutes.root);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _toast(e.toString());
    }
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    try {
      final code = await context.read<AuthProvider>().sendPhoneOtp(
        widget.phone,
      );
      if (!mounted) return;
      if (code != null && code.isNotEmpty) {
        _codeController.text = code;
      }
      _toast(AppLocalizations.of(context).otpVerificationScreenCodeResent);
    } catch (e) {
      if (mounted) _toast(e.toString());
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Widget _buildDigitBoxes(
    Color primary, {
    required bool isDark,
    required Color boxColor,
    required Color textColor,
    required Color borderColor,
  }) {
    final text = _codeController.text;
    final hasFocus = _codeFocusNode.hasFocus;
    final activeIndex = text.length < _kCodeLength
        ? text.length
        : _kCodeLength - 1;

    return GestureDetector(
      onTap: () => _codeFocusNode.requestFocus(),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_kCodeLength, (i) {
              final digit = i < text.length ? text[i] : '';
              final isActive = hasFocus && i == activeIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 46,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: boxColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isActive
                        ? primary
                        : digit.isNotEmpty
                        ? primary.withValues(alpha: 0.4)
                        : borderColor,
                    width: isActive ? 1.5 : 1.0,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: primary.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.2 : 0.02,
                            ),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Text(
                  digit,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              );
            }),
          ),
          // Invisible field that actually captures keyboard input; the boxes
          // above are purely a visual overlay driven by its text.
          Opacity(
            opacity: 0,
            child: TextField(
              controller: _codeController,
              focusNode: _codeFocusNode,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(_kCodeLength),
              ],
              cursorWidth: 0,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              onSubmitted: (_) => _verify(),
              onChanged: (value) {
                if (value.length == _kCodeLength) _verify();
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final primary = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canPop = Navigator.canPop(context);

    final bgColor = isDark ? AppTheme.darkBg : AppTheme.lightBg;
    final cardColor = isDark ? AppTheme.darkCard : AppTheme.lightCard;
    final textColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final textSecondary = isDark
        ? AppTheme.darkTextSecondary
        : AppTheme.lightTextSecondary;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bgColor,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
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
                    if (canPop)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Icon(
                              Icons.arrow_back_rounded,
                              color: primary,
                              size: 26,
                            ),
                          ),
                        ),
                      )
                    else
                      const SizedBox(height: 26),
                    const SizedBox(height: 8),

                    AuthPulsingLogo(
                      areaSize: 250,
                      ringBaseSize: 120,
                      ringMaxSize: 244,
                      accent: primary,
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
                    const SizedBox(height: 8),

                    Text(
                      l10n.otpVerificationScreenTitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.otpVerificationScreenSentTo(widget.phone),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 28),

                    _buildDigitBoxes(
                      primary,
                      isDark: isDark,
                      boxColor: cardColor,
                      textColor: textColor,
                      borderColor: borderColor,
                    ),

                    const SizedBox(height: 28),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _verify,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _loading
                            ? const ThreeDotLoader(color: Colors.white)
                            : Text(
                                l10n.otpVerificationScreenVerify,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          l10n.otpVerificationScreenDidntGetCode,
                          style: TextStyle(color: textSecondary),
                        ),
                        TextButton(
                          onPressed: _resending ? null : _resend,
                          child: Text(
                            _resending
                                ? l10n.otpVerificationScreenSending
                                : l10n.otpVerificationScreenResend,
                            style: TextStyle(
                              color: primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
