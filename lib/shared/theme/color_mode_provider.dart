library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 支援的顏色主題
enum AppColorScheme {
  black,
  gray,
  white,
  blue,
  pink,
  purple,
  green,
  yellow,
}

/// 亮暗模式
enum AppBrightness { dark, light }

/// 目前的 Color Mode 狀態
class ColorMode {
  final AppColorScheme scheme;
  final AppBrightness brightness;

  const ColorMode({
    this.scheme = AppColorScheme.black,
    this.brightness = AppBrightness.dark,
  });

  ColorMode copyWith({
    AppColorScheme? scheme,
    AppBrightness? brightness,
  }) => ColorMode(
    scheme: scheme ?? this.scheme,
    brightness: brightness ?? this.brightness,
  );
}

/// Color Mode Provider
final colorModeProvider = StateProvider<ColorMode>((ref) {
  return const ColorMode();
});
