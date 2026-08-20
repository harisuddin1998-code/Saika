import 'package:flutter/material.dart';

/// Plain page background — a soft baby-pink fill, no pattern or texture —
/// meant to sit behind light content cards.
class SaikaWallpaper extends StatelessWidget {
  final Widget child;
  final Color base;
  const SaikaWallpaper({
    super.key,
    required this.child,
    this.base = const Color(0xFFFBD9E7),
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(decoration: BoxDecoration(color: base)),
        child,
      ],
    );
  }
}
