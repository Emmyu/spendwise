import 'package:firebase_ai/firebase_ai.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  MCP IN 40 LINES
//
//  MCP (Model Context Protocol) is just JSON-RPC over HTTP with three steps:
//    1. initialize   → "hello, who are you?"
//    2. tools/list   → "what can you do?"      (the menu)
//    3. tools/call   → "do this one for me"
//
//  TODO(step 6): write the client. The app asks the server for its menu at
//  runtime and hands it to Gemini. Add a tool on the server and the app gains
//  the skill: no app update.
// ─────────────────────────────────────────────────────────────────────────────

class McpTool {
  const McpTool(this.name, this.description, this.inputSchema);

  final String name;
  final String description;

  /// A JSON Schema describing the arguments.
  final Map<String, dynamic> inputSchema;
}

class McpException implements Exception {
  McpException(this.message);

  final String message;

  @override
  String toString() => 'McpException: $message';
}

class McpClient {
  McpClient(this.url);

  final Uri url;

  // TODO(step 6): Future<void> initialize()                     → POST {"method": "initialize"}
  // TODO(step 6): Future<List<McpTool>> listTools()             → POST {"method": "tools/list"}
  // TODO(step 6): Future<String> callTool(name, args)           → POST {"method": "tools/call"}
}

/// Turns an MCP tool into something Gemini understands.
/// TODO(step 6): convert the tool's JSON Schema into a FunctionDeclaration.
FunctionDeclaration declarationFromMcp(McpTool tool) => throw UnimplementedError('TODO(step 6)');
