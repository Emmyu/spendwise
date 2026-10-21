// ignore_for_file: avoid_print
// Puts the code for one workshop step into your project.
//
//   dart run tool/step.dart 3
//
// Each step adds to the one before it, so `step 3` also applies steps 1 and 2.
// That means you can catch up at any time: run the step the presenter is on.
// The files are copied from tool/steps/stepN/ (open them to read the code).
import 'dart:io';

const _titles = {
  1: 'Gemini says hello',
  2: 'Give it hands: add_expense',
  3: 'Save for real: Firestore',
  4: 'More hands: get_spending_summary',
  5: 'Change the model without an app update: Remote Config',
  6: 'New skills with no app update: MCP',
};

void main(List<String> args) {
  final numbers = args.where((a) => !a.startsWith('--'));
  final step = numbers.length == 1 ? int.tryParse(numbers.first) : null;
  if (step == null || !_titles.containsKey(step)) {
    print('Usage: dart run tool/step.dart <1-${_titles.length}>');
    for (final e in _titles.entries) {
      print('  ${e.key}  ${e.value}');
    }
    exit(64);
  }

  final root = Directory.current.path.replaceAll('\\', '/');
  if (!File('$root/pubspec.yaml').existsSync() || !Directory('$root/tool/steps').existsSync()) {
    print('Run this from the project folder (the one with pubspec.yaml and tool/steps).');
    exit(64);
  }

  // The finished project has tool/make_starter.dart; the attendees' starter does not.
  // Running a step here would overwrite the finished code with an earlier step.
  if (File('$root/tool/make_starter.dart').existsSync() && !args.contains('--force')) {
    print('This is the FINISHED project. A step would overwrite its code with an earlier version.');
    print('Run steps inside the starter folder (spendwise_starter) instead.');
    exit(65);
  }

  final changed = <String>[];
  for (var n = 1; n <= step; n++) {
    final dir = Directory('$root/tool/steps/step$n');
    if (!dir.existsSync()) {
      print('Missing tool/steps/step$n. Is the project complete?');
      exit(66);
    }
    final base = dir.path.replaceAll('\\', '/');
    for (final file in dir.listSync(recursive: true).whereType<File>()) {
      final relative = file.path.replaceAll('\\', '/').substring(base.length + 1);
      File('$root/$relative')
        ..parent.createSync(recursive: true)
        ..writeAsBytesSync(file.readAsBytesSync());
      if (n == step) changed.add(relative);
    }
  }

  print('Step $step: ${_titles[step]}\n');
  print('Files changed in this step:');
  for (final f in changed) {
    print('  $f');
  }
  print('\nNow restart the app (press R in the terminal, or stop it and run `flutter run` again).');
}
