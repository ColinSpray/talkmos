import 'package:flutter/material.dart';

class AuthWordmark extends StatelessWidget {
  final bool isDark;
  final Color primary;
  final double fontSize;

  const AuthWordmark({
    super.key,
    required this.isDark,
    required this.primary,
    this.fontSize = 42,
  });

  @override
  Widget build(BuildContext context) {
    // FittedBox so the wordmark shrinks instead of overflowing the row
    // horizontally at large system text scales.
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Talk',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF000000),
              letterSpacing: -1.5,
            ),
          ),
          Text(
            'Mos',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              color: primary,
              letterSpacing: -1.5,
            ),
          ),
        ],
      ),
    );
  }
}
