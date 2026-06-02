import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData lightTheme({double fontScale = 1.0}) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightPinkBackground,
      primaryColor: AppColors.lightPrimaryBrown,
      colorScheme: const ColorScheme.light(
        primary: AppColors.lightPrimaryBrown,
        secondary: AppColors.lightSecondaryBrown,
        surface: AppColors.lightCard,
        error: AppColors.lightAlert,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightPrimaryBrown,
        foregroundColor: AppColors.lightCard,
        centerTitle: true,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightCard,
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lightPrimaryBrown,
          foregroundColor: AppColors.lightCard,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: TextStyle(
            fontSize: 16 * fontScale,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightCard,
        labelStyle: TextStyle(
          color: AppColors.lightTextSecondary,
          fontSize: 15 * fontScale,
        ),
        hintStyle: TextStyle(
          color: AppColors.lightTextSecondary,
          fontSize: 14 * fontScale,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.lightPrimaryBrown,
            width: 1.5,
          ),
        ),
      ),
      textTheme: _textTheme(
        primaryText: AppColors.lightTextPrimary,
        secondaryText: AppColors.lightTextSecondary,
        fontScale: fontScale,
      ),
    );
  }

  static ThemeData darkTheme({double fontScale = 1.0}) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      primaryColor: AppColors.darkPrimaryBrown,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.darkPrimaryBrown,
        secondary: AppColors.darkSecondaryBrown,
        surface: AppColors.darkCard,
        error: AppColors.darkAlert,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkPrimaryBrown,
        foregroundColor: AppColors.darkTextPrimary,
        centerTitle: true,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkPrimaryBrown,
          foregroundColor: AppColors.darkTextPrimary,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: TextStyle(
            fontSize: 16 * fontScale,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
        labelStyle: TextStyle(
          color: AppColors.darkTextSecondary,
          fontSize: 15 * fontScale,
        ),
        hintStyle: TextStyle(
          color: AppColors.darkTextSecondary,
          fontSize: 14 * fontScale,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.darkEmphasisBrown,
            width: 1.5,
          ),
        ),
      ),
      textTheme: _textTheme(
        primaryText: AppColors.darkTextPrimary,
        secondaryText: AppColors.darkTextSecondary,
        fontScale: fontScale,
      ),
    );
  }

  static TextTheme _textTheme({
    required Color primaryText,
    required Color secondaryText,
    required double fontScale,
  }) {
    return TextTheme(
      headlineLarge: TextStyle(
        color: primaryText,
        fontSize: 30 * fontScale,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: TextStyle(
        color: primaryText,
        fontSize: 24 * fontScale,
        fontWeight: FontWeight.bold,
      ),
      titleLarge: TextStyle(
        color: primaryText,
        fontSize: 20 * fontScale,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: TextStyle(
        color: primaryText,
        fontSize: 18 * fontScale,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        color: primaryText,
        fontSize: 16 * fontScale,
      ),
      bodyMedium: TextStyle(
        color: secondaryText,
        fontSize: 14 * fontScale,
      ),
      labelLarge: TextStyle(
        color: primaryText,
        fontSize: 16 * fontScale,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}