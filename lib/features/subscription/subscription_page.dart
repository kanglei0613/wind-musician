library;

import 'package:flutter/material.dart';

/// 訂閱頁面
///
/// 重要：根據 Apple 規定，此頁面不能放任何價格或付費按鈕
/// 只能說明 Pro 功能，並引導用戶去官網
///
/// 規劃內容：
/// - 列出 Pro 版功能清單
/// - 顯示「前往官網了解更多」按鈕
/// - 按鈕導向 AppConstants.subscriptionUrl
/// - 不顯示價格、不放付款連結（Apple 審查規定）
///
/// 觸發時機：
/// - 免費用戶碰到 Pro 功能時自動顯示
/// - 設定頁有入口
/// - AI 分析次數用完時顯示
///
/// 定價（僅在官網顯示）：
/// - 台灣：NT$99/月，NT$799/年
/// - 日本：¥480/月，¥3,800/年
/// - 韓國：₩4,500/月，₩36,000/年
/// - 美國：$3.99/月，$29.99/年

class SubscriptionPage extends StatelessWidget {
  const SubscriptionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('升級 Pro')),
      body: const Center(
        child: Text('訂閱頁面 coming soon'),
      ),
    );
  }
}
