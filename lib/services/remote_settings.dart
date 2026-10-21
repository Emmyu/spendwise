/// Settings you can change in the Firebase console, with no app update.
///
/// TODO(step 5): back this with Firebase Remote Config. Two parameters:
///   gemini_model  which Gemini model the assistant uses
///   mcp_url       the MCP server to borrow extra tools from (optional)
class RemoteSettings {
  /// Used until Remote Config answers, and if it never does.
  static const defaultModel = 'gemini-3.5-flash-lite';

  Future<void> init() async {
    // TODO(step 5): setDefaults, then fetchAndActivate
  }

  /// Asked at the start of every new chat.
  Future<String> geminiModel() async => defaultModel; // TODO(step 5): read 'gemini_model'

  String get mcpUrl => const String.fromEnvironment('MCP_URL'); // TODO(step 6): read 'mcp_url'
}
