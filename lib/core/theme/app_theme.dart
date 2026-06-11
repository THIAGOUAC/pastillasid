import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData lightTheme({double fontScale = 1.0}) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBackground,
      primaryColor: AppColors.lightPrimary,
      colorScheme: const ColorScheme.light(
        primary: AppColors.lightPrimary,
        secondary: AppColors.lightSecondary,
        tertiary: AppColors.lightAccent,
        surface: AppColors.lightCard,
        error: AppColors.lightAlert,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightPrimary,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightCard,
        elevation: 3,
        shadowColor: Color.fromRGBO(26, 107, 138, 0.12),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lightPrimary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: TextStyle(
            fontSize: 16 * fontScale,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.lightPrimary,
          minimumSize: const Size(double.infinity, 52),
          side: const BorderSide(color: AppColors.lightPrimary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: TextStyle(
            fontSize: 16 * fontScale,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurface,
        labelStyle: TextStyle(
          color: AppColors.lightTextSecondary,
          fontSize: 15 * fontScale,
        ),
        hintStyle: TextStyle(
          color: AppColors.lightTextSecondary,
          fontSize: 14 * fontScale,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.lightPrimary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.lightAccent,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lightSurface,
        selectedColor: Color.fromRGBO(26, 107, 138, 0.15),
        labelStyle: TextStyle(
          color: AppColors.lightTextPrimary,
          fontSize: 13 * fontScale,
        ),
        side: const BorderSide(color: AppColors.lightBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.lightBorder,
        thickness: 1,
      ),
      textTheme: _buildTextTheme(
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
      primaryColor: AppColors.darkPrimary,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.darkPrimary,
        secondary: AppColors.darkSecondary,
        tertiary: AppColors.darkAccent,
        surface: AppColors.darkCard,
        error: AppColors.darkAlert,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkCard,
        foregroundColor: AppColors.darkTextPrimary,
        centerTitle: true,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: 3,
        shadowColor: Colors.black38,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkPrimary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: TextStyle(
            fontSize: 16 * fontScale,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkPrimary,
          minimumSize: const Size(double.infinity, 52),
          side: const BorderSide(color: AppColors.darkPrimary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: TextStyle(
            fontSize: 16 * fontScale,
            fontWeight: FontWeight.w600,
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
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.darkPrimary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.darkAccent,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedColor: Color.fromRGBO(30, 138, 176, 0.25),
        labelStyle: TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: 13 * fontScale,
        ),
        side: const BorderSide(color: AppColors.darkBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorder,
        thickness: 1,
      ),
      textTheme: _buildTextTheme(
        primaryText: AppColors.darkTextPrimary,
        secondaryText: AppColors.darkTextSecondary,
        fontScale: fontScale,
      ),
    );
  }

  static TextTheme _buildTextTheme({
    required Color primaryText,
    required Color secondaryText,
    required double fontScale,
  }) {
    return TextTheme(
      headlineLarge: TextStyle(
        color: primaryText,
        fontSize: 30 * fontScale,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
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
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        color: secondaryText,
        fontSize: 14 * fontScale,
        height: 1.4,
      ),
      labelLarge: TextStyle(
        color: primaryText,
        fontSize: 16 * fontScale,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      ),
      labelSmall: TextStyle(
        color: secondaryText,
        fontSize: 11 * fontScale,
        letterSpacing: 0.5,
      ),
    );
  }
}
