library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'shared/widgets/app_bottom_nav.dart';
import 'shared/widgets/app_drawer.dart';
import 'features/tuner/tuner_page.dart';
import 'features/recorder/recorder_page.dart';
import 'features/analysis/analysis_page.dart';
import 'features/schedule/schedule_page.dart';

final appRouter = GoRouter(
  initialLocation: '/tuner',
  routes: [
    ShellRoute(
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

/// 包含底部導覽列和側拉選單的 Scaffold
class ScaffoldWithBottomNav extends StatelessWidget {
  final Widget child;

  const ScaffoldWithBottomNav({super.key, required this.child});

  int _locationToIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/recorder')) return 1;
    if (location.startsWith('/analysis')) return 2;
    if (location.startsWith('/schedule')) return 3;
    return 0;
  }

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
      // 側拉選單（從左側滑出）
      drawer: const AppDrawer(),
      body: child,
      bottomNavigationBar: AppBottomNav(
        currentIndex: _locationToIndex(context),
        onTap: (index) => _onTap(context, index),
      ),
    );
  }
}
