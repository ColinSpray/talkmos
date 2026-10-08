import 'package:flutter/material.dart';

/// Bold field label used above an input.
class FieldLabel extends StatelessWidget {
  final String text;
  final Color textColor;

  const FieldLabel(this.text, {super.key, required this.textColor});

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: textColor,
    ),
  );
}

/// Rounded outlined container used for every input on this screen.
class InputShell extends StatelessWidget {
  final Widget child;
  final bool isDark;
  final double? height;
  final bool filled;

  const InputShell({
    super.key,
    required this.child,
    required this.isDark,
    this.height,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: filled
            ? (isDark ? const Color(0xFF111A2E) : const Color(0xFFF1F3F8))
            : (isDark ? const Color(0xFF0B1424) : Colors.white),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE3E6EF),
        ),
      ),
      child: child,
    );
  }
}
