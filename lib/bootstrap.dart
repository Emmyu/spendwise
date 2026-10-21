import 'data/mock_data.dart';
import 'data/transaction_repository.dart';
import 'services/ai_assistant.dart';
import 'services/mock_ai.dart';

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

/// Builds everything the app runs on.
///
/// RIGHT NOW the app is a CHATBOT: demo data in memory, and a scripted
/// assistant that matches keywords. During the workshop you turn it into an
/// AGENT by filling in the TODOs below, one step at a time.
Future<AppServices> bootstrap() async {
  // TODO(step 1): start Firebase, the door to Gemini:
  //   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // TODO(step 5): read the model name from Remote Config:
  //   final settings = RemoteSettings();
  //   await settings.init();

  // TODO(step 3): store expenses in Firestore instead of in memory:
  //   final repository = FirestoreTransactionRepository();
  //   await repository.seedIfEmpty(today);

  // TODO(step 1): use Gemini instead of the scripted chatbot:
  //   GeminiAssistant(today: today, modelName: settings.geminiModel)

  return AppServices(
    repository: InMemoryTransactionRepository(),
    assistant: MockAiAssistant(),
    today: kToday,
  );
}
