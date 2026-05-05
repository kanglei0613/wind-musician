library;

import 'package:flutter/material.dart';

/// Ensures a widget has a minimum tap target size (default 48×48 dp),
/// satisfying accessibility guidelines without changing the visual size.
class MinTouchTarget extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final double minSize;

  const MinTouchTarget({
    super.key,
    required this.child,
    required this.onTap,
    this.minSize = 48,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: minSize, minHeight: minSize),
        child: Center(child: child),
      ),
    );
  }
}
