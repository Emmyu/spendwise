import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'data/mock_data.dart';
import 'data/transaction_repository.dart';
import 'firebase_options.dart';
import 'services/ai_assistant.dart';
import 'services/gemini_assistant.dart';
import 'services/mock_ai.dart';
import 'services/remote_settings.dart';

/// What the app runs on.
class AppServices {
  const AppServices({
    required this.repository,
    required this.assistant,
    required this.today,
    this.notice,
  });

  final TransactionRepository repository;
  final AiAssistant assistant;
  final DateTime today;

  /// Shown once at start-up, e.g. why we are in offline demo mode.
  final String? notice;
}

/// Skips Firebase entirely: in-memory data and the keyword assistant.
/// `flutter run --dart-define=SPENDWISE_OFFLINE_DEMO=true`
const _offlineDemo = bool.fromEnvironment('SPENDWISE_OFFLINE_DEMO');

/// Keeps Firestore but swaps Gemini for the keyword assistant (a safety net
/// for a live demo when the Wi-Fi or the quota fails).
const _mockAi = bool.fromEnvironment('SPENDWISE_MOCK_AI');


/// Starts Firebase and builds the services. If Firebase isn't set up yet, the
/// app still opens, on demo data, and says so.
Future<AppServices> bootstrap() async {
  AppServices offline([String? notice]) => AppServices(
        repository: InMemoryTransactionRepository(),
        assistant: MockAiAssistant(),
        today: kToday,
        notice: notice,
      );

  if (_offlineDemo) return offline();

  try {
    return await _startFirebase().timeout(const Duration(seconds: 20));
  } catch (e) {
    debugPrint('Firebase is not ready, running the offline demo instead: $e');
    return offline('Firebase isn’t connected yet, so this is demo data. See WORKSHOP.md.');
  }
}

Future<AppServices> _startFirebase() async {
  // ── Firebase itself ──────────────────────────────────────────────────────
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ── Remote Config: the Gemini model name lives in the console ─
  final settings = RemoteSettings();
  // TODO(step 5): await settings.init();

  // ── Firestore: where expenses are stored ─────────────────────────────────
  // TODO(step 3): store expenses in Firestore instead of in memory.
  final today = kToday;
  final repository = InMemoryTransactionRepository();

  // ── The assistant ────────────────────────────────────────────────────────
  final AiAssistant assistant = _mockAi
      ? MockAiAssistant(today: today)
      : GeminiAssistant(today: today, modelName: settings.geminiModel);

  return AppServices(repository: repository, assistant: assistant, today: today);
}
