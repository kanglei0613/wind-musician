library;

import 'package:flutter/material.dart';

/// 行程記錄頁面（骨架）
/// P2 階段會在這裡實作練習行程管理
class SchedulePage extends StatelessWidget {
  const SchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('行程')),
      body: const Center(
        child: Text('行程 coming soon'),
      ),
    );
  }
}
