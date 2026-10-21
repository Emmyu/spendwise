# Build an AI agent with Flutter + Gemini

**GDG Ibadan · Pre-DevFest 2026.** You'll turn a naira expense tracker into an **agent**: an AI that does real things in the app, not just chat.

> **Gemini is the brain. Your code is the hands. The code does the maths, never the AI.**

## Before the workshop (about 15 minutes, at home)

**You need:** Flutter, a device to run the app on, a Google account, and Node.js.

1. **Install the Firebase tools and sign in:**
   ```sh
   npm install -g firebase-tools
   dart pub global activate flutterfire_cli
   firebase login
   ```
2. **Get the code** and open the folder:
   ```sh
   git clone https://github.com/Emmyu/spendwise.git
   cd spendwise
   ```
3. **Make your own free Firebase project** at [console.firebase.google.com](https://console.firebase.google.com):
   - Create a **Firestore** database (production mode).
   - Turn on **AI Logic** with the **Gemini Developer API**, and keep **App Check** off ("Unenforced / Monitoring").
   - Stay on the free **Spark** plan: no billing needed.
4. **Connect and run:**
   ```sh
   flutter pub get
   flutterfire configure
   firebase deploy --only firestore:rules --project YOUR_PROJECT_ID
   flutter run
   ```

**You're ready when** the app opens and shows demo expenses. The first run is slow, which is why you do it now.

## On the day

The presenter explains each step on the big screen. You add that step's code with **one command** (run it in the project folder), then restart the app:

```sh
dart run tool/step.dart 1
```

| Step | What you'll see |
|---|---|
| `1` | Gemini says hello |
| `2` | Gemini asks the app to do something: the `add_expense` tool |
| `3` | Expenses are saved in Firestore |
| `4` | A second tool: your code adds up the spending |
| `5` | Change the AI model without updating the app |
| `6` | Teach the app a new skill with MCP |

**Behind?** Run the step the presenter is on. It also applies the steps before it.

## Stuck?

- Ask a helper. 🙋
- No luck with Firebase? Run `flutter run --dart-define=SPENDWISE_OFFLINE_DEMO=true` to follow along without it.
- If the AI says it "couldn't reach the assistant", check that **App Check** for **AI Logic** says **Monitoring** (Firebase console → App Check → APIs).

> **After 2 Nov 2026** Firebase requires App Check for AI Logic, so this workshop app's Gemini calls will stop working then. That's expected.
