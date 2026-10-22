import '../models/chat.dart';
import '../models/transaction.dart';
import 'ai_assistant.dart';

/// What the Ask AI chat uses before Gemini is connected.
///
/// It never pretends to understand anything and never records an expense: it
/// just says the assistant isn't connected yet. (The scripted [MockAiAssistant]
/// is only used when you ask for it with `--dart-define=SPENDWISE_OFFLINE_DEMO=true`.)
class NotConnectedAssistant implements AiAssistant {
  NotConnectedAssistant({this.message = defaultMessage});

  static const defaultMessage =
      'The assistant isn’t connected yet. Finish the Firebase setup in WORKSHOP.md, '
      'then add the AI with the workshop steps (dart run tool/step.dart 1).';

  final String message;

  @override
  String? get label => null;

  @override
  Future<ChatMessage> respond(AssistantRequest request) async =>
      ChatMessage(id: request.nextId(), role: ChatRole.ai, text: message);

  @override
  void reset() {}

  /// Never reached: this assistant doesn't propose expenses, so nothing is confirmed through it.
  @override
  ChatMessage savedMessage(Transaction tx, List<Transaction> transactions, String id) =>
      ChatMessage(id: id, role: ChatRole.ai, text: message);
}
