import 'package:firebase_ai/firebase_ai.dart';

import '../models/chat.dart';
import '../models/transaction.dart';
import '../utils/format.dart';
import 'agent_tools.dart';
import 'ai_assistant.dart';

/// The agent: Gemini is the brain, [agent_tools] are the hands.
///
/// Each message goes round this loop:
///   1. send the user's words to Gemini
///   2. Gemini replies with text, or asks us to run a tool
///   3. we run the tool (our Dart code does the maths) and send the result back
///   4. Gemini words the final answer
class GeminiAssistant implements AiAssistant {
  GeminiAssistant({required this.today, required this.modelName});

  final DateTime today;

  /// Asked for at the start of every new chat (it comes from Remote Config),
  /// so changing the value switches the model with no app update.
  final Future<String> Function() modelName;

  ChatSession? _chat;
  String? _model;

  @override
  String? get label => _model == null ? null : 'Gemini · $_model';

  @override
  void reset() => _chat = null; // the next message starts a fresh conversation

  @override
  ChatMessage savedMessage(Transaction tx, List<Transaction> transactions, String id) =>
      savedConfirmation(tx, transactions, id, today);

  /// Builds the model on the first message of a chat.
  Future<ChatSession> _startChat() async {
    final model = _model = await modelName();

    return FirebaseAI.googleAI()
        .generativeModel(
          model: model,
          tools: [Tool.functionDeclarations(builtInTools)],
          systemInstruction: Content.system(_instructions),
        )
        .startChat();
  }

  String get _instructions => '''
You are SpendWise, the assistant inside a naira (₦) expense tracker. Today is ${longDate(today)}.

- To record an expense, call add_expense. It only PROPOSES the expense; the user must tap Confirm in the app. Never say an expense is saved.
- If the amount or what it was for is missing, ask the user for it. Do not guess.
- For questions about spending, call get_spending_summary or compare_spending. Never work out totals yourself; use the numbers the tools return.
- Convert currencies only with a tool, if one is available. Never guess an exchange rate.
- Keep answers to one or two short sentences. Use ₦ with thousands separators, like ₦4,500.
- If the user asks about something unrelated to their spending, politely say you can only help with expenses.
''';

  @override
  Future<ChatMessage> respond(AssistantRequest request) async {
    final chat = _chat ??= await _startChat();

    // 1. The user's words go to Gemini.
    var response = await chat.sendMessage(Content.text(request.text));

    ProposalCardData? proposal;
    SummaryCardData? summary;

    // 2–3. While Gemini asks for tools, run them and send the results back.
    for (var round = 0; round < 5 && response.functionCalls.isNotEmpty; round++) {
      final results = <FunctionResponse>[];
      for (final call in response.functionCalls) {
        request.onWorking(workingLabel(call.name), tool: call.name);
        final result = await _runTool(call, request);
        proposal = result.proposal ?? proposal;
        summary = result.summary ?? summary;
        results.add(FunctionResponse(call.name, result.forModel, id: call.id));
      }
      response = await chat.sendMessage(Content.functionResponses(results));
    }

    // 4. Gemini's final words, with the card our code produced (if any).
    final text = response.text?.trim() ?? '';
    return ChatMessage(
      id: request.nextId(),
      role: ChatRole.ai,
      text: text.isNotEmpty
          ? text
          : proposal != null
              ? 'Here’s what I understood. Nothing is saved until you confirm.'
              : 'Sorry, I couldn’t work that out. Try rephrasing?',
      proposal: proposal,
      summary: summary,
    );
  }

  Future<ToolOutcome> _runTool(FunctionCall call, AssistantRequest request) async {
    final args = call.args.cast<String, Object?>();

    final outcome = runBuiltInTool(
      call.name,
      args,
      transactions: request.transactions(),
      today: today,
      newId: request.nextId(),
    );
    // A tool we never offered: tell Gemini, so it can recover.
    return outcome ?? ToolOutcome({'error': 'Unknown tool: ${call.name}'});
  }
}
