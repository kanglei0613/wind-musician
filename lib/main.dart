import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'firebase_options.dart';
import 'shared/constants/app_constants.dart';
import 'shared/theme/color_mode_provider.dart';

void main() async {
  // 1. Flutter engine
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 3. Crashlytics — 捕捉所有未處理例外
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // 4. SoLoud 音訊引擎（失敗不阻擋 app 啟動）
  try {
    await SoLoud.instance.init();
  } catch (e) {
    debugPrint('SoLoud init failed: $e');
  }

  // 5. 讀取已儲存的語言設定，在 runApp 前注入，避免冷啟動時語言閃爍
  final prefs = await SharedPreferences.getInstance();
  final savedLocale = prefs.getString(AppConstants.keyLocale);
  final initialLocale = (savedLocale != null &&
          AppConstants.supportedLocales.contains(savedLocale))
      ? Locale(savedLocale)
      : const Locale('zh');

  // 5b. 讀取已儲存的 Color Mode（scheme + brightness）
  final savedScheme = prefs.getString(AppConstants.keyColorScheme);
  final savedBrightness = prefs.getString(AppConstants.keyColorBrightness);
  final initialColorMode = ColorMode(
    scheme: AppColorScheme.values.firstWhere(
      (e) => e.name == savedScheme,
      orElse: () => AppColorScheme.black,
    ),
    brightness: AppBrightness.values.firstWhere(
      (e) => e.name == savedBrightness,
      orElse: () => AppBrightness.dark,
    ),
  );

  // 6. 啟動 app
  runZonedGuarded(
    () => runApp(
      ProviderScope(
        overrides: [
          localeProvider.overrideWith((ref) => initialLocale),
          colorModeProvider.overrideWith((ref) => initialColorMode),
        ],
        child: const MyApp(),
      ),
    ),
    (error, stack) =>
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true),
  );
}

