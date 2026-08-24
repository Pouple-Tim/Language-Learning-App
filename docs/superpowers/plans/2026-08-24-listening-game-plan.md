# Listening Game Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a new "listening" game mode — hear a HSK1 word's hanzi spoken aloud via TTS, pick the matching hanzi among 4 options — as a new `GameType` plugged into the existing quiz-style game architecture.

**Architecture:** A new `GameType.listening` enum value reuses `GameProvider`'s existing quiz-option-generation and answer-checking untouched. A new `TtsService` (static wrapper around `flutter_tts`) speaks `Word.answer` (the hanzi) on a manual "Écouter" button tap. The answer UI reuses the existing `QuizWidget` unchanged. No deck/JSON schema changes.

**Tech Stack:** Flutter/Dart, `provider` for state, `flutter_tts` (new dependency) for speech synthesis, `flutter_test` for tests (no mocking framework — this repo constructs real objects, see existing `test/providers/game_provider_test.dart`).

**Spec:** `docs/superpowers/specs/2026-08-24-listening-pronunciation-games-design.md`

## Global Constraints

- Dart SDK `>=3.8.0 <4.0.0` (from `pubspec.yaml`).
- No mocking framework in this repo's tests — construct real `Deck`/`Word`/`GameProvider` objects, per existing test files.
- Every `GameType` switch in the codebase is exhaustive (compiler-enforced) — adding the enum value means filling in every `switch`, not just the ones this plan touches.
- TTS speaks `Word.answer` (hanzi), never `Word.prompt` (romanized pinyin) — a `zh-CN` voice would mispronounce/misread the latter.
- Work happens on a new branch off `develop`, per this repo's git-flow (`develop` persistent, never delete it; see project memory `project-branch-workflow`).
- No automated test for `TtsService`/`ListenPromptCard` — platform-channel/widget code isn't unit-tested in this repo (see `docs/superpowers/specs/2026-08-21-phase2-supabase-decks-design.md`'s Testing section: "No widget/integration tests... verified via `flutter analyze` + `flutter test` plus a manual pass"). Manual verification step is Task 6.

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
git checkout -b feature/listening-game
```

- [ ] **Step 3: Verify**

```bash
git branch --show-current
```

Expected: `feature/listening-game`

---

### Task 2: `flutter_tts` dependency + `TtsService`

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/core/audio/tts_service.dart`

**Interfaces:**
- Produces: `TtsService.speak(String text) -> Future<void>` — later tasks call this with a hanzi string.

- [ ] **Step 1: Add the dependency**

In `pubspec.yaml`, after the `tutorial_coach_mark: ^1.3.3` line (inside `dependencies:`), add:

```yaml
  # Audio (jeu d'écoute)
  flutter_tts: ^4.2.5
```

- [ ] **Step 2: Fetch packages**

```bash
flutter pub get
```

Expected: completes without error, `pubspec.lock` updated.

- [ ] **Step 3: Write `TtsService`**

Create `lib/core/audio/tts_service.dart`:

```dart
import 'package:flutter_tts/flutter_tts.dart';

/// Speaks Chinese text aloud for the listening game, using the device's
/// native zh-CN voice engine. One shared FlutterTts instance, language
/// configured once on first use.
class TtsService {
  static final FlutterTts _tts = FlutterTts();
  static bool _languageSet = false;

  /// Speaks [text] (expected to be Chinese hanzi, e.g. a Word.answer —
  /// not romanized pinyin, which a zh-CN voice would mispronounce).
  static Future<void> speak(String text) async {
    if (!_languageSet) {
      await _tts.setLanguage('zh-CN');
      _languageSet = true;
    }
    await _tts.stop();
    await _tts.speak(text);
  }
}
```

- [ ] **Step 4: Run analyzer**

```bash
flutter analyze lib/core/audio/tts_service.dart
```

Expected: `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/core/audio/tts_service.dart
git commit -m "feat: add flutter_tts dependency and TtsService"
```

---

### Task 3: `GameType.listening` enum value

