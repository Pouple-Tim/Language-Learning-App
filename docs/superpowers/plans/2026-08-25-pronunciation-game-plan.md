# Pronunciation Game Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a new "pronunciation" game mode — see a HSK1 word's hanzi and pinyin, hold a mic button and say it aloud, get basic speech-to-text feedback (right word / wrong word, no tone scoring) — as a new `GameType` plugged into the existing game architecture.

**Architecture:** A new `GameType.pronunciation` enum value reuses `GameProvider.checkAnswer` untouched (it already compares the spoken text, once transcribed, against `currentWord.answer` exactly the same way it compares typed text — no new comparison logic needed). A new `SpeechService` (static wrapper around `speech_to_text`) starts/stops a push-to-talk recording and reports the finalized transcript. Two new widgets: `PronunciationPromptCard` (shows hanzi + pinyin, unlike the listening game which hides both) and `PronunciationWidget` (the push-to-talk mic button, replacing `QuizWidget`/`TextInputWidget` for this mode). No deck/JSON schema changes.

**Tech Stack:** Flutter/Dart, `provider` for state, `speech_to_text` (new dependency) for on-device speech recognition, `flutter_test` for tests (no mocking framework — this repo constructs real objects, see existing `test/providers/game_provider_test.dart`).

**Spec:** `docs/superpowers/specs/2026-08-24-listening-pronunciation-games-design.md` (section "Pronunciation game")

## Global Constraints

- Dart SDK `>=3.8.0 <4.0.0` (from `pubspec.yaml`).
- No mocking framework in this repo's tests — construct real `Deck`/`Word`/`GameProvider` objects, per existing test files.
- Every `GameType` switch in the codebase is exhaustive (compiler-enforced): `lib/data/models/game_mode.dart` (`badgeLabel`, `statsLabel`), `lib/screens/games/classic_game/game_screen.dart` (`_buildGameInputArea`), `lib/screens/stats/widgets/game_mode_stats_widget.dart` (`_getModeColor`, `_getModeIcon`). Adding the enum value means filling in every one of these, not just the ones this plan's feature code touches.
- Recognition compares against `Word.answer` (hanzi), never `Word.prompt` (pinyin) — same rule as the listening game's TTS, mirrored here for the mic input.
- No tone scoring — exact/near text match only, reusing `GameProvider.checkAnswer`'s existing exact-match logic as-is (per spec: "V1 pronunciation is 'did you say the right word' via basic speech-to-text, not 'did you say it correctly'").
- Incorrect attempt retries the same word (no `resetCurrentWord`/`spinWheel` call); correct attempt advances like every other mode.
- Work happens on a new branch off `develop`, per this repo's git-flow (`develop` persistent, never delete it; see project memory `project-branch-workflow`).
- No automated test for `SpeechService`/`PronunciationWidget` — platform-channel/widget code isn't unit-tested in this repo (same precedent as `TtsService`/`ListenPromptCard` in the listening game plan). Manual verification step is Task 6.

---

### Task 1: Create the feature branch

**Files:** none (git only).

- [ ] **Step 1: Switch to `develop` and pull latest**

```bash
git checkout develop
git pull origin develop
```

- [ ] **Step 2: Create and switch to the feature branch**

```bash
git checkout -b feature/pronunciation-game
```

- [ ] **Step 3: Verify**

```bash
git branch --show-current
```

Expected: `feature/pronunciation-game`

---

### Task 2: `speech_to_text` dependency + `SpeechService` + platform permissions

**Files:**
- Modify: `pubspec.yaml`
- Modify: `android/app/src/main/AndroidManifest.xml`
- Modify: `ios/Runner/Info.plist`
- Create: `lib/core/audio/speech_service.dart`

