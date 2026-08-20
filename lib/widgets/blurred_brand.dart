import 'dart:ui';
import 'package:flutter/material.dart';

/// Wraps brand text/marks that are pending internal approval — visually
/// blurred so the shape/rhythm of the name reads without being legible.
/// Swap [BlurredBrand] out for the plain widget once the name is signed off.
class BlurredBrand extends StatelessWidget {
  final Widget child;
  final double sigma;

  const BlurredBrand({super.key, required this.child, this.sigma = 6});

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
      child: child,
    );
  }
}
