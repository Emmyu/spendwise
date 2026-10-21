import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:spendwise/app.dart';
import 'package:spendwise/models/design_state.dart';
import 'package:spendwise/state/app_state.dart';

bool _fontsLoaded = false;

/// Loads the real Archivo font so text measures like it does on device
/// (the test default font draws every glyph as a full-width box).
Future<void> loadAppFonts() async {
  if (_fontsLoaded) return;
  final archivo = FontLoader('Archivo')..addFont(rootBundle.load('assets/fonts/Archivo-Variable.ttf'));
  final lucide = FontLoader('packages/lucide_icons_flutter/Lucide')
    ..addFont(rootBundle.load('packages/lucide_icons_flutter/assets/lucide.ttf'));
  await Future.wait([archivo.load(), lucide.load()]);
  _fontsLoaded = true;
}

Future<AppState> pumpApp(
  WidgetTester tester, {
  DesignState initial = DesignState.home,
  Size size = const Size(390, 844),
  bool showSplash = false,
}) async {
  await tester.runAsync(loadAppFonts);
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final state = AppState(initial: initial);
  await tester.pumpWidget(
    ChangeNotifierProvider.value(value: state, child: SpendWiseApp(showSplash: showSplash)),
  );
  await tester.pump(const Duration(milliseconds: 300));
  return state;
}

/// Advances fake time without waiting for repeating animations to finish.
/// Pumps once first so animations that start this frame get a start time.
Future<void> settle(WidgetTester tester, [int ms = 300]) async {
  await tester.pump();
  await tester.pump(Duration(milliseconds: ms));
}

/// Scrolls the first scrollable until [finder] is built and visible.
Future<void> scrollTo(WidgetTester tester, Finder finder) async {
  final vertical = find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down);
  await tester.scrollUntilVisible(finder, 200, scrollable: vertical.first);
  await settle(tester);
}
