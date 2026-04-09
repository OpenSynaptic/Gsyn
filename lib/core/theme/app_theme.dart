/// Dark industrial IoT theme.
import 'package:flutter/material.dart';
import 'package:gsyn/core/constants.dart';
import 'package:gsyn/core/theme/theme_provider.dart';

// Light-mode text colors
const _lightTextPrimary = Color(0xFF202124);
const _lightTextSecondary = Color(0xFF5F6368);

class AppTheme {
  /// Build a dark theme seeded by [seedColor] with [bg] controlling background tones.
  static ThemeData buildDark(Color seedColor, AppBgPreset bg) => ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    colorSchemeSeed: seedColor,
    scaffoldBackgroundColor: bg.background,
    cardTheme: CardThemeData(
      color: bg.card,
      elevation: 2,
      margin: const EdgeInsets.all(8),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: bg.surface,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: bg.surface,
      indicatorColor: seedColor.withValues(alpha: 0.3),
    ),
    drawerTheme: DrawerThemeData(backgroundColor: bg.surface),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: TextStyle(color: AppColors.textPrimary),
      titleMedium: TextStyle(color: AppColors.textPrimary),
      bodyLarge: TextStyle(color: AppColors.textPrimary),
      bodyMedium: TextStyle(color: AppColors.textSecondary),
      labelLarge: TextStyle(color: AppColors.textPrimary),
    ),
    dividerTheme: DividerThemeData(
      color: bg.surface.withValues(
        alpha: 1.5,
      ) /* slightly lighter than surface */,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: bg.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: bg.card),
      ),
    ),
  );

  /// Build a light theme seeded by [seedColor] with [bg] controlling background tones.
  static ThemeData buildLight(Color seedColor, AppBgPreset bg) => ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    colorSchemeSeed: seedColor,
    scaffoldBackgroundColor: bg.background,
    cardTheme: CardThemeData(
      color: bg.card,
      elevation: 1,
      margin: const EdgeInsets.all(8),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: bg.surface,
      foregroundColor: _lightTextPrimary,
      elevation: 0,
      shadowColor: Colors.black12,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: bg.surface,
      indicatorColor: seedColor.withValues(alpha: 0.18),
    ),
    drawerTheme: DrawerThemeData(backgroundColor: bg.surface),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: _lightTextPrimary,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: TextStyle(
        color: _lightTextPrimary,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: TextStyle(color: _lightTextPrimary),
      titleMedium: TextStyle(color: _lightTextPrimary),
      bodyLarge: TextStyle(color: _lightTextPrimary),
      bodyMedium: TextStyle(color: _lightTextSecondary),
      labelLarge: TextStyle(color: _lightTextPrimary),
    ),
    dividerTheme: const DividerThemeData(color: Color(0xFFDADCE0)),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: bg.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFDADCE0)),
      ),
    ),
  );

  /// Build the correct theme (dark or light) based on [bg].
  static ThemeData build(Color seedColor, AppBgPreset bg) =>
      bg.isLight ? buildLight(seedColor, bg) : buildDark(seedColor, bg);

  /// Default dark theme (kept for backward compat).
  static ThemeData get dark =>
      buildDark(AppColors.primary, AppBgPreset.deepNavy);
}
