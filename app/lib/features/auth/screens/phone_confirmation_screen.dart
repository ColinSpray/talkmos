import 'package:flutter/material.dart';
import '../../../core/widgets/avatar_circle.dart';
import 'package:talkmos/core/utils/titlecase_function.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';
import '../../../providers/auth_provider.dart';

class PhoneConfirmationScreen extends StatefulWidget {
  const PhoneConfirmationScreen({super.key});

  @override
  State<PhoneConfirmationScreen> createState() =>
      _PhoneConfirmationScreenState();
}

class _PhoneConfirmationScreenState extends State<PhoneConfirmationScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();

  String _selectedCode = '+91';
  String _selectedFlag = '🇮🇳';
  bool _isLoading = false;
  String? _errorMessage;

  final List<Map<String, String>> _countries = const [
    {'flag': '🇮🇳', 'name': 'India', 'code': '+91'},
    {'flag': '🇺🇸', 'name': 'United States', 'code': '+1'},
    {'flag': '🇬🇧', 'name': 'United Kingdom', 'code': '+44'},
    {'flag': '🇧🇩', 'name': 'Bangladesh', 'code': '+880'},
    {'flag': '🇦🇪', 'name': 'United Arab Emirates', 'code': '+971'},
    {'flag': '🇸🇦', 'name': 'Saudi Arabia', 'code': '+966'},
    {'flag': '🇸🇬', 'name': 'Singapore', 'code': '+65'},
    {'flag': '🇦🇺', 'name': 'Australia', 'code': '+61'},
    {'flag': '🇨🇦', 'name': 'Canada', 'code': '+1'},
    {'flag': '🇩🇪', 'name': 'Germany', 'code': '+49'},
    {'flag': '🇫🇷', 'name': 'France', 'code': '+33'},
    {'flag': '🇯🇵', 'name': 'Japan', 'code': '+81'},
    {'flag': '🇧🇷', 'name': 'Brazil', 'code': '+55'},
  ];

  @override
  void initState() {
    super.initState();
    _phoneFocusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _phoneFocusNode.removeListener(_onFocusChange);
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {});
  }

  void _showCountryPicker() {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.phoneConfirmationScreenSelectCountryCode,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF000000),
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _countries.length,
                itemBuilder: (ctx, i) {
                  final c = _countries[i];
                  final isSelected =
                      c['code'] == _selectedCode && c['flag'] == _selectedFlag;
                  return ListTile(
                    leading: Text(
                      c['flag']!,
                      style: const TextStyle(fontSize: 22),
                    ),
                    title: Text(
                      c['name']!,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    trailing: Text(
                      c['code']!,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : const Color(0xFF64748B),
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        _selectedFlag = c['flag']!;
                        _selectedCode = c['code']!;
                      });
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitPhone() async {
    final rawPhone = _phoneController.text.trim();
    if (rawPhone.length != 10) {
      setState(() {
        _errorMessage = AppLocalizations.of(
          context,
        ).phoneConfirmationScreenInvalidPhone;
      });
      return;
    }

    final fullPhone = '$_selectedCode$rawPhone';
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.updatePhone(fullPhone);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Widget _buildPhoneField() {
    final isFocused = _phoneFocusNode.hasFocus;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _errorMessage != null
              ? Colors.redAccent
              : (isFocused
                    ? Theme.of(context).primaryColor
                    : const Color(0xFFE2E8F0)),
          width: isFocused ? 1.5 : 1.0,
        ),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          InkWell(
            onTap: _showCountryPicker,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_selectedFlag, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF64748B),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _selectedCode,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF000000),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 1,
            height: 24,
            color: isFocused
                ? Theme.of(context).primaryColor.withValues(alpha: 0.3)
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
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF000000),
              ),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(
                  context,
                ).phoneConfirmationScreenPhoneHint,
                hintStyle: const TextStyle(
                  color: Color(0xFFCBD5E1),
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
              onSubmitted: (_) => _submitPhone(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),

                    // ── Header Brand / Shield Icon ─────────────────────────────────────
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).primaryColor.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            Icons.phonelink_ring_rounded,
                            color: Theme.of(context).primaryColor,
                            size: 42,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    Text(
                      l10n.phoneConfirmationScreenTitle,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF000000),
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 10),

                    Text(
                      l10n.phoneConfirmationScreenSubtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                        height: 1.45,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 32),

                    // ── User Google Account Profile Card ───────────────────────────
                    if (user != null)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            AvatarCircle(
                              imageUrl: user.avatarUrl,
                              radius: 22,
                              backgroundColor: Theme.of(
                                context,
                              ).primaryColor.withValues(alpha: 0.12),
                              fallback: Text(
                                user.name.isNotEmpty
                                    ? user.name[0].toUpperCase()
                                    : 'G',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    toTitleCase(user.name),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Color(0xFF000000),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (user.email != null &&
                                      user.email!.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      user.email!,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF64748B),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Color(0xFFDCFCE7),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: Color(0xFF16A34A),
                                size: 14,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 24),

                    // ── Phone Input Field (Matches PhoneLoginScreen) ───────────────────
                    _buildPhoneField(),

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // ── Primary Action Button ─────────────────────────────────────────
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitPhone,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              l10n.phoneConfirmationScreenConfirmContinue,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
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
