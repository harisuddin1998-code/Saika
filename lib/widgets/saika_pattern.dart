import 'package:flutter/material.dart';

/// A plain rose-to-gold gradient trim band used on identity screens
/// (splash, login, drawer header) as a simple brand accent.
class SaikaBand extends StatelessWidget {
  final double height;
  final Color rose;
  final Color gold;

  const SaikaBand({
    super.key,
    this.height = 6,
    this.rose = const Color(0xFFD6336C),
    this.gold = const Color(0xFFE8B04B),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [rose, gold]),
      ),
    );
  }
}
