library;

import 'package:flutter/material.dart';

/// Score Following 頁面（第三版預留）
///
/// 規劃功能：
/// - KTV 式標記，隨演奏速度高亮當前小節和拍子
/// - 即時音訊對齊（Online Dynamic Time Warping）
/// - 不管演奏者快或慢都能跟上
/// - 支援 MusicXML 格式樂譜
///
/// 技術規劃：
/// - 音訊對齊演算法：Online DTW（librosa）
/// - 取樣率：22050 Hz（AppConstants.scoreFollowingSampleRate）
/// - DTW 視窗：50（AppConstants.dtwWindowSize）
/// - 後端即時處理，結果透過 WebSocket 回傳
///
/// 開發前置條件：
/// 1. MusicXML 匯入功能完成（score_page.dart）
/// 2. 後端有穩定的即時音訊處理能力
/// 3. 有足夠用戶驗證需求（建議 1,000+ 用戶後開發）
///
/// 市場價值：
/// - 市面上很少 App 做得好
/// - 管樂手練習時特別需要
/// - 可作為 Pro 功能的核心賣點

class ScoreFollowingPage extends StatelessWidget {
  const ScoreFollowingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('跟譜練習')),
      body: const Center(
        child: Text('跟譜練習 coming soon'),
      ),
    );
  }
}
