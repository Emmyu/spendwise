import 'package:firebase_ai/firebase_ai.dart';

import '../models/category.dart';
import '../models/chat.dart';
import '../models/transaction.dart';
import '../utils/dates.dart';
import '../utils/format.dart';
import '../utils/spending.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  THE AGENT'S HANDS
//
//  Gemini decides WHICH tool to call and with WHAT arguments.
//  The code in this file does the actual work: it adds up the money.
//  Gemini never does the maths; it only puts our numbers into words.
// ─────────────────────────────────────────────────────────────────────────────

const _categoryNames = ['food', 'transport', 'shopping', 'bills', 'other'];

/// Tool 1: propose an expense. Saves NOTHING: the user must tap Confirm.
final addExpenseTool = FunctionDeclaration(
  'add_expense',
  'Prepare an expense for the user to review. Nothing is saved until the user taps Confirm in the app.',
  parameters: {
    'amount': Schema.number(description: 'Amount in naira, for example 4500.'),
    'description': Schema.string(description: 'Short label, for example "Lunch" or "Bolt ride".'),
    'category': Schema.enumString(enumValues: _categoryNames, description: 'Best matching category.'),
    'date': Schema.string(description: 'Date as YYYY-MM-DD. Leave out for today.'),
  },
  optionalParameters: ['date'],
);

/// Tool 2: how much was spent. The app calculates the total.
final spendingSummaryTool = FunctionDeclaration(
  'get_spending_summary',
  'Get the total the user spent this week or this month, optionally for one category. The app calculates the numbers.',
  parameters: {
    'period': Schema.enumString(enumValues: ['week', 'month'], description: '"week" is Monday to today.'),
    'category': Schema.enumString(enumValues: _categoryNames, description: 'Only count this category.'),
  },
  optionalParameters: ['category'],
);

/// Tool 3 (bonus): this month so far against the same days last month.
final compareSpendingTool = FunctionDeclaration(
  'compare_spending',
  'Compare spending so far this month with the same days last month. The app calculates the difference.',
  parameters: {},
);

final builtInTools = [addExpenseTool, spendingSummaryTool, compareSpendingTool];

/// What running a tool produced.
class ToolOutcome {
  const ToolOutcome(this.forModel, {this.proposal, this.summary});

  /// Sent back to Gemini so it can word the answer.
  final Map<String, Object?> forModel;

  /// Shown in the chat as an expense card (from `add_expense`).
  final ProposalCardData? proposal;

  /// Shown in the chat as a spending card (from the summary tools).
  final SummaryCardData? summary;
}

/// Runs one of our own tools. [name] and [args] come from Gemini's function
/// call. Returns null for a name we don't know (it might be an MCP tool).
ToolOutcome? runBuiltInTool(
  String name,
  Map<String, Object?> args, {
  required List<Transaction> transactions,
  required DateTime today,
  required String newId,
}) {
  switch (name) {
    case 'add_expense':
      return _addExpense(args, today, newId);
    case 'get_spending_summary':
      return _spendingSummary(args, transactions, today);
    case 'compare_spending':
      return _compare(transactions, today);
  }
  return null;
}

ToolOutcome _addExpense(Map<String, Object?> args, DateTime today, String newId) {
  final amount = (args['amount'] as num?)?.toDouble();
  final desc = (args['description'] as String?)?.trim() ?? '';
  final category = ExpenseCategory.values.asNameMap()[args['category']] ?? ExpenseCategory.other;
  final date = _parseDate(args['date'], today);

  // Our code, not the model, decides what a valid expense is.
  if (amount == null || amount <= 0 || amount > 10000000) {
    return const ToolOutcome({'error': 'The amount must be between ₦1 and ₦10,000,000. Ask the user for it.'});
  }
  if (desc.isEmpty) {
    return const ToolOutcome({'error': 'The expense needs a short description. Ask the user what it was for.'});
  }

  final tx = Transaction(
    id: 'ai-$newId',
    desc: desc,
    category: category,
    amount: amount,
    date: date,
    time: nowTime(),
    source: TxSource.ai,
  );
  return ToolOutcome(
    {
      'status': 'proposed_not_saved',
      'amount': amount,
      'description': desc,
      'category': category.name,
      'date': isoDate(date),
      'note': 'The user must tap Confirm in the app. Never say it has been saved.',
    },
    proposal: ProposalCardData(status: ProposalStatus.proposed, tx: tx),
  );
}

