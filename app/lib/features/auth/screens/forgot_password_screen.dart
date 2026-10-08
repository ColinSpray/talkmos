import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with TickerProviderStateMixin {
  final _authService = AuthService();

  // Step tracking  (0 = email, 1 = OTP, 2 = new password, 3 = success)
  int _step = 0;
  bool _isLoading = false;
  String? _errorMessage;

  // Controllers
  final _emailController = TextEditingController();
  final _otpControllers = List.generate(6, (_) => TextEditingController());
  final _otpFocusNodes = List.generate(6, (_) => FocusNode());
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  // Animation
  late final AnimationController _fadeController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  )..forward();
  late final Animation<double> _fadeAnim = CurvedAnimation(
    parent: _fadeController,
    curve: Curves.easeOut,
  );

  @override
  void dispose() {
    _fadeController.dispose();
    _emailController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _setError(String? msg) => setState(() => _errorMessage = msg);

  void _advanceStep() {
    _setError(null);
    _fadeController.reset();
    setState(() => _step++);
    _fadeController.forward();
  }

  void _goBack() {
    if (_step == 0) {
      Navigator.of(context).pop();
      return;
    }
    _setError(null);
    _fadeController.reset();
    setState(() => _step--);
    _fadeController.forward();
  }

  Future<void> _sendOtp({bool isResend = false}) async {
    final identifier = _emailController.text.trim();
    if (identifier.isEmpty) {
      _setError(AppLocalizations.of(context).forgotPasswordScreenEmailRequired);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.forgotPassword(identifier);

      if (isResend) {
        for (final c in _otpControllers) {
          c.clear();
        }
        if (_otpFocusNodes.isNotEmpty) _otpFocusNodes.first.requestFocus();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context).forgotPasswordScreenCodeResent,
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        _advanceStep();
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Step 1: verify OTP ──────────────────────────────────────────────────────
  void _verifyOtp() {
    final entered = _otpControllers.map((c) => c.text).join();
    if (entered.length < 6) {
      _setError(
        AppLocalizations.of(context).forgotPasswordScreenIncompleteCode,
      );
      return;
    }
    _advanceStep();
  }

  // ── Step 2: reset password ──────────────────────────────────────────────────
  Future<void> _resetPassword() async {
    final newPass = _newPasswordController.text;
    final confirmPass = _confirmPasswordController.text;

    if (newPass.length < 8) {
      _setError(
        AppLocalizations.of(context).forgotPasswordScreenPasswordMinLength,
      );
      return;
    }
    if (newPass != confirmPass) {
      _setError(
        AppLocalizations.of(context).forgotPasswordScreenPasswordsMismatch,
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final code = _otpControllers.map((c) => c.text).join();
      final identifier = _emailController.text.trim();
      await _authService.resetPassword(
        identifier: identifier,
        code: code,
        password: newPass,
      );
      _advanceStep(); // Step 3 — success
    } catch (e) {
      _setError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── OTP box input handling ──────────────────────────────────────────────────
  void _onOtpChanged(String value, int index) {
    if (value.length == 1 && index < 5) {
      _otpFocusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _otpFocusNodes[index - 1].requestFocus();
    }
    setState(() {});
  }

  // ── Build helpers ───────────────────────────────────────────────────────────

  Widget _buildStepIndicator(bool isDark) {
    const totalSteps = 3;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSteps, (i) {
        final isActive = i == _step;
        final isDone = i < _step;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 28 : 10,
          height: 10,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            gradient: isActive || isDone ? AppTheme.primaryGradient : null,
            color: isActive || isDone
                ? null
                : (isDark ? const Color(0xFF000E23) : const Color(0xFFE2E8F0)),
          ),
        );
      }),
    );
  }

  Widget _buildHeader(bool isDark) {
    final l10n = AppLocalizations.of(context);
    final titles = [
      l10n.forgotPasswordScreenTitleEmail,
      l10n.forgotPasswordScreenTitleOtp,
      l10n.forgotPasswordScreenTitleNewPassword,
    ];
    final subtitles = [
      l10n.forgotPasswordScreenSubtitleEmail,
      l10n.forgotPasswordScreenSubtitleOtp,
      l10n.forgotPasswordScreenSubtitleNewPassword,
    ];
    final icons = [
      Icons.lock_reset_rounded,
      Icons.mark_email_read_rounded,
      Icons.key_rounded,
    ];

    final safeStep = _step.clamp(0, 2);

    return Column(
      children: [
        // Icon badge
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(icons[safeStep], color: Colors.white, size: 32),
        ),
        const SizedBox(height: 20),
        Text(
          titles[safeStep],
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppTheme.lightText,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          subtitles[safeStep],
          style: TextStyle(
            fontSize: 14,
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildOtpField(bool isDark) {
    return Row(
      children: List.generate(6, (i) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == 5 ? 0 : 8),
            child: TextFormField(
              controller: _otpControllers[i],
              focusNode: _otpFocusNodes[i],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 1,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                counterText: '',
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark
                        ? const Color(0xFF000E23)
                        : const Color(0xFFE2E8F0),
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).primaryColor,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF000814) : Colors.white,
              ),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppTheme.lightText,
              ),
              onChanged: (v) => _onOtpChanged(v, i),
            ),
          ),
        );
      }),
    );
  }

  // ── Error chip ───────────────────────────────────────────────────────────────
  Widget _buildError() {
    return AnimatedOpacity(
      opacity: _errorMessage != null ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 250),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.redAccent.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.redAccent,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _errorMessage ?? '',
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback? onPressed,
    IconData? icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: onPressed,
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (icon != null) ...[
                    const SizedBox(width: 8),
                    Icon(icon, size: 20),
                  ],
                ],
              ),
      ),
    );
  }

  // ── Step views ───────────────────────────────────────────────────────────────

  Widget _buildEmailStep(bool isDark) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) {
            if (!_isLoading) _sendOtp();
          },
          decoration: InputDecoration(
            labelText: l10n.forgotPasswordScreenEmailOrPhoneLabel,
            prefixIcon: Icon(
              Icons.alternate_email_rounded,
              size: 20,
              color: Theme.of(context).primaryColor,
            ),
            hintText: l10n.forgotPasswordScreenEmailOrPhoneHint,
          ),
        ),
        const SizedBox(height: 20),
        _buildPrimaryButton(
          label: l10n.forgotPasswordScreenSendCode,
          icon: Icons.send_rounded,
          onPressed: _isLoading ? null : _sendOtp,
        ),
      ],
    );
  }

  Widget _buildOtpStep(bool isDark) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Sent-to label
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: Theme.of(context).primaryColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.forgotPasswordScreenCodeSentTo(
                    _emailController.text.trim(),
                  ),
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildOtpField(isDark),
        const SizedBox(height: 20),
        _buildPrimaryButton(
          label: l10n.forgotPasswordScreenVerifyCode,
          icon: Icons.check_circle_outline_rounded,
          onPressed: _isLoading ? null : _verifyOtp,
        ),
        const SizedBox(height: 16),
        Center(
          child: GestureDetector(
            onTap: _isLoading ? null : () => _sendOtp(isResend: true),
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
                children: [
                  TextSpan(text: l10n.forgotPasswordScreenDidntReceiveCode),
                  TextSpan(
                    text: l10n.forgotPasswordScreenResend,
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNewPasswordStep(bool isDark) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // New password
        TextFormField(
          controller: _newPasswordController,
          obscureText: _obscureNewPassword,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: l10n.forgotPasswordScreenNewPasswordLabel,
            prefixIcon: Icon(
              Icons.lock_rounded,
              size: 20,
              color: Theme.of(context).primaryColor,
            ),
            hintText: l10n.forgotPasswordScreenAtLeast8Chars,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureNewPassword
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                size: 20,
                color: AppTheme.lightTextSecondary,
              ),
              onPressed: () =>
                  setState(() => _obscureNewPassword = !_obscureNewPassword),
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        // Confirm password
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) {
            if (!_isLoading) _resetPassword();
          },
          decoration: InputDecoration(
            labelText: l10n.forgotPasswordScreenConfirmPasswordLabel,
            prefixIcon: const Icon(
              Icons.lock_reset_rounded,
              size: 20,
              color: AppTheme.secondary,
            ),
            hintText: l10n.forgotPasswordScreenReenterPassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                size: 20,
                color: AppTheme.lightTextSecondary,
              ),
              onPressed: () => setState(
                () => _obscureConfirmPassword = !_obscureConfirmPassword,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Password strength hint
        _buildPasswordStrengthRow(isDark),
        const SizedBox(height: 20),
        _buildPrimaryButton(
          label: l10n.forgotPasswordScreenResetPassword,
          icon: Icons.check_rounded,
          onPressed: _isLoading ? null : _resetPassword,
        ),
      ],
    );
  }

  Widget _buildPasswordStrengthRow(bool isDark) {
    final l10n = AppLocalizations.of(context);
    final password = _newPasswordController.text;
    final hasMinLength = password.length >= 8;
    final hasUpper = password.contains(RegExp(r'[A-Z]'));
    final hasDigit = password.contains(RegExp(r'[0-9]'));

    Widget chip(bool met, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          met
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          size: 14,
          color: met ? Colors.green : AppTheme.lightTextSecondary,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            color: met ? Colors.green : AppTheme.lightTextSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );

    return Row(
      children: [
        Flexible(
          child: chip(hasMinLength, l10n.forgotPasswordScreenChars8Plus),
        ),
        const SizedBox(width: 10),
        Flexible(child: chip(hasUpper, l10n.forgotPasswordScreenUppercase)),
        const SizedBox(width: 10),
        Flexible(child: chip(hasDigit, l10n.forgotPasswordScreenNumber)),
      ],
    );
  }

  // ── Success view ─────────────────────────────────────────────────────────────
  Widget _buildSuccessView(bool isDark) {
    final l10n = AppLocalizations.of(context);
    return FadeTransition(
      opacity: _fadeAnim,
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF22C55E).withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 48,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            l10n.forgotPasswordScreenSuccessTitle,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.lightText,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.forgotPasswordScreenSuccessMessage,
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 36),
          _buildPrimaryButton(
            label: l10n.forgotPasswordScreenBackToLogin,
            icon: Icons.arrow_forward_rounded,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  // ── Root build ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSuccess = _step >= 3;

    return PopScope(
      canPop: _step == 0 || isSuccess,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _goBack();
      },
      child: Scaffold(
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
            child: Stack(
              children: [
                Center(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 20.0,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Reserve room for the back button above the
                          // step content.
                          SizedBox(height: isSuccess ? 8 : 44),

                          if (isSuccess)
                            _buildSuccessView(isDark)
                          else ...[
                            // Step indicator dots
                            _buildStepIndicator(isDark),
                            const SizedBox(height: 28),

                            // Header icon + title + subtitle
                            _buildHeader(isDark),
                            const SizedBox(height: 32),

                            // Error message
                            if (_errorMessage != null) ...[
                              _buildError(),
                              const SizedBox(height: 16),
                            ],

                            // Animated step content
                            FadeTransition(
                              opacity: _fadeAnim,
                              child: _step == 0
                                  ? _buildEmailStep(isDark)
                                  : _step == 1
                                  ? _buildOtpStep(isDark)
                                  : _buildNewPasswordStep(isDark),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                // FIX: explicit themed back button (matches login_screen),
                // hidden on the success screen since that has its own CTA.
                if (!isSuccess)
                  Positioned(
                    top: 4,
                    left: 8,
                    child: IconButton(
                      onPressed: _goBack,
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 20,
                        color: isDark ? Colors.white : const Color(0xFF000000),
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.white,
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(10),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
