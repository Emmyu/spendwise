# Build an AI agent with Flutter + Gemini

**GDG Ibadan · Pre-DevFest 2026.** You'll turn a naira expense tracker into an **agent**: an AI that does real things in the app, not just chat.

> **Gemini is the brain. Your code is the hands. The code does the maths, never the AI.**

You type *"I spent ₦4,500 on lunch"*. Gemini understands it and asks your app to prepare an expense. You tap **Confirm**, and only then is it saved. You ask *"How much on food this week?"* and your Dart code adds it up. Gemini just puts the number into words.

---

## 0. Before the workshop (about 15 minutes)

You need: **Flutter** (3.35+), a **device to run the app on**, a **Google account**, and **Node.js 20+** (for the Firebase CLI). A laptop with 8 GB of RAM or more is best.

```sh
npm install -g firebase-tools
dart pub global activate flutterfire_cli
firebase login
```

### Get the code

```sh
git clone THE-REPO-LINK-FROM-THE-ORGANISERS
cd THE-FOLDER-IT-CREATES        # the folder that contains pubspec.yaml
```

Every command in this guide is run **inside that folder**.

### Get your device ready

Any device Flutter can run on works. Make sure your device is started, then check that Flutter can see it:

```sh
flutter doctor        # fix anything marked with ✗
flutter devices       # your device must be listed here
```

If `flutter devices` shows nothing, fix that first (ask a helper, or the organisers). The presenter will say which device to use on the day.

> **Do this at home, on good internet.** The first run downloads a lot and can take 5–10 minutes. Running it once (below) does that, so on the day it starts quickly.

### Create your own free Firebase project

Everyone makes their own, so nobody shares a quota.

