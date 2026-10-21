import 'package:flutter_test/flutter_test.dart';
import 'package:spendwise/data/mock_data.dart';
import 'package:spendwise/models/category.dart';
import 'package:spendwise/models/chat.dart';
import 'package:spendwise/services/mock_ai.dart';

void main() {
  final ai = MockAiAssistant();
  final withLunch = [...baseTransactions, lunchTransaction];

  test('records an expense as a proposal that is not saved yet', () {
    final plan = ai.interpret('I spent ₦4,500 on lunch today.');
    expect(plan.tool, 'add_expense · draft');
    final reply = plan.build(baseTransactions, 'a1');
    final p = reply.proposal!;
    expect(p.status, ProposalStatus.proposed);
    expect(p.tx.amount, 4500);
    expect(p.tx.desc, 'Lunch');
    expect(p.tx.category, ExpenseCategory.food);
    expect(p.tx.date, kToday);
    expect(reply.text, contains('Nothing is saved until you confirm'));
  });

  test('understands "k" amounts and yesterday', () {
    final p = ai.interpret('I paid 2.5k for a bolt yesterday').build(baseTransactions, 'a1').proposal!;
    expect(p.tx.amount, 2500);
    expect(p.tx.category, ExpenseCategory.transport);
    expect(p.tx.date, DateTime(2026, 10, 12));
  });

  test('asks for a missing amount, then completes from the follow-up', () {
    final ask = ai.interpret('I spent money on transport');
    final question = ask.build(baseTransactions, 'a1');
    expect(question.text, startsWith('How much did you spend on transport?'));
    expect(question.chips, isNotEmpty);
    expect(ask.pending?.category, ExpenseCategory.transport);

    final follow = ai.interpret('₦2,500 for a Bolt ride', pending: ask.pending);
    final p = follow.build(baseTransactions, 'a2').proposal!;
    expect(p.tx.amount, 2500);
    expect(p.tx.desc, 'Bolt ride');
  });

  test('asks what an amount was for', () {
    final plan = ai.interpret('I spent 3000');
    expect(plan.build(baseTransactions, 'a1').text, 'What was the ₦3,000 for? For example “lunch” or “Bolt ride”.');
    expect(plan.pending?.amount, 3000);
  });

  test('rejects impossible amounts', () {
    final reply = ai.interpret('I spent 0 on lunch').build(baseTransactions, 'a1');
    expect(reply.text, startsWith('That amount doesn’t look right'));
    expect(reply.proposal, isNull);
  });

  test('food this week sums only food since Monday', () {
    final plan = ai.interpret('How much have I spent on food this week?');
    expect(plan.tool, 'get_spending_summary');
    final reply = plan.build(withLunch, 'a1');
    expect(reply.summary!.total, 17000); // Groceries 12,500 + Lunch 4,500
    expect(reply.summary!.count, 2);
    expect(reply.summary!.range, 'Mon 12 – Tue 13 Oct');
    expect(reply.text, 'You’ve spent ₦17,000 on food this week, across 2 transactions.');
  });

  test('biggest category is food', () {
    final reply = ai.interpret('What is my biggest expense category?').build(withLunch, 'a1');
    expect(reply.text, startsWith('Food is your biggest category this month at ₦37,500'));
    expect(reply.summary!.rows.first.label, 'Food');
  });

  test('compare uses the previous period total', () {
    final plan = ai.interpret('Compare my spending this month with last month.');
    expect(plan.tool, 'compare_spending');
    final reply = plan.build(withLunch, 'a1');
    expect(reply.summary!.total, 128000);
    expect(reply.summary!.sub, '8% less than ₦139,200');
    expect(reply.summary!.subDown, isTrue);
  });

  test('falls back with suggestions', () {
    final reply = ai.interpret('hello there').build(baseTransactions, 'a1');
    expect(reply.chips, hasLength(2));
  });

  test('saved message reports the month total', () {
    final msg = ai.savedMessage(lunchTransaction, withLunch, 'a1');
    expect(msg.text, 'Saved. Lunch for ₦4,500 is now in your transactions under Food. '
        'You’ve spent ₦128,000 in October so far.');
  });
}
