import 'data/transaction_repository.dart';
import 'services/ai_assistant.dart';
import 'services/not_connected_assistant.dart';
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

  /// Shown once at start-up, e.g. why Firebase isn't connected.
  final String? notice;
}

/// Builds everything the app runs on.
///
/// RIGHT NOW the app has no brain: it starts empty (₦0, no expenses), and the
/// Ask AI chat says the assistant isn't connected yet. During the workshop you
/// turn it into an AGENT by filling in the TODOs below, one step at a time.
Future<AppServices> bootstrap() async {
  // TODO(step 1): start Firebase, the door to Gemini:
  //   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // TODO(step 5): read the model name from Remote Config:
  //   final settings = RemoteSettings();
  //   await settings.init();

  // TODO(step 3): store expenses in Firestore instead of in memory:
  //   final repository = FirestoreTransactionRepository();

  // TODO(step 1): use Gemini instead of the "not connected" assistant:
  //   GeminiAssistant(today: today, modelName: settings.geminiModel)

  return AppServices(
    repository: InMemoryTransactionRepository(seed: const []),
    assistant: NotConnectedAssistant(),
    today: dateOnly(DateTime.now()),
  );
}
