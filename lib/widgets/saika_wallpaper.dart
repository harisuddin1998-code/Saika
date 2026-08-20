import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Soft blush page background painted with a repeating scatter of small
/// five-petal flowers and dots in rose/gold — a gentle, feminine texture
/// meant to sit behind light content cards, replacing the old ajrak
/// medallion wallpaper.
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
        Container(color: base),
        const Positioned.fill(
          child: CustomPaint(painter: _SaikaWallpaperPainter()),
        ),
        child,
      ],
    );
  }
}

class _SaikaWallpaperPainter extends CustomPainter {
  const _SaikaWallpaperPainter();

  static const _rose = Color(0xFFE85D97);
  static const _gold = Color(0xFFE8B04B);
  static const _cream = Color(0xFFFCEEF3);

  @override
  void paint(Canvas canvas, Size size) {
    const tile = 70.0;
    final rows = (size.height / tile).ceil() + 2;
    final cols = (size.width / tile).ceil() + 2;

    for (var row = -1; row < rows; row++) {
      final offsetX = row.isOdd ? tile / 2 : 0.0;
      for (var col = -1; col < cols; col++) {
        final cx = col * tile + offsetX;
        final cy = row * tile;
        if ((row + col).isEven) {
          _drawFlower(canvas, Offset(cx, cy), tile * 0.28);
        } else {
          _drawDotRing(canvas, Offset(cx, cy), tile * 0.22);
        }
      }
    }
  }

  void _drawFlower(Canvas canvas, Offset c, double r) {
    final petalPaint = Paint()..color = _rose.withValues(alpha: 0.55);
    for (var i = 0; i < 5; i++) {
      final angle = 2 * math.pi * i / 5 - math.pi / 2;
      final px = c.dx + r * 0.42 * math.cos(angle);
      final py = c.dy + r * 0.42 * math.sin(angle);
      canvas.drawCircle(Offset(px, py), r * 0.32, petalPaint);
    }
    canvas.drawCircle(c, r * 0.20, Paint()..color = _gold.withValues(alpha: 0.75));
  }

  void _drawDotRing(Canvas canvas, Offset c, double r) {
    final dotPaint = Paint()..color = _cream.withValues(alpha: 0.35);
    const dotCount = 8;
    for (var i = 0; i < dotCount; i++) {
      final angle = 2 * math.pi * i / dotCount;
      final x = c.dx + r * math.cos(angle);
      final y = c.dy + r * math.sin(angle);
      canvas.drawCircle(Offset(x, y), r * 0.09, dotPaint);
    }
    canvas.drawCircle(c, r * 0.10, Paint()..color = _rose.withValues(alpha: 0.4));
  }

  @override
  bool shouldRepaint(covariant _SaikaWallpaperPainter oldDelegate) => false;
}
