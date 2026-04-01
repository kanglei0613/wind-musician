library;

import 'package:flutter/material.dart';

/// 樂譜功能頁面（預留）
/// 規劃功能：
/// - MusicXML / MXL 檔案匯入
/// - 移調轉譜（Bb → Eb 等）
/// - 輸出音檔（MIDI / MP3）
/// - 譜頻分析（對照錄音）
/// - 練習模式
/// 預計第二版實作
class ScorePage extends StatelessWidget {
  const ScorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('樂譜')),
      body: const Center(
        child: Text('樂譜功能 coming soon'),
      ),
    );
  }
}