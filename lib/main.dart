import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'bootstrap.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Starts Firebase, Remote Config, Firestore and the assistant.
  // The native splash stays up until this finishes and the first frame draws.
  final services = await bootstrap();

  final state = AppState(
    repository: services.repository,
    assistant: services.assistant,
    today: services.today,
  );
  runApp(ChangeNotifierProvider.value(value: state, child: const SpendWiseApp()));

  // Android and iOS drop the native splash on the first frame by themselves;
  // the web splash image is only removed by this call.
  FlutterNativeSplash.remove();

  // Tell the user once, after the splash animation, if we fell back to demo data.
  final notice = services.notice;
  if (notice != null) Future<void>.delayed(const Duration(milliseconds: 2200), () => state.showToast(notice));
}
