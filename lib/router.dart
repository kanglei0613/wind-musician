library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'shared/widgets/app_bottom_nav.dart';
import 'features/tuner/tuner_page.dart';
import 'features/recorder/recorder_page.dart';
import 'features/analysis/analysis_page.dart';
import 'features/schedule/schedule_page.dart';

/// App 路由設定
/// 新增頁面時在這裡加路由，不需要動其他檔案
final appRouter = GoRouter(
  initialLocation: '/tuner',
  routes: [
    ShellRoute(
      // 底部導覽列 shell，所有主頁面都包在這裡
      builder: (context, state, child) {
        return ScaffoldWithBottomNav(child: child);
      },
      routes: [
        GoRoute(path: '/tuner', builder: (c, s) => const TunerPage()),
        GoRoute(path: '/recorder', builder: (c, s) => const RecorderPage()),
        GoRoute(path: '/analysis', builder: (c, s) => const AnalysisPage()),
        GoRoute(path: '/schedule', builder: (c, s) => const SchedulePage()),
      ],
    ),
  ],
);

/// 包含底部導覽列的 Scaffold
/// 所有主頁面共用這個外殼
class ScaffoldWithBottomNav extends StatelessWidget {
  final Widget child;

  const ScaffoldWithBottomNav({super.key, required this.child});

  /// 根據目前路由決定底部導覽列選中哪個 tab
  int _locationToIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/recorder')) return 1;
    if (location.startsWith('/analysis')) return 2;
    if (location.startsWith('/schedule')) return 3;
    return 0; // 預設調音器
  }

  /// 根據 tab 索引決定要導到哪個路由
  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0: context.go('/tuner'); break;
      case 1: context.go('/recorder'); break;
      case 2: context.go('/analysis'); break;
      case 3: context.go('/schedule'); break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: AppBottomNav(
        currentIndex: _locationToIndex(context),
        onTap: (index) => _onTap(context, index),
      ),
    );
  }
}