ToolOutcome _spendingSummary(Map<String, Object?> args, List<Transaction> all, DateTime today) {
  final byWeek = args['period'] == 'week';
  final category = ExpenseCategory.values.asNameMap()[args['category']];

  final start = startOfWeek(today);
  final items = all.where((t) {
    final inPeriod = byWeek ? (!t.date.isBefore(start) && !t.date.isAfter(today)) : isSameMonth(t.date, today);
    return inPeriod && (category == null || t.category == category);
  }).toList();

  final total = sumOf(items); // ← the maths, done by our code
  final range = byWeek ? weekToDateLabel(today) : monthToDateLabel(today);
  final forModel = <String, Object?>{
    'period': byWeek ? 'this week' : 'this month',
    'range': range,
    if (category != null) 'category': category.label,
    'total_naira': total,
    'transaction_count': items.length,
    if (category == null) 'by_category': {for (final r in categoryBreakdown(items)) r.category.label: r.amount},
  };
  if (items.isEmpty) return ToolOutcome(forModel);

  final rows = category == null
      ? [for (final r in categoryBreakdown(items)) SummaryRow(label: r.category.label, amount: r.amount, color: r.category.color)]
      : [
          for (final t in items.take(6))
            SummaryRow(label: '${t.desc} · ${dayLabel(t.date, today: today)}', amount: t.amount, color: category.color),
        ];
  return ToolOutcome(
    forModel,
    summary: SummaryCardData(
      title: '${category?.label ?? 'All spending'} · ${byWeek ? 'this week' : monthLong(today)}',
      range: range,
      total: total,
      rows: rows,
      count: items.length,
      tool: 'get_spending_summary',
    ),
  );
}

ToolOutcome _compare(List<Transaction> all, DateTime today) {
  final month = all.where((t) => isSameMonth(t.date, today)).toList();
  final thisMonth = sumOf(month);
  final before = previousPeriodTotal(all, today);
  final prevName = monthLong(DateTime(today.year, today.month - 1));

  if (before == 0) {
    return ToolOutcome({
      'this_month_naira': thisMonth,
      'note': 'There is no spending recorded in $prevName to compare with.',
    });
  }
  final diff = thisMonth - before;
  final pct = (diff.abs() / before * 100).round();
  final word = diff < 0 ? 'less' : 'more';
  return ToolOutcome(
    {
      'this_month_naira': thisMonth,
      'last_month_same_days_naira': before,
      'difference_naira': diff.abs(),
      'percent_change': pct,
      'direction': 'spent $word than last month',
    },
    summary: SummaryCardData(
      title: '${monthLong(today)} vs $prevName',
      range: 'Days 1–${today.day}',
      total: thisMonth,
      sub: '$pct% $word than ${money(before)}',
      subDown: diff < 0,
      rows: [for (final r in categoryBreakdown(month)) SummaryRow(label: r.category.label, amount: r.amount, color: r.category.color)],
      count: month.length,
      tool: 'compare_spending',
    ),
  );
}

DateTime _parseDate(Object? raw, DateTime today) {
  final parts = raw is String ? RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(raw) : null;
  if (parts == null) return today;
  final d = DateTime(int.parse(parts[1]!), int.parse(parts[2]!), int.parse(parts[3]!));
  return d.isAfter(today) ? today : d; // no expenses from the future
}

/// What the chat shows while a tool runs.
String workingLabel(String tool) => switch (tool) {
      'add_expense' => 'Preparing expense details',
      'get_spending_summary' || 'compare_spending' => 'Checking your transactions',
      _ => 'Using a tool',
    };
