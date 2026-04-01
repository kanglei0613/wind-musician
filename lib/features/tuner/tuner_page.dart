library;

import 'package:flutter/material.dart';

/// 調音器頁面（骨架）
/// P2 階段會在這裡實作即時音高偵測
class TunerPage extends StatelessWidget {
  const TunerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('調音器')),
      body: const Center(
        child: Text('調音器 coming soon'),
      ),
    );
  }
}
