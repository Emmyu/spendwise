import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:spendwise/data/mock_data.dart';
import 'package:spendwise/data/transaction_repository.dart';
import 'package:spendwise/models/category.dart';
import 'package:spendwise/models/chat.dart';
import 'package:spendwise/models/design_state.dart';
import 'package:spendwise/models/transaction.dart';
import 'package:spendwise/services/ai_assistant.dart';
import 'package:spendwise/state/app_state.dart';
import 'package:spendwise/utils/spending.dart';

/// A repository whose writes can be switched to "no connection".
class FlakyRepository extends InMemoryTransactionRepository {
  FlakyRepository() : super(latency: const Duration(milliseconds: 50));

  bool offline = false;
  int writes = 0;

  @override
  Future<void> add(Transaction tx) async {
    if (offline) throw TimeoutException('no connection');
    writes++;
    return super.add(tx);
  }

  @override
  Future<void> update(String id, TransactionEdit edit) async {
    if (offline) throw TimeoutException('no connection');
    return super.update(id, edit);
  }

  @override
  Future<void> delete(String id) async {
    if (offline) throw TimeoutException('no connection');
    return super.delete(id);
  }
}

/// A repository whose reads fail, like Firestore with the wrong rules.
class BrokenReadRepository implements TransactionRepository {
  final _controller = StreamController<List<Transaction>>.broadcast(sync: true);
  int subscriptions = 0;

  @override
  List<Transaction> get initial => const [];

  @override
  bool get loadsAsync => true;

  @override
  Stream<List<Transaction>> watch() {
    subscriptions++;
    return _controller.stream;
  }

  void fail() => _controller.addError(StateError('permission-denied'));
  void deliver(List<Transaction> list) => _controller.add(list);

  @override
  Future<void> add(Transaction tx) async {}

  @override
  Future<void> update(String id, TransactionEdit edit) async {}

  @override
  Future<void> delete(String id) async {}
}

/// An assistant whose answer we release by hand.
class SlowAssistant implements AiAssistant {
  final answer = Completer<ChatMessage>();
  int resets = 0;

  @override
  String? get label => 'test-model';

  @override
  void reset() => resets++;

  @override
  Future<ChatMessage> respond(AssistantRequest request) => answer.future;

  @override
  ChatMessage savedMessage(Transaction tx, List<Transaction> transactions, String id) =>
      savedConfirmation(tx, transactions, id, kToday);
}

/// Proposes an expense for any message.
class ProposingAssistant extends SlowAssistant {
  @override
  Future<ChatMessage> respond(AssistantRequest request) async => ChatMessage(
        id: request.nextId(),
        role: ChatRole.ai,
        text: 'Here’s what I understood.',
        proposal: ProposalCardData(status: ProposalStatus.proposed, tx: lunchTransaction),
      );
}

