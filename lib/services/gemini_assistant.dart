import '../models/chat.dart';
import '../models/transaction.dart';
import 'ai_assistant.dart';

/// The agent: Gemini is the brain, our tools are the hands.
///
/// Every message goes round this loop:
///   1. send the user's words to Gemini
///   2. Gemini replies with text, or asks us to run a tool
///   3. we run the tool (our Dart code does the maths) and send the result back
///   4. Gemini words the final answer
class GeminiAssistant implements AiAssistant {
  GeminiAssistant({required this.today, required this.modelName});

  final DateTime today;

  /// Asked for at the start of every new chat (it comes from Remote Config).
  final Future<String> Function() modelName;

  // TODO(step 1): keep the chat here
  //   ChatSession? _chat;
  //   String? _model;

  @override
  String? get label => null; // TODO(step 5): 'Gemini · $_model'

  @override
  void reset() {
    // TODO(step 1): forget the conversation: _chat = null;
  }

  @override
  ChatMessage savedMessage(Transaction tx, List<Transaction> transactions, String id) =>
      savedConfirmation(tx, transactions, id, today);

  @override
  Future<ChatMessage> respond(AssistantRequest request) async {
    // TODO(step 1): create the model:
    //   FirebaseAI.googleAI().generativeModel(model: await modelName(), systemInstruction: ...).startChat()
    // TODO(step 1): send the user's words:
    //   var response = await chat.sendMessage(Content.text(request.text));
    // TODO(step 2): while response.functionCalls is not empty, run each tool and
    //   send the result back with Content.functionResponses(...)
    // TODO(step 6): also offer the tools from the MCP server
    throw UnimplementedError('TODO(step 1): ask Gemini');
  }
}
