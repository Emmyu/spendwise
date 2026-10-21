import 'package:flutter/foundation.dart';

import '../data/mock_data.dart';
import '../models/category.dart';
import '../models/chat.dart';
import '../models/transaction.dart';
import '../utils/dates.dart';
import '../utils/format.dart';
import '../utils/spending.dart';
import 'ai_assistant.dart';

/// Details remembered between turns while the assistant asks a follow-up
/// question, e.g. the description when the amount is still missing.
@immutable
class PendingExpense {
  const PendingExpense({this.desc, this.category, this.amount});

  final String? desc;
  final ExpenseCategory? category;
  final double? amount;
}

/// Builds the assistant's reply from the transactions at the time it resolves.
typedef AiReplyBuilder = ChatMessage Function(List<Transaction> transactions, String id);

/// What the mock will do with a message: an optional busy label and tool
/// name to show while it "works", then the reply.
@immutable
class AiPlan {
  const AiPlan({required this.build, this.busyLabel, this.tool, this.pending});

  final AiReplyBuilder build;
  final String? busyLabel;
  final String? tool;
  final PendingExpense? pending;
}

enum SpendingQuestion { week, biggest, categoryMonth, compare }

/// Offline stand-in for the assistant, ported from the HTML prototype's
/// keyword interpreter. Totals are always computed from recorded transactions.
class MockAiAssistant implements AiAssistant {
  MockAiAssistant({DateTime? today, this.thinkTime = const Duration(milliseconds: 900)}) : today = today ?? kToday;

  final DateTime today;

  /// How long the "thinking" row shows before a reply (a stand-in for a
  /// network round trip).
  final Duration thinkTime;

  PendingExpense? _pending;

  @override
  String? get label => null;

  @override
  void reset() => _pending = null;

  @override
  Future<ChatMessage> respond(AssistantRequest request) async {
    final plan = interpret(request.text, pending: _pending);
    _pending = plan.pending;
    if (plan.tool == null) {
      await Future<void>.delayed(thinkTime);
    } else {
      await Future<void>.delayed(thinkTime * 7 ~/ 9); // 700 ms
      request.onWorking(plan.busyLabel ?? 'Working on it', tool: plan.tool);
      await Future<void>.delayed(thinkTime * 8 ~/ 9); // 800 ms
    }
    return plan.build(request.transactions(), request.nextId());
  }

  static const maxAmount = 10000000;

  static const _keywords = <(String, String, ExpenseCategory)>[
    ('lunch', 'Lunch', ExpenseCategory.food),
    ('breakfast', 'Breakfast', ExpenseCategory.food),
    ('dinner', 'Dinner', ExpenseCategory.food),
    ('suya', 'Suya', ExpenseCategory.food),
    ('grocer', 'Groceries', ExpenseCategory.food),
    ('bolt', 'Bolt ride', ExpenseCategory.transport),
    ('uber', 'Uber ride', ExpenseCategory.transport),
    ('taxi', 'Taxi', ExpenseCategory.transport),
    ('bus', 'Bus fare', ExpenseCategory.transport),
    ('fuel', 'Fuel', ExpenseCategory.transport),
    ('transport', 'Transport', ExpenseCategory.transport),
    ('shoe', 'Shoes', ExpenseCategory.shopping),
    ('sneaker', 'Sneakers', ExpenseCategory.shopping),
    ('cloth', 'Clothes', ExpenseCategory.shopping),
    ('shopping', 'Shopping', ExpenseCategory.shopping),
    ('electric', 'Electricity token', ExpenseCategory.bills),
    ('internet', 'Internet subscription', ExpenseCategory.bills),
    ('airtime', 'Airtime & data', ExpenseCategory.bills),
    ('data', 'Airtime & data', ExpenseCategory.bills),
    ('dstv', 'DStv subscription', ExpenseCategory.bills),
    ('rent', 'Rent', ExpenseCategory.bills),
    ('cinema', 'Cinema', ExpenseCategory.other),
    ('movie', 'Cinema', ExpenseCategory.other),
    ('haircut', 'Haircut', ExpenseCategory.other),
    ('food', 'Food', ExpenseCategory.food),
  ];

  static final _amountPattern = RegExp(r'(-?\d+(?:\.\d+)?)\s*(k\b)?');
  static final _questionPattern = RegExp(r'how much|what|which|compare|show|biggest|summar|\?');
  static final _recordPattern = RegExp(r'spent|spend|paid|pay|record|add|bought|buy|log');

