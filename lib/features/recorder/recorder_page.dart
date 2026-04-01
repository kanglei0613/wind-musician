library;

import 'package:flutter/material.dart';

/// 錄音頁面（骨架）
/// P2 階段會在這裡實作錄音功能
class RecorderPage extends StatelessWidget {
  const RecorderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('錄音')),
      body: const Center(
        child: Text('錄音 coming soon'),
      ),
    );
  }
}