**Interfaces:**
- Produces: `SpeechService.startListening(void Function(String recognizedWords) onFinalResult) -> Future<bool>` (returns `false` if the mic/recognizer isn't available — caller should show an error), `SpeechService.stopListening() -> Future<void>`. Later tasks call these from `PronunciationWidget`.

- [ ] **Step 1: Add the dependency**

In `pubspec.yaml`, after the `flutter_tts: ^4.2.5` line (inside `dependencies:`), add:

```yaml
  # Audio (jeu de prononciation)
  speech_to_text: ^7.4.0
```

- [ ] **Step 2: Fetch packages**

```bash
flutter pub get
```

Expected: completes without error, `pubspec.lock` updated.

- [ ] **Step 3: Add the Android `RECORD_AUDIO` permission**

In `android/app/src/main/AndroidManifest.xml`, change:

```xml
    <uses-permission android:name="android.permission.INTERNET"/>
```

to:

```xml
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.RECORD_AUDIO"/>
```

- [ ] **Step 4: Add the iOS microphone/speech-recognition usage descriptions**

In `ios/Runner/Info.plist`, change:

```xml
	<key>UIApplicationSupportsIndirectInputEvents</key>
	<true/>
</dict>
```

to:

```xml
	<key>UIApplicationSupportsIndirectInputEvents</key>
	<true/>
	<key>NSMicrophoneUsageDescription</key>
	<string>Microphone access is needed for the pronunciation game.</string>
	<key>NSSpeechRecognitionUsageDescription</key>
	<string>Speech recognition is needed to check your pronunciation.</string>
</dict>
```

- [ ] **Step 5: Write `SpeechService`**

Create `lib/core/audio/speech_service.dart`:

```dart
import 'package:speech_to_text/speech_to_text.dart';

/// Push-to-talk speech recognition for the pronunciation game, using the
/// device's native zh-CN speech engine. One shared SpeechToText instance,
/// availability (and the OS permission prompt) checked lazily on first use.
class SpeechService {
  static final SpeechToText _speech = SpeechToText();
  static bool _available = false;
  static bool _checkedAvailability = false;

  static Future<bool> _ensureInitialized() async {
    if (!_checkedAvailability) {
      _available = await _speech.initialize();
      _checkedAvailability = true;
    }
    return _available;
  }

  /// Starts a listening session. [onFinalResult] is called once, with the
  /// recognized text, when the session ends (either the recognizer detects
  /// end of speech on its own, or [stopListening] is called) -- never with
  /// interim/partial results.
  ///
  /// Returns `false` (without calling [onFinalResult]) if the microphone or
  /// speech recognizer isn't available -- the caller should surface an error
  /// in that case.
  static Future<bool> startListening(void Function(String recognizedWords) onFinalResult) async {
    final available = await _ensureInitialized();
    if (!available) return false;

    await _speech.listen(
      localeId: 'zh-CN',
      onResult: (result) {
        if (result.finalResult) {
          onFinalResult(result.recognizedWords);
        }
      },
    );
    return true;
  }

  static Future<void> stopListening() => _speech.stop();
}
```

- [ ] **Step 6: Run analyzer**

```bash
flutter analyze lib/core/audio/speech_service.dart
```

Expected: `No issues found!`

- [ ] **Step 7: Commit**

```bash
git add pubspec.yaml pubspec.lock android/app/src/main/AndroidManifest.xml ios/Runner/Info.plist lib/core/audio/speech_service.dart
git commit -m "feat: add speech_to_text dependency, SpeechService, and mic permissions"
```

---

### Task 3: `GameType.pronunciation` enum value

**Files:**
- Modify: `lib/data/models/game_mode.dart`
- Modify: `lib/screens/stats/widgets/game_mode_stats_widget.dart`
- Modify: `lib/screens/settings/widgets/reset_deck_dialog.dart`

**Interfaces:**
- Produces: `GameType.pronunciation`, `.storageId == 'pronunciation'`, `.badgeLabel == 'PRONONCIATION'`, `.statsLabel == 'Prononciation'`.

- [ ] **Step 1: Add the enum value**

In `lib/data/models/game_mode.dart`, change:

```dart
enum GameType {
  classic,
  reverse,
  quiz,
  sentence,
  listening,
  memory, // Futur
}
```

to:

```dart
enum GameType {
  classic,
  reverse,
  quiz,
  sentence,
  listening,
  pronunciation,
  memory, // Futur
}
```

- [ ] **Step 2: Fill in `badgeLabel`**

In the same file's `badgeLabel` switch, add a case before `case GameType.memory:`:

```dart
      case GameType.pronunciation:
        return 'PRONONCIATION';
```

- [ ] **Step 3: Fill in `statsLabel`**

In the same file's `statsLabel` switch, add a case before `case GameType.memory:`:

```dart
      case GameType.pronunciation:
        return 'Prononciation';
```

- [ ] **Step 4: Run the existing generic test (already covers the new value, no edits needed)**

```bash
flutter test test/data/models/game_mode_test.dart
```

Expected: all tests PASS, exercising `pronunciation` automatically via the `GameType.values` loops.

- [ ] **Step 5: Fix the now-broken exhaustive switch in `game_mode_stats_widget.dart`**

In `lib/screens/stats/widgets/game_mode_stats_widget.dart`, change:

```dart
  Color _getModeColor(GameType type) {
    switch (type) {
      case GameType.classic:
        return AppColors.primary;
      case GameType.reverse:
        return AppColors.secondary;
      case GameType.quiz:
        return Colors.orange;
      case GameType.sentence:
      case GameType.listening:
      case GameType.memory:
        return Colors.teal;
    }
  }

  IconData _getModeIcon(GameType type) {
    switch (type) {
      case GameType.classic:
        return Icons.school;
      case GameType.reverse:
        return Icons.swap_horiz;
      case GameType.quiz:
        return Icons.timer;
      case GameType.sentence:
      case GameType.listening:
      case GameType.memory:
        return Icons.gamepad;
    }
  }
```

to:

```dart
  Color _getModeColor(GameType type) {
    switch (type) {
      case GameType.classic:
        return AppColors.primary;
      case GameType.reverse:
        return AppColors.secondary;
      case GameType.quiz:
        return Colors.orange;
      case GameType.pronunciation:
        return Colors.pink;
      case GameType.sentence:
      case GameType.listening:
      case GameType.memory:
        return Colors.teal;
    }
  }

  IconData _getModeIcon(GameType type) {
    switch (type) {
      case GameType.classic:
        return Icons.school;
      case GameType.reverse:
        return Icons.swap_horiz;
      case GameType.quiz:
        return Icons.timer;
      case GameType.pronunciation:
        return Icons.mic_rounded;
      case GameType.sentence:
      case GameType.listening:
      case GameType.memory:
        return Icons.gamepad;
    }
  }
```

- [ ] **Step 6: Add the mode to the reset-progress dialog's resettable list**

In `lib/screens/settings/widgets/reset_deck_dialog.dart`, change:

```dart
    final resettableModes = [GameType.classic, GameType.reverse, GameType.quiz, GameType.sentence, GameType.listening]
        .where((type) => type != GameType.sentence || deck.sentences.isNotEmpty)
        .toList();
```

to:

```dart
    final resettableModes = [
      GameType.classic,
      GameType.reverse,
      GameType.quiz,
      GameType.sentence,
      GameType.listening,
      GameType.pronunciation,
    ].where((type) => type != GameType.sentence || deck.sentences.isNotEmpty).toList();
```

- [ ] **Step 7: Run the full analyzer (catches any other switch this plan hasn't listed)**

```bash
flutter analyze
```

Expected: two known errors remain -- non-exhaustive switch in `lib/screens/games/classic_game/game_screen.dart:_buildGameInputArea` (Task 5 fixes it) and any reference to widgets/l10n keys not yet created (Tasks 4/5/6). No "non-exhaustive switch" errors anywhere outside `game_screen.dart` -- if any appear, that's a gap to fix in this task before moving on.

- [ ] **Step 8: Commit**

```bash
git add lib/data/models/game_mode.dart lib/screens/stats/widgets/game_mode_stats_widget.dart lib/screens/settings/widgets/reset_deck_dialog.dart
git commit -m "feat: add GameType.pronunciation"
```

---

### Task 4: `PronunciationPromptCard` widget (hanzi + pinyin display)

**Files:**
- Create: `lib/screens/games/classic_game/widgets/pronunciation_prompt_card.dart`
- Modify: `lib/screens/games/classic_game/game_screen.dart`

**Interfaces:**
- Consumes: `GameProvider.currentWord` (existing).
- Produces: `const PronunciationPromptCard()` -- a self-contained widget, no constructor params.

- [ ] **Step 1: Write `PronunciationPromptCard`**

Create `lib/screens/games/classic_game/widgets/pronunciation_prompt_card.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:language_learning_app/core/theme/app_colors.dart';
import 'package:language_learning_app/providers/game_provider.dart';

/// Replaces the text prompt card for GameType.pronunciation: shows both the
/// hanzi and the pinyin -- unlike the listening game, there's no ambiguity
/// to preserve here, the point is producing the right sound, not recalling
/// the character.
class PronunciationPromptCard extends StatelessWidget {
  const PronunciationPromptCard({super.key});

  @override
  Widget build(BuildContext context) {
    final word = context.watch<GameProvider>().currentWord;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 500),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              word?.answer ?? '',
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            word?.prompt ?? '',
            style: const TextStyle(fontSize: 18, color: Colors.white70, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Wire it into `GameScreen._buildWordDisplay`**

In `lib/screens/games/classic_game/game_screen.dart`, add the import after `import 'widgets/listen_prompt_card.dart';`:

```dart
import 'widgets/pronunciation_prompt_card.dart';
```

Change:

```dart
  Widget _buildWordDisplay(BuildContext context, GameProvider gameProvider) {
    final l10n = AppLocalizations.of(context)!;
    final isListening = gameProvider.currentGameType == GameType.listening;

    return Column(
      children: [
        if (isListening)
          const ListenPromptCard()
        else
```

to:

```dart
  Widget _buildWordDisplay(BuildContext context, GameProvider gameProvider) {
    final l10n = AppLocalizations.of(context)!;
    final isListening = gameProvider.currentGameType == GameType.listening;
    final isPronunciation = gameProvider.currentGameType == GameType.pronunciation;

    return Column(
      children: [
        if (isListening)
          const ListenPromptCard()
        else if (isPronunciation)
          const PronunciationPromptCard()
        else
```

And change the trailing "Change word" button condition:

```dart
        if (gameProvider.currentGameType != GameType.quiz &&
            gameProvider.currentGameType != GameType.sentence &&
            gameProvider.currentGameType != GameType.listening)
```

to:

```dart
        if (gameProvider.currentGameType != GameType.quiz &&
            gameProvider.currentGameType != GameType.sentence &&
            gameProvider.currentGameType != GameType.listening &&
            gameProvider.currentGameType != GameType.pronunciation)
```

- [ ] **Step 3: Skip `flutter analyze` here -- `_buildGameInputArea`'s switch is still non-exhaustive until Task 5.**

- [ ] **Step 4: Commit**

```bash
git add lib/screens/games/classic_game/widgets/pronunciation_prompt_card.dart lib/screens/games/classic_game/game_screen.dart
git commit -m "feat: add PronunciationPromptCard, show hanzi+pinyin for pronunciation mode"
```

---

### Task 5: `PronunciationWidget` (push-to-talk mic input) + wire into `GameScreen`

**Files:**
- Create: `lib/screens/games/classic_game/widgets/pronunciation_widget.dart`
- Modify: `lib/screens/games/classic_game/game_screen.dart`

**Interfaces:**
- Consumes: `SpeechService.startListening`/`stopListening` (Task 2), `GameProvider.checkAnswer`/`resetCurrentWord`/`spinWheel`/`remainingWords` (existing), `AppLocalizations.pronunciationHoldToSpeak`/`pronunciationListening`/`pronunciationMicUnavailable` (Task 6 adds the arb keys; this task references the getters, Task 6's `flutter gen-l10n` step is what actually makes them compile).
- Produces: `const PronunciationWidget()` -- a self-contained widget, no constructor params.

- [ ] **Step 1: Write `PronunciationWidget`**

Create `lib/screens/games/classic_game/widgets/pronunciation_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:language_learning_app/core/audio/speech_service.dart';
import 'package:language_learning_app/core/theme/app_colors.dart';
import 'package:language_learning_app/providers/game_provider.dart';
import 'package:language_learning_app/l10n/app_localizations.dart';

/// Push-to-talk input for GameType.pronunciation: hold the mic button to
/// record, release to stop and run recognition. Correct -> advance like
/// every other mode. Incorrect -> retry the same word (no tone scoring,
/// no partial credit -- see the pronunciation game design spec).
class PronunciationWidget extends StatefulWidget {
  const PronunciationWidget({super.key});

  @override
  State<PronunciationWidget> createState() => _PronunciationWidgetState();
}

class _PronunciationWidgetState extends State<PronunciationWidget> {
  bool _isListening = false;
  bool _isChecked = false;
  bool _lastCorrect = false;

  Future<void> _handleFinalResult(String recognizedWords, GameProvider provider) async {
    final isCorrect = await provider.checkAnswer(recognizedWords);
    if (!mounted) return;

    setState(() {
      _isListening = false;
      _isChecked = true;
      _lastCorrect = isCorrect;
    });

    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    setState(() => _isChecked = false);

    if (isCorrect) {
      provider.resetCurrentWord();
      if (provider.remainingWords > 0) {
        provider.spinWheel();
      }
    }
    // Incorrect: nothing to reset -- the word stays current, user retries.
  }

  Future<void> _startRecording(GameProvider provider) async {
    setState(() => _isListening = true);
    final started = await SpeechService.startListening((text) => _handleFinalResult(text, provider));
    if (!started && mounted) {
      final l10n = AppLocalizations.of(context)!;
      setState(() => _isListening = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pronunciationMicUnavailable), backgroundColor: AppColors.error),
      );
    }
  }

  void _stopRecording() {
    SpeechService.stopListening();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<GameProvider>();

    Color color = AppColors.primary;
    if (_isChecked) {
      color = _lastCorrect ? AppColors.success : AppColors.error;
    } else if (_isListening) {
      color = AppColors.secondary;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onLongPressStart: _isChecked ? null : (_) => _startRecording(provider),
          onLongPressEnd: _isChecked ? null : (_) => _stopRecording(),
          child: CircleAvatar(
            radius: 40,
            backgroundColor: color,
            child: Icon(
              _isListening ? Icons.mic : Icons.mic_none_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _isListening ? l10n.pronunciationListening : l10n.pronunciationHoldToSpeak,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Wire it into `GameScreen._buildGameInputArea`**

In `lib/screens/games/classic_game/game_screen.dart`, add the import after `import 'widgets/pronunciation_prompt_card.dart';`:

```dart
import 'widgets/pronunciation_widget.dart';
```

Change:

```dart
  Widget _buildGameInputArea(BuildContext context, GameProvider gameProvider) {
    switch (gameProvider.currentGameType) {
      case GameType.quiz:
      case GameType.listening:
        return const QuizWidget();
      case GameType.sentence:
        return const SentenceBuilderWidget();
      case GameType.classic:
      case GameType.reverse:
      case GameType.memory:
      case null:
        return gameProvider.activeInputType == InputType.text
            ? const TextInputWidget()
            : const DrawingWidget();
    }
  }
```

to:

```dart
  Widget _buildGameInputArea(BuildContext context, GameProvider gameProvider) {
    switch (gameProvider.currentGameType) {
      case GameType.quiz:
      case GameType.listening:
        return const QuizWidget();
      case GameType.pronunciation:
        return const PronunciationWidget();
      case GameType.sentence:
        return const SentenceBuilderWidget();
      case GameType.classic:
      case GameType.reverse:
      case GameType.memory:
      case null:
        return gameProvider.activeInputType == InputType.text
            ? const TextInputWidget()
            : const DrawingWidget();
    }
  }
```

- [ ] **Step 3: Analyzer will currently fail on the missing l10n getters -- expected, Task 6 adds them next.** Skip running `flutter analyze` here.

- [ ] **Step 4: Commit**

```bash
git add lib/screens/games/classic_game/widgets/pronunciation_widget.dart lib/screens/games/classic_game/game_screen.dart
git commit -m "feat: add PronunciationWidget, wire GameType.pronunciation into GameScreen"
```

---

### Task 6: Home screen card + l10n

**Files:**
- Modify: `lib/screens/home/home_screen.dart`
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_fr.arb`, `lib/l10n/app_es.arb`, `lib/l10n/app_it.arb`

**Interfaces:**
- Consumes: `GameType.pronunciation` (Task 3).
- Produces: `AppLocalizations.pronunciationModeTitle`, `.pronunciationModeDesc`, `.pronunciationHoldToSpeak`, `.pronunciationListening`, `.pronunciationMicUnavailable` -- the latter three consumed by `PronunciationWidget` (Task 5).

- [ ] **Step 1: Add arb keys -- `lib/l10n/app_en.arb`**

After the line `"listenButtonTooltip": "Play pronunciation",`, add:

```json
  "pronunciationModeTitle": "Pronunciation",
  "pronunciationModeDesc": "Say the word out loud.",
  "pronunciationHoldToSpeak": "Hold to speak",
  "pronunciationListening": "Listening...",
  "pronunciationMicUnavailable": "Microphone unavailable. Check app permissions.",
```

- [ ] **Step 2: Add arb keys -- `lib/l10n/app_fr.arb`**

After the line `"listenButtonTooltip": "Jouer la prononciation",`, add:

```json
  "pronunciationModeTitle": "Prononciation",
  "pronunciationModeDesc": "Prononce le mot à voix haute.",
  "pronunciationHoldToSpeak": "Maintenir pour parler",
  "pronunciationListening": "Écoute en cours...",
  "pronunciationMicUnavailable": "Microphone indisponible. Vérifie les autorisations de l'application.",
```

- [ ] **Step 3: Add arb keys -- `lib/l10n/app_es.arb`**

After the line `"listenButtonTooltip": "Reproducir pronunciación",`, add:

```json
    "pronunciationModeTitle": "Pronunciación",
    "pronunciationModeDesc": "Di la palabra en voz alta.",
    "pronunciationHoldToSpeak": "Mantén para hablar",
    "pronunciationListening": "Escuchando...",
    "pronunciationMicUnavailable": "Micrófono no disponible. Comprueba los permisos de la aplicación.",
```

- [ ] **Step 4: Add arb keys -- `lib/l10n/app_it.arb`**

After the line `"listenButtonTooltip": "Riproduci pronuncia",`, add:

```json
  "pronunciationModeTitle": "Pronuncia",
  "pronunciationModeDesc": "Pronuncia la parola ad alta voce.",
  "pronunciationHoldToSpeak": "Tieni premuto per parlare",
  "pronunciationListening": "In ascolto...",
  "pronunciationMicUnavailable": "Microfono non disponibile. Controlla i permessi dell'app.",
```

- [ ] **Step 5: Regenerate localizations**

```bash
flutter gen-l10n
```

Expected: completes without error, regenerates `lib/l10n/app_localizations*.dart` with the five new getters.

- [ ] **Step 6: Add the home screen card**

In `lib/screens/home/home_screen.dart`'s `_buildGameModes`, add a new entry after the `GameType.listening` entry:

```dart
    GameMode(
      type: GameType.pronunciation,
      title: l10n.pronunciationModeTitle,
      description: l10n.pronunciationModeDesc,
      icon: Icons.mic_rounded,
      color: Colors.pink,
    ),
```

- [ ] **Step 7: Run the full analyzer**

```bash
flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 8: Run the full test suite**

```bash
flutter test
```

Expected: all PASS.

- [ ] **Step 9: Commit**

```bash
git add lib/screens/home/home_screen.dart lib/l10n/
git commit -m "feat: add pronunciation mode card and localized strings"
```

---

### Task 7: Manual verification and push

**Files:** none.

- [ ] **Step 1: Manual verification on Android (mic input requires a real device -- desktop/simulator mics are unreliable for this)**

Build and install on the connected Android phone:

```bash
flutter run -d <android-device-id>
```

(`flutter devices` lists the id if unknown.) Walk through: Home screen shows a "Prononciation" card → select an HSK1 deck → tap the card → grant the microphone permission prompt on first use → confirm the card shows both hanzi and pinyin → hold the mic button, say the hanzi aloud, release → confirm correct/incorrect coloring and that the correct case advances to the next word while the incorrect case keeps the same word for a retry.

- [ ] **Step 2: Verify the permission-denied path**

In the device's app settings, revoke the microphone permission, then retry the mic button in-app. Expected: the "microphone unavailable" snackbar appears (from `PronunciationWidget._startRecording`), no crash.

- [ ] **Step 3: Push the branch**

```bash
git push -u origin feature/pronunciation-game
```

- [ ] **Step 4: Open a PR from `feature/pronunciation-game` into `develop`** (not `main` -- matches this repo's git-flow)

```bash
gh pr create --base develop --head feature/pronunciation-game --title "feat: add pronunciation game mode" --body "Adds a new pronunciation practice mode: see a HSK1 word's hanzi+pinyin, hold a mic button and say it aloud, get basic speech-to-text feedback (right word / wrong word, no tone scoring). See docs/superpowers/specs/2026-08-24-listening-pronunciation-games-design.md for the full design (this PR is the pronunciation-game follow-up to the already-merged listening game)."
```
