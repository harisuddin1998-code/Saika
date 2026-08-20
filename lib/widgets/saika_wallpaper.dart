import 'package:flutter/material.dart';

/// Plain page background — a subtle top-to-bottom plum gradient, no
/// pattern or texture — meant to sit behind light content cards.
class SaikaWallpaper extends StatelessWidget {
  final Widget child;
  final Color base;
  const SaikaWallpaper({
    super.key,
    required this.child,
    this.base = const Color(0xFF2B1424),
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [base, Color.lerp(base, Colors.black, 0.22)!],
            ),
          ),
        ),
        child,
      ],
    );
  }
}
