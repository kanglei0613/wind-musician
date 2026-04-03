import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 在 App 啟動時初始化 SoLoud
  await SoLoud.instance.init();
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}
