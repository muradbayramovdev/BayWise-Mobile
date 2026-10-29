import 'package:flutter/material.dart';

class AppColors {
  // Dark backgrounds
  static const dark900 = Color(0xFF0D0F14);
  static const dark800 = Color(0xFF161B24);
  static const dark700 = Color(0xFF1E2535);
  static const dark600 = Color(0xFF2A3347);
  static const dark400 = Color(0xFF6B7A99);
  static const dark300 = Color(0xFF8B9ABB);
  static const dark200 = Color(0xFFB0BEDB);
  static const dark100 = Color(0xFFD6DDED);

  // Light backgrounds
  static const light900 = Color(0xFFF8FAFC);
  static const light800 = Color(0xFFFFFFFF);
  static const light700 = Color(0xFFF1F5F9);
  static const light600 = Color(0xFFE2E8F0);
  static const light400 = Color(0xFF94A3B8);
  static const light300 = Color(0xFF64748B);
  static const light200 = Color(0xFF475569);
  static const light100 = Color(0xFF1E293B);

  // Accents
  static const accentPurple = Color(0xFF8B5CF6);
  static const accentTeal = Color(0xFF14B8A6);
  static const accentGreen = Color(0xFF22C55E);
  static const accentAmber = Color(0xFFF59E0B);
  static const accentRed = Color(0xFFEF4444);
  static const accentCyan = Color(0xFF06B6D4);

  // Chart colors
  static const List<Color> chartColors = [
    accentGreen,
    accentTeal,
    accentPurple,
    accentCyan,
    accentAmber,
    accentRed,
    Color(0xFF84CC16),
    Color(0xFFA855F7),
  ];
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.dark900,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accentPurple,
        secondary: AppColors.accentTeal,
        surface: AppColors.dark800,
        error: AppColors.accentRed,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.dark900,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: AppColors.dark100,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: AppColors.dark100),
      ),
      cardTheme: CardThemeData(
        color: AppColors.dark800,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.dark700,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(color: AppColors.dark400),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentPurple,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          minimumSize: const Size(double.infinity, 48),
        ),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.dark100),
        bodyMedium: TextStyle(color: AppColors.dark200),
        bodySmall: TextStyle(color: AppColors.dark300),
        titleLarge:
            TextStyle(color: AppColors.dark100, fontWeight: FontWeight.w600),
        titleMedium:
            TextStyle(color: AppColors.dark100, fontWeight: FontWeight.w500),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.dark800,
        selectedItemColor: AppColors.accentPurple,
        unselectedItemColor: AppColors.dark400,
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.light900,
      colorScheme: const ColorScheme.light(
        primary: AppColors.accentPurple,
        secondary: AppColors.accentTeal,
        surface: AppColors.light800,
        error: AppColors.accentRed,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.light800,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: AppColors.light100,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: AppColors.light100),
      ),
      cardTheme: CardThemeData(
        color: AppColors.light800,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.light700,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(color: AppColors.light400),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentPurple,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          minimumSize: const Size(double.infinity, 48),
        ),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.light100),
        bodyMedium: TextStyle(color: AppColors.light200),
        bodySmall: TextStyle(color: AppColors.light300),
        titleLarge:
            TextStyle(color: AppColors.light100, fontWeight: FontWeight.w600),
        titleMedium:
            TextStyle(color: AppColors.light100, fontWeight: FontWeight.w500),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.light800,
        selectedItemColor: AppColors.accentPurple,
        unselectedItemColor: AppColors.light400,
      ),
    );
  }
}
