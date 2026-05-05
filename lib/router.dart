library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'features/auth/login_page.dart';
import 'features/calendar/calendar_page.dart';
import 'features/calendar/ensemble_page.dart';
import 'features/community/community_page.dart';
import 'features/feedback/feedback_page.dart';
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
    // 問題回報頁面
    GoRoute(
      path: '/feedback',
      builder: (c, s) => const FeedbackPage(),
    ),
    // 樂團詳情頁 — 獨立於 shell 外，有自己的 AppBar
    GoRoute(
      path: '/ensemble/:id',
      builder: (c, s) => EnsemblePage(ensembleId: s.pathParameters['id']!),
    ),
  ],
);

/// 包含底部導覽列和側拉選單的 Scaffold
class ScaffoldWithBottomNav extends StatefulWidget {
  final Widget child;

  const ScaffoldWithBottomNav({super.key, required this.child});

  @override
  State<ScaffoldWithBottomNav> createState() => _ScaffoldWithBottomNavState();
}

class _ScaffoldWithBottomNavState extends State<ScaffoldWithBottomNav> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  /// 記錄上一次按下返回鍵的時間，用於實現「再按一次以退出」
  DateTime? _lastBackPress;

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
    return PopScope(
      // 攔截所有系統返回，由 onPopInvokedWithResult 決定行為
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        // 如果側拉選單開著 → 關閉選單即可
        if (_scaffoldKey.currentState?.isDrawerOpen == true) {
          _scaffoldKey.currentState?.closeDrawer();
          return;
        }

        // 主畫面：雙擊返回退出（2 秒視窗）
        final now = DateTime.now();
        final isFirstPress = _lastBackPress == null ||
            now.difference(_lastBackPress!) > const Duration(seconds: 2);

        if (isFirstPress) {
          _lastBackPress = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('再按一次以退出'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          // 第二次按返回 → 退出 App
          SystemNavigator.pop();
        }
      },
      child: Builder(
        builder: (context) {
          // On Android with gesture navigation, the left edge is reserved for
          // the system back gesture, which conflicts with the drawer open drag.
          // Detect this via systemGestureInsets.left > 0 (only true in gesture
          // nav mode). On iOS, swipe-from-left opens the drawer natively, so
          // we always keep it enabled there.
          final gestureInsets = MediaQuery.of(context).systemGestureInsets;
          final suppressDrawerDrag =
              Platform.isAndroid && gestureInsets.left > 0;

          return Scaffold(
            key: _scaffoldKey,
            drawer: const AppDrawer(),
            drawerEnableOpenDragGesture: !suppressDrawerDrag,
            endDrawerEnableOpenDragGesture: false,
            body: Stack(
              children: [
                widget.child,
                // Show a hamburger button only when the drag-to-open gesture
                // is suppressed (Android gesture navigation mode).
                if (suppressDrawerDrag)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 8,
                    left: 8,
                    child: Material(
                      color: Colors.transparent,
                      child: IconButton(
                        icon: const Icon(Icons.menu),
                        tooltip: 'Open menu',
                        onPressed: () =>
                            _scaffoldKey.currentState?.openDrawer(),
                      ),
                    ),
                  ),
              ],
            ),
            bottomNavigationBar: AppBottomNav(
              currentIndex: _locationToIndex(context),
              onTap: (index) => _onTap(context, index),
            ),
          );
        },
      ),
    );
  }
}
