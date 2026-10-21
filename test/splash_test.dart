import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendwise/state/app_state.dart';
import 'package:spendwise/ui/splash/brand_mark.dart';
import 'package:spendwise/ui/splash/splash_overlay.dart';

import 'helpers.dart';

void main() {
  testWidgets('splash plays over Home, blocks taps, then reveals the app', (tester) async {
    final state = await pumpApp(tester, showSplash: true);
    expect(find.byType(SplashOverlay), findsOneWidget);
    expect(find.byType(BrandMark), findsOneWidget);
    expect(find.text('SpendWise AI'), findsOneWidget);

    // Home is already built underneath, but the splash takes the taps.
    expect(find.text('₦128,000'), findsOneWidget);
    await tester.tap(find.text('Ask AI').last, warnIfMissed: false);
    await settle(tester, 100);
    expect(state.tab, AppTab.home);

    await settle(tester, SplashOverlay.duration.inMilliseconds);
    expect(find.byType(SplashOverlay), findsNothing);
    expect(find.text('Last 7 days'), findsOneWidget);
  });

  testWidgets('reduced motion shortens the splash', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await pumpApp(tester, showSplash: true);
    await settle(tester, SplashOverlay.reducedMotionDuration.inMilliseconds);
    expect(find.byType(SplashOverlay), findsNothing);
  });

  testWidgets('splash fits a small phone', (tester) async {
    await pumpApp(tester, showSplash: true, size: const Size(320, 568));
    await settle(tester, 900);
    expect(tester.takeException(), isNull);
    await settle(tester, 1200);
  });
}
