import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/colors.dart';

/// Small ring spinner (the prototype's `swSpin` keyframes).
class Spinner extends StatefulWidget {
  const Spinner({
    super.key,
    this.size = 16,
    this.color = AppColors.white,
    this.trackColor = const Color(0x59FFFFFF),
  });

  final double size;
  final Color color;
  final Color trackColor;

  @override
  State<Spinner> createState() => _SpinnerState();
}

class _SpinnerState extends State<Spinner> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading',
      child: RotationTransition(
        turns: _c,
        child: CustomPaint(
          size: Size.square(widget.size),
          painter: _RingPainter(widget.color, widget.trackColor),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.color, this.track);

  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 2.0;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawOval(rect, paint..color = track);
    canvas.drawArc(rect, -math.pi * 3 / 4, math.pi / 2, false, paint..color = color);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.color != color || old.track != track;
}

/// Three bouncing dots (the prototype's `swDot` keyframes).
class TypingDots extends StatefulWidget {
  const TypingDots({super.key, this.color = AppColors.primary});

  final Color color;

  @override
  State<TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<TypingDots> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// 0 → 1 → 0 over 0–40–80 % of the cycle, eased.
  double _lift(double t) {
    final raw = t < 0.4 ? t / 0.4 : (t < 0.8 ? 1 - (t - 0.4) / 0.4 : 0.0);
    return Curves.easeInOut.transform(raw.clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            () {
              final p = _lift((_c.value - i * 0.125) % 1.0);
              return Transform.translate(
                offset: Offset(0, -3 * p),
                child: Opacity(
                  opacity: 0.25 + 0.75 * p,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
                  ),
                ),
              );
            }(),
          ],
        ],
      ),
    );
  }
}

/// Gentle opacity pulse for skeleton placeholders.
class SkeletonPulse extends StatefulWidget {
  const SkeletonPulse({super.key, required this.child});

  final Widget child;

  @override
  State<SkeletonPulse> createState() => _SkeletonPulseState();
}

class _SkeletonPulseState extends State<SkeletonPulse> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: Tween(begin: 0.55, end: 1.0).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
        child: widget.child,
      );
}

/// Grey rounded placeholder bar.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, this.width, required this.height, this.radius, this.color = AppColors.skeleton3});

  final double? width;
  final double height;
  final double? radius;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(radius ?? height / 2)),
      );
}
