import 'package:firebase_ai/firebase_ai.dart';

import '../models/chat.dart';
import '../models/transaction.dart';
import '../utils/format.dart';
import 'ai_assistant.dart';

/// The agent: Gemini is the brain, our tools are the hands.
///
/// Step 1: just the brain. We send the user's words to Gemini and show its answer.
class GeminiAssistant implements AiAssistant {
  GeminiAssistant({required this.today, required this.modelName});

  final DateTime today;

  /// Asked for at the start of every new chat (it comes from Remote Config).
  final Future<String> Function() modelName;

  ChatSession? _chat;
  // TODO(step 5): String? _model;  (so the chat header can show which model answered)

  @override
  String? get label => null; // TODO(step 5): _model == null ? null : 'Gemini · $_model'

  @override
  void reset() => _chat = null; // the next message starts a fresh conversation

  @override
  ChatMessage savedMessage(Transaction tx, List<Transaction> transactions, String id) =>
      savedConfirmation(tx, transactions, id, today);

  /// Builds the model on the first message of a chat. Firebase AI Logic is the
  /// door to Gemini: there is no API key in this app.
  Future<ChatSession> _startChat() async {
    final model = await modelName();

    return FirebaseAI.googleAI()
        .generativeModel(
          model: model,
          // TODO(step 2): tools: [Tool.functionDeclarations(builtInTools)],
          systemInstruction: Content.system(_instructions),
        )
        .startChat();
  }

  String get _instructions => '''
You are SpendWise, the assistant inside a naira (₦) expense tracker. Today is ${longDate(today)}.

Keep answers to one or two short sentences. Use ₦ with thousands separators, like ₦4,500.
If the user asks about something unrelated to their spending, politely say you can only help with expenses.
''';

  @override
  Future<ChatMessage> respond(AssistantRequest request) async {
    final chat = _chat ??= await _startChat();

    // Send the user's words to Gemini and show what it says.
    final response = await chat.sendMessage(Content.text(request.text));

    // TODO(step 2): while response.functionCalls is not empty, run each tool
    //   and send the result back with Content.functionResponses(...)

    return ChatMessage(
      id: request.nextId(),
      role: ChatRole.ai,
      text: response.text?.trim() ?? 'Sorry, I couldn’t work that out. Try rephrasing?',
    );
  }
}
