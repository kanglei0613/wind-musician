library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'shared/theme/app_theme.dart';
import 'router.dart';

/// 語言設定 Provider
/// 使用者在設定頁切換語言時更新這個 Provider
/// 整個 App 的語言會跟著自動切換
final localeProvider = StateProvider<Locale>((ref) {
  // 預設中文
  return const Locale('zh');
});

/// App 根元件
/// 所有全域設定都在這裡：主題、語言、路由
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 監聽語言變化
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      // App 名稱
      title: 'Wind Musician',

      // 深色主題
      theme: AppTheme.dark,

      // 路由設定
      routerConfig: appRouter,

      // 多語言設定
      locale: locale,
      supportedLocales: const [
        Locale('zh'), // 中文
        Locale('en'), // 英文
        Locale('ja'), // 日文
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}