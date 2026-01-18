import 'package:flutter/material.dart';

class RadioAppTheme {
  static const Color warmIvory = Color(0xFFF2E3D2);
  static const Color warmBrown = Color(0xFF3E2B1E);
  static const Color burnishedGold = Color(0xFFB7833F);
  static const Color deepLeather = Color(0xFF1B1410);
  static const Color brass = Color(0xFFCF9A4A);
  static const Color ember = Color(0xFFB6473D);

  static ThemeData get theme {
    final base = ThemeData(
      brightness: Brightness.dark,
      fontFamily: 'ChosunCentennial',
      colorScheme: ColorScheme.fromSeed(
        seedColor: burnishedGold,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: Colors.transparent,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xCC2E231A),
        hintStyle: const TextStyle(color: Colors.white54),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: burnishedGold,
          foregroundColor: deepLeather,
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: brass,
          textStyle: const TextStyle(letterSpacing: 0.4),
        ),
      ),
    );

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        headlineMedium: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: warmIvory,
          letterSpacing: 0.6,
        ),
        titleLarge: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: warmIvory,
        ),
        bodyLarge: const TextStyle(
          fontSize: 16,
          color: warmIvory,
          height: 1.4,
        ),
        bodyMedium: const TextStyle(
          fontSize: 15,
          color: warmIvory,
          height: 1.4,
        ),
        labelLarge: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
