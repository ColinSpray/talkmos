import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors matching Talkmos design (#0266fa)
  static const Color primary = Color(0xFF0266FA);
  static const Color primaryLight = Color(0xFF3B85FF);
  static const Color secondary = Color(0xFF8B5CF6); // Violet
  static const Color accent = Color(0xFF0266FA); // Accent Blue

  // Custom Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF3B85FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient activeStoryGradient = LinearGradient(
    colors: [primary, Color(0xFFD946EF), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Color darkBg = Color(0xFF000000); // Pure black — surface
  static const Color darkSurfaceLow = Color(0xFF00050C); // 5% primary/black
  static const Color darkCard = Color(
    0xFF000814,
  ); // 8% primary/black — surfaceContainer
  static const Color darkSurfaceHigh = Color(0xFF000E23); // 14% primary/black
  static const Color darkSurfaceHighest = Color(
    0xFF001028,
  ); // 16% primary/black
  static const Color darkText = Color(0xFFF8FAFC); // Slate 50
  static const Color darkTextSecondary = Color(0xFF94A3B8); // Slate 400

  // Light Theme Colors
  static const Color lightBg = Colors.white; // Crisp White
  static const Color lightCard = Colors.white;
  static const Color lightText = Color(0xFF000000); // Black
  static const Color lightTextSecondary = Color(0xFF64748B); // Slate 500

  static ThemeData get lightTheme => getLightTheme(primary);
  static ThemeData get darkTheme => getDarkTheme(primary);

  // Light Theme Data
  static ThemeData getLightTheme(Color primaryColor) {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: lightBg,
      cardColor: lightCard,
      dividerColor: Colors.black.withValues(alpha: 0.06),
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: secondary,
        surface: lightCard,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
      ),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: lightText,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: lightText),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: lightText,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: lightText,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: lightText,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: lightText),
        bodyMedium: TextStyle(fontSize: 14, color: lightTextSecondary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        labelStyle: const TextStyle(color: lightTextSecondary, fontSize: 14),
        floatingLabelStyle: TextStyle(
          color: primaryColor,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  // Dark Theme Data
  static ThemeData getDarkTheme(Color primaryColor) {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: darkBg,
      cardColor: darkCard,
      dividerColor: Colors.white.withValues(alpha: 0.06),
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: secondary,
        surface: darkBg,
        surfaceContainerLowest: darkBg,
        surfaceContainerLow: darkSurfaceLow,
        surfaceContainer: darkCard,
        surfaceContainerHigh: darkSurfaceHigh,
        surfaceContainerHighest: darkSurfaceHighest,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
      ),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: darkText,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: darkText),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: darkText,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: darkText,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: darkText,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: darkText),
        bodyMedium: TextStyle(fontSize: 14, color: darkTextSecondary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCard,
        labelStyle: const TextStyle(color: darkTextSecondary, fontSize: 14),
        floatingLabelStyle: const TextStyle(
          color: primaryLight,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: const TextStyle(color: darkTextSecondary, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white24, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
