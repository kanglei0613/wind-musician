library;

import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'color_mode_provider.dart';

class AppTheme {
  static ThemeData fromMode(ColorMode mode) {
    final colors = AppColors.fromMode(mode);
    final isDark = mode.brightness == AppBrightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: colors.background,

      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: colors.accent,
        onPrimary: Colors.white,
        secondary: colors.accent,
        onSecondary: Colors.white,
        surface: colors.surface,
        onSurface: colors.textPrimary,
        onSurfaceVariant: colors.textSecondary,
        surfaceContainerHighest: colors.surfaceLight,
        error: AppColors.error,
        onError: Colors.white,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.surface,
        selectedItemColor: colors.accent,
        unselectedItemColor: colors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
      ),

      textTheme: TextTheme(
        headlineLarge: TextStyle(
          color: colors.textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.w700,
        ),
        headlineMedium: TextStyle(
          color: colors.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: colors.textPrimary,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: colors.textSecondary,
          fontSize: 14,
        ),
      ),

      drawerTheme: DrawerThemeData(
        backgroundColor: colors.surface,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(colors.accent),
        trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? colors.accent.withAlpha(120)
              : colors.surfaceLight,
        ),
      ),
    );
  }

  static ThemeData get dark => fromMode(const ColorMode());
}
