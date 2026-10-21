import '../models/chat.dart';
import '../models/transaction.dart';
import '../utils/dates.dart';
import '../utils/format.dart';
import '../utils/spending.dart';

/// Everything an assistant needs to answer one message.
class AssistantRequest {
  const AssistantRequest({
    required this.text,
    required this.transactions,
    required this.today,
    required this.nextId,
    required this.onWorking,
  });

  /// What the user typed.
  final String text;

  /// The expenses right now. A function, not a list, because a slow answer
  /// should see anything saved while it was thinking.
  final List<Transaction> Function() transactions;

  final DateTime today;

  /// A fresh id for the reply message.
  final String Function() nextId;

  /// Tells the chat what the assistant is doing, e.g. "Checking your
  /// transactions" with the tool name `get_spending_summary`.
  final void Function(String label, {String? tool}) onWorking;
}

/// Whatever answers the Ask SpendWise chat: the offline [MockAiAssistant] or
/// the Gemini-powered [GeminiAssistant].
abstract interface class AiAssistant {
  /// Shown under the chat title, e.g. the Gemini model in use. Null for none.
  String? get label;

  /// Answers one message. A reply is text plus, optionally, an expense
  /// proposal card or a spending summary card.
  Future<ChatMessage> respond(AssistantRequest request);

  /// Forget the conversation so far ("new chat").
  void reset();

  /// The confirmation posted after a proposed expense is saved.
  ChatMessage savedMessage(Transaction tx, List<Transaction> transactions, String id);
}

/// "Saved. Lunch for ₦4,500 is now in your transactions under Food. …"
/// Plain app code: nothing here needs an AI.
ChatMessage savedConfirmation(Transaction tx, List<Transaction> transactions, String id, DateTime today) {
  final total = sumOf(transactions.where((t) => isSameMonth(t.date, today)));
  return ChatMessage(
    id: id,
    role: ChatRole.ai,
    text: 'Saved. ${tx.desc} for ${money(tx.amount)} is now in your transactions under ${tx.category.label}. '
        'You’ve spent ${money(total)} in ${monthLong(today)} so far.',
  );
}
