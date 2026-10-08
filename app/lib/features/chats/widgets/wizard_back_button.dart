import 'package:flutter/material.dart';

/// Circular back button — gives the header row proper visual weight next to
/// the bold title, instead of a bare chevron floating beside it.
class WizardBackButton extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;

  const WizardBackButton({
    super.key,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFF1F3F8),
        ),
        child: Icon(
          Icons.arrow_back_rounded,
          size: 20,
          color: isDark ? Colors.white : const Color(0xFF0B1120),
        ),
      ),
    );
  }
}