  /// Best-guess description and category for an expense mentioned in [lower].
  static ({String desc, ExpenseCategory category})? guess(String lower) {
    for (final (key, desc, category) in _keywords) {
      if (lower.contains(key)) return (desc: desc, category: category);
    }
    return null;
  }

  AiPlan interpret(String text, {PendingExpense? pending}) {
    final t = text.toLowerCase();
    final pend = pending ?? const PendingExpense();

    final match = _amountPattern.firstMatch(t.replaceAll(',', ''));
    double? amount = match == null
        ? null
        : double.parse(match.group(1)!) * (match.group(2) != null ? 1000 : 1);
    final g = guess(t);
    final isQuestion = _questionPattern.hasMatch(t);
    final pendingAmount = (pend.amount ?? 0) != 0 ? pend.amount : null;
    final hasPending = pend.desc != null || pendingAmount != null;
    final isRecord = !isQuestion &&
        (_recordPattern.hasMatch(t) || (hasPending && (amount != null || g != null)));

    if (isRecord) {
      amount ??= pendingAmount;
      final item = g ??
          (pend.desc != null && pend.category != null
              ? (desc: pend.desc!, category: pend.category!)
              : null);
      final keep = item == null
          ? const PendingExpense()
          : PendingExpense(desc: item.desc, category: item.category);

      if (amount != null && (!(amount > 0) || amount > maxAmount)) {
        return AiPlan(
          pending: keep,
          build: (_, id) => _say(id,
              'That amount doesn’t look right. Enter an amount greater than ₦0 and I’ll prepare the expense.'),
        );
      }
      if (amount == null) {
        final what = item == null ? 'it' : item.desc.toLowerCase();
        return AiPlan(
          busyLabel: 'Understanding your expense',
          pending: keep,
          build: (_, id) => _say(
            id,
            'How much did you spend on $what? Tell me the amount and I’ll prepare the expense for you to review.',
            chips: const ['₦1,500', '₦3,000', '₦5,000'],
          ),
        );
      }
      if (item == null) {
        final a = amount;
        return AiPlan(
          pending: PendingExpense(amount: a),
          build: (_, id) => _say(id, 'What was the ${money(a)} for? For example “lunch” or “Bolt ride”.'),
        );
      }

      final a = amount;
      final date = t.contains('yesterday') ? addDays(today, -1) : today;
      return AiPlan(
        busyLabel: 'Preparing expense details',
        tool: 'add_expense · draft',
        build: (_, id) => ChatMessage(
          id: id,
          role: ChatRole.ai,
          text: 'Here’s what I understood. Nothing is saved until you confirm.',
          proposal: ProposalCardData(
            status: ProposalStatus.proposed,
            tx: Transaction(
              id: 'ai-$id',
              desc: item.desc,
              category: item.category,
              amount: a,
              date: date,
              time: nowTime(),
              source: TxSource.ai,
            ),
          ),
        ),
      );
    }

    final ExpenseCategory? catWord = RegExp(r'eat|food').hasMatch(t)
        ? ExpenseCategory.food
        : ExpenseCategory.values.where((c) => t.contains(c.label.toLowerCase())).firstOrNull;

    AiPlan ask(SpendingQuestion kind, {ExpenseCategory? category, String tool = 'get_spending_summary'}) {
      return AiPlan(
        busyLabel: 'Checking your transactions',
        tool: tool,
        build: (txs, id) => answer(kind, txs, id, category: category),
      );
    }

    if (t.contains('week')) return ask(SpendingQuestion.week, category: catWord);
    if (RegExp(r'biggest|most|top|largest|highest').hasMatch(t)) {
      return ask(SpendingQuestion.biggest);
    }
    if (RegExp(r'compare|last month|versus|vs').hasMatch(t)) {
      return ask(SpendingQuestion.compare, tool: 'compare_spending');
    }
    if (catWord != null) return ask(SpendingQuestion.categoryMonth, category: catWord);
    if (RegExp('month|${monthLong(today).toLowerCase()}|total').hasMatch(t)) {
      return ask(SpendingQuestion.compare, tool: 'compare_spending');
    }
    return AiPlan(
      build: (_, id) => _say(
        id,
        'I can record an expense or answer questions about your spending. Try one of these:',
        chips: const ['How much have I spent this week?', 'What is my biggest expense category?'],
      ),
    );
  }

