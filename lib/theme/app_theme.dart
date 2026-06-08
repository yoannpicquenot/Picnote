import 'package:flutter/material.dart';

class AppColors {
  // Light mode
  static const beige = Color(0xFFF5E6D3);
  static const beigeCard = Color(0xFFFAEFE4);
  static const brown = Color(0xFF8B4513);
  static const brownDark = Color(0xFF5C2D0A);
  static const brownMedium = Color(0xFFB07040);
  static const charcoal = Color(0xFF1A1208);

  // Dark mode
  static const darkBg = Color(0xFF1A1208);
  static const darkCard = Color(0xFF2A1F10);
  static const darkCardLight = Color(0xFF352818);

  static const white = Color(0xFFFFFFFF);
  static const checkGreen = Color(0xFF8B4513);
}

class AppTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.beige,
      colorScheme: const ColorScheme.light(
        primary: AppColors.brownDark,
        secondary: AppColors.brownMedium,
        surface: AppColors.beigeCard,
        onPrimary: AppColors.white,
        onSurface: AppColors.brownDark,
      ),
      textTheme: _buildTextTheme(AppColors.brownDark),
      fontFamily: 'Chillax',
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.brownMedium,
        secondary: AppColors.brown,
        surface: AppColors.darkCard,
        onPrimary: AppColors.white,
        onSurface: AppColors.beigeCard,
      ),
      textTheme: _buildTextTheme(AppColors.beigeCard),
      fontFamily: 'Chillax',
    );
  }

  static TextTheme _buildTextTheme(Color color) {
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w900,
        color: color,
        letterSpacing: 1.2,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: color,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: color.withOpacity(0.8),
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        color: color.withOpacity(0.5),
      ),
    );
  }
}
