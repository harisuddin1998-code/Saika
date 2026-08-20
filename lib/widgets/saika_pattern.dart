import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A delicate five-petal floral border band in rose/gold tones — used on
/// identity screens (splash, login, drawer header) in place of the old
/// ajrak block-print trim, for a softer, feminine brand feel.
class SaikaBand extends StatelessWidget {
  final double height;
  final Color rose;
  final Color gold;
  final Color cream;

  const SaikaBand({
    super.key,
    this.height = 30,
    this.rose = const Color(0xFFD6336C),
    this.gold = const Color(0xFFE8B04B),
    this.cream = const Color(0xFFFFF3F6),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _FloralBandPainter(rose: rose, gold: gold, cream: cream)),
    );
  }
}

class _FloralBandPainter extends CustomPainter {
  final Color rose;
  final Color gold;
  final Color cream;
  _FloralBandPainter({required this.rose, required this.gold, required this.cream});

  @override
  void paint(Canvas canvas, Size size) {
    final tile = size.height;
    final count = (size.width / tile).ceil() + 1;

    canvas.drawRect(Offset.zero & size, Paint()..color = cream);

    for (var i = 0; i < count; i++) {
      final c = Offset(i * tile + tile / 2, size.height / 2);
      _drawFlower(canvas, c, tile * 0.42, i.isEven ? rose : gold);
    }

    final edgePaint = Paint()
      ..color = gold.withValues(alpha: 0.6)
      ..strokeWidth = 1.4;
    canvas.drawLine(Offset(0, 1), Offset(size.width, 1), edgePaint);
    canvas.drawLine(Offset(0, size.height - 1), Offset(size.width, size.height - 1), edgePaint);
  }

  void _drawFlower(Canvas canvas, Offset c, double r, Color petalColor) {
    final petalPaint = Paint()..color = petalColor.withValues(alpha: 0.85);
    for (var i = 0; i < 5; i++) {
      final angle = 2 * math.pi * i / 5 - math.pi / 2;
      final px = c.dx + r * 0.42 * math.cos(angle);
      final py = c.dy + r * 0.42 * math.sin(angle);
      canvas.drawCircle(Offset(px, py), r * 0.34, petalPaint);
    }
    canvas.drawCircle(c, r * 0.22, Paint()..color = const Color(0xFFFFF3F6));
    canvas.drawCircle(
      c,
      r * 0.22,
      Paint()
        ..color = petalColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  @override
  bool shouldRepaint(covariant _FloralBandPainter oldDelegate) => false;
}