**Files:**
- Modify: `lib/data/models/game_mode.dart`

**Interfaces:**
- Produces: `GameType.listening`, `GameType.listening.storageId == 'listening'`, `.badgeLabel == 'ÉCOUTE'`, `.statsLabel == 'Écoute'`.

- [ ] **Step 1: Add the enum value**

In `lib/data/models/game_mode.dart`, change:

```dart
enum GameType {
  classic,
  reverse,
  quiz,
  sentence,
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
  memory, // Futur
}
```

- [ ] **Step 2: Fill in `badgeLabel`**

In the same file's `badgeLabel` switch, add a case before `case GameType.memory:`:

```dart
      case GameType.listening:
        return 'ÉCOUTE';
```

- [ ] **Step 3: Fill in `statsLabel`**

In the same file's `statsLabel` switch, add a case before `case GameType.memory:`:

```dart
      case GameType.listening:
        return 'Écoute';
```

- [ ] **Step 4: Run the existing generic test (already covers the new value, no edits needed)**

```bash
flutter test test/data/models/game_mode_test.dart
```

Expected: all tests PASS, including `'classic has no badge label, every other mode has one'` and `'every GameType has a non-empty statsLabel'` — both loop over `GameType.values` and will exercise `listening` automatically.

- [ ] **Step 5: Run analyzer (catches any switch you forgot elsewhere in the codebase)**

```bash
flutter analyze
```

Expected: no "non-exhaustive switch" errors. If any appear outside this plan's files, note the file/line — later tasks in this plan handle `game_screen.dart` and `game_provider.dart`; anything else is a gap to fix in this task before moving on.

- [ ] **Step 6: Commit**

```bash
git add lib/data/models/game_mode.dart
git commit -m "feat: add GameType.listening"
```

---

### Task 4: `GameProvider` — generate quiz options for listening mode

**Files:**
- Modify: `lib/providers/game_provider.dart:210-212`
- Test: `test/providers/game_provider_test.dart`

**Interfaces:**
- Consumes: `GameType.listening` (Task 3).
- Produces: after `spinWheel()` with `currentGameType == GameType.listening`, `quizOptions` is populated exactly like quiz mode (4 options, includes `currentWord!.answer`) — `ListenPromptCard`/`QuizWidget` (Task 5) rely on this.

- [ ] **Step 1: Write the failing test**

In `test/providers/game_provider_test.dart`, add a new group after the `'GameProvider - quiz mode'` group (after line 201, before `group('GameProvider.resetDeck'...)`):

```dart
  group('GameProvider - listening mode', () {
    test('spinWheel in listening mode populates 4 quiz options including the correct answer', () async {
      final provider = GameProvider();
      await provider.setDeck(_buildDeck(wordCount: 5), gameMode: GameType.listening);
      await provider.spinWheel();

      expect(provider.quizOptions.length, 4);
      expect(provider.quizOptions.contains(provider.currentWord!.answer), isTrue);
    });
  });
```

- [ ] **Step 2: Run it to verify it fails**

```bash
flutter test test/providers/game_provider_test.dart --plain-name "listening mode"
```

