import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendwise/models/design_state.dart';
import 'package:spendwise/state/app_state.dart';

import 'helpers.dart';

void main() {
  testWidgets('home shows the month total and recent transactions', (tester) async {
    await pumpApp(tester);
    expect(find.text('₦128,000'), findsOneWidget);
    expect(find.text('8% less'), findsOneWidget);
    expect(find.text('Last 7 days'), findsOneWidget);
    await scrollTo(tester, find.text('Recent transactions'));
    expect(find.text('See all'), findsOneWidget);
  });

  testWidgets('hide amounts masks money', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.bySemanticsLabel('Hide amounts'));
    await settle(tester);
    expect(find.text('₦128,000'), findsNothing);
    expect(find.text('₦ ••••'), findsWidgets);
  });

  testWidgets('nav switches tabs', (tester) async {
    final state = await pumpApp(tester);
    await tester.tap(find.bySemanticsLabel('Transactions'));
    await settle(tester);
    expect(state.tab, AppTab.transactions);
    expect(find.text('Search expenses'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Ask AI'));
    await settle(tester);
    expect(state.tab, AppTab.ai);
    expect(find.text('Describe an expense or ask a question'), findsOneWidget);
  });

  testWidgets('open a transaction, delete it, see the toast', (tester) async {
    final state = await pumpApp(tester, initial: DesignState.transactions);
    await scrollTo(tester, find.text('Internet subscription'));
    await tester.tap(find.text('Internet subscription'));
    await settle(tester);
    expect(find.text('Sun, 11 Oct 2026'), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await settle(tester);
    expect(find.text('Delete this transaction?'), findsOneWidget);

    await tester.tap(find.text('Delete transaction'));
    await settle(tester, 900);
    await settle(tester);
    expect(state.transactions.any((t) => t.id == 'b3'), isFalse);
    expect(find.text('Transaction deleted'), findsOneWidget);
    expect(find.text('Internet subscription'), findsNothing);
    await settle(tester, 2600);
  });

  testWidgets('add expense validates, then saves', (tester) async {
    final state = await pumpApp(tester);
    await tester.tap(find.text('Add expense'));
    await settle(tester);
    await tester.tap(find.text('Save expense'));
    await settle(tester);
    expect(find.text('Enter an amount'), findsOneWidget);
    expect(find.text('Add a short description'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), '8,000');
    await tester.enterText(find.byType(TextField).at(1), 'Fuel');
    await tester.tap(find.text('Transport').last);
    await tester.tap(find.text('Save expense'));
    await settle(tester, 1000);
    await settle(tester);
    expect(state.monthTotal, 136000);
    expect(find.text('₦136,000'), findsOneWidget);
    await settle(tester, 2600);
  });

  testWidgets('Ask AI: prompt, confirm, view in transactions', (tester) async {
    final state = await pumpApp(tester, initial: DesignState.aiInitial);
    expect(find.text('Try asking'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'I spent ₦4,500 on lunch today.');
    await tester.tap(find.bySemanticsLabel('Send'));
    await settle(tester, 100);
    expect(find.text('Understanding your request'), findsOneWidget);
    await settle(tester, 1600);
    await settle(tester);
    expect(find.text('Proposed · not saved yet'), findsOneWidget);

    await tester.tap(find.text('Confirm expense'));
    await settle(tester, 200);
    expect(find.text('Saving to your account…'), findsOneWidget);
    await settle(tester, 1200);
    await settle(tester);
    expect(find.text('Saved to your transactions'), findsOneWidget);
    expect(state.monthTotal, 128000);

    await tester.tap(find.text('View in Transactions'));
    await settle(tester);
    expect(state.tab, AppTab.transactions);
    expect(state.overlay, OverlayKind.detail);
  });

  for (final size in const [Size(390, 844), Size(320, 640)]) {
    testWidgets('every design state renders at ${size.width.toInt()}×${size.height.toInt()}', (tester) async {
      final state = await pumpApp(tester, size: size);
      for (final d in DesignState.values) {
        state.applyDesignState(d);
        await settle(tester);
        expect(tester.takeException(), isNull, reason: d.name);
      }
    });
  }
}
