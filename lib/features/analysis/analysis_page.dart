library;

import 'package:flutter/material.dart';

/// AI 分析頁面（骨架）
/// P3 階段會在這裡實作 AI 分析結果顯示
class AnalysisPage extends StatelessWidget {
  const AnalysisPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI 分析')),
      body: const Center(
        child: Text('AI 分析 coming soon'),
      ),
    );
  }
}