  /// Answers a spending question from [txs].
  ChatMessage answer(
    SpendingQuestion kind,
    List<Transaction> txs,
    String id, {
    ExpenseCategory? category,
  }) {
    final month = txs.where((t) => isSameMonth(t.date, today)).toList();
    final monthTotal = sumOf(month);
    final monthName = monthLong(today);
    final mtd = monthToDateLabel(today);

    List<SummaryRow> breakdownRows(Iterable<Transaction> items) => [
          for (final r in categoryBreakdown(items))
            SummaryRow(label: r.category.label, amount: r.amount, color: r.category.color),
        ];

    switch (kind) {
      case SpendingQuestion.week:
        final start = startOfWeek(today);
        final items = txs
            .where((t) =>
                !t.date.isBefore(start) &&
                !t.date.isAfter(today) &&
                (category == null || t.category == category))
            .toList();
        final total = sumOf(items);
        final what = category?.label.toLowerCase() ?? 'everything';
        final range = weekToDateLabel(today);
        if (items.isEmpty) {
          final kindWord = category == null ? '' : '$what ';
          return _say(id, 'You haven’t recorded any ${kindWord}expenses this week ($range).');
        }
        final rows = category == null
            ? breakdownRows(items)
            : [
                for (final t in items)
                  SummaryRow(label: '${t.desc} · ${dayLabel(t.date, today: today)}', amount: t.amount, color: t.category.color),
              ];
        final n = items.length;
        return ChatMessage(
          id: id,
          role: ChatRole.ai,
          text: 'You’ve spent ${money(total)} on $what this week, across $n transaction${n > 1 ? 's' : ''}.',
          summary: SummaryCardData(
            title: '${category?.label ?? 'All spending'} · this week',
            range: range,
            total: total,
            rows: rows,
            count: n,
            tool: 'get_spending_summary',
          ),
        );

      case SpendingQuestion.biggest:
        if (month.isEmpty) {
          return _say(id, 'You haven’t recorded any expenses in $monthName yet.');
        }
        final rows = categoryBreakdown(month);
        final top = rows.first;
        final pct = (top.amount / monthTotal * 100).round();
        return ChatMessage(
          id: id,
          role: ChatRole.ai,
          text: '${top.category.label} is your biggest category this month at ${money(top.amount)}, '
              'which is $pct% of your $monthName spending.',
          summary: SummaryCardData(
            title: '$monthName by category',
            range: mtd,
            total: monthTotal,
            rows: breakdownRows(month),
            count: month.length,
            tool: 'get_spending_summary',
          ),
        );

      case SpendingQuestion.categoryMonth:
        final cat = category ?? ExpenseCategory.food;
        final items = month.where((t) => t.category == cat).toList();
        final label = cat.label;
        if (items.isEmpty) {
          return _say(id, 'You haven’t recorded any ${label.toLowerCase()} expenses in $monthName yet.');
        }
        final total = sumOf(items);
        return ChatMessage(
          id: id,
          role: ChatRole.ai,
          text: 'You’ve spent ${money(total)} on ${label.toLowerCase()} so far in $monthName.',
          summary: SummaryCardData(
            title: '$label · $monthName',
            range: mtd,
            total: total,
            rows: [
              for (final t in items.take(5))
                SummaryRow(label: '${t.desc} · ${dayLabel(t.date, today: today)}', amount: t.amount, color: cat.color),
            ],
            count: items.length,
            tool: 'get_spending_summary',
          ),
        );

      case SpendingQuestion.compare:
        final prevMonthName = monthLong(DateTime(today.year, today.month - 1));
        final before = previousPeriodTotal(txs, today);
        if (before == 0) {
          return _say(id,
              'So far this month you’ve spent ${money(monthTotal)}. I don’t have any spending from $prevMonthName to compare with.');
        }
        final diff = monthTotal - before;
        final pct = (diff.abs() / before * 100).round();
        final word = diff < 0 ? 'less' : 'more';
        return ChatMessage(
          id: id,
          role: ChatRole.ai,
          text: 'So far this month you’ve spent ${money(monthTotal)}. '
              'That’s ${money(diff.abs())} $word than the same days in $prevMonthName.',
          summary: SummaryCardData(
            title: '$monthName vs $prevMonthName',
            range: 'Days 1–${today.day}',
            total: monthTotal,
            sub: '$pct% $word than ${money(before)}',
            subDown: diff < 0,
            rows: breakdownRows(month),
            count: month.length,
            tool: 'compare_spending',
          ),
        );
    }
  }

  @override
  ChatMessage savedMessage(Transaction tx, List<Transaction> transactions, String id) =>
      savedConfirmation(tx, transactions, id, today);

  static ChatMessage _say(String id, String text, {List<String> chips = const []}) =>
      ChatMessage(id: id, role: ChatRole.ai, text: text, chips: chips);
}
