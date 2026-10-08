import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:talkmos/features/auth/screens/login_screen.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';
import '../../../providers/providers.dart';
import '../../../core/theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).registerScreenAccountCreated,
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      Navigator.of(context).pop();
    } else if (auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage!),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authProviderVal = context.watch<AuthProvider>();
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 88,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.primaryGradient,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: const Icon(
                                    Icons.chat_bubble_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                                Positioned(
                                  top: 6,
                                  left: size.width * 0.22,
                                  child: _buildSmallNode(
                                    Icons.videocam_rounded,
                                    const Color(0xFF4F46E5),
                                    isDark,
                                  ),
                                ),
                                Positioned(
                                  top: 14,
                                  right: size.width * 0.22,
                                  child: _buildSmallNode(
                                    Icons.groups_rounded,
                                    const Color(0xFF6366F1),
                                    isDark,
                                  ),
                                ),
                                Positioned(
                                  bottom: 6,
                                  left: size.width * 0.16,
                                  child: _buildSmallNode(
                                    Icons.phone_rounded,
                                    const Color(0xFF06B6D4),
                                    isDark,
                                  ),
                                ),
                                Positioned(
                                  bottom: 10,
                                  right: size.width * 0.16,
                                  child: _buildSmallNode(
                                    Icons.lock_rounded,
                                    Theme.of(context).primaryColor,
                                    isDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Center(
                            child: RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF000000),
                                  letterSpacing: -0.5,
                                ),
                                children: [
                                  TextSpan(
                                    text: l10n.registerScreenCreateYourPrefix,
                                  ),
                                  TextSpan(
                                    text: l10n.registerScreenAccountWord,
                                    style: TextStyle(
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l10n.registerScreenSubtitle,
                            style: TextStyle(
                              fontSize: 13.5,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextFormField(
                                  controller: _nameController,
                                  keyboardType: TextInputType.name,
                                  textInputAction: TextInputAction.next,
                                  decoration: InputDecoration(
                                    labelText: l10n.registerScreenFullName,
                                    prefixIcon: const Icon(
                                      Icons.person_rounded,
                                      size: 20,
                                      color: Color(0xFF8B5CF6),
                                    ),
                                    hintText: l10n.registerScreenFullNameHint,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty)
                                      return l10n.registerScreenNameRequired;
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  decoration: InputDecoration(
                                    labelText: l10n.registerScreenEmailAddress,
                                    prefixIcon: const Icon(
                                      Icons.email_rounded,
                                      size: 20,
                                      color: Color(0xFF6366F1),
                                    ),
                                    hintText: l10n.registerScreenEmailHint,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty)
                                      return l10n.registerScreenEmailRequired;
                                    if (!RegExp(
                                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                    ).hasMatch(value.trim())) {
                                      return l10n.registerScreenEmailInvalid;
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  textInputAction: TextInputAction.next,
                                  decoration: InputDecoration(
                                    labelText: l10n.commonPassword,
                                    prefixIcon: Icon(
                                      Icons.lock_rounded,
                                      size: 20,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off_rounded
                                            : Icons.visibility_rounded,
                                        size: 20,
                                        color: const Color(0xFF94A3B8),
                                      ),
                                      onPressed: () => setState(
                                        () => _obscurePassword =
                                            !_obscurePassword,
                                      ),
                                    ),
                                    hintText: l10n.registerScreenPasswordHint,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty)
                                      return l10n
                                          .registerScreenPasswordRequired;
                                    if (value.length < 6)
                                      return l10n
                                          .registerScreenPasswordMinLength;
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _confirmPasswordController,
                                  obscureText: _obscureConfirmPassword,
                                  textInputAction: TextInputAction.done,
                                  decoration: InputDecoration(
                                    labelText:
                                        l10n.registerScreenConfirmPassword,
                                    prefixIcon: const Icon(
                                      Icons.lock_reset_rounded,
                                      size: 22,
                                      color: Color(0xFF06B6D4),
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureConfirmPassword
                                            ? Icons.visibility_off_rounded
                                            : Icons.visibility_rounded,
                                        size: 20,
                                        color: const Color(0xFF94A3B8),
                                      ),
                                      onPressed: () => setState(
                                        () => _obscureConfirmPassword =
                                            !_obscureConfirmPassword,
                                      ),
                                    ),
                                    hintText:
                                        l10n.registerScreenConfirmPasswordHint,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty)
                                      return l10n
                                          .registerScreenConfirmPasswordRequired;
                                    if (value != _passwordController.text)
                                      return l10n
                                          .registerScreenPasswordsMismatch;
                                    return null;
                                  },
                                  onFieldSubmitted: (_) => _submit(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(
                                    context,
                                  ).primaryColor.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                minimumSize: const Size(double.infinity, 52),
                              ),
                              onPressed: authProviderVal.isLoading
                                  ? null
                                  : _submit,
                              child: authProviderVal.isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(l10n.registerScreenSignUp),
                                        const SizedBox(width: 8),
                                        const Icon(
                                          Icons.arrow_forward_rounded,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: isDark
                                      ? Colors.white12
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                ),
                                child: Text(
                                  l10n.registerScreenOrContinueWith,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: isDark
                                      ? Colors.white12
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(
                                color: isDark
                                    ? Colors.white12
                                    : const Color(0xFFE2E8F0),
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              backgroundColor: isDark
                                  ? Colors.white.withValues(alpha: 0.02)
                                  : Colors.white,
                            ),
                            onPressed: authProviderVal.isLoading
                                ? null
                                : () async {
                                    final success = await context
                                        .read<AuthProvider>()
                                        .signInWithGoogle();
                                    if (!mounted) return;
                                    if (success) {
                                      Navigator.of(context).pop();
                                    } else {
                                      final error = context
                                          .read<AuthProvider>()
                                          .errorMessage;
                                      if (error != null) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(error),
                                            backgroundColor: Colors.redAccent,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SvgPicture.asset(
                                  'assets/svg/google_logo.svg',
                                  height: 22,
                                  width: 22,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  l10n.registerScreenSignInWithGoogle,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF000000),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                l10n.registerScreenAlreadyHaveAccount,
                                style: TextStyle(
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LoginScreen(),
                                  ),
                                ),
                                child: Text(
                                  l10n.registerScreenSignIn,
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSmallNode(IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF000814) : Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, color: color, size: 14),
    );
  }
}
