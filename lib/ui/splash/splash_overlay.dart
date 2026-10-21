import 'package:flutter/material.dart';

import '../../theme/colors.dart';
import '../../theme/text.dart';
import 'brand_mark.dart';

/// Animated hand-off from the native splash into the app.
///
/// Frame 0 matches the native splash exactly (120 px mark centred on
/// #CBDDD3). The mark then lifts, the wordmark fades in, and the overlay
/// fades out to reveal Home, which is already built underneath.
class SplashOverlay extends StatefulWidget {
  const SplashOverlay({super.key, required this.onFinished});

  final VoidCallback onFinished;

  static const duration = Duration(milliseconds: 1700);
  static const reducedMotionDuration = Duration(milliseconds: 600);

  @override
  State<SplashOverlay> createState() => _SplashOverlayState();
}

class _SplashOverlayState extends State<SplashOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final reduce = MediaQuery.disableAnimationsOf(context);
    _c.duration = reduce ? SplashOverlay.reducedMotionDuration : SplashOverlay.duration;
    _c.forward().whenComplete(() {
      if (mounted) widget.onFinished();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// Progress of [t] through the [begin]–[end] slice of the timeline, eased.
  static double _phase(double t, double begin, double end, Curve curve) =>
      curve.transform(((t - begin) / (end - begin)).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: 'SpendWise AI',
      container: true,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value;
          // With reduced motion: no movement, just show the wordmark and fade.
          final lift = reduce ? 1.0 : _phase(t, 0.10, 0.45, Curves.easeOutCubic);
          final twinkle = reduce ? 0.0 : _phase(t, 0.05, 0.40, Curves.easeInOut);
          final text = reduce ? 1.0 : _phase(t, 0.30, 0.62, Curves.easeOut);
          final out = _phase(t, reduce ? 0.6 : 0.80, 1.0, Curves.easeIn);
          // Sparkle grows ~10% and settles back: 1 → 1.1 → 1.
          final sparkle = 1 + 0.1 * (1 - (2 * twinkle - 1).abs());

          return Opacity(
            opacity: 1 - out,
            // ColoredBox takes the taps; Material provides the text styles.
            child: ColoredBox(
              color: AppColors.backdrop,
              child: Material(
                type: MaterialType.transparency,
                child: SizedBox.expand(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Transform.translate(
                        offset: Offset(0, -44 * lift),
                        child: BrandMark(sparkleScale: sparkle),
                      ),
                      Transform.translate(
                        offset: Offset(0, 70 + 14 * (1 - text)),
                        child: Opacity(
                          opacity: text,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('SpendWise AI', style: AppText.style(26, weight: 600, width: 112, tracking: -0.02)),
                              const SizedBox(height: 6),
                              Text(
                                'Record and understand your spending',
                                style: AppText.style(14, color: AppColors.ink2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
