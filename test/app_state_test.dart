import 'package:flutter_test/flutter_test.dart';
import 'package:spendwise/models/category.dart';
import 'package:spendwise/models/chat.dart';
import 'package:spendwise/models/design_state.dart';
import 'package:spendwise/models/expense_form.dart';
import 'package:spendwise/state/app_state.dart';

void main() {
  test('home figures match the prototype', () {
    final s = AppState();
    expect(s.monthTotal, 128000);
    expect(s.dailyAverage.round(), 9846);
    expect(s.recentTransactions.first.desc, 'Lunch');
    final week = s.lastSevenDays;
    expect(week, hasLength(7));
    expect(week.last.isToday, isTrue);
    expect(week.last.amount, 6500); // Bolt 2,000 + Lunch 4,500
    expect(s.monthBreakdown.first.category, ExpenseCategory.food);
    s.dispose();
  });

  test('filters by range, category and search', () {
    final s = AppState();
    expect(s.filteredTransactions, hasLength(17));
    s.cycleRange(); // this week
    expect(s.filteredTransactions.map((t) => t.desc), ['Lunch', 'Bolt ride', 'Groceries']);
    s.cycleRange(); // last 30 days
    expect(s.filteredTransactions, hasLength(21));
    s.clearFilters();
    s.setCategoryFilter(ExpenseCategory.bills);
    expect(s.filteredTransactions, hasLength(4));
    s.setSearch('dstv');
    expect(s.filteredTransactions.single.desc, 'DStv subscription');
    s.setSearch('pizza');
    expect(s.transactionGroups, isEmpty);
    s.dispose();
  });

  test('groups by day and by month', () {
    final s = AppState();
    expect(s.transactionGroups.first.label, 'Today');
    expect(s.transactionGroups.first.total, 6500);
    s.setGrouping(TxGrouping.month);
    expect(s.transactionGroups.single.label, 'October 2026');
    s.dispose();
  });

  test('validation messages match the prototype', () {
    expect(AppState.validate('', 'x').amount, 'Enter an amount');
    expect(AppState.validate('0', 'x').amount, 'Amount must be greater than ₦0');
    expect(AppState.validate('20,000,000', 'x').amount, 'That amount looks too large. Check it and try again');
    expect(AppState.validate('4,500', ' ').desc, 'Add a short description');
    final ok = AppState.validate('4,500', 'Lunch');
    expect(ok.amount, isNull);
    expect(ok.desc, isNull);
  });

  testWidgets('adding an expense updates totals after saving', (tester) async {
    final s = AppState();
    s.openNewExpense();
    s.saveForm();
    expect(s.form!.amountError, 'Enter an amount');
    expect(s.form!.descError, 'Add a short description');

    s.updateForm(amount: '8,000', desc: 'Fuel', category: ExpenseCategory.transport);
    expect(s.form!.amountError, isNull);
    s.saveForm();
    expect(s.form!.saving, isTrue);
    await tester.pump(const Duration(milliseconds: 900));
    expect(s.overlay, OverlayKind.none);
    expect(s.monthTotal, 136000);
    expect(s.toast, 'Expense saved');
    await tester.pump(const Duration(milliseconds: 2400));
    expect(s.toast, isNull);
    s.dispose();
  });

  testWidgets('editing returns to the detail sheet with new values', (tester) async {
    final s = AppState();
    s.openDetail('b4');
    s.openEditExpense();
    expect(s.form!.mode, FormMode.edit);
    expect(s.form!.amount, '3,000');
    s.updateForm(amount: '3,500');
    s.saveForm();
    await tester.pump(const Duration(milliseconds: 900));
    expect(s.overlay, OverlayKind.detail);
    expect(s.detailTransaction!.amount, 3500);
    await tester.pump(const Duration(milliseconds: 2400));
    s.dispose();
  });

  testWidgets('deleting removes the transaction', (tester) async {
    final s = AppState();
    s.openDetail('b3');
    s.askDelete();
    s.deleteSelected();
    expect(s.deleting, isTrue);
    await tester.pump(const Duration(milliseconds: 800));
    expect(s.transactions.any((t) => t.id == 'b3'), isFalse);
    expect(s.overlay, OverlayKind.none);
    expect(s.toast, 'Transaction deleted');
    await tester.pump(const Duration(milliseconds: 2400));
    s.dispose();
  });

  testWidgets('chat: propose, confirm, saved', (tester) async {
    final s = AppState(initial: DesignState.aiInitial);
    expect(s.send('I spent ₦4,500 on lunch today.'), isTrue);
    expect(s.busy!.label, 'Understanding your request');
    expect(s.send('another'), isFalse, reason: 'ignored while busy');
    await tester.pump(const Duration(milliseconds: 700));
    expect(s.busy!.tool, 'add_expense · draft');
    await tester.pump(const Duration(milliseconds: 800));
    expect(s.busy, isNull);
    final proposal = s.messages.last;
    expect(proposal.proposal!.status, ProposalStatus.proposed);
    expect(s.monthTotal, 123500, reason: 'nothing saved before confirming');

    s.confirmProposal(proposal.id);
    expect(s.messages.last.proposal!.status, ProposalStatus.saving);
    await tester.pump(const Duration(milliseconds: 1100));
    expect(s.messages[1].proposal!.status, ProposalStatus.saved);
    expect(s.messages.last.text, startsWith('Saved. Lunch for ₦4,500'));
    expect(s.monthTotal, 128000);
    s.dispose();
  });

  testWidgets('chat: editing a proposal updates it without saving', (tester) async {
    final s = AppState(initial: DesignState.aiConfirm);
    s.editProposal('m2');
    expect(s.form!.mode, FormMode.ai);
    s.updateForm(amount: '5,000');
    s.saveForm();
    expect(s.overlay, OverlayKind.none);
    expect(s.messages.last.proposal!.tx.amount, 5000);
    expect(s.messages.last.proposal!.status, ProposalStatus.proposed);
    expect(s.transactions.any((t) => t.id == 'ai-lunch'), isFalse);
    s.dispose();
  });

  test('every design state seeds without errors', () {
    final s = AppState();
    for (final d in DesignState.values) {
      s.applyDesignState(d);
      expect(s.designState, d);
    }
    s.applyDesignState(DesignState.aiError);
    expect(s.messages.last.proposal!.status, ProposalStatus.failed);
    s.applyDesignState(DesignState.aiConvo);
    expect(s.busy!.frozen, isTrue);
    s.dispose();
  });

  test('back closes overlays in order', () {
    final s = AppState(initial: DesignState.deleteConfirm);
    expect(s.handleBack(), isTrue);
    expect(s.overlay, OverlayKind.detail);
    expect(s.handleBack(), isTrue);
    expect(s.overlay, OverlayKind.none);
    expect(s.handleBack(), isFalse);
    s.dispose();
  });
}
