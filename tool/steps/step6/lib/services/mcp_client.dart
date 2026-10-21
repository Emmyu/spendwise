import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:http/http.dart' as http;

// ─────────────────────────────────────────────────────────────────────────────
//  MCP IN 40 LINES
//
//  MCP (Model Context Protocol) is just JSON-RPC over HTTP with three steps:
//    1. initialize   → "hello, who are you?"
//    2. tools/list   → "what can you do?"      (the menu)
//    3. tools/call   → "do this one for me"
//
//  The app asks the server for its menu at runtime and hands it to Gemini.
//  Add a tool on the server and the app gains the skill: no app update.
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
  McpClient(this.url, {http.Client? client}) : _http = client ?? http.Client();

  final Uri url;
  final http.Client _http;
  int _nextId = 0;

  /// Step 1: say hello.
  Future<void> initialize() => _rpc('initialize', {
        'protocolVersion': '2025-06-18',
        'capabilities': <String, Object?>{},
        'clientInfo': {'name': 'spendwise', 'version': '1.0.0'},
      });

  /// Step 2: ask for the menu.
  Future<List<McpTool>> listTools() async {
    final result = await _rpc('tools/list', {});
    return [
      for (final t in (result['tools'] as List? ?? const []).cast<Map<String, dynamic>>())
        McpTool(
          t['name'] as String,
          t['description'] as String? ?? '',
          (t['inputSchema'] as Map?)?.cast<String, dynamic>() ?? const {'type': 'object'},
        ),
    ];
  }

  /// Step 3: run one tool. Returns the text it answered with.
  Future<String> callTool(String name, Map<String, Object?> args) async {
    final result = await _rpc('tools/call', {'name': name, 'arguments': args});
    final text = [
      for (final c in (result['content'] as List? ?? const []).cast<Map<String, dynamic>>())
        if (c['type'] == 'text') c['text'] as String,
    ].join('\n');
    if (result['isError'] == true) throw McpException(text.isEmpty ? 'The tool reported an error.' : text);
    return text;
  }

  /// One JSON-RPC request. That's all MCP is.
  Future<Map<String, dynamic>> _rpc(String method, Map<String, Object?> params) async {
    final res = await _http
        .post(
          url,
          headers: {'Content-Type': 'application/json', 'Accept': 'application/json, text/event-stream'},
          body: jsonEncode({'jsonrpc': '2.0', 'id': ++_nextId, 'method': method, 'params': params}),
        )
        .timeout(const Duration(seconds: 15));
    if (res.statusCode >= 400) throw McpException('Server answered ${res.statusCode}');

    // Servers may answer with plain JSON or as an event stream ("data: {...}").
    // Decode as UTF-8 ourselves: `res.body` assumes Latin-1 when the server sends no charset, which would mangle ₦.
    var body = utf8.decode(res.bodyBytes);
    if ((res.headers['content-type'] ?? '').contains('text/event-stream')) {
      body = body.split('\n').lastWhere((l) => l.startsWith('data:'), orElse: () => '').substring(5).trim();
    }
    final json = jsonDecode(body) as Map<String, dynamic>;
    final error = json['error'];
    if (error is Map) throw McpException('${error['message']}');
    return (json['result'] as Map?)?.cast<String, dynamic>() ?? {};
  }
}

/// Turns an MCP tool into something Gemini understands, so the model can call
/// it exactly like our own tools.
FunctionDeclaration declarationFromMcp(McpTool tool) {
  final props = (tool.inputSchema['properties'] as Map?)?.cast<String, dynamic>() ?? const {};
  final required = ((tool.inputSchema['required'] as List?) ?? const []).cast<String>().toSet();
  return FunctionDeclaration(
    tool.name,
    tool.description,
    parameters: {for (final e in props.entries) e.key: _schemaFromJson((e.value as Map).cast<String, dynamic>())},
    optionalParameters: [for (final k in props.keys) if (!required.contains(k)) k],
  );
}

/// A small JSON Schema → Gemini schema converter: strings, numbers, booleans,
/// enums, arrays and objects. Plenty for simple tools.
Schema _schemaFromJson(Map<String, dynamic> j) {
  final description = j['description'] as String?;
  switch (j['type']) {
    case 'number':
      return Schema.number(description: description);
    case 'integer':
      return Schema.integer(description: description);
    case 'boolean':
      return Schema.boolean(description: description);
    case 'array':
      return Schema.array(items: _schemaFromJson((j['items'] as Map?)?.cast<String, dynamic>() ?? {'type': 'string'}), description: description);
    case 'object':
      final props = (j['properties'] as Map?)?.cast<String, dynamic>() ?? const {};
      final required = ((j['required'] as List?) ?? const []).cast<String>().toSet();
      return Schema.object(
        properties: {for (final e in props.entries) e.key: _schemaFromJson((e.value as Map).cast<String, dynamic>())},
        optionalProperties: [for (final k in props.keys) if (!required.contains(k)) k],
        description: description,
      );
    default:
      final values = (j['enum'] as List?)?.map((e) => '$e').toList();
      return values == null ? Schema.string(description: description) : Schema.enumString(enumValues: values, description: description);
  }
}
