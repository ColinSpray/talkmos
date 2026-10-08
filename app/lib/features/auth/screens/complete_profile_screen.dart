import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/three_dot_loader.dart';
import '../../../providers/auth_provider.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  /// Same red the phone-login field uses for its error state — legible on
  /// both backgrounds, unlike Colors.redAccent against the dark surface.
  static const _errorColor = Color(0xFFEF4444);

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _finish() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await context.read<AuthProvider>().completePhoneProfile(
        name: _nameController.text.trim(),
        username: _usernameController.text.trim(),
      );
      if (!mounted) return;
      // Signed in — AuthGate now shows the app; clear the auth stack.
      Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _toast(e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? AppTheme.darkBg : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF000000);
    final mutedColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          l10n.completeProfileScreenTitle,
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                Text(
                  l10n.completeProfileScreenSubtitle,
                  style: TextStyle(color: mutedColor, fontSize: 14),
                ),
                const SizedBox(height: 28),
                _label(l10n.completeProfileScreenFullName, isDark),
                const SizedBox(height: 8),
                _field(
                  controller: _nameController,
                  hint: l10n.completeProfileScreenFullNameHint,
                  isDark: isDark,
                  textInputAction: TextInputAction.next,
                  validator: (v) => (v == null || v.trim().length < 2)
                      ? l10n.completeProfileScreenNameRequired
                      : null,
                ),
                const SizedBox(height: 20),
                _label(l10n.commonUsername, isDark),
                const SizedBox(height: 8),
                _field(
                  controller: _usernameController,
                  hint: l10n.completeProfileScreenUsernameHint,
                  isDark: isDark,
                  prefix: '@',
                  textInputAction: TextInputAction.done,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_.]')),
                    LengthLimitingTextInputFormatter(20),
                  ],
                  validator: (v) {
                    final t = v?.trim() ?? '';
                    if (t.length < 3)
                      return l10n.completeProfileScreenUsernameMinLength;
                    return null;
                  },
                  onSubmitted: (_) => _finish(),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _finish,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: theme.primaryColor.withValues(
                        alpha: 0.5,
                      ),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _loading
                        ? const ThreeDotLoader(color: Colors.white)
                        : Text(
                            l10n.completeProfileScreenFinish,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
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

  Widget _label(String text, bool isDark) => Text(
    text,
    style: TextStyle(
      fontWeight: FontWeight.w600,
      // Light mode's near-black label doubles as the dark palette's raised
      // surface, so it has to flip rather than being dimmed.
      color: isDark ? Colors.white : AppTheme.darkSurfaceHigh,
    ),
  );

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required bool isDark,
    String? prefix,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    TextInputAction? textInputAction,
    void Function(String)? onSubmitted,
  }) {
    final textColor = isDark ? Colors.white : const Color(0xFF000000);
    return TextFormField(
      controller: controller,
      validator: validator,
      inputFormatters: inputFormatters,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmitted,
      cursorColor: Theme.of(context).primaryColor,
      style: TextStyle(fontSize: 16, color: textColor),
      decoration: InputDecoration(
        hintText: hint,
        prefixText: prefix,
        prefixStyle: TextStyle(fontSize: 16, color: textColor),
        hintStyle: TextStyle(
          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
        ),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _errorColor, width: 1.5),
        ),
      ),
    );
  }
}