1. **[console.firebase.google.com](https://console.firebase.google.com) → Add project.** Name it anything (e.g. `spendwise-yourname`). Google Analytics is not needed.
2. **Firestore:** *Build → Firestore Database → Create database.* Pick the closest location (it can't be changed later) and **Start in production mode**. Production mode is fine: we deploy our own rules next.
3. **Gemini:** *AI Services → AI Logic → Get started → Gemini Developer API.* On the setup screen, find **App Check** and choose **Unenforced (monitoring only)**.
   > **Important:** new projects turn App Check *on* automatically, and then every Gemini call from this workshop app is rejected (403). This app doesn't use App Check, so keep it in **monitoring** mode. To check: *Console → App Check → APIs tab → the **Firebase AI Logic** row.* Its status must say **Monitoring** (not *Enforced*). If it says Enforced, open that row and choose **Unenforce**.
   > **Stay on the free Spark plan.** Don't add a billing account. Then nobody can be charged: if a limit is reached, Gemini just answers "too many requests" and you wait.
4. **Connect the app** (from this project's folder):
   ```sh
   flutter pub get
   flutterfire configure        # choose your project, then select the platform your device uses
   firebase deploy --only firestore:rules --project YOUR_PROJECT_ID
   ```
   And install the little server we use in step 6 (once; it runs on your own laptop):
   ```sh
   cd mcp-server
   npm install
   cd ..
   ```
5. **Run it:**
   ```sh
   flutter run                  # if you have several devices: flutter run -d YOUR_DEVICE_ID (from flutter devices)
   ```
   The first run is slow (5–10 minutes). Later runs take seconds. You should see a **fresh, empty app**: ₦0 and no expenses. In the Ask AI tab it says the assistant isn't connected yet: that's right, because the starter has no brain until step 1. If `flutterfire configure` printed no errors, you're set.

You're ready. The app starts **empty** and has no brain yet. During the workshop you give it a real brain and hands, and you add your own expenses as you go.

---

## The steps

During the session the presenter explains each step on the big screen. To get that step's code into **your** project, run one command and restart the app:

```sh
dart run tool/step.dart 1        # then press a CAPITAL R in the terminal (not lowercase r), or stop and run `flutter run` again
```

Each step builds on the one before it, so **if you fall behind, just run the step the presenter is on**. It brings you fully up to date. The code for every step is in `tool/steps/stepN/`, so you can open it and read along.

| Run | What it adds | The idea |
|---|---|---|
| `dart run tool/step.dart 1` | **Gemini says hello** | Firebase AI Logic is the door to Gemini: there's no API key in your app. |
| `dart run tool/step.dart 2` | **Give it hands: `add_expense`** | A tool is a name, a description and its arguments. Gemini *asks* for it, your code builds a **proposal**. Nothing is saved. |
| `dart run tool/step.dart 3` | **Save for real: Firestore** | **Confirm** is the only thing that writes. Home and Transactions update live. |
| `dart run tool/step.dart 4` | **More hands: `get_spending_summary`** | Your Dart code adds up the money; Gemini only words the answer. *The code does the maths.* |
| `dart run tool/step.dart 5` | **Change the model without an app update** | Remote Config. After this step, add a parameter `gemini_model` (String) in the console, *Run → Remote Config*, with the value `gemini-3.5-flash-lite`, and **Publish**. Change it to `gemini-3.5-flash`, publish, tap **New chat** and ask something. The header shows which model answered. |
| `dart run tool/step.dart 6` | **New skills with no app update: MCP** | A small server (running on your own laptop) offers a tool: *naira → dollars*. Your app asks "what can you do?" and hands the answer to Gemini. |

**Step 6 needs the little server running.** In a **second terminal** (leave it open):
```sh
cd mcp-server
npm start          # you should see: MCP server listening on :8080
```
Then, in the project folder, run the app and tell it where the server is:
```sh
flutter run -d chrome --dart-define=MCP_URL=http://localhost:8080/mcp
```
(Android emulator? Use `http://10.0.2.2:8080/mcp`.) In the app tap **New chat**, add an expense like *"I spent ₦4,000 on lunch"*, then ask: *"Convert my food total to dollars."*

**Want to try more after step 6?** Add a tool of your own: *"What was my biggest expense this week?"* The pattern is the same: declare, run in Dart, send the result back.

---

## When something goes wrong

| You see | Why | Fix |
|---|---|---|
| *"Firebase isn't connected yet, so nothing is saved"* | Firebase didn't start | Re-run `flutterfire configure`, then restart the app. Look at the terminal for the real reason. |
| Chat says *"I couldn't reach the assistant"* | Usually AI Logic not enabled, or App Check switched on. In a debug run, the real reason is printed under the message | Console → AI Logic is set up? *App Check → APIs →* the **Firebase AI Logic** row must say **Monitoring** (not *Enforced*) |
| The message mentions *"App Check"*, *"attestation"* or *403* | App Check is *Enforced* on your project, and this app doesn't use it | *Console → App Check → APIs →* the **Firebase AI Logic** row → **Unenforce**, so it says **Monitoring**. Wait a minute, ask again |
| *"The project does not exist or you do not have permission"* in the console | The browser is signed in to a different Google account | Switch to the account that created the project (profile picture, top right) |
| The app is slow to start or won't start | Not enough memory, or the device is still starting up | Wait until your device is fully started and `flutter devices` lists it. Close other heavy apps |
| `dart run tool/step.dart 3` says it can't find files | You are not in the project folder | `cd` into the folder that contains `pubspec.yaml`, then run it again |
| Expenses don't save, toast says *"Couldn't save"* | Firestore rules not deployed, or no connection | `firebase deploy --only firestore:rules --project YOUR_PROJECT_ID` |
| *"model not found"* in the terminal | Typo in the `gemini_model` Remote Config value | Use exactly `gemini-3.5-flash-lite` or `gemini-3.5-flash` |
| The MCP tool is never used | The app reads the tool list when a chat starts | Tap **New chat**; check the address ends in `/mcp` |
| Nothing works and the Wi-Fi is crowded | 100 people, one router | `flutter run --dart-define=SPENDWISE_OFFLINE_DEMO=true` runs everything offline with sample expenses and a scripted chatbot |

Handy switches: `--dart-define=SPENDWISE_OFFLINE_DEMO=true` (no Firebase at all) and `--dart-define=SPENDWISE_MOCK_AI=true` (Firebase, but the scripted chatbot instead of Gemini).
