library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'features/auth/login_page.dart';
import 'features/calendar/calendar_page.dart';
import 'features/calendar/ensemble_page.dart';
import 'features/community/community_page.dart';
import 'shared/widgets/app_bottom_nav.dart';
import 'shared/widgets/app_drawer.dart';
import 'features/tuner/tuner_page.dart';
import 'features/recorder/recorder_page.dart';

final appRouter = GoRouter(
  initialLocation: '/tuner',
  routes: [
    GoRoute(
      path: '/login',
      builder: (c, s) => const LoginPage(),
    ),
    ShellRoute(
      builder: (context, state, child) {
        return ScaffoldWithBottomNav(child: child);
      },
      routes: [
        GoRoute(path: '/tuner', builder: (c, s) => const TunerPage()),
        GoRoute(path: '/recorder', builder: (c, s) => const RecorderPage()),
        GoRoute(path: '/calendar', builder: (c, s) => const CalendarPage()),
        GoRoute(path: '/community', builder: (c, s) => const CommunityPage()),
      ],
    ),
    // 樂團詳情頁 — 獨立於 shell 外，有自己的 AppBar
    GoRoute(
      path: '/ensemble/:id',
      builder: (c, s) => EnsemblePage(ensembleId: s.pathParameters['id']!),
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
    if (location.startsWith('/calendar')) return 2;
    if (location.startsWith('/community')) return 3;
    return 0; // tuner
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/tuner');
      case 1:
        context.go('/recorder');
      case 2:
        context.go('/calendar');
      case 3:
        context.go('/community');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      body: child,
      bottomNavigationBar: AppBottomNav(
        currentIndex: _locationToIndex(context),
        onTap: (index) => _onTap(context, index),
      ),
    );
  }
}
