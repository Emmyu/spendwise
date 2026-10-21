import 'package:firebase_ai/firebase_ai.dart';

import '../models/category.dart';
import '../models/chat.dart';
import '../models/transaction.dart';
import '../utils/dates.dart';
import '../utils/format.dart';

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

final builtInTools = [
  addExpenseTool,
  // TODO(step 4): spendingSummaryTool,
];

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
    // TODO(step 4): case 'get_spending_summary': add up the matching transactions. YOU do the maths.
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
