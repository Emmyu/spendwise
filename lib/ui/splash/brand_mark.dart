import 'package:flutter/material.dart';

import '../../theme/colors.dart';

/// The SpendWise mark: a green rounded square with a mint four-point sparkle.
/// Same geometry as the prototype's brand thumbnail and the native splash
/// image (`assets/splash/splash_logo.png`), so the hand-off is seamless.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 120, this.sparkleScale = 1});

  final double size;

  /// Lets the splash "twinkle" the sparkle without moving the square.
  final double sparkleScale;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _BrandMarkPainter(sparkleScale)),
    );
  }
}

class _BrandMarkPainter extends CustomPainter {
  _BrandMarkPainter(this.sparkleScale);

  final double sparkleScale;

  /// Sparkle points on a 240-unit square, relative to its centre.
  static const _star = [
    Offset(0, -70), Offset(20, -15), Offset(75, 0), Offset(20, 15),
    Offset(0, 70), Offset(-20, 15), Offset(-75, 0), Offset(-20, -15),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / 240;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(60 * unit)),
      Paint()..color = AppColors.primary,
    );
    final centre = size.center(Offset.zero);
    final k = unit * sparkleScale;
    final path = Path()..addPolygon([for (final p in _star) centre + p * k], true);
    canvas.drawPath(path, Paint()..color = AppColors.mint);
  }

  @override
  bool shouldRepaint(_BrandMarkPainter old) => old.sparkleScale != sparkleScale;
}
