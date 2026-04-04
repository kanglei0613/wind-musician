library;

import 'package:flutter/material.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _items = [
    BottomNavigationBarItem(icon: Icon(Icons.tune), label: ''),
    BottomNavigationBarItem(icon: Icon(Icons.mic), label: ''),
    BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), label: ''),
    BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined), label: ''),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: cs.surfaceContainerHighest,
            width: 1,
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        iconSize: 20,
        selectedFontSize: 0,
        unselectedFontSize: 0,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: _items,
      ),
    );
  }
}