Expected: FAIL — `quizOptions.length` is `0`, not `4` (listening mode doesn't populate options yet).

- [ ] **Step 3: Implement — extend the `spinWheel` branch**

In `lib/providers/game_provider.dart`, change (around line 210):

```dart
    if (_currentGameType == GameType.quiz) {
      _generateQuizOptions(activeWords);
    }
```

to:

```dart
    if (_currentGameType == GameType.quiz || _currentGameType == GameType.listening) {
      _generateQuizOptions(activeWords);
    }
```

- [ ] **Step 4: Run the test to verify it passes**

```bash
flutter test test/providers/game_provider_test.dart --plain-name "listening mode"
```

Expected: PASS

- [ ] **Step 5: Run the full provider test file to check nothing else broke**

```bash
flutter test test/providers/game_provider_test.dart
```

Expected: all PASS

- [ ] **Step 6: Commit**

```bash
git add lib/providers/game_provider.dart test/providers/game_provider_test.dart
git commit -m "feat: generate quiz options for listening mode"
```

---

### Task 5: `ListenPromptCard` widget + wire into `GameScreen`

**Files:**
- Create: `lib/screens/games/classic_game/widgets/listen_prompt_card.dart`
- Modify: `lib/screens/games/classic_game/game_screen.dart`

**Interfaces:**
- Consumes: `TtsService.speak` (Task 2), `GameProvider.currentWord`/`currentGameType`/`quizOptions` (Task 4), `AppLocalizations.listenButtonLabel`/`listenButtonTooltip` (Task 6 — this task references them; Task 6 adds the arb keys before this task's l10n regen step).
- Produces: `const ListenPromptCard()` — a self-contained widget, no constructor params.

- [ ] **Step 1: Write `ListenPromptCard`**

Create `lib/screens/games/classic_game/widgets/listen_prompt_card.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:language_learning_app/core/audio/tts_service.dart';
import 'package:language_learning_app/core/theme/app_colors.dart';
import 'package:language_learning_app/providers/game_provider.dart';
import 'package:language_learning_app/l10n/app_localizations.dart';

/// Replaces the text prompt card for GameType.listening: no word text is
/// shown (that would defeat a listening exercise) — just a speaker button
/// the user taps to play/replay the current word's pronunciation.
class ListenPromptCard extends StatelessWidget {
  const ListenPromptCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
          IconButton(
            iconSize: 56,
            color: Colors.white,
            icon: const Icon(Icons.volume_up_rounded),
            tooltip: l10n.listenButtonTooltip,
            onPressed: word == null ? null : () => TtsService.speak(word.answer),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.listenButtonLabel,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Wire it into `GameScreen._buildWordDisplay`**

In `lib/screens/games/classic_game/game_screen.dart`, add the import near the other widget imports (after `import 'widgets/quiz_widget.dart';`):

```dart
import 'widgets/listen_prompt_card.dart';
```

Replace `_buildWordDisplay` (lines 213-260) with:

```dart
  Widget _buildWordDisplay(BuildContext context, GameProvider gameProvider) {
    final l10n = AppLocalizations.of(context)!;
    final isListening = gameProvider.currentGameType == GameType.listening;

    return Column(
      children: [
        if (isListening)
          const ListenPromptCard()
        else
          Container(
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
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    gameProvider.currentQuestionText,
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        if (gameProvider.currentGameType != GameType.quiz &&
            gameProvider.currentGameType != GameType.sentence &&
            gameProvider.currentGameType != GameType.listening)
          TextButton.icon(
            onPressed: gameProvider.resetCurrentWord,
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(l10n.changeWord),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            ),
          ),
      ],
    );
  }
```

- [ ] **Step 3: Wire it into `GameScreen._buildGameInputArea`**

In the same file, replace the `_buildGameInputArea` switch (lines 197-211):

```dart
  Widget _buildGameInputArea(BuildContext context, GameProvider gameProvider) {
    switch (gameProvider.currentGameType) {
      case GameType.quiz:
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

with:

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

- [ ] **Step 4: Analyzer will currently fail on the missing l10n getters — expected, Task 6 adds them next.** Skip running `flutter analyze` here; it's run at the end of Task 6.

- [ ] **Step 5: Commit**

```bash
git add lib/screens/games/classic_game/widgets/listen_prompt_card.dart lib/screens/games/classic_game/game_screen.dart
git commit -m "feat: add ListenPromptCard, wire GameType.listening into GameScreen"
```

---

### Task 6: Home screen card + l10n

**Files:**
- Modify: `lib/screens/home/home_screen.dart`
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_fr.arb`, `lib/l10n/app_es.arb`, `lib/l10n/app_it.arb`

**Interfaces:**
- Consumes: `GameType.listening` (Task 3).
- Produces: `AppLocalizations.listeningModeTitle`, `.listeningModeDesc`, `.listenButtonLabel`, `.listenButtonTooltip` — the last two consumed by `ListenPromptCard` (Task 5).

- [ ] **Step 1: Add arb keys — `lib/l10n/app_en.arb`**

After the line `"quizModeDesc": "Choose the correct answer from 4 options.",`, add:

```json
  "listeningModeTitle": "Listening",
  "listeningModeDesc": "Listen and pick the right character.",
  "listenButtonLabel": "Listen",
  "listenButtonTooltip": "Play pronunciation",
```

- [ ] **Step 2: Add arb keys — `lib/l10n/app_fr.arb`**

After the line `"quizModeDesc": "Choisis la bonne réponse parmi 4 propositions.",`, add:

```json
  "listeningModeTitle": "Écoute",
  "listeningModeDesc": "Écoute et choisis le bon caractère.",
  "listenButtonLabel": "Écouter",
  "listenButtonTooltip": "Jouer la prononciation",
```

- [ ] **Step 3: Add arb keys — `lib/l10n/app_es.arb`**

After the line `"quizModeDesc": "Elige la respuesta correcta entre 4 opciones.",` (line 161), add:

```json
    "listeningModeTitle": "Escucha",
    "listeningModeDesc": "Escucha y elige el carácter correcto.",
    "listenButtonLabel": "Escuchar",
    "listenButtonTooltip": "Reproducir pronunciación",
```

- [ ] **Step 4: Add arb keys — `lib/l10n/app_it.arb`**

After the line `"quizModeDesc": "Scegli la risposta corretta tra 4 opzioni.",` (line 161), add:

```json
  "listeningModeTitle": "Ascolto",
  "listeningModeDesc": "Ascolta e scegli il carattere corretto.",
  "listenButtonLabel": "Ascolta",
  "listenButtonTooltip": "Riproduci pronuncia",
```

- [ ] **Step 5: Regenerate localizations**

```bash
flutter gen-l10n
```

Expected: completes without error, regenerates `lib/l10n/app_localizations*.dart` with the four new getters.

- [ ] **Step 6: Add the home screen card**

In `lib/screens/home/home_screen.dart`, in `_buildGameModes` (lines 16-47), add a new entry after the `GameType.quiz` entry (after line 38's closing `),`):

```dart
    GameMode(
      type: GameType.listening,
      title: l10n.listeningModeTitle,
      description: l10n.listeningModeDesc,
      icon: Icons.headphones_rounded,
      color: Colors.teal,
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
git commit -m "feat: add listening mode card and localized strings"
```

---

### Task 7: Manual verification and push

**Files:** none.

- [ ] **Step 1: Run on the Linux desktop to sanity-check the flow (audio output only, no mic needed for this game)**

```bash
flutter run -d linux
```

Walk through: Home screen shows an "Écoute"/"Listening" card → select an HSK1 deck → tap the card → tap the speaker button (hear the word, or at least confirm no crash if the desktop lacks a zh-CN voice) → tap a hanzi option → confirm correct/incorrect coloring like the existing quiz mode → confirm it advances to the next word either way.

- [ ] **Step 2: Manual verification on Android (primary target for audio quality)**

Build and install on the connected Android phone:

```bash
flutter run -d <android-device-id>
```

(`flutter devices` lists the id if unknown.) Repeat the same walkthrough as Step 1, paying attention to whether the zh-CN TTS voice is installed/audible — if not, note it as a follow-up (installing the language pack is a device-side action, not a code fix).

- [ ] **Step 3: Push the branch**

```bash
git push -u origin feature/listening-game
```

- [ ] **Step 4: Open a PR from `feature/listening-game` into `develop`** (not `main` — matches this repo's git-flow)

```bash
gh pr create --base develop --head feature/listening-game --title "feat: add listening game mode" --body "Adds a new listening practice mode: hear a HSK1 word's pronunciation via TTS, pick the matching hanzi among 4 options. See docs/superpowers/specs/2026-08-24-listening-pronunciation-games-design.md for the full design (this PR covers the listening game only; pronunciation game is a follow-up plan on its own branch)."
```