void main() {
  group('InMemoryTransactionRepository', () {
    test('add, update and delete notify watchers', () async {
      final repo = InMemoryTransactionRepository(seed: [], latency: Duration.zero);
      final seen = <int>[];
      repo.watch().listen((list) => seen.add(list.length));

      await repo.add(lunchTransaction);
      await repo.update(
        lunchTransaction.id,
        TransactionEdit(
          desc: 'Late lunch',
          category: ExpenseCategory.food,
          amount: 5000,
          date: kToday,
          note: '',
        ),
      );
      expect(repo.initial.single.desc, 'Late lunch');
      await repo.delete(lunchTransaction.id);
      expect(repo.initial, isEmpty);
      expect(seen, [1, 1, 0]);
    });

    test('adding the same id twice replaces it', () async {
      final repo = InMemoryTransactionRepository(seed: [], latency: Duration.zero);
      await repo.add(lunchTransaction);
      await repo.add(lunchTransaction.copyWith(amount: 9));
      expect(repo.initial.single.amount, 9);
    });
  });

  group('demoTransactionsFor (the first-run seed)', () {
    test('keeps this month at ₦128,000 and last month in the previous month', () {
      for (final today in [DateTime(2026, 10, 31), DateTime(2026, 10, 19), DateTime(2027, 1, 20), DateTime(2026, 3, 15)]) {
        final rows = demoTransactionsFor(today);
        final month = rows.where((t) => t.date.year == today.year && t.date.month == today.month);
        expect(sumOf(month), 128000, reason: '$today');
        expect(rows.any((t) => t.date.isAfter(today)), isFalse, reason: 'nothing in the future: $today');
        expect(previousPeriodTotal(rows, today), greaterThan(0), reason: '$today');
      }
    });

    test('nothing lands before the 1st when today is early in the month', () {
      final rows = demoTransactionsFor(DateTime(2026, 10, 5));
      expect(rows.every((t) => !t.date.isBefore(DateTime(2026, 9, 1))), isTrue);
      expect(rows.where((t) => t.date.month == 10).every((t) => t.date.day >= 1), isTrue);
    });
  });

  group('when things go wrong', () {
    testWidgets('a failed save keeps the form open, with the data, and says so', (tester) async {
      final repo = FlakyRepository();
      final s = AppState(repository: repo);
      s.openNewExpense();
      s.updateForm(amount: '8,000', desc: 'Fuel');
      repo.offline = true;
      s.saveForm();
      expect(s.form!.saving, isTrue);
      await tester.pump(const Duration(milliseconds: 100));
      expect(s.overlay, OverlayKind.form);
      expect(s.form!.saving, isFalse);
      expect(s.form!.amount, '8,000');
      expect(s.toast, startsWith('Couldn’t save'));
      expect(s.monthTotal, 123500); // the sample data, without the extra lunch the gallery adds

      repo.offline = false; // the Wi-Fi comes back; same form, try again
      s.saveForm();
      await tester.pump(const Duration(milliseconds: 100));
      expect(s.overlay, OverlayKind.none);
      expect(s.monthTotal, 131500); // + the ₦8,000 that finally saved
      await tester.pump(const Duration(seconds: 3));
      s.dispose();
    });

    testWidgets('a failed delete leaves the transaction there', (tester) async {
      final repo = FlakyRepository();
      final s = AppState(repository: repo);
      s.openDetail('b3');
      s.askDelete();
      repo.offline = true;
      s.deleteSelected();
      await tester.pump(const Duration(milliseconds: 100));
      expect(s.deleting, isFalse);
      expect(s.transactions.any((t) => t.id == 'b3'), isTrue);
      expect(s.toast, startsWith('Couldn’t delete'));
      await tester.pump(const Duration(seconds: 3));
      s.dispose();
    });

    testWidgets('Confirm on a dropped connection shows "Not saved", then Try again works', (tester) async {
      final repo = FlakyRepository();
      final s = AppState(repository: repo, assistant: ProposingAssistant(), initial: DesignState.aiInitial);
      s.send('lunch');
      await tester.pump();
      final id = s.messages.last.id;

      repo.offline = true;
      s.confirmProposal(id);
      await tester.pump(const Duration(milliseconds: 100));
      expect(s.messages.last.proposal!.status, ProposalStatus.failed);
      expect(s.transactions.any((t) => t.id == 'ai-lunch'), isFalse);

      repo.offline = false;
      s.confirmProposal(id);
      await tester.pump(const Duration(milliseconds: 100));
      expect(s.messages.firstWhere((m) => m.id == id).proposal!.status, ProposalStatus.saved);
      expect(s.transactions.any((t) => t.id == 'ai-lunch'), isTrue);
      s.dispose();
    });

    testWidgets('an AI proposal writes NOTHING until Confirm is tapped', (tester) async {
      final repo = FlakyRepository();
      final s = AppState(repository: repo, assistant: ProposingAssistant(), initial: DesignState.aiInitial);
      final before = s.monthTotal;
      s.send('I spent 4,500 on lunch');
      await tester.pump();
      expect(s.messages.last.proposal!.status, ProposalStatus.proposed);
      expect(repo.writes, 0);
      expect(s.monthTotal, before);

      s.confirmProposal(s.messages.last.id);
      await tester.pump(const Duration(milliseconds: 100));
      expect(repo.writes, 1);
      expect(s.monthTotal, before + 4500);
      s.dispose();
    });

    testWidgets('an assistant error becomes a friendly message, not a crash', (tester) async {
      final assistant = SlowAssistant();
      final s = AppState(assistant: assistant, initial: DesignState.aiInitial);
      s.send('hello');
      assistant.answer.completeError(Exception('App Check token rejected'));
      await tester.pump();
      expect(s.busy, isNull);
      expect(s.messages.last.text, contains('couldn’t reach the assistant'));
      s.dispose();
    });

    testWidgets('an answer that arrives after "new chat" is thrown away', (tester) async {
      final assistant = SlowAssistant();
      final s = AppState(assistant: assistant, initial: DesignState.aiInitial);
      s.send('hello');
      s.resetChat();
      expect(assistant.resets, greaterThan(0));
      assistant.answer.complete(const ChatMessage(id: 'late', role: ChatRole.ai, text: 'Too late'));
      await tester.pump();
      expect(s.messages, isEmpty);
      s.dispose();
    });

    testWidgets('a failed load shows the error state; Try again re-subscribes', (tester) async {
      final repo = BrokenReadRepository();
      final s = AppState(repository: repo, initial: DesignState.transactions);
      expect(s.txLoad, TxLoadState.loading); // waiting for the first snapshot

      repo.fail();
      expect(s.txLoad, TxLoadState.error);

      s.retryLoad();
      expect(s.txLoad, TxLoadState.loading);
      expect(repo.subscriptions, 2);

      repo.deliver([lunchTransaction]);
      expect(s.txLoad, TxLoadState.ready);
      expect(s.transactions.single.id, 'ai-lunch');
      s.dispose();
    });

    test('the assistant label (model name) is exposed for the UI', () {
      expect(AppState(assistant: SlowAssistant()).assistantLabel, 'test-model');
      expect(AppState().assistantLabel, isNull);
    });
  });
}
