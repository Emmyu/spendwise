import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';

import '../models/chat.dart';
import '../models/transaction.dart';
import '../utils/format.dart';
import 'agent_tools.dart';
import 'ai_assistant.dart';
import 'mcp_client.dart';

/// The agent: Gemini is the brain, [agent_tools] and the MCP server are the hands.
///
/// Each message goes round this loop:
///   1. send the user's words to Gemini
///   2. Gemini replies with text, or asks us to run a tool
///   3. we run the tool (our Dart code does the maths) and send the result back
///   4. Gemini words the final answer
class GeminiAssistant implements AiAssistant {
  GeminiAssistant({
    required this.today,
    required this.modelName,
    this.mcp,
  });

  final DateTime today;

  /// Asked for at the start of every new chat (it comes from Remote Config),
  /// so changing the value switches the model with no app update.
  final Future<String> Function() modelName;

  /// Optional MCP server whose tools are added to ours at runtime.
  final McpClient? mcp;

  ChatSession? _chat;
  String? _model;
  Set<String> _mcpToolNames = {};

  @override
  String? get label => _model == null ? null : 'Gemini · $_model${_mcpToolNames.isEmpty ? '' : ' · MCP'}';

  @override
  void reset() => _chat = null; // the next message starts a fresh conversation

  @override
  ChatMessage savedMessage(Transaction tx, List<Transaction> transactions, String id) =>
      savedConfirmation(tx, transactions, id, today);

  /// Builds the model on the first message of a chat.
  Future<ChatSession> _startChat() async {
    final model = _model = await modelName();

    // Our tools, plus whatever the MCP server offers right now.
    final tools = [...builtInTools];
    _mcpToolNames = {};
    if (mcp == null) {
      debugPrint('MCP: no server address, so only our own tools are on. Start the app with --dart-define=MCP_URL=http://localhost:8080/mcp');
    } else {
      try {
        await mcp!.initialize();
        final menu = await mcp!.listTools();
        tools.addAll(menu.map(declarationFromMcp));
        _mcpToolNames = {for (final t in menu) t.name};
      } catch (e) {
        debugPrint('MCP server unavailable, continuing without it: $e');
      }
    }

    return FirebaseAI.googleAI()
        .generativeModel(
          model: model,
          tools: [Tool.functionDeclarations(tools)],
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
        request.onWorking(
          _mcpToolNames.contains(call.name) ? 'Using the MCP server' : workingLabel(call.name),
          tool: call.name,
        );
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

    // One of ours?
    final builtIn = runBuiltInTool(
      call.name,
      args,
      transactions: request.transactions(),
      today: today,
      newId: request.nextId(),
    );
    if (builtIn != null) return builtIn;

    // Otherwise it must come from the MCP server.
    try {
      return ToolOutcome({'result': await mcp!.callTool(call.name, args)});
    } catch (e) {
      return ToolOutcome({'error': 'The tool failed: $e'});
    }
  }
}
