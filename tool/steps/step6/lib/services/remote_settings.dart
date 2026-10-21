import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

/// Settings you can change in the Firebase console, with no app update.
///
/// Two parameters:
///   gemini_model  which Gemini model the assistant uses
///   mcp_url       the MCP server to borrow extra tools from (optional)
class RemoteSettings {
  /// Used until Remote Config answers, and if it never does.
  static const defaultModel = 'gemini-3.5-flash-lite';

  static const _modelKey = 'gemini_model';
  static const _mcpKey = 'mcp_url';

  final _config = FirebaseRemoteConfig.instance;

  Future<void> init() async {
    await _config.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 5),
      // Short while developing so a console change shows up quickly.
      minimumFetchInterval: kDebugMode ? const Duration(seconds: 10) : const Duration(hours: 1),
    ));
    await _config.setDefaults({
      _modelKey: defaultModel,
      _mcpKey: const String.fromEnvironment('MCP_URL'),
    });
    await refresh();
  }

  Future<void> refresh() async {
    try {
      await _config.fetchAndActivate();
    } catch (e) {
      debugPrint('Remote Config fetch failed, using the last known values: $e');
    }
  }

  /// Asked at the start of every new chat, so a new value is picked up without restarting.
  Future<String> geminiModel() async {
    await refresh();
    final name = _config.getString(_modelKey).trim();
    return name.isEmpty ? defaultModel : name;
  }

  String get mcpUrl => _config.getString(_mcpKey).trim();
}
