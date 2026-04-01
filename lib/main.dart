import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

void main() {
  runApp(
    // ProviderScope 是 Riverpod 的根容器
    // 所有 Provider 都必須在這個範圍內才能使用
    const ProviderScope(
      child: MyApp(),
    ),
  );
}
