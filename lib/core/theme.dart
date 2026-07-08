import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors (Tinder Inspired Sleek Theme)
  static const Color primaryPink = Color(0xFFFD3A73);
  static const Color primaryOrange = Color(0xFFFF6B6B);
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color textPrimaryLight = Color(0xFFF8FAFC);
  static const Color textSecondaryLight = Color(0xFF94A3B8);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryPink, primaryOrange],
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
  );

  static const LinearGradient premiumGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)], // Golden Gradient
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundDark,
      primaryColor: primaryPink,
      cardColor: surfaceDark,
      colorScheme: const ColorScheme.dark(
        primary: primaryPink,
        secondary: accentPurple,
        surface: surfaceDark,
        error: Colors.redAccent,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: textPrimaryLight, fontFamily: 'Outfit'),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textPrimaryLight, fontFamily: 'Outfit'),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: textPrimaryLight, fontFamily: 'Outfit'),
        bodyLarge: TextStyle(fontSize: 16, color: textPrimaryLight, fontFamily: 'Inter'),
        bodyMedium: TextStyle(fontSize: 14, color: textSecondaryLight, fontFamily: 'Inter'),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDark,
        hintStyle: const TextStyle(color: textSecondaryLight, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF334155), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryPink, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
      buttonTheme: const ButtonThemeData(
        buttonColor: primaryPink,
        textTheme: ButtonTextTheme.primary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: primaryPink,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
        ),
      ),
    );
  }
}
