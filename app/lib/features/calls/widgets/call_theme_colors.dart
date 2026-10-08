import 'package:flutter/material.dart';

Color callBgColor(bool isDark) =>
    isDark ? const Color(0xFF0A0F1D) : Colors.white;
Color callTileBg(bool isDark) =>
    isDark ? const Color(0xFF000814) : Colors.white;
Color callTileBorder(bool isDark) => isDark
    ? Colors.white.withValues(alpha: 0.12)
    : Colors.black.withValues(alpha: 0.08);
Color callTextPrimary(bool isDark) =>
    isDark ? Colors.white : const Color(0xFF000000);
Color callTextSecondary(bool isDark) =>
    isDark ? Colors.white70 : const Color(0xFF475569);
Color callTextMuted(bool isDark) =>
    isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
Color callPillBg(bool isDark) =>
    isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF3F4F6);

const Color callSuccessColor = Color(0xFF09C26F);
const Color callErrorColor = Color(0xFFEF4444);
