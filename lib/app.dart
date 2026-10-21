import 'package:flutter/material.dart';

import 'theme/colors.dart';
import 'theme/theme.dart';
import 'ui/root_shell.dart';
import 'ui/splash/splash_overlay.dart';

class SpendWiseApp extends StatelessWidget {
  const SpendWiseApp({super.key, this.showSplash = true});

  /// Plays the animated launch splash. Tests turn this off.
  final bool showSplash;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SpendWise AI',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      builder: (context, child) => _PreviewFrame(child: child!),
      home: showSplash ? const _LaunchGate() : const RootShell(),
    );
  }
}

/// Shows the splash over the app, which builds underneath so the reveal is
/// instant. The splash blocks touches and hides the app from screen readers
/// until it finishes.
class _LaunchGate extends StatefulWidget {
  const _LaunchGate();

  @override
  State<_LaunchGate> createState() => _LaunchGateState();
}

class _LaunchGateState extends State<_LaunchGate> {
  bool _splashDone = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ExcludeSemantics(excluding: !_splashDone, child: const RootShell()),
        if (!_splashDone)
          Positioned.fill(
            child: SplashOverlay(onFinished: () => setState(() => _splashDone = true)),
          ),
      ],
    );
  }
}

/// On phones the app fills the screen. On wide screens (web or desktop
/// previews) it sits in a phone-sized column on the prototype's backdrop.
class _PreviewFrame extends StatelessWidget {
  const _PreviewFrame({required this.child});

  final Widget child;

  static const _phone = Size(390, 844);

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final size = media.size;
    if (size.width <= 600) return child;

    final roomy = size.height >= _phone.height + 64;
    final frame = Size(_phone.width, roomy ? _phone.height : size.height);
    return ColoredBox(
      color: AppColors.backdrop,
      child: Center(
        child: Container(
          width: frame.width,
          height: frame.height,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.bgBase,
            borderRadius: BorderRadius.circular(roomy ? 44 : 0),
            boxShadow: const [
              BoxShadow(color: Color(0x80133529), blurRadius: 90, spreadRadius: -30, offset: Offset(0, 50)),
            ],
          ),
          child: MediaQuery(
            data: media.copyWith(
              size: frame,
              padding: EdgeInsets.only(top: roomy ? 24 : 12, bottom: roomy ? 20 : 0),
              viewPadding: EdgeInsets.only(top: roomy ? 24 : 12, bottom: roomy ? 20 : 0),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
