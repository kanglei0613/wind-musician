library;

import 'package:flutter/material.dart';
import 'color_mode_provider.dart';

/// 動態顏色系統
/// 根據 ColorMode 產生對應的顏色
class AppColors {
  // ── 固定顏色（不隨主題變化）────────────────────
  static const tunerInTune = Color(0xFF00C896);
  static const tunerSharp = Color(0xFFFF5252);
  static const tunerFlat = Color(0xFFFFB300);
  static const success = Color(0xFF00C896);
  static const warning = Color(0xFFFFB300);
  static const error = Color(0xFFFF5252);

  // ── 預設顏色（黑色 Dark Mode，向下相容）─────────
  static const primary = Color(0xFF3D5AFE);
  static const accent1 = Color(0xFF3b82f6);
  static const primaryDark = Color(0xFF0031CA);
  static const primaryLight = Color(0xFF8187FF);
  static const background = Color(0xFF0F1923);
  static const surface = Color(0xFF1A2535);
  static const surfaceLight = Color(0xFF243044);
  static const textPrimary = Color(0xFFE8EDF5);
  static const textSecondary = Color(0xFF8A9BB5);

  // ── 動態顏色產生 ──────────────────────────────
  static AppColorSet fromMode(ColorMode mode) {
    final isDark = mode.brightness == AppBrightness.dark;
    return _schemes[mode.scheme]!(isDark);
  }

  static final Map<AppColorScheme, AppColorSet Function(bool isDark)> _schemes = {
    AppColorScheme.black: (isDark) => isDark
        ? const AppColorSet(
            background: Color(0xFF0F1923),
            surface: Color(0xFF1A2535),
            surfaceLight: Color(0xFF243044),
            textPrimary: Color(0xFFE8EDF5),
            textSecondary: Color(0xFF8A9BB5),
            accent: Color(0xFF3b82f6),
          )
        : const AppColorSet(
            background: Color(0xFFF0F4F8),
            surface: Color(0xFFFFFFFF),
            surfaceLight: Color(0xFFE2E8F0),
            textPrimary: Color(0xFF1A202C),
            textSecondary: Color(0xFF718096),
            accent: Color(0xFF3b82f6),
          ),

    AppColorScheme.gray: (isDark) => isDark
        ? const AppColorSet(
            background: Color(0xFF1A1A1A),
            surface: Color(0xFF2D2D2D),
            surfaceLight: Color(0xFF3D3D3D),
            textPrimary: Color(0xFFE8E8E8),
            textSecondary: Color(0xFF9A9A9A),
            accent: Color(0xFF3b82f6),
          )
        : const AppColorSet(
            background: Color(0xFFF5F5F5),
            surface: Color(0xFFFFFFFF),
            surfaceLight: Color(0xFFE0E0E0),
            textPrimary: Color(0xFF212121),
            textSecondary: Color(0xFF757575),
            accent: Color(0xFF3b82f6),
          ),

    AppColorScheme.white: (isDark) => isDark
        ? const AppColorSet(
            background: Color(0xFF2C2C2C),
            surface: Color(0xFF3C3C3C),
            surfaceLight: Color(0xFF4C4C4C),
            textPrimary: Color(0xFFFFFFFF),
            textSecondary: Color(0xFFAAAAAA),
            accent: Color(0xFF3b82f6),
          )
        : const AppColorSet(
            background: Color(0xFFFFFFFF),
            surface: Color(0xFFF8F8F8),
            surfaceLight: Color(0xFFEEEEEE),
            textPrimary: Color(0xFF111111),
            textSecondary: Color(0xFF666666),
            accent: Color(0xFF3b82f6),
          ),

    AppColorScheme.blue: (isDark) => isDark
        ? const AppColorSet(
            background: Color(0xFF0D1B2A),
            surface: Color(0xFF1B2D42),
            surfaceLight: Color(0xFF243D58),
            textPrimary: Color(0xFFE8F1FF),
            textSecondary: Color(0xFF7A9CBF),
            accent: Color(0xFF60A5FA),
          )
        : const AppColorSet(
            background: Color(0xFFEBF5FF),
            surface: Color(0xFFFFFFFF),
            surfaceLight: Color(0xFFD6EBFF),
            textPrimary: Color(0xFF1A3A5C),
            textSecondary: Color(0xFF5A8AB0),
            accent: Color(0xFF3b82f6),
          ),

    AppColorScheme.pink: (isDark) => isDark
        ? const AppColorSet(
            background: Color(0xFF1F0D14),
            surface: Color(0xFF2D1420),
            surfaceLight: Color(0xFF3D1F2E),
            textPrimary: Color(0xFFFFE8F0),
            textSecondary: Color(0xFFBF7A95),
            accent: Color(0xFFF472B6),
          )
        : const AppColorSet(
            background: Color(0xFFFFF0F5),
            surface: Color(0xFFFFFFFF),
            surfaceLight: Color(0xFFFFD6E7),
            textPrimary: Color(0xFF5C1A35),
            textSecondary: Color(0xFFB05A7A),
            accent: Color(0xFFEC4899),
          ),

    AppColorScheme.purple: (isDark) => isDark
        ? const AppColorSet(
            background: Color(0xFF130D1F),
            surface: Color(0xFF1E142D),
            surfaceLight: Color(0xFF2A1F3D),
            textPrimary: Color(0xFFEEE8FF),
            textSecondary: Color(0xFF9A7ABF),
            accent: Color(0xFFA78BFA),
          )
        : const AppColorSet(
            background: Color(0xFFF3EEFF),
            surface: Color(0xFFFFFFFF),
            surfaceLight: Color(0xFFE4D6FF),
            textPrimary: Color(0xFF2D1A5C),
            textSecondary: Color(0xFF7A5AB0),
            accent: Color(0xFF8B5CF6),
          ),

    AppColorScheme.green: (isDark) => isDark
        ? const AppColorSet(
            background: Color(0xFF0D1F14),
            surface: Color(0xFF142D1E),
            surfaceLight: Color(0xFF1F3D28),
            textPrimary: Color(0xFFE8FFEe),
            textSecondary: Color(0xFF7ABF95),
            accent: Color(0xFF34D399),
          )
        : const AppColorSet(
            background: Color(0xFFEDFFF4),
            surface: Color(0xFFFFFFFF),
            surfaceLight: Color(0xFFD6FFE7),
            textPrimary: Color(0xFF1A5C35),
            textSecondary: Color(0xFF5AB07A),
            accent: Color(0xFF10B981),
          ),

    AppColorScheme.yellow: (isDark) => isDark
        ? const AppColorSet(
            background: Color(0xFF1F1A0D),
            surface: Color(0xFF2D2514),
            surfaceLight: Color(0xFF3D321F),
            textPrimary: Color(0xFFFFF8E8),
            textSecondary: Color(0xFFBFAA7A),
            accent: Color(0xFFFBBF24),
          )
        : const AppColorSet(
            background: Color(0xFFFFFBEB),
            surface: Color(0xFFFFFFFF),
            surfaceLight: Color(0xFFFFF3C4),
            textPrimary: Color(0xFF5C4A1A),
            textSecondary: Color(0xFFB09A5A),
            accent: Color(0xFFF59E0B),
          ),
  };
}

/// 一組完整的顏色
class AppColorSet {
  final Color background;
  final Color surface;
  final Color surfaceLight;
  final Color textPrimary;
  final Color textSecondary;
  final Color accent;

  const AppColorSet({
    required this.background,
    required this.surface,
    required this.surfaceLight,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
  });
}