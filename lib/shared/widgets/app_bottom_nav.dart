library;

import 'package:flutter/material.dart';
import '../../shared/theme/app_colors.dart';

/// 底部導覽列
/// 所有頁面共用這個元件
/// 新增頁面時，在 _items 加一個項目，並在 router.dart 加對應路由
class AppBottomNav extends StatelessWidget {
  /// 目前選中的 tab 索引
  final int currentIndex;

  /// tab 切換時的回呼
  final ValueChanged<int> onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  /// 導覽項目清單
  static const _items = [
    BottomNavigationBarItem(
      icon: Icon(Icons.tune),
      label: '調音器',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.mic),
      label: '錄音',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.analytics_outlined),
      label: '分析',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.calendar_month_outlined),
      label: '行程',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColors.surfaceLight,
            width: 1,
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        items: _items,
      ),
    );
  }
}
