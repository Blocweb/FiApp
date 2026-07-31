import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Tema Material 3 de la aplicación.
///
/// Centraliza tipografía (Inter), radios, elevaciones y esquema de color
/// para que todas las pantallas compartan la misma identidad visual que
/// tenía el prototipo original.
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.blue,
      brightness: Brightness.light,
      primary: AppColors.blue,
      secondary: AppColors.green,
      error: AppColors.red,
      surface: AppColors.card,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.bg,
      fontFamily: 'Inter',
      textTheme: _textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.card,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.blue, width: 1.5),
        ),
        labelStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.muted,
        ),
        hintStyle: const TextStyle(
          fontFamily: 'Inter',
          color: AppColors.muted,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static const TextTheme _textTheme = TextTheme(
    displayLarge: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w800),
    displayMedium: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w800),
    headlineLarge: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w800),
    headlineMedium: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700),
    titleLarge: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700),
    titleMedium: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600),
    bodyLarge: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w400),
    bodyMedium: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w400),
    labelLarge: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600),
  );
}
