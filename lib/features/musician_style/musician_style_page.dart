library;

import 'package:flutter/material.dart';

/// 音樂家風格選擇頁面（Pro 功能）
///
/// 規劃功能：
/// - 選擇音樂家風格影響 AI 分析的回饋方向
/// - 每位音樂家有獨立的風格檔案（JSON）
/// - 風格檔案包含：演奏哲學、技術重點、教學語氣、文化背景
/// - AI 收到分析結果後，根據風格檔案產生對應風格的建議文字
///
/// 規劃的音樂家（初版）：
/// - Dennis Brain（法國號，英國派，鼓勵型）
/// - Philip Farkas（法國號，美國派，技術型）
/// - Maurice André（小號，法國派，音色派）
/// - Wynton Marsalis（小號，爵士派）
/// - 持續擴充...
///
/// 版權說明：
/// - 不使用任何版權音訊或影片
/// - 風格檔案是公開知識的整理，不涉及版權
/// - UI 不使用音樂家照片（肖像權）
/// - 標示「XX 風格」而非「XX 本人建議」

class MusicianStylePage extends StatelessWidget {
  const MusicianStylePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('音樂家風格')),
      body: const Center(
        child: Text('音樂家風格 coming soon'),
      ),
    );
  }
}
