# SpendWise AI: workshop starter

A naira expense tracker in Flutter. In the workshop you turn its scripted chatbot into an **AI agent** with Gemini and Firebase.

> **Gemini is the brain. Our code is the hands. The code does the maths, never the AI.**

## Start here

1. Follow **[WORKSHOP.md](WORKSHOP.md)** to set up your own free Firebase project (about 15 minutes, do it before the day).
2. Run the app: `flutter run`
3. During the session, add each step's code with one command (run it inside this folder):

```sh
dart run tool/step.dart 1    # Gemini says hello
dart run tool/step.dart 2    # give it hands: add_expense
dart run tool/step.dart 3    # save for real: Firestore
dart run tool/step.dart 4    # more hands: get_spending_summary
dart run tool/step.dart 5    # change the model with Remote Config
dart run tool/step.dart 6    # new skills with MCP
```

Each step also applies the steps before it, so if you fall behind, run the step the presenter is on. The code for every step is in `tool/steps/`, so you can read it.

Stack: Flutter · Gemini via Firebase AI Logic · Remote Config · Firestore.
