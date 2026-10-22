import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'data/firestore_transaction_repository.dart';
import 'data/mock_data.dart';
import 'data/transaction_repository.dart';
import 'firebase_options.dart';
import 'services/ai_assistant.dart';
import 'services/gemini_assistant.dart';
import 'services/mock_ai.dart';
import 'services/not_connected_assistant.dart';
import 'services/remote_settings.dart';
import 'utils/dates.dart';

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
/// app still opens, empty, and says the assistant isn't connected.
Future<AppServices> bootstrap() async {
  // Asked for on purpose: the sample expenses and the scripted chatbot.
  if (_offlineDemo) {
    return AppServices(repository: InMemoryTransactionRepository(), assistant: MockAiAssistant(), today: kToday);
  }

  try {
    return await _startFirebase().timeout(const Duration(seconds: 20));
  } catch (e) {
    debugPrint('Firebase is not ready yet: $e');
    // A fresh, empty app. Nothing is saved, and the chat says it isn't connected.
    return AppServices(
      repository: InMemoryTransactionRepository(seed: const []),
      assistant: NotConnectedAssistant(),
      today: dateOnly(DateTime.now()),
      notice: 'Firebase isn’t connected yet, so nothing is saved. See WORKSHOP.md.',
    );
  }
}

Future<AppServices> _startFirebase() async {
  // ── Firebase itself ──────────────────────────────────────────────────────
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ── Remote Config: the Gemini model name lives in the console ─
  final settings = RemoteSettings();
  // TODO(step 5): await settings.init();

  // ── Firestore: where expenses are stored ─────────────────────────────────
  final today = dateOnly(DateTime.now());
  final repository = FirestoreTransactionRepository();

  // ── The assistant ────────────────────────────────────────────────────────
  final AiAssistant assistant = _mockAi
      ? MockAiAssistant(today: today)
      : GeminiAssistant(today: today, modelName: settings.geminiModel);

  return AppServices(repository: repository, assistant: assistant, today: today);
}
