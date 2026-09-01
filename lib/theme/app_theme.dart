import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color _navy = Color(0xFF17365D);
  static const Color _navySoft = Color(0xFF2F5D8A);
  static const Color _pageBackground = Color(0xFFF2F4F7);
  static const Color _border = Color(0xFFD7DEE8);
  static const Color _textPrimary = Color(0xFF1F2D3D);
  static const Color _textSecondary = Color(0xFF5C6B7A);

  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: _pageBackground,
      canvasColor: _pageBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _navy,
        brightness: Brightness.light,
        primary: _navy,
        secondary: _navySoft,
        surface: Colors.white,
        surfaceContainer: const Color(0xFFF8F9FB),
      ),
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: _navy,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        iconTheme: IconThemeData(color: _navy),
        actionsIconTheme: IconThemeData(color: _navy),
        titleTextStyle: TextStyle(
          color: _navy,
          fontSize: 19,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
        ),
      ),
      dividerTheme: const DividerThemeData(color: _border, thickness: 1),
      cardTheme: CardThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        shadowColor: const Color(0x1A0B1F33),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: _border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _navy, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFB3261E)),
        ),
        hintStyle: const TextStyle(color: Color(0xFF8793A1)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _navy,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          minimumSize: const Size(0, 46),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _navy,
          side: const BorderSide(color: _border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          minimumSize: const Size(0, 46),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: _navy),
      ),
      textTheme: base.textTheme.copyWith(
        headlineLarge: const TextStyle(
          fontSize: 29,
          fontWeight: FontWeight.w800,
          color: _navy,
        ),
        headlineMedium: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: _navy,
        ),
        headlineSmall: const TextStyle(
          color: _textPrimary,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: const TextStyle(
          color: _textPrimary,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: _textPrimary,
        ),
        bodyLarge: const TextStyle(fontSize: 16, color: _textPrimary),
        bodyMedium: const TextStyle(fontSize: 14, color: _textSecondary),
        bodySmall: const TextStyle(color: _textSecondary),
      ),
    );
  }
}
