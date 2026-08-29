import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF5F8FC),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0D47A1),
        primary: const Color(0xFF0D47A1),
        secondary: const Color(0xFF1976D2),
        surface: Colors.white,
        surfaceContainer: const Color(0xFFF5F8FC),
      ),
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF0D47A1)),
        titleTextStyle: TextStyle(
          color: Color(0xFF0D47A1),
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE0E7F1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE0E7F1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF0D47A1), width: 2),
        ),
        hintStyle: const TextStyle(color: Color(0xFF8A9BB5)),
      ),
      textTheme: base.textTheme.copyWith(
        headlineLarge: const TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          color: Color(0xFF0D47A1),
        ),
        headlineMedium: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: Color(0xFF0D47A1),
        ),
        titleMedium: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Color(0xFF102B52),
        ),
        bodyLarge: const TextStyle(fontSize: 16, color: Color(0xFF23406A)),
        bodyMedium: const TextStyle(fontSize: 14, color: Color(0xFF5B6B82)),
      ),
    );
  }
}
