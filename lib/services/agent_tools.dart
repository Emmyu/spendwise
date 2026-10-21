import 'package:firebase_ai/firebase_ai.dart';

import '../models/chat.dart';
import '../models/transaction.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  THE AGENT'S HANDS
//
//  Gemini decides WHICH tool to call and with WHAT arguments.
//  The code in this file does the actual work: it adds up the money.
//  Gemini never does the maths; it only puts our numbers into words.
// ─────────────────────────────────────────────────────────────────────────────

// TODO(step 2): declare the add_expense tool. It only PROPOSES an expense.
//   final addExpenseTool = FunctionDeclaration('add_expense', '...', parameters: {
//     'amount': Schema.number(description: '...'),
//     'description': Schema.string(description: '...'),
//     'category': Schema.enumString(enumValues: [...]),
//   });

// TODO(step 4): declare get_spending_summary (period: week | month, optional category).

/// The tools Gemini is allowed to call.
final List<FunctionDeclaration> builtInTools = [
  // TODO(step 2): addExpenseTool,
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
    // TODO(step 2): case 'add_expense': build a Transaction and return it as a PROPOSAL. Save nothing.
    // TODO(step 4): case 'get_spending_summary': add up the matching transactions. YOU do the maths.
  }
  return null;
}

/// What the chat shows while a tool runs.
String workingLabel(String tool) => switch (tool) {
      'add_expense' => 'Preparing expense details',
      'get_spending_summary' || 'compare_spending' => 'Checking your transactions',
      _ => 'Using a tool',
    };
