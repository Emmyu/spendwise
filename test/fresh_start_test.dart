import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:spendwise/app.dart';
import 'package:spendwise/data/transaction_repository.dart';
import 'package:spendwise/services/not_connected_assistant.dart';
import 'package:spendwise/state/app_state.dart';

import 'helpers.dart';

/// A brand-new app has no data: ₦0, no expenses, no made-up person, and the
/// chat says the assistant isn't connected. (The sample data is only for tests
/// and `--dart-define=SPENDWISE_OFFLINE_DEMO=true`.)
void main() {
  Future<AppState> pumpFresh(WidgetTester tester) async {
    await tester.runAsync(loadAppFonts);
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final state = AppState(
      assistant: NotConnectedAssistant(),
      repository: InMemoryTransactionRepository(seed: const [], latency: Duration.zero),
      today: DateTime(2026, 10, 21),
    );
    addTearDown(state.dispose);
    await tester.pumpWidget(ChangeNotifierProvider.value(value: state, child: const SpendWiseApp(showSplash: false)));
    await tester.pump(const Duration(milliseconds: 400));
    return state;
  }

  testWidgets('Home shows zero and no expenses, and no made-up name', (tester) async {
    final state = await pumpFresh(tester);

    expect(state.transactions, isEmpty);
    expect(state.monthTotal, 0);
    expect(find.text('₦0'), findsWidgets);
    expect(find.text('No expenses yet.'), findsOneWidget);
    expect(find.text('Adaeze'), findsNothing);
    expect(find.text('₦128,000'), findsNothing);
  });

  testWidgets('the chat says the assistant is not connected and records nothing', (tester) async {
    final state = await pumpFresh(tester);

    state.goTo(AppTab.ai);
    await settle(tester);
    state.send('I spent ₦4,500 on lunch');
    await tester.pump(const Duration(seconds: 2));

    expect(find.textContaining('isn’t connected yet'), findsOneWidget);
    expect(state.transactions, isEmpty);
  });
}
