library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'shared/theme/app_theme.dart';
import 'shared/theme/color_mode_provider.dart';
import 'router.dart';

/// 語言設定 Provider
final localeProvider = StateProvider<Locale>((ref) {
  return const Locale('zh');
});

/// App 根元件
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final colorMode = ref.watch(colorModeProvider);

    return MaterialApp.router(
      title: 'Wind Musician',
      theme: AppTheme.fromMode(colorMode),
      routerConfig: appRouter,
      locale: locale,
      supportedLocales: const [
        Locale('zh'),
        Locale('en'),
        Locale('ja'),
        Locale('ko'),
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
