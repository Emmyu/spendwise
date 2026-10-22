import 'package:flutter_test/flutter_test.dart';
import 'package:spendwise/models/chat.dart';
import 'package:spendwise/services/ai_assistant.dart';
import 'package:spendwise/services/not_connected_assistant.dart';
import 'package:spendwise/state/app_state.dart';

AssistantRequest _request(String text) => AssistantRequest(
      text: text,
      transactions: () => const [],
      today: DateTime(2026, 10, 13),
      nextId: () => 'a1',
      onWorking: (label, {tool}) {},
    );

void main() {
  test('says it is not connected, and never proposes an expense', () async {
    final reply = await NotConnectedAssistant().respond(_request('I spent ₦4,500 on lunch'));

    expect(reply.role, ChatRole.ai);
    expect(reply.text, contains('isn’t connected yet'));
    expect(reply.proposal, isNull);
    expect(reply.summary, isNull);
  });

  test('has no model label to show', () {
    expect(NotConnectedAssistant().label, isNull);
  });

  test('inside the app, a message gets that answer and nothing is recorded', () async {
    final state = AppState(assistant: NotConnectedAssistant());
    final before = state.transactions.length;

    state.send('I spent ₦4,500 on lunch');
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(state.messages.last.text, contains('isn’t connected yet'));
    expect(state.transactions.length, before);
    state.dispose();
  });
}
