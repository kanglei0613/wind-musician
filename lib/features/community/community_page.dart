library;

import 'package:flutter/material.dart';

/// 社群功能頁面（第三版預留）
///
/// 規劃功能：
/// - 分享演奏錄音（最長 60 秒）
/// - 互相評論、按讚
/// - 追蹤其他演奏者
/// - 挑戰賽（同一首曲子大家來比）
/// - 老師平台（追蹤多個學生進度）
///
/// 技術規劃：
/// - 錄音儲存：Supabase Storage
/// - 社群資料：Supabase Realtime
/// - 需要臨界用戶數才有意義，建議 5,000+ 用戶後開啟
class CommunityPage extends StatelessWidget {
  const CommunityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('社群')),
      body: const Center(
        child: Text('社群功能 coming soon'),
      ),
    );
  }
}
