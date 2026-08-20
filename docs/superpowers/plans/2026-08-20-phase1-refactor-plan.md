# Phase 1 Mode-Registry & Word-Schema Refactor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the fragmented, duplicated game-mode identity system with a single source of truth (`GameType`), give `Word` a stable `id` to fix silent progress-restore failures, remove dead code/fields, decompose the two most tangled files, and add the test coverage this business logic never had — all on the local (non-Supabase) codebase.

**Architecture:** `GameType` (already existing, currently missing a `reverse` value) becomes the one enum every layer switches on — providers, screens, and stats — via a small extension carrying `storageId`/`badgeLabel`/`statsLabel`. `Word` and `Sentence` gain/keep a stable `id`; `game_provider.dart`'s progress-restore merge matches on `id` instead of content. `game_screen.dart` is split into four presentational sub-widgets. No behavior outside what's described below changes; no Supabase code is touched.

**Tech Stack:** Flutter (Dart >=3.8.0 <4.0.0), `provider` (state management), `json_serializable`/`build_runner` (codegen), `shared_preferences` (persistence, mocked via `SharedPreferences.setMockInitialValues` in tests), `flutter_test`.

**Spec:** `docs/superpowers/plans/2026-08-20-phase1-refactor-spec.md`

## Global Constraints

- Flutter SDK `>=3.8.0 <4.0.0`; keep `flutter analyze` at 0 issues after every task (project uses `flutter_lints: ^6.0.0`).
- No backward-compatibility requirement for locally saved `SharedPreferences` data — free to change key formats/schemas (spec Q2).
- Nothing Supabase-related in this plan (spec Q5) — but don't regress `DeckRepository`'s clean interface (no `SharedPreferences`/file access leaking into providers).
- `review_history.dart`/`ReviewEntry` stays untouched — its `gameMode` field remains `String?`, populated via `GameType.storageId`.
- Existing test suite (`test/data/models/*.dart`, `test/core/utils/*.dart`) must keep passing after every task.
- Baseline: branch `develop`, commit `b900bca "prechangement avant refacto"`, clean working tree.

---

## File Structure

**Modify:**
- `lib/data/models/game_mode.dart` — add `GameType.reverse`, add `GameTypeIdentity` extension (`storageId`, `fromStorageId`, `badgeLabel`, `statsLabel`), drop `GameMode.id`/`GameMode.routeName`.
- `lib/screens/home/home_screen.dart` — build `GameMode`s via `type:` (no `id`/`routeName`), hoist list construction into a method, pass `mode.type` into `setDeck`.
- `assets/decks/**/*.json` (44 files) — add a stable `id` per word, remove the unused `meaning` key.
- `lib/data/models/word.dart` (+ regenerated `word.g.dart`) — add required `id`, switch equality/hashCode to `id`-based.
- `lib/screens/decks/deck_editor_screen.dart` — pass `id:` when constructing `Word` (new UUID on add, preserved id on edit).
- `lib/data/models/sentence.dart` (+ new `sentence.g.dart`) — convert to `json_serializable` codegen.
- `lib/providers/game_provider.dart` — `GameType`-based mode state, `id`-based progress-restore matching (no more silent `catch (_) {}`).
- `lib/screens/games/classic_game/game_screen.dart` — consume `GameType`, delegate to four new sub-widgets.
- `lib/data/repositories/deck_repository.dart` — `resetAllProgressForDeck` derives its mode list from `GameType.values`.
- `lib/providers/statistics_provider.dart` — new `GameModeStat` class, `getGameModeStats()` returns typed data instead of pre-formatted-label-keyed map entries.
- `lib/screens/stats/widgets/game_mode_stats_widget.dart` — consumes `GameModeStat`, switches on `GameType` instead of substring-matching a display label.
- `test/data/models/word_test.dart`, `test/data/models/deck_test.dart` — updated for required `Word.id`.

**Create:**
- `tool/migrate_word_ids.dart` — one-off migration script (deleted at the end of the task that uses it).
- `lib/screens/games/classic_game/widgets/game_header.dart`
- `lib/screens/games/classic_game/widgets/game_progress_bar.dart`
- `lib/screens/games/classic_game/widgets/completed_card.dart`
- `lib/screens/games/classic_game/widgets/remaining_words_sheet.dart`
- `test/providers/game_provider_test.dart`
- `test/providers/statistics_provider_test.dart`
- `test/data/repositories/deck_repository_test.dart`
- `test/data/models/game_mode_test.dart`
- `test/data/models/sentence_test.dart`

---

### Task 1: Characterization tests for `GameProvider` (safety net, current API)

**Files:**
- Create: `test/providers/game_provider_test.dart`

**Interfaces:**
- Consumes: `GameProvider` current API — `setDeck(Deck, {String gameMode = 'classic'})`, `currentGameMode` (String?), `isReverseMode`, `checkAnswer(String)`, `checkSentenceConstruction()`, `spinWheel()`, `resetDeck()`. `Word(prompt:, answer:, removed:)` (no `id` yet). `DeckRepository().saveProgress(deckId, gameMode, deck)`.
- Produces: nothing consumed by later tasks directly, but this file is edited again in Task 6 once the API it tests changes.

This locks in today's observable behavior before anything underneath it changes, per the interview's Q4/Q16 (test the risky, currently-untested business logic first).

- [ ] **Step 1: Write the test file against the current (pre-refactor) API**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:language_learning_app/data/models/deck.dart';
import 'package:language_learning_app/data/models/word.dart';
import 'package:language_learning_app/data/models/sentence.dart';
import 'package:language_learning_app/data/repositories/deck_repository.dart';
import 'package:language_learning_app/providers/game_provider.dart';
import 'package:language_learning_app/core/utils/storage_helper.dart';

Deck _buildDeck({int wordCount = 3, List<Sentence> sentences = const []}) {
  final words = List.generate(
    wordCount,
    (i) => Word(prompt: 'prompt$i', answer: 'answer$i', removed: false),
  );
  return Deck(
    id: 'deck1',
    name: 'Test Deck',
    type: DeckType.base,
    inputType: InputType.text,
    reverseInputType: InputType.text,
    words: words,
    sentences: sentences,
  );
}

Deck _oneWordDeck() {
  return Deck(
    id: 'deck1',
    name: 'Test Deck',
    type: DeckType.base,
    inputType: InputType.text,
    words: [Word(prompt: 'un', answer: 'one', removed: false)],
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageHelper.init();
  });

  group('GameProvider.setDeck', () {
    test('initializes a fresh game with no saved progress', () async {
      final provider = GameProvider();
      await provider.setDeck(_buildDeck(), gameMode: 'classic');

      expect(provider.currentDeck, isNotNull);
      expect(provider.totalWords, 3);
      expect(provider.remainingWords, 3);
      expect(provider.currentGameMode, 'classic');
      expect(provider.isReverseMode, isFalse);
    });

    test('isReverseMode is true only for the reverse mode string', () async {
      final provider = GameProvider();
      await provider.setDeck(_buildDeck(), gameMode: 'reverse');
      expect(provider.isReverseMode, isTrue);

      final classicProvider = GameProvider();
      await classicProvider.setDeck(_buildDeck(), gameMode: 'classic');
      expect(classicProvider.isReverseMode, isFalse);
    });

    test('restores removed words from saved progress by matching prompt text', () async {
      final repo = DeckRepository();
      final saved = _buildDeck()..words.first.removed = true;
      await repo.saveProgress('deck1', 'classic', saved);

      final provider = GameProvider();
      await provider.setDeck(_buildDeck(), gameMode: 'classic');

      expect(provider.currentDeck!.words.first.removed, isTrue);
      expect(provider.remainingWords, 2);
    });

    test('a saved word with no matching prompt in the fresh deck is silently skipped, not restored', () async {
      final repo = DeckRepository();
      final saved = _buildDeck()..words.first.removed = true;
      // Simulate the fresh deck's first word text having changed.
      final renamedFreshDeck = _buildDeck();
      renamedFreshDeck.words.first.removed = false;
      renamedFreshDeck.words[0] = Word(prompt: 'renamed', answer: 'answer0', removed: false);

      await repo.saveProgress('deck1', 'classic', saved);

      final provider = GameProvider();
      await provider.setDeck(renamedFreshDeck, gameMode: 'classic');

      // Old behavior: content-based match fails silently, nothing restored.
      expect(provider.remainingWords, 3);
    });
  });

  group('GameProvider.checkAnswer', () {
    test('correct answer (classic mode) marks the word removed', () async {
      final provider = GameProvider();
      await provider.setDeck(_oneWordDeck(), gameMode: 'classic');
      await provider.spinWheel();

      final result = await provider.checkAnswer('one');

      expect(result, isTrue);
      expect(provider.currentDeck!.words.first.removed, isTrue);
    });

    test('incorrect answer (classic mode) leaves the word not removed', () async {
      final provider = GameProvider();
      await provider.setDeck(_oneWordDeck(), gameMode: 'classic');
      await provider.spinWheel();

      final result = await provider.checkAnswer('wrong');

      expect(result, isFalse);
      expect(provider.currentDeck!.words.first.removed, isFalse);
    });

    test('reverse mode checks the answer against prompt, not answer', () async {
      final provider = GameProvider();
      await provider.setDeck(_oneWordDeck(), gameMode: 'reverse');
      await provider.spinWheel();

      final result = await provider.checkAnswer('un');

      expect(result, isTrue);
    });
  });

  group('GameProvider - sentence mode', () {
    Sentence buildSentence() => Sentence(
          id: 's1',
          original: 'Bonjour',
          translation: 'nihao',
          blocks: ['ni', 'hao', 'bu'],
        );

    test('spinWheel loads a sentence and shuffles blocks into availableBlocks', () async {
      final provider = GameProvider();
      await provider.setDeck(_buildDeck(sentences: [buildSentence()]), gameMode: 'sentence');
      await provider.spinWheel();

      expect(provider.currentSentence, isNotNull);
      expect(provider.availableBlocks.toSet(), {'ni', 'hao', 'bu'});
      expect(provider.selectedBlocks, isEmpty);
    });

    test('addBlockToSentence / removeBlockFromSentence move blocks between lists', () async {
      final provider = GameProvider();
      await provider.setDeck(_buildDeck(sentences: [buildSentence()]), gameMode: 'sentence');
      await provider.spinWheel();

      provider.addBlockToSentence('ni');
      expect(provider.selectedBlocks, ['ni']);
      expect(provider.availableBlocks.contains('ni'), isFalse);

      provider.removeBlockFromSentence('ni');
      expect(provider.selectedBlocks, isEmpty);
      expect(provider.availableBlocks.contains('ni'), isTrue);
    });

    test('checkSentenceConstruction: correct order marks the sentence completed', () async {
      final provider = GameProvider();
      await provider.setDeck(_buildDeck(sentences: [buildSentence()]), gameMode: 'sentence');
      await provider.spinWheel();

      provider.addBlockToSentence('ni');
      provider.addBlockToSentence('hao');

      final result = await provider.checkSentenceConstruction();

      expect(result, isTrue);
      expect(provider.currentDeck!.sentences.first.completed, isTrue);
    });

    test('checkSentenceConstruction: wrong order does not complete the sentence', () async {
      final provider = GameProvider();
      await provider.setDeck(_buildDeck(sentences: [buildSentence()]), gameMode: 'sentence');
      await provider.spinWheel();

      provider.addBlockToSentence('hao');
      provider.addBlockToSentence('ni');

      final result = await provider.checkSentenceConstruction();

      expect(result, isFalse);
      expect(provider.currentDeck!.sentences.first.completed, isFalse);
    });
  });

  group('GameProvider - quiz mode', () {
    test('spinWheel in quiz mode populates 4 quiz options including the correct answer', () async {
      final provider = GameProvider();
      await provider.setDeck(_buildDeck(wordCount: 5), gameMode: 'quiz');
      await provider.spinWheel();

      expect(provider.quizOptions.length, 4);
      expect(provider.quizOptions.contains(provider.currentWord!.answer), isTrue);
    });
  });

  group('GameProvider.resetDeck', () {
    test('resets all removed words and completed sentences', () async {
      final provider = GameProvider();
      final deck = _buildDeck(sentences: [
        Sentence(id: 's1', original: 'o', translation: 't', blocks: ['t']),
      ]);
      await provider.setDeck(deck, gameMode: 'classic');
      provider.currentDeck!.words.first.removed = true;
      provider.currentDeck!.sentences.first.completed = true;

      await provider.resetDeck();

      expect(provider.currentDeck!.words.every((w) => !w.removed), isTrue);
      expect(provider.currentDeck!.sentences.every((s) => !s.completed), isTrue);
    });
  });
}
```

- [ ] **Step 2: Run the new test file to confirm it passes against current code**

Run: `flutter test test/providers/game_provider_test.dart`
Expected: all tests PASS (this characterizes existing behavior, including the "silently skipped" restore-by-content quirk we will change later).

- [ ] **Step 3: Run the full suite to confirm nothing else broke**

Run: `flutter test`
Expected: PASS (existing 6 test files + this new one).

- [ ] **Step 4: Commit**

```bash
git add test/providers/game_provider_test.dart
git commit -m "test: characterize GameProvider behavior before mode/id refactor"
```

---

### Task 2: `GameType` registry (add `reverse`, extension methods) + `home_screen.dart`

**Files:**
- Modify: `lib/data/models/game_mode.dart`
- Modify: `lib/screens/home/home_screen.dart`
- Create: `test/data/models/game_mode_test.dart`

**Interfaces:**
- Consumes: nothing new.
- Produces: `enum GameType { classic, reverse, quiz, sentence, memory }`; extension `GameTypeIdentity` on `GameType` with `String get storageId`, `static GameType fromStorageId(String id)`, `String get badgeLabel`, `String get statsLabel`. `class GameMode { final GameType type; final String title; final String description; final IconData icon; final Color color; const GameMode({required this.type, required this.title, required this.description, required this.icon, required this.color}); }` (no more `id`/`routeName`). These are consumed by Tasks 6, 7, 8, 9.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:language_learning_app/data/models/game_mode.dart';

void main() {
  group('GameType identity', () {
    test('storageId matches the enum name for every value', () {
      for (final type in GameType.values) {
        expect(type.storageId, type.name);
      }
    });

    test('fromStorageId resolves every known storage id back to its GameType', () {
      for (final type in GameType.values) {
        expect(GameTypeIdentity.fromStorageId(type.storageId), type);
      }
    });

    test('fromStorageId falls back to classic for an unknown id', () {
      expect(GameTypeIdentity.fromStorageId('unknown_mode'), GameType.classic);
    });

    test('classic has no badge label, every other mode has one', () {
      expect(GameType.classic.badgeLabel, isEmpty);
      for (final type in GameType.values.where((t) => t != GameType.classic)) {
        expect(type.badgeLabel, isNotEmpty);
      }
    });

    test('every GameType has a non-empty statsLabel', () {
      for (final type in GameType.values) {
        expect(type.statsLabel, isNotEmpty);
      }
    });
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/data/models/game_mode_test.dart`
Expected: FAIL — `GameType.reverse` / `GameTypeIdentity` don't exist yet.

- [ ] **Step 3: Rewrite `game_mode.dart`**

```dart
import 'package:flutter/material.dart';

enum GameType {
  classic,
  reverse,
  quiz,
  sentence,
  memory, // Futur
}

/// Single source of truth for mode identity: the id used for persistence
/// keys and stats storage, plus the display labels used in different UI
/// contexts. Add a new mode by adding a GameType value and filling in its
/// case in every switch below -- the compiler keeps them exhaustive.
extension GameTypeIdentity on GameType {
  /// Stable string used in SharedPreferences progress keys and in
  /// ReviewEntry.gameMode. Existing values ('classic', 'reverse', 'quiz',
  /// 'sentence') are preserved as-is even though no migration is required,
  /// simply to avoid churn.
  String get storageId => name;

  static GameType fromStorageId(String id) {
    return GameType.values.firstWhere(
      (type) => type.storageId == id,
      orElse: () => GameType.classic,
    );
  }

  /// Short badge shown in GameScreen's header for non-default modes.
  /// Empty means "no badge" (classic mode).
  String get badgeLabel {
    switch (this) {
      case GameType.classic:
        return '';
      case GameType.reverse:
        return 'REVERSE';
      case GameType.quiz:
        return 'QUIZ MODE';
      case GameType.sentence:
        return 'PHRASE';
      case GameType.memory:
        return 'MEMORY';
    }
  }

  /// French display label used on the statistics screen.
  String get statsLabel {
    switch (this) {
      case GameType.classic:
        return 'Classique';
      case GameType.reverse:
        return 'Inversé';
      case GameType.quiz:
        return 'Quiz';
      case GameType.sentence:
        return 'Phrase';
      case GameType.memory:
        return 'Mémoire';
    }
  }
}

class GameMode {
  final GameType type;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const GameMode({
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/data/models/game_mode_test.dart`
Expected: PASS

- [ ] **Step 5: Update `home_screen.dart` to use the new `GameMode` shape**

In `lib/screens/home/home_screen.dart`, replace the inline list construction inside `build()`:

```dart
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final List<GameMode> gameModes = _buildGameModes(l10n);
```

Add this method (module-level private function, hoisting the list out of `build()`):

```dart
List<GameMode> _buildGameModes(AppLocalizations l10n) {
  return [
    GameMode(
      type: GameType.classic,
      title: l10n.classicModeTitle,
      description: l10n.classicModeDesc,
      icon: Icons.school_rounded,
      color: AppColors.primary,
    ),
    GameMode(
      type: GameType.reverse,
      title: l10n.reverseModeTitle,
      description: l10n.reverseModeDesc,
      icon: Icons.swap_horiz_rounded,
      color: AppColors.secondary,
    ),
    GameMode(
      type: GameType.quiz,
      title: l10n.quizModeTitle,
      description: l10n.quizModeDesc,
      icon: Icons.quiz_rounded,
      color: Colors.orange,
    ),
    GameMode(
      type: GameType.sentence,
      title: "Phrase",
      description: "Reconstitue la phrase correcte.",
      icon: Icons.segment_rounded,
      color: Colors.purple,
    ),
  ];
}
```

And update the tap handler in `_buildGameModeCard` (around line 311):

```dart
            gameProvider.setDeck(
              deckProvider.selectedDeck!,
              gameMode: mode.type,
            );
```

(This last line's argument type changes from `String` to `GameType` — it will not compile until Task 6 changes `GameProvider.setDeck`'s signature. That's expected: Tasks 2–5 land the supporting model changes first; Task 6 is the one that makes `game_provider.dart` and its callers agree again. Do not attempt to `flutter run` the app between Task 2 and Task 6.)

- [ ] **Step 6: Run `flutter analyze` to confirm the only new error is the expected, temporary `setDeck` type mismatch**

Run: `flutter analyze`
Expected: one error at `home_screen.dart`'s `gameProvider.setDeck(... gameMode: mode.type)` call (argument type `GameType` not assignable to parameter type `String`) — everything else clean. This is resolved in Task 6.

- [ ] **Step 7: Run the test suite (excluding the known-broken app) to confirm models/tests are fine**

Run: `flutter test test/data/models/game_mode_test.dart test/data/models/word_test.dart test/data/models/deck_test.dart test/data/models/deck_manifest_test.dart test/core/utils/`
Expected: PASS

- [ ] **Step 8: Commit**

```bash
git add lib/data/models/game_mode.dart lib/screens/home/home_screen.dart test/data/models/game_mode_test.dart
git commit -m "refactor: make GameType the single source of truth for mode identity"
```

---

### Task 3: Deck JSON migration — add stable word ids, remove dead `meaning` field

**Files:**
- Create: `tool/migrate_word_ids.dart` (temporary — deleted at the end of this task)
- Modify: all 44 files under `assets/decks/**/*.json` (except `manifest.json`)

**Interfaces:**
- Consumes: nothing (pure data migration).
- Produces: every word object in every deck JSON file has a unique-within-file `"id"` key (format `"<deckId>_w<index>"`, 1-based); no word object has a `"meaning"` key. Consumed by Task 4 (`Word.fromJson` requires `id`).

This intentionally runs *before* `Word.id` becomes a required Dart field (Task 4): today's `Word.fromJson` (via `json_serializable`) ignores unknown JSON keys, exactly as it already silently ignores `meaning` — so adding `id` to the JSON now is a no-op for the current app, and the app never has a broken intermediate state where the model expects a field the data doesn't have yet.

- [ ] **Step 1: Write the migration script**

```dart
import 'dart:convert';
import 'dart:io';

/// One-off migration: adds a stable `id` to every word entry in the bundled
/// deck JSON files, and removes the unused `meaning` key. Run once with
/// `dart run tool/migrate_word_ids.dart`, review the diff, then delete this
/// script -- it is not meant to run again.
Future<void> main() async {
  final decksDir = Directory('assets/decks');
  var filesChanged = 0;

  await for (final entity in decksDir.list(recursive: true)) {
    if (entity is! File ||
        !entity.path.endsWith('.json') ||
        entity.path.endsWith('manifest.json')) {
      continue;
    }

    final content = await entity.readAsString();
    final json = jsonDecode(content) as Map<String, dynamic>;
    final deckId = json['id'] as String? ??
        entity.uri.pathSegments.last.replaceAll('.json', '');
    final words = (json['words'] as List<dynamic>?) ?? [];

    var changed = false;
    for (var i = 0; i < words.length; i++) {
      final word = words[i] as Map<String, dynamic>;
      if (word.remove('meaning') != null) changed = true;
      if (!word.containsKey('id')) {
        word['id'] = '${deckId}_w${i + 1}';
        changed = true;
      }
    }

    if (changed) {
      final encoded = const JsonEncoder.withIndent('  ').convert(json);
      await entity.writeAsString('$encoded\n');
      filesChanged++;
      stdout.writeln('✅ ${entity.path}');
    }
  }

  stdout.writeln('\n✨ $filesChanged fichier(s) de deck mis à jour.');
}
```

- [ ] **Step 2: Run it**

Run: `dart run tool/migrate_word_ids.dart`
Expected: output lists every changed file; script reports 44 files changed (all deck files gain `id`s; the 19 files that had `meaning` also lose it).

- [ ] **Step 3: Spot-check the diff**

Run: `git diff assets/decks/chinese/hsk1/part1-5/chinese_hsk1_part1.json assets/decks/english/a2_key/colours.json`
Expected: each word object gained `"id": "<deck>_w<N>"`; `chinese_hsk1_part1.json`'s word objects no longer have `"meaning"`. JSON stays valid (verify with `dart run tool/generate_deck_manifest.dart` in the next step, which parses every file).

- [ ] **Step 4: Confirm every deck file is still valid JSON and still loads via the existing manifest generator**

Run: `dart run tool/generate_deck_manifest.dart`
Expected: completes without errors, same deck count as before (`✨ Manifest généré avec 44 decks !` — confirm the count matches `find assets/decks -name "*.json" ! -name manifest.json | wc -l`).

- [ ] **Step 5: Run the existing test suite to confirm nothing regressed**

Run: `flutter test`
Expected: PASS (no test currently loads real deck JSON assets, so this is a sanity check, not a direct exercise of the new `id`s).

- [ ] **Step 6: Delete the one-off script**

```bash
git rm tool/migrate_word_ids.dart
```

- [ ] **Step 7: Commit**

```bash
git add assets/decks/ assets/decks/manifest.json
git commit -m "data: add stable word ids to deck JSON, remove unused meaning field"
```

---

### Task 4: `Word.id` (model) — required field, id-based equality

**Files:**
- Modify: `lib/data/models/word.dart`
- Modify (regenerated): `lib/data/models/word.g.dart`
- Modify: `test/data/models/word_test.dart`
- Modify: `test/data/models/deck_test.dart`
- Modify: `test/providers/game_provider_test.dart` (fixtures only)
- Modify: `lib/screens/decks/deck_editor_screen.dart`

**Interfaces:**
- Consumes: nothing new (deck JSON already has `id` per Task 3).
- Produces: `Word({required String id, required String prompt, required String answer, bool removed = false})`, equality/hashCode based on `id`. Consumed by Task 6 (progress-restore matching) and every existing `Word(...)` call site.

- [ ] **Step 1: Rewrite `lib/data/models/word.dart`**

```dart
import 'package:json_annotation/json_annotation.dart';

part 'word.g.dart';

@JsonSerializable()
class Word {
  final String id;
  final String prompt;   // Le mot à afficher (ex: "あ")
  final String answer;   // La réponse attendue (ex: "a")
  bool removed;          // Si le mot a été réussi aujourd'hui

  Word({
    required this.id,
    required this.prompt,
    required this.answer,
    this.removed = false,
  });

  // Créer une copie avec modifications
  Word copyWith({
    String? id,
    String? prompt,
    String? answer,
    bool? removed,
  }) {
    return Word(
      id: id ?? this.id,
      prompt: prompt ?? this.prompt,
      answer: answer ?? this.answer,
      removed: removed ?? this.removed,
    );
  }

  // JSON Serialization
  factory Word.fromJson(Map<String, dynamic> json) => _$WordFromJson(json);
  Map<String, dynamic> toJson() => _$WordToJson(this);

  @override
  String toString() => 'Word(id: $id, prompt: $prompt, answer: $answer, removed: $removed)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Word &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
```

- [ ] **Step 2: Regenerate `word.g.dart`**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: `lib/data/models/word.g.dart` regenerated with `id` read/written; build_runner reports success for `word.g.dart` (other `.g.dart` files may also rebuild — that's fine and expected, this is a shared codegen step).

- [ ] **Step 3: Update `test/data/models/word_test.dart` for the new required `id` and id-based equality**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:language_learning_app/data/models/word.dart';

void main() {
  group('Word Model Tests', () {
    const id = 'w1';
    const prompt = 'あ';
    const answer = 'a';

    test('Constructor initializes values correctly', () {
      final word = Word(id: id, prompt: prompt, answer: answer);
      expect(word.id, id);
      expect(word.prompt, prompt);
      expect(word.answer, answer);
      expect(word.removed, isFalse); // Default value
    });

    test('JSON Serialization (toJson / fromJson)', () {
      final word = Word(id: id, prompt: prompt, answer: answer, removed: true);
      final json = word.toJson();

      expect(json['id'], id);
      expect(json['prompt'], prompt);
      expect(json['answer'], answer);
      expect(json['removed'], true);

      final newWord = Word.fromJson(json);
      expect(newWord, equals(word));
    });

    test('fromJson throws when the required id is missing (fails loudly on malformed data)', () {
      final json = {'prompt': prompt, 'answer': answer};
      expect(() => Word.fromJson(json), throwsA(isA<TypeError>()));
    });

    test('Equality and hashCode are based on the stable id, not content', () {
      final word1 = Word(id: id, prompt: prompt, answer: answer);
      final word2 = Word(id: id, prompt: 'different prompt', answer: 'different answer');
      final word3 = Word(id: 'w2', prompt: prompt, answer: answer);

      // Same id -> equal, even if prompt/answer differ.
      expect(word1, equals(word2));
      expect(word1.hashCode, equals(word2.hashCode));

      // Different id -> not equal, even if prompt/answer match.
      expect(word1, isNot(equals(word3)));
      expect(word1.hashCode, isNot(equals(word3.hashCode)));
    });

    test('copyWith creates a new instance with updated values', () {
      final word = Word(id: id, prompt: prompt, answer: answer);

      final updatedWord = word.copyWith(removed: true);

      expect(updatedWord.id, word.id);
      expect(updatedWord.prompt, word.prompt);
      expect(updatedWord.answer, word.answer);
      expect(updatedWord.removed, isTrue);

      // Original instance stays same
      expect(word.removed, isFalse);
    });

    test('copyWith can change id', () {
      final word = Word(id: id, prompt: prompt, answer: answer);
      final updatedWord = word.copyWith(id: 'w2');
      expect(updatedWord.id, 'w2');
      expect(updatedWord, isNot(equals(word)));
    });
  });
}
```

- [ ] **Step 4: Update `test/data/models/deck_test.dart`'s `Word(...)` fixtures**

In the `setUp`, change:

```dart
      deck = Deck(
        id: 'test_deck',
        name: 'Test Deck',
        type: DeckType.base,
        inputType: InputType.text,
        words: [
          Word(id: 'w1', prompt: '1', answer: 'one', removed: false),
          Word(id: 'w2', prompt: '2', answer: 'two', removed: true), // Déjà fait
          Word(id: 'w3', prompt: '3', answer: 'three', removed: false),
          Word(id: 'w4', prompt: '4', answer: 'four', removed: true), // Déjà fait
        ],
      );
```

(No other test in this file constructs `Word` directly — the "Unknown Enum Value Fallback" test uses `'words': []`, unaffected.)

- [ ] **Step 5: Update `test/providers/game_provider_test.dart`'s `Word(...)` fixtures**

Replace the whole file with the following (identical to Task 1's version, except every `Word(...)` construction now includes `id:`; the two restore tests are updated to build ids explicitly so they keep compiling and still characterize the *current*, prompt-based restore logic — Task 6 replaces those two tests wholesale once the matching logic itself changes to `id`-based):

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:language_learning_app/data/models/deck.dart';
import 'package:language_learning_app/data/models/word.dart';
import 'package:language_learning_app/data/models/sentence.dart';
import 'package:language_learning_app/data/repositories/deck_repository.dart';
import 'package:language_learning_app/providers/game_provider.dart';
import 'package:language_learning_app/core/utils/storage_helper.dart';

Deck _buildDeck({int wordCount = 3, List<Sentence> sentences = const []}) {
  final words = List.generate(
    wordCount,
    (i) => Word(id: 'w$i', prompt: 'prompt$i', answer: 'answer$i', removed: false),
  );
  return Deck(
    id: 'deck1',
    name: 'Test Deck',
    type: DeckType.base,
    inputType: InputType.text,
    reverseInputType: InputType.text,
    words: words,
    sentences: sentences,
  );
}

Deck _oneWordDeck() {
  return Deck(
    id: 'deck1',
    name: 'Test Deck',
    type: DeckType.base,
    inputType: InputType.text,
    words: [Word(id: 'w0', prompt: 'un', answer: 'one', removed: false)],
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageHelper.init();
  });

  group('GameProvider.setDeck', () {
    test('initializes a fresh game with no saved progress', () async {
      final provider = GameProvider();
      await provider.setDeck(_buildDeck(), gameMode: 'classic');

      expect(provider.currentDeck, isNotNull);
      expect(provider.totalWords, 3);
      expect(provider.remainingWords, 3);
      expect(provider.currentGameMode, 'classic');
      expect(provider.isReverseMode, isFalse);
    });

    test('isReverseMode is true only for the reverse mode string', () async {
      final provider = GameProvider();
      await provider.setDeck(_buildDeck(), gameMode: 'reverse');
      expect(provider.isReverseMode, isTrue);

      final classicProvider = GameProvider();
      await classicProvider.setDeck(_buildDeck(), gameMode: 'classic');
      expect(classicProvider.isReverseMode, isFalse);
    });

    test('restores removed words from saved progress by matching prompt text', () async {
      final repo = DeckRepository();
      final saved = _buildDeck()..words.first.removed = true;
      await repo.saveProgress('deck1', 'classic', saved);

      final provider = GameProvider();
      await provider.setDeck(_buildDeck(), gameMode: 'classic');

      expect(provider.currentDeck!.words.first.removed, isTrue);
      expect(provider.remainingWords, 2);
    });

    test('a saved word with no matching prompt in the fresh deck is silently skipped, not restored', () async {
      final repo = DeckRepository();
      final saved = _buildDeck()..words.first.removed = true;
      final renamedFreshDeck = _buildDeck();
      renamedFreshDeck.words[0] = Word(id: 'w0', prompt: 'renamed', answer: 'answer0', removed: false);

      await repo.saveProgress('deck1', 'classic', saved);

      final provider = GameProvider();
      await provider.setDeck(renamedFreshDeck, gameMode: 'classic');

      // Old behavior: content-based match fails silently (id matches, but the
      // current logic still matches on prompt, which no longer matches), nothing restored.
      expect(provider.remainingWords, 3);
    });
  });

  group('GameProvider.checkAnswer', () {
    test('correct answer (classic mode) marks the word removed', () async {
      final provider = GameProvider();
      await provider.setDeck(_oneWordDeck(), gameMode: 'classic');
      await provider.spinWheel();

      final result = await provider.checkAnswer('one');

      expect(result, isTrue);
      expect(provider.currentDeck!.words.first.removed, isTrue);
    });

    test('incorrect answer (classic mode) leaves the word not removed', () async {
      final provider = GameProvider();
      await provider.setDeck(_oneWordDeck(), gameMode: 'classic');
      await provider.spinWheel();

      final result = await provider.checkAnswer('wrong');

      expect(result, isFalse);
      expect(provider.currentDeck!.words.first.removed, isFalse);
    });

    test('reverse mode checks the answer against prompt, not answer', () async {
      final provider = GameProvider();
      await provider.setDeck(_oneWordDeck(), gameMode: 'reverse');
      await provider.spinWheel();

      final result = await provider.checkAnswer('un');

      expect(result, isTrue);
    });
  });

  group('GameProvider - sentence mode', () {
    Sentence buildSentence() => Sentence(
          id: 's1',
          original: 'Bonjour',
          translation: 'nihao',
          blocks: ['ni', 'hao', 'bu'],
        );

    test('spinWheel loads a sentence and shuffles blocks into availableBlocks', () async {
      final provider = GameProvider();
      await provider.setDeck(_buildDeck(sentences: [buildSentence()]), gameMode: 'sentence');
      await provider.spinWheel();

      expect(provider.currentSentence, isNotNull);
      expect(provider.availableBlocks.toSet(), {'ni', 'hao', 'bu'});
      expect(provider.selectedBlocks, isEmpty);
    });

    test('addBlockToSentence / removeBlockFromSentence move blocks between lists', () async {
      final provider = GameProvider();
      await provider.setDeck(_buildDeck(sentences: [buildSentence()]), gameMode: 'sentence');
      await provider.spinWheel();

      provider.addBlockToSentence('ni');
      expect(provider.selectedBlocks, ['ni']);
      expect(provider.availableBlocks.contains('ni'), isFalse);

      provider.removeBlockFromSentence('ni');
      expect(provider.selectedBlocks, isEmpty);
      expect(provider.availableBlocks.contains('ni'), isTrue);
    });

    test('checkSentenceConstruction: correct order marks the sentence completed', () async {
      final provider = GameProvider();
      await provider.setDeck(_buildDeck(sentences: [buildSentence()]), gameMode: 'sentence');
      await provider.spinWheel();

      provider.addBlockToSentence('ni');
      provider.addBlockToSentence('hao');

      final result = await provider.checkSentenceConstruction();

      expect(result, isTrue);
      expect(provider.currentDeck!.sentences.first.completed, isTrue);
    });

    test('checkSentenceConstruction: wrong order does not complete the sentence', () async {
      final provider = GameProvider();
      await provider.setDeck(_buildDeck(sentences: [buildSentence()]), gameMode: 'sentence');
      await provider.spinWheel();

      provider.addBlockToSentence('hao');
      provider.addBlockToSentence('ni');

      final result = await provider.checkSentenceConstruction();

      expect(result, isFalse);
      expect(provider.currentDeck!.sentences.first.completed, isFalse);
    });
  });

  group('GameProvider - quiz mode', () {
    test('spinWheel in quiz mode populates 4 quiz options including the correct answer', () async {
      final provider = GameProvider();
      await provider.setDeck(_buildDeck(wordCount: 5), gameMode: 'quiz');
      await provider.spinWheel();

      expect(provider.quizOptions.length, 4);
      expect(provider.quizOptions.contains(provider.currentWord!.answer), isTrue);
    });
  });

  group('GameProvider.resetDeck', () {
    test('resets all removed words and completed sentences', () async {
      final provider = GameProvider();
      final deck = _buildDeck(sentences: [
        Sentence(id: 's1', original: 'o', translation: 't', blocks: ['t']),
      ]);
      await provider.setDeck(deck, gameMode: 'classic');
      provider.currentDeck!.words.first.removed = true;
      provider.currentDeck!.sentences.first.completed = true;

      await provider.resetDeck();

      expect(provider.currentDeck!.words.every((w) => !w.removed), isTrue);
      expect(provider.currentDeck!.sentences.every((s) => !s.completed), isTrue);
    });
  });
}
```

- [ ] **Step 6: Update `lib/screens/decks/deck_editor_screen.dart`**

`_addWord` (around line 55) generates a fresh id for a brand-new word:

```dart
          setState(() => _words.add(Word(id: const Uuid().v4(), prompt: prompt, answer: answer)));
```

`_editWord` (around line 67) preserves the existing word's id (identity doesn't change just because its text was edited — this is the exact scenario the `id` migration exists to make safe):

```dart
          setState(() => _words[index] = Word(
                id: _words[index].id,
                prompt: prompt,
                answer: answer,
              ));
```

(`Uuid` is already imported in this file for deck ids — no new import needed. `removed` still defaults to `false` on edit, matching current behavior; that's a pre-existing quirk, not something this plan changes.)

- [ ] **Step 7: Run `flutter analyze`**

Run: `flutter analyze`
Expected: same single pre-existing error as after Task 2 (`home_screen.dart`'s `setDeck` call), nothing new.

- [ ] **Step 8: Run the test suite**

Run: `flutter test test/data/models/ test/core/utils/`
Expected: PASS. (`test/providers/game_provider_test.dart` will not fully compile/pass yet if its call sites elsewhere still pass `gameMode: 'classic'` as a String while other things shift — but since `setDeck`'s signature itself hasn't changed yet in this task, it should still compile and pass; verify by also running `flutter test test/providers/game_provider_test.dart` and confirm PASS.)

- [ ] **Step 9: Commit**

```bash
git add lib/data/models/word.dart lib/data/models/word.g.dart lib/screens/decks/deck_editor_screen.dart test/data/models/word_test.dart test/data/models/deck_test.dart test/providers/game_provider_test.dart
git commit -m "refactor: give Word a stable id, use it for equality"
```

---

### Task 5: `Sentence` — convert to `json_serializable` codegen

**Files:**
- Modify: `lib/data/models/sentence.dart`
- Create (regenerated): `lib/data/models/sentence.g.dart`
- Create: `test/data/models/sentence_test.dart`

**Interfaces:**
- Consumes: nothing new.
- Produces: `Sentence.fromJson`/`toJson` now throw on missing required fields instead of silently defaulting to `''`/`[]`. Public shape (`id`, `original`, `translation`, `blocks`, `completed`) is unchanged.

- [ ] **Step 1: Write the test file (new — `Sentence` had zero tests before)**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:language_learning_app/data/models/sentence.dart';

void main() {
  group('Sentence Model Tests', () {
    test('Constructor initializes values correctly', () {
      final sentence = Sentence(
        id: 's1',
        original: 'Bonjour',
        translation: '你好',
        blocks: ['你', '好', '您'],
      );
      expect(sentence.id, 's1');
      expect(sentence.original, 'Bonjour');
      expect(sentence.translation, '你好');
      expect(sentence.blocks, ['你', '好', '您']);
      expect(sentence.completed, isFalse);
    });

    test('JSON Serialization (toJson / fromJson)', () {
      final sentence = Sentence(
        id: 's1',
        original: 'Bonjour',
        translation: '你好',
        blocks: ['你', '好'],
        completed: true,
      );
      final json = sentence.toJson();

      expect(json['id'], 's1');
      expect(json['original'], 'Bonjour');
      expect(json['translation'], '你好');
      expect(json['blocks'], ['你', '好']);
      expect(json['completed'], true);

      final fromJson = Sentence.fromJson(json);
      expect(fromJson.id, sentence.id);
      expect(fromJson.original, sentence.original);
      expect(fromJson.translation, sentence.translation);
      expect(fromJson.blocks, sentence.blocks);
      expect(fromJson.completed, sentence.completed);
    });

    test('completed defaults to false when absent from JSON', () {
      final json = {
        'id': 's1',
        'original': 'Bonjour',
        'translation': '你好',
        'blocks': ['你', '好'],
      };
      final sentence = Sentence.fromJson(json);
      expect(sentence.completed, isFalse);
    });

    test('fromJson throws on a missing required field (fails loudly on malformed data)', () {
      final json = {
        'id': 's1',
        'original': 'Bonjour',
        // 'translation' missing
        'blocks': ['你', '好'],
      };
      expect(() => Sentence.fromJson(json), throwsA(isA<TypeError>()));
    });
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/data/models/sentence_test.dart`
Expected: FAIL — `toJson`/`fromJson` behave per the current hand-written implementation, but more importantly the "throws on missing field" test fails because the current implementation defaults instead of throwing.

- [ ] **Step 3: Rewrite `lib/data/models/sentence.dart`**

```dart
import 'package:json_annotation/json_annotation.dart';

part 'sentence.g.dart';

@JsonSerializable()
class Sentence {
  final String id;
  final String original;
  final String translation;
  final List<String> blocks;

  bool completed;

  Sentence({
    required this.id,
    required this.original,
    required this.translation,
    required this.blocks,
    this.completed = false,
  });

  factory Sentence.fromJson(Map<String, dynamic> json) => _$SentenceFromJson(json);
  Map<String, dynamic> toJson() => _$SentenceToJson(this);
}
```

- [ ] **Step 4: Regenerate the codegen**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: `lib/data/models/sentence.g.dart` created.

- [ ] **Step 5: Run the test to verify it passes**

Run: `flutter test test/data/models/sentence_test.dart`
Expected: PASS

- [ ] **Step 6: Run `flutter analyze` and the model/util test suite**

Run: `flutter analyze && flutter test test/data/models/ test/core/utils/`
Expected: same single known error (`home_screen.dart`), everything else clean/passing.

- [ ] **Step 7: Commit**

```bash
git add lib/data/models/sentence.dart lib/data/models/sentence.g.dart test/data/models/sentence_test.dart
git commit -m "refactor: convert Sentence to json_serializable codegen"
```

---

### Task 6: `GameProvider` — `GameType`-based mode state, `id`-based progress restore

**Files:**
- Modify: `lib/providers/game_provider.dart`
- Modify: `test/providers/game_provider_test.dart`

**Interfaces:**
- Consumes: `GameType`/`GameTypeIdentity` (Task 2), `Word.id` (Task 4).
- Produces: `setDeck(Deck, {GameType gameMode = GameType.classic})`, `GameType? get currentGameType`, `String? get currentGameMode` (derived, kept for `ReviewEntry.gameMode`/`drawing_widget.dart` compatibility). Consumed by Task 7 (`game_screen.dart`) and `home_screen.dart` (Task 2, now compiles).

This is the task that finally makes the codebase compile again end-to-end (it resolves the intentional, documented gap left since Task 2).

- [ ] **Step 1: Rewrite `lib/providers/game_provider.dart`**

```dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:language_learning_app/data/models/deck.dart';
import 'package:language_learning_app/data/models/word.dart';
import 'package:language_learning_app/data/models/sentence.dart';
import 'package:language_learning_app/data/models/game_mode.dart';
import 'package:language_learning_app/data/repositories/deck_repository.dart';
import 'package:language_learning_app/core/utils/date_helper.dart';
import 'package:language_learning_app/providers/statistics_provider.dart';

class GameProvider extends ChangeNotifier {
  final DeckRepository _repository = DeckRepository();
  final StatisticsProvider? statisticsProvider;

  // État du jeu en cours
  String? _currentDeckId;
  GameType? _currentGameType;
  Deck? _currentProgressDeck;

  // État Mode Mots (Classic/Reverse/Quiz)
  Word? _currentWord;

  // État Mode Phrase (Sentence)
  Sentence? _currentSentence;
  List<String> _availableBlocks = []; // Blocs disponibles (en bas)
  List<String> _selectedBlocks = [];  // Blocs choisis (en haut)

  // Jeu Quiz
  List<String> _quizOptions = [];
  List<String> get quizOptions => _quizOptions;

  // Animation
  bool _isSpinning = false;
  double _wheelRotation = 0.0;

  GameProvider({this.statisticsProvider});

  // ===========================================================================
  // GETTERS (Calculs dynamiques selon le mode)
  // ===========================================================================

  Deck? get currentDeck => _currentProgressDeck;
  Word? get currentWord => _currentWord;
  Sentence? get currentSentence => _currentSentence;

  List<String> get availableBlocks => _availableBlocks;
  List<String> get selectedBlocks => _selectedBlocks;

  bool get isSpinning => _isSpinning;
  double get wheelRotation => _wheelRotation;

  /// Enum-based mode identity -- the single source of truth for behavior.
  GameType? get currentGameType => _currentGameType;

  /// String form kept for callers that persist/display it as text
  /// (SharedPreferences progress keys, ReviewEntry.gameMode).
  String? get currentGameMode => _currentGameType?.storageId;

  bool get isReverseMode => _currentGameType == GameType.reverse;

  /// Nombre total d'éléments à apprendre (Mots ou Phrases)
  int get totalWords {
    if (_currentProgressDeck == null) return 0;
    if (_currentGameType == GameType.sentence) {
      return _currentProgressDeck!.sentences.length;
    }
    return _currentProgressDeck!.totalWords;
  }

  /// Nombre d'éléments restants
  int get remainingWords {
    if (_currentProgressDeck == null) return 0;
    if (_currentGameType == GameType.sentence) {
      return _currentProgressDeck!.sentences.where((s) => !s.completed).length;
    }
    return _currentProgressDeck!.remainingWords;
  }

  /// Pourcentage de progression (0 à 100)
  double get progress {
    if (totalWords == 0) return 0.0;
    return ((totalWords - remainingWords) / totalWords) * 100;
  }

  /// Jeu terminé ?
  bool get isCompleted => remainingWords == 0;

  /// Texte de la question à afficher
  String get currentQuestionText {
    if (_currentGameType == GameType.sentence && _currentSentence != null) {
      return _currentSentence!.original;
    }
    if (_currentWord == null) return '';
    return isReverseMode ? _currentWord!.answer : _currentWord!.prompt;
  }

  /// Type d'input (Clavier ou Dessin) pour les modes mots
  InputType get activeInputType {
    if (_currentProgressDeck == null) return InputType.text;
    return isReverseMode
        ? _currentProgressDeck!.effectiveReverseInputType
        : _currentProgressDeck!.inputType;
  }

  // ===========================================================================
  // INITIALISATION (SetDeck avec Merge)
  // ===========================================================================

  Future<void> setDeck(Deck baseDeck, {GameType gameMode = GameType.classic}) async {
    _currentDeckId = baseDeck.id;
    _currentGameType = gameMode;

    debugPrint('🎮 Initialisation du jeu');
    debugPrint('   Deck: ${baseDeck.name} (${baseDeck.id})');
    debugPrint('   Mode: ${gameMode.storageId}');

    final savedProgress = await _repository.loadProgress(baseDeck.id, gameMode.storageId);

    if (savedProgress != null) {
      debugPrint('   ✅ Progression existante détectée. Fusion des données...');

      // STRATÉGIE DE FUSION :
      // On prend le deck "frais" (JSON) pour avoir le contenu à jour.
      // On applique les états "removed" (mots) et "completed" (phrases)
      // depuis la sauvegarde, en faisant correspondre par id stable
      // (et non plus par contenu, qui casse silencieusement si le texte
      // d'un mot change entre deux révisions du deck).

      final freshDeck = baseDeck.copyWith(
        words: baseDeck.words.map((w) => w.copyWith(removed: false)).toList(),
        sentences: baseDeck.sentences.map((s) => Sentence(
          id: s.id,
          original: s.original,
          translation: s.translation,
          blocks: s.blocks,
          completed: false,
        )).toList(),
      );

      // A. Restauration des mots appris (match par id)
      for (final savedWord in savedProgress.words) {
        if (!savedWord.removed) continue;
        for (final freshWord in freshDeck.words) {
          if (freshWord.id == savedWord.id) {
            freshWord.removed = true;
            break;
          }
        }
      }

      // B. Restauration des phrases complétées (match par id)
      for (final savedSentence in savedProgress.sentences) {
        if (!savedSentence.completed) continue;
        for (final freshSentence in freshDeck.sentences) {
          if (freshSentence.id == savedSentence.id) {
            freshSentence.completed = true;
            break;
          }
        }
      }

      _currentProgressDeck = freshDeck;
    } else {
      debugPrint('   🆕 Nouvelle partie créée');
      _currentProgressDeck = baseDeck.copyWith(
        words: baseDeck.words.map((w) => w.copyWith(removed: false)).toList(),
        sentences: baseDeck.sentences,
      );
    }

    // Reset des pointeurs
    _currentWord = null;
    _currentSentence = null;
    _wheelRotation = 0.0;
    notifyListeners();
  }

  // ===========================================================================
  // BOUCLE DE JEU PRINCIPALE (SpinWheel)
  // ===========================================================================

  Future<void> spinWheel() async {
    if (_currentProgressDeck == null) return;

    if (_isSpinning && _currentGameType != GameType.sentence) return;

    if (_currentGameType == GameType.sentence) {
      _loadNextSentence();
      notifyListeners();
      return;
    }

    final activeWords = _currentProgressDeck!.activeWords;
    if (activeWords.isEmpty) {
      debugPrint('⚠️ Aucun mot actif disponible');
      return;
    }

    _isSpinning = true;
    notifyListeners();

    final random = Random();
    _currentWord = activeWords[random.nextInt(activeWords.length)];

    if (_currentGameType == GameType.quiz) {
      _generateQuizOptions(activeWords);
    }

    final rotations = 5 + random.nextDouble() * 3;
    _wheelRotation = rotations * 2 * pi;

    await Future.delayed(const Duration(milliseconds: 2000));

    _isSpinning = false;
    notifyListeners();
  }

  // ===========================================================================
  // LOGIQUE : MODE PHRASE (SENTENCE)
  // ===========================================================================

  void _loadNextSentence() {
    final activeSentences = _currentProgressDeck?.sentences.where((s) => !s.completed).toList() ?? [];

    if (activeSentences.isNotEmpty) {
      final random = Random();
      _currentSentence = activeSentences[random.nextInt(activeSentences.length)];
      _availableBlocks = List.from(_currentSentence!.blocks)..shuffle();
      _selectedBlocks = [];
    } else {
      _currentSentence = null;
    }
  }

  void addBlockToSentence(String block) {
    _availableBlocks.remove(block);
    _selectedBlocks.add(block);
    notifyListeners();
  }

  void removeBlockFromSentence(String block) {
    _selectedBlocks.remove(block);
    _availableBlocks.add(block);
    notifyListeners();
  }

  Future<bool> checkSentenceConstruction() async {
    if (_currentSentence == null) return false;

    final userSentence = _selectedBlocks.join('').replaceAll(' ', '').toLowerCase();
    final correctSentence = _currentSentence!.translation.replaceAll(' ', '').toLowerCase();

    final isCorrect = userSentence == correctSentence;

    if (statisticsProvider != null && _currentProgressDeck != null) {
      await statisticsProvider!.addReview(
        wordId: _currentSentence!.original,
        deckId: _currentProgressDeck!.id,
        wasCorrect: isCorrect,
        inputType: 'blocks',
        gameMode: GameType.sentence.storageId,
      );
    }

    if (isCorrect) {
      _currentSentence!.completed = true;
      await _saveProgress();

      debugPrint('✅ Phrase correcte !');
      notifyListeners();
      return true;
    }

    debugPrint('❌ Phrase incorrecte.');
    return false;
  }

  void resetCurrentSentence() {
    _currentSentence = null;
    _selectedBlocks = [];
    _availableBlocks = [];
    notifyListeners();
  }

  // ===========================================================================
  // LOGIQUE : MODE MOTS (Classic / Quiz / Reverse)
  // ===========================================================================

  Future<bool> checkAnswer(String userAnswer) async {
    if (_currentWord == null || _currentProgressDeck == null) return false;

    final userAnswerClean = userAnswer.toLowerCase().trim();
    String expectedAnswer;

    if (isReverseMode) {
      expectedAnswer = _currentWord!.prompt.toLowerCase().trim();
    } else {
      expectedAnswer = _currentWord!.answer.toLowerCase().trim();
    }

    final isCorrect = expectedAnswer == userAnswerClean;

    await statisticsProvider?.addReview(
      wordId: _currentWord!.id,
      deckId: _currentProgressDeck!.id,
      wasCorrect: isCorrect,
      inputType: activeInputType == InputType.text ? 'text' : 'draw',
      gameMode: _currentGameType!.storageId,
    );

    if (isCorrect) {
      _currentWord!.removed = true;
      await _saveProgress();
      debugPrint('✅ Bonne réponse !');
      notifyListeners();
      return true;
    }

    debugPrint('❌ Mauvaise réponse');
    return false;
  }

  // Pour le mode Dessin (validation manuelle)
  Future<void> markCurrentWordAsCorrect() async {
    if (_currentWord == null || _currentProgressDeck == null) return;

    _currentWord!.removed = true;
    await _saveProgress();
    debugPrint('✅ Dessin validé !');
    notifyListeners();
  }

  void resetCurrentWord() {
    _currentWord = null;
    _wheelRotation = 0.0;
    notifyListeners();
  }

  void _generateQuizOptions(List<Word> activeWords) {
    if (_currentWord == null) return;

    final correctAnswer = _currentWord!.answer;
    final allWords = _currentProgressDeck!.words;

    final distractors = allWords
        .where((w) => w.answer.toLowerCase() != correctAnswer.toLowerCase())
        .map((w) => w.answer)
        .toList();

    distractors.shuffle();
    final selectedDistractors = distractors.take(3).toList();

    while (selectedDistractors.length < 3) {
      selectedDistractors.add("Option ${selectedDistractors.length + 1}");
    }

    _quizOptions = [...selectedDistractors, correctAnswer];
    _quizOptions.shuffle();
  }

  // ===========================================================================
  // MAINTENANCE & SAUVEGARDE
  // ===========================================================================

  Future<void> resetDeck() async {
    if (_currentProgressDeck == null || _currentDeckId == null || _currentGameType == null) return;

    _currentProgressDeck!.resetWords();

    for (final s in _currentProgressDeck!.sentences) {
      s.completed = false;
    }

    _currentWord = null;
    _currentSentence = null;
    _wheelRotation = 0.0;

    await _saveProgress();
    debugPrint('🔄 Deck réinitialisé');
    notifyListeners();
    spinWheel();
  }

  Future<void> checkDailyReset(DateTime lastReset) async {
    if (_currentProgressDeck == null) return;

    if (DateHelper.needsReset(lastReset)) {
      debugPrint('📅 Reset quotidien déclenché');
      await resetDeck();
    }
  }

  Future<void> _saveProgress() async {
    if (_currentProgressDeck == null || _currentDeckId == null || _currentGameType == null) {
      return;
    }

    await _repository.saveProgress(
      _currentDeckId!,
      _currentGameType!.storageId,
      _currentProgressDeck!,
    );
    debugPrint('💾 Progression sauvegardée: progress_${_currentDeckId}_${_currentGameType!.storageId}');
  }
}
```

Note: `checkAnswer`'s recorded `wordId` changed from `_currentWord!.prompt` to `_currentWord!.id` — consistent with `Word.id` now being the real identity (Task 4); leaving it on `prompt` would reintroduce the exact fragility this refactor removes elsewhere. This does not require a migration (Q2: no saved data to preserve).

- [ ] **Step 2: Update `test/providers/game_provider_test.dart` for the new `GameType`-based API**

Replace the whole file with:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:language_learning_app/data/models/deck.dart';
import 'package:language_learning_app/data/models/word.dart';
import 'package:language_learning_app/data/models/sentence.dart';
import 'package:language_learning_app/data/models/game_mode.dart';
import 'package:language_learning_app/data/repositories/deck_repository.dart';
import 'package:language_learning_app/providers/game_provider.dart';
import 'package:language_learning_app/core/utils/storage_helper.dart';

Deck _buildDeck({int wordCount = 3, List<Sentence> sentences = const []}) {
  final words = List.generate(
    wordCount,
    (i) => Word(id: 'w$i', prompt: 'prompt$i', answer: 'answer$i', removed: false),
  );
  return Deck(
    id: 'deck1',
    name: 'Test Deck',
    type: DeckType.base,
    inputType: InputType.text,
    reverseInputType: InputType.text,
    words: words,
    sentences: sentences,
  );
}

Deck _oneWordDeck() {
  return Deck(
    id: 'deck1',
    name: 'Test Deck',
    type: DeckType.base,
    inputType: InputType.text,
    words: [Word(id: 'w0', prompt: 'un', answer: 'one', removed: false)],
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageHelper.init();
  });

  group('GameProvider.setDeck', () {
    test('initializes a fresh game with no saved progress', () async {
      final provider = GameProvider();
      await provider.setDeck(_buildDeck(), gameMode: GameType.classic);

      expect(provider.currentDeck, isNotNull);
      expect(provider.totalWords, 3);
      expect(provider.remainingWords, 3);
      expect(provider.currentGameMode, 'classic');
      expect(provider.currentGameType, GameType.classic);
      expect(provider.isReverseMode, isFalse);
    });

    test('isReverseMode is true only for the reverse mode', () async {
      final provider = GameProvider();
      await provider.setDeck(_buildDeck(), gameMode: GameType.reverse);
      expect(provider.isReverseMode, isTrue);

      final classicProvider = GameProvider();
      await classicProvider.setDeck(_buildDeck(), gameMode: GameType.classic);
      expect(classicProvider.isReverseMode, isFalse);
    });

    test('restores removed words from saved progress by matching id, even if prompt/answer text changed', () async {
      final repo = DeckRepository();
      final saved = _buildDeck()..words.first.removed = true;
      await repo.saveProgress('deck1', GameType.classic.storageId, saved);

      // Simulate a deck JSON revision that changed word text but kept the same id.
      final revisedDeck = _buildDeck();
      revisedDeck.words[0] = Word(id: 'w0', prompt: 'renamed prompt', answer: 'renamed answer', removed: false);

      final provider = GameProvider();
      await provider.setDeck(revisedDeck, gameMode: GameType.classic);

      expect(provider.currentDeck!.words.first.removed, isTrue);
      expect(provider.remainingWords, 2);
    });

    test('does not restore, and does not throw, when a saved word id no longer exists in the fresh deck', () async {
      final repo = DeckRepository();
      final saved = _buildDeck();
      saved.words.add(Word(id: 'deleted_word', prompt: 'x', answer: 'y', removed: true));
      await repo.saveProgress('deck1', GameType.classic.storageId, saved);

      final provider = GameProvider();
      await expectLater(
        provider.setDeck(_buildDeck(), gameMode: GameType.classic),
        completes,
      );
      expect(provider.remainingWords, 3);
    });
  });

  group('GameProvider.checkAnswer', () {
    test('correct answer (classic mode) marks the word removed', () async {
      final provider = GameProvider();
      await provider.setDeck(_oneWordDeck(), gameMode: GameType.classic);
      await provider.spinWheel();

      final result = await provider.checkAnswer('one');

      expect(result, isTrue);
      expect(provider.currentDeck!.words.first.removed, isTrue);
    });

    test('incorrect answer (classic mode) leaves the word not removed', () async {
      final provider = GameProvider();
      await provider.setDeck(_oneWordDeck(), gameMode: GameType.classic);
      await provider.spinWheel();

      final result = await provider.checkAnswer('wrong');

      expect(result, isFalse);
      expect(provider.currentDeck!.words.first.removed, isFalse);
    });

    test('reverse mode checks the answer against prompt, not answer', () async {
      final provider = GameProvider();
      await provider.setDeck(_oneWordDeck(), gameMode: GameType.reverse);
      await provider.spinWheel();

      final result = await provider.checkAnswer('un');

      expect(result, isTrue);
    });
  });

  group('GameProvider - sentence mode', () {
    Sentence buildSentence() => Sentence(
          id: 's1',
          original: 'Bonjour',
          translation: 'nihao',
          blocks: ['ni', 'hao', 'bu'],
        );

    test('spinWheel loads a sentence and shuffles blocks into availableBlocks', () async {
      final provider = GameProvider();
      await provider.setDeck(_buildDeck(sentences: [buildSentence()]), gameMode: GameType.sentence);
      await provider.spinWheel();

      expect(provider.currentSentence, isNotNull);
      expect(provider.availableBlocks.toSet(), {'ni', 'hao', 'bu'});
      expect(provider.selectedBlocks, isEmpty);
    });

    test('addBlockToSentence / removeBlockFromSentence move blocks between lists', () async {
      final provider = GameProvider();
      await provider.setDeck(_buildDeck(sentences: [buildSentence()]), gameMode: GameType.sentence);
      await provider.spinWheel();

      provider.addBlockToSentence('ni');
      expect(provider.selectedBlocks, ['ni']);
      expect(provider.availableBlocks.contains('ni'), isFalse);

      provider.removeBlockFromSentence('ni');
      expect(provider.selectedBlocks, isEmpty);
      expect(provider.availableBlocks.contains('ni'), isTrue);
    });

    test('checkSentenceConstruction: correct order marks the sentence completed', () async {
      final provider = GameProvider();
      await provider.setDeck(_buildDeck(sentences: [buildSentence()]), gameMode: GameType.sentence);
      await provider.spinWheel();

      provider.addBlockToSentence('ni');
      provider.addBlockToSentence('hao');

      final result = await provider.checkSentenceConstruction();

      expect(result, isTrue);
      expect(provider.currentDeck!.sentences.first.completed, isTrue);
    });

    test('checkSentenceConstruction: wrong order does not complete the sentence', () async {
      final provider = GameProvider();
      await provider.setDeck(_buildDeck(sentences: [buildSentence()]), gameMode: GameType.sentence);
      await provider.spinWheel();

      provider.addBlockToSentence('hao');
      provider.addBlockToSentence('ni');

      final result = await provider.checkSentenceConstruction();

      expect(result, isFalse);
      expect(provider.currentDeck!.sentences.first.completed, isFalse);
    });
  });

  group('GameProvider - quiz mode', () {
    test('spinWheel in quiz mode populates 4 quiz options including the correct answer', () async {
      final provider = GameProvider();
      await provider.setDeck(_buildDeck(wordCount: 5), gameMode: GameType.quiz);
      await provider.spinWheel();

      expect(provider.quizOptions.length, 4);
      expect(provider.quizOptions.contains(provider.currentWord!.answer), isTrue);
    });
  });

  group('GameProvider.resetDeck', () {
    test('resets all removed words and completed sentences', () async {
      final provider = GameProvider();
      final deck = _buildDeck(sentences: [
        Sentence(id: 's1', original: 'o', translation: 't', blocks: ['t']),
      ]);
      await provider.setDeck(deck, gameMode: GameType.classic);
      provider.currentDeck!.words.first.removed = true;
      provider.currentDeck!.sentences.first.completed = true;

      await provider.resetDeck();

      expect(provider.currentDeck!.words.every((w) => !w.removed), isTrue);
      expect(provider.currentDeck!.sentences.every((s) => !s.completed), isTrue);
    });
  });
}
```

- [ ] **Step 3: Run `flutter analyze`**

Run: `flutter analyze`
Expected: 0 issues (the `home_screen.dart` error from Task 2 is now resolved).

- [ ] **Step 4: Run the provider test suite**

Run: `flutter test test/providers/game_provider_test.dart`
Expected: PASS

- [ ] **Step 5: Run the full suite**

Run: `flutter test`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add lib/providers/game_provider.dart test/providers/game_provider_test.dart
git commit -m "refactor: GameProvider uses GameType and id-based progress restore"
```

---

### Task 7: `game_screen.dart` — consume `GameType`, decompose into sub-widgets

**Files:**
- Create: `lib/screens/games/classic_game/widgets/game_header.dart`
- Create: `lib/screens/games/classic_game/widgets/game_progress_bar.dart`
- Create: `lib/screens/games/classic_game/widgets/completed_card.dart`
- Create: `lib/screens/games/classic_game/widgets/remaining_words_sheet.dart`
- Modify: `lib/screens/games/classic_game/game_screen.dart`

**Interfaces:**
- Consumes: `GameProvider.currentGameType` (Task 6), `GameType.badgeLabel` (Task 2).
- Produces: no public API consumed by other tasks — this is a leaf UI task.

- [ ] **Step 1: Create `GameHeader`**

```dart
import 'package:flutter/material.dart';
import 'package:language_learning_app/core/theme/app_colors.dart';
import 'package:language_learning_app/data/models/deck.dart';
import 'package:language_learning_app/core/extensions/deck_extensions.dart';

class GameHeader extends StatelessWidget {
  final Deck deck;
  final String badgeLabel;

  const GameHeader({super.key, required this.deck, required this.badgeLabel});

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        children: [
          Text(
            deck.localizedName(context),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          if (badgeLabel.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                badgeLabel,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.secondary),
              ),
            ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Create `GameProgressBar`**

```dart
import 'package:flutter/material.dart';
import 'package:language_learning_app/core/theme/app_colors.dart';

class GameProgressBar extends StatelessWidget {
  final int total;
  final int remaining;
  final double progress;

  const GameProgressBar({
    super.key,
    required this.total,
    required this.remaining,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${total - remaining}/$total', style: Theme.of(context).textTheme.bodyMedium),
            Text(
              '${progress.toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress / 100,
            minHeight: 10,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 3: Create `CompletedCard`**

```dart
import 'package:flutter/material.dart';
import 'package:language_learning_app/core/theme/app_colors.dart';
import 'package:language_learning_app/l10n/app_localizations.dart';

class CompletedCard extends StatelessWidget {
  final VoidCallback onRestart;

  const CompletedCard({super.key, required this.onRestart});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      elevation: 0,
      color: AppColors.success.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.success, width: 2),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.celebration, size: 60, color: AppColors.success),
            const SizedBox(height: 16),
            Text(
              l10n.completed,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.completedMessage,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onRestart,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.restart),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Create `RemainingWordsSheet`**

```dart
import 'package:flutter/material.dart';
import 'package:language_learning_app/core/theme/app_colors.dart';
import 'package:language_learning_app/data/models/deck.dart';
import 'package:language_learning_app/data/models/word.dart';
import 'package:language_learning_app/l10n/app_localizations.dart';
import 'package:language_learning_app/core/extensions/deck_extensions.dart';

class RemainingWordsSheet extends StatelessWidget {
  final Deck deck;

  const RemainingWordsSheet({super.key, required this.deck});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final remainingWords = deck.activeWords;
    final completedWords = deck.words.where((w) => w.removed).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.list_alt_rounded, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        deck.localizedName(context),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatCompact(context, l10n.remaining, '${remainingWords.length}', AppColors.warning),
                    Container(width: 1, height: 30, color: Colors.grey.shade300),
                    _buildStatCompact(context, l10n.succeeded, '${completedWords.length}', AppColors.success),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      TabBar(
                        labelColor: AppColors.primary,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: AppColors.primary,
                        tabs: [
                          Tab(text: l10n.toReview),
                          Tab(text: l10n.succeeded),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildWordsList(context, remainingWords, false, scrollController),
                            _buildWordsList(context, completedWords, true, scrollController),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCompact(BuildContext context, String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildWordsList(BuildContext context, List<Word> words, bool isCompleted, ScrollController scrollController) {
    final l10n = AppLocalizations.of(context)!;
    if (words.isEmpty) {
      return Center(child: Text(isCompleted ? l10n.noWordSucceeded : l10n.allWordsSucceeded));
    }
    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: words.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final word = words[index];
        return ListTile(title: Text(word.prompt));
      },
    );
  }
}
```

- [ ] **Step 5: Rewrite `lib/screens/games/classic_game/game_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:language_learning_app/providers/game_provider.dart';
import 'package:language_learning_app/data/models/word.dart';
import 'package:language_learning_app/data/models/game_mode.dart';
import 'package:language_learning_app/l10n/app_localizations.dart';

// Imports des widgets d'input
import 'widgets/text_input_widget.dart';
import 'widgets/drawing_widget.dart';
import 'widgets/wheel_widget.dart';
import 'widgets/quiz_widget.dart';
import 'widgets/sentence_builder_widget.dart';
import 'widgets/game_header.dart';
import 'widgets/game_progress_bar.dart';
import 'widgets/completed_card.dart';
import 'widgets/remaining_words_sheet.dart';

class GameScreen extends StatelessWidget {
  final String? gameTitle;

  const GameScreen({super.key, this.gameTitle});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = gameTitle ?? l10n.homeTitle;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        actions: [
          Consumer<GameProvider>(
            builder: (context, gameProvider, _) {
              return IconButton(
                icon: Badge(
                  label: Text('${gameProvider.remainingWords}'),
                  isLabelVisible: gameProvider.remainingWords > 0,
                  child: const Icon(Icons.list),
                ),
                tooltip: l10n.remainingWordsList,
                onPressed: () => _showRemainingWordsBottomSheet(context, gameProvider),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        bottom: true,
        child: Consumer<GameProvider>(
          builder: (context, gameProvider, _) {
            if (gameProvider.currentDeck == null) {
              return Center(child: Text(l10n.noDeckSelected));
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final isSmallScreen = constraints.maxWidth < 380;

                return GestureDetector(
                  onTap: () => FocusScope.of(context).unfocus(),
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              const SizedBox(height: 12),
                              GameHeader(
                                deck: gameProvider.currentDeck!,
                                badgeLabel: gameProvider.currentGameType?.badgeLabel ?? '',
                              ),
                              const SizedBox(height: 8),
                              GameProgressBar(
                                total: gameProvider.totalWords,
                                remaining: gameProvider.remainingWords,
                                progress: gameProvider.progress,
                              ),
                              const SizedBox(height: 12),
                              if (gameProvider.isCompleted)
                                Expanded(
                                  child: Center(
                                    child: CompletedCard(onRestart: gameProvider.resetDeck),
                                  ),
                                )
                              else if (gameProvider.currentWord == null && gameProvider.currentSentence == null)
                                Expanded(
                                  child: Center(
                                    child: WheelWidget(
                                      words: gameProvider.currentDeck!.activeWords,
                                      isSpinning: gameProvider.isSpinning,
                                      selectedWord: gameProvider.currentWord,
                                      onSpin: () => gameProvider.spinWheel(),
                                    ),
                                  ),
                                )
                              else ...[
                                _buildWordDisplay(context, gameProvider, isSmallScreen),
                                const Spacer(),
                                const SizedBox(height: 16),
                                _buildGameInputArea(context, gameProvider),
                                const SizedBox(height: 16),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

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

  Widget _buildWordDisplay(BuildContext context, GameProvider gameProvider, bool isSmallScreen) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
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
        if (gameProvider.currentGameType != GameType.quiz && gameProvider.currentGameType != GameType.sentence)
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

  void _showRemainingWordsBottomSheet(BuildContext context, GameProvider gameProvider) {
    final deck = gameProvider.currentDeck;
    if (deck == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RemainingWordsSheet(deck: deck),
    );
  }
}
```

(`AppColors` is still used directly in `_buildWordDisplay` — keep `import 'package:language_learning_app/core/theme/app_colors.dart';` at the top; it was already imported before and is still needed here.)

- [ ] **Step 6: Run `flutter analyze`**

Run: `flutter analyze`
Expected: 0 issues.

- [ ] **Step 7: Run the full test suite**

Run: `flutter test`
Expected: PASS (no test exercises `game_screen.dart` directly — this task has no automated widget-test coverage, per the spec's explicit scope; verify manually per Task 10's checklist).

- [ ] **Step 8: Commit**

```bash
git add lib/screens/games/classic_game/
git commit -m "refactor: decompose game_screen.dart into sub-widgets, consume GameType"
```

---

### Task 8: `DeckRepository` — fix `resetAllProgressForDeck`, add tests

**Files:**
- Modify: `lib/data/repositories/deck_repository.dart`
- Create: `test/data/repositories/deck_repository_test.dart`

**Interfaces:**
- Consumes: `GameType.values`/`storageId` (Task 2).
- Produces: nothing new consumed elsewhere.

`loadBaseDecks()`'s asset-loading path (and its existing per-file try/catch that skips a malformed deck file and logs, continuing with the rest) is intentionally not covered by a new test here: it reads from `rootBundle`, and faking a corrupt file would mean adding fake broken content to the real shipped `assets/decks/` tree, which is worse than not testing it. The malformed-input robustness this plan promises (spec Q16) is covered at the model level instead — `Word`/`Sentence`/`Deck.fromJson` throwing clearly on missing required fields (Tasks 4, 5, and the existing `deck_test.dart` "Unknown Enum Value Fallback" test) — which is what actually determines whether a bad file is skip-and-logged or crashes the app.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:language_learning_app/data/repositories/deck_repository.dart';
import 'package:language_learning_app/data/models/deck.dart';
import 'package:language_learning_app/data/models/word.dart';
import 'package:language_learning_app/data/models/game_mode.dart';
import 'package:language_learning_app/core/utils/storage_helper.dart';

Deck _buildDeck() {
  return Deck(
    id: 'deck1',
    name: 'Test Deck',
    type: DeckType.base,
    inputType: InputType.text,
    words: [Word(id: 'w1', prompt: 'un', answer: 'one')],
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageHelper.init();
  });

  group('DeckRepository - progress persistence', () {
    test('loadProgress returns null when nothing was saved', () async {
      final repo = DeckRepository();
      expect(await repo.loadProgress('deck1', 'classic'), isNull);
    });

    test('saveProgress then loadProgress round-trips the deck', () async {
      final repo = DeckRepository();
      final deck = _buildDeck()..words.first.removed = true;

      await repo.saveProgress('deck1', 'classic', deck);
      final loaded = await repo.loadProgress('deck1', 'classic');

      expect(loaded, isNotNull);
      expect(loaded!.words.first.removed, isTrue);
    });

    test('progress is scoped per game mode', () async {
      final repo = DeckRepository();
      await repo.saveProgress('deck1', 'classic', _buildDeck());

      expect(await repo.loadProgress('deck1', 'quiz'), isNull);
    });

    test('resetProgress removes only the targeted mode', () async {
      final repo = DeckRepository();
      await repo.saveProgress('deck1', 'classic', _buildDeck());
      await repo.saveProgress('deck1', 'quiz', _buildDeck());

      await repo.resetProgress('deck1', 'classic');

      expect(await repo.loadProgress('deck1', 'classic'), isNull);
      expect(await repo.loadProgress('deck1', 'quiz'), isNotNull);
    });

    test('resetAllProgressForDeck clears every known GameType, including quiz and sentence', () async {
      final repo = DeckRepository();
      for (final type in GameType.values) {
        await repo.saveProgress('deck1', type.storageId, _buildDeck());
      }

      await repo.resetAllProgressForDeck('deck1');

      for (final type in GameType.values) {
        expect(await repo.loadProgress('deck1', type.storageId), isNull);
      }
    });
  });

  group('DeckRepository - custom decks', () {
    test('loadCustomDecks returns an empty list when none saved', () async {
      final repo = DeckRepository();
      expect(await repo.loadCustomDecks(), isEmpty);
    });

    test('saveCustomDecks then loadCustomDecks round-trips', () async {
      final repo = DeckRepository();
      await repo.saveCustomDecks([_buildDeck()]);

      final loaded = await repo.loadCustomDecks();
      expect(loaded.length, 1);
      expect(loaded.first.id, 'deck1');
    });
  });

  group('DeckRepository - selected deck id', () {
    test('getSelectedDeckId falls back to the default when unset', () async {
      final repo = DeckRepository();
      expect(await repo.getSelectedDeckId(), isNotEmpty);
    });

    test('saveSelectedDeckId then getSelectedDeckId round-trips', () async {
      final repo = DeckRepository();
      await repo.saveSelectedDeckId('custom-123');
      expect(await repo.getSelectedDeckId(), 'custom-123');
    });
  });
}
```

- [ ] **Step 2: Run it to verify the `resetAllProgressForDeck` test fails**

Run: `flutter test test/data/repositories/deck_repository_test.dart`
Expected: FAIL on `resetAllProgressForDeck clears every known GameType, including quiz and sentence` (the current hardcoded `['classic', 'reverse']` list leaves `quiz`/`sentence`/`memory` progress in place). Other tests PASS already (they exercise existing correct behavior).

- [ ] **Step 3: Fix `resetAllProgressForDeck` in `lib/data/repositories/deck_repository.dart`**

Add the import at the top: `import 'package:language_learning_app/data/models/game_mode.dart';`

Replace:

```dart
  /// Réinitialise TOUTES les progressions d'un deck (tous modes confondus)
  Future<void> resetAllProgressForDeck(String deckId) async {
    // Liste des modes connus (à adapter si tu en ajoutes)
    const gameModes = ['classic', 'reverse'];
    for (final mode in gameModes) {
      await resetProgress(deckId, mode);
    }
    debugPrint('🗑️ Toutes les progressions supprimées pour: $deckId');
  }
```

with:

```dart
  /// Réinitialise TOUTES les progressions d'un deck (tous modes confondus)
  Future<void> resetAllProgressForDeck(String deckId) async {
    for (final type in GameType.values) {
      await resetProgress(deckId, type.storageId);
    }
    debugPrint('🗑️ Toutes les progressions supprimées pour: $deckId');
  }
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/data/repositories/deck_repository_test.dart`
Expected: PASS

- [ ] **Step 5: Run `flutter analyze` and the full suite**

Run: `flutter analyze && flutter test`
Expected: 0 issues, all PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/data/repositories/deck_repository.dart test/data/repositories/deck_repository_test.dart
git commit -m "fix: resetAllProgressForDeck clears every GameType, not a stale hardcoded list"
```

---

### Task 9: `StatisticsProvider` + `GameModeStatsWidget` — typed `GameModeStat`, drop label substring-matching

**Files:**
- Modify: `lib/providers/statistics_provider.dart`
- Modify: `lib/screens/stats/widgets/game_mode_stats_widget.dart`
- Create: `test/providers/statistics_provider_test.dart`

**Interfaces:**
- Consumes: `GameType`/`GameTypeIdentity` (Task 2).
- Produces: `class GameModeStat { final GameType type; final String label; final int count; }`, `List<GameModeStat> getGameModeStats()`. `lib/screens/stats/statistics_screen.dart` (the only caller of `GameModeStatsWidget`) needs no change — it already just forwards `statsProvider.getGameModeStats()` into `data:`, and the type flows through automatically.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:language_learning_app/providers/statistics_provider.dart';
import 'package:language_learning_app/data/models/game_mode.dart';
import 'package:language_learning_app/core/utils/storage_helper.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageHelper.init();
  });

  group('StatisticsProvider', () {
    test('getGameModeStats groups and sorts by play count, using GameType labels', () async {
      final provider = StatisticsProvider();
      await provider.loadHistory();

      await provider.addReview(wordId: 'w1', deckId: 'd1', wasCorrect: true, inputType: 'text', gameMode: 'classic');
      await provider.addReview(wordId: 'w2', deckId: 'd1', wasCorrect: true, inputType: 'text', gameMode: 'classic');
      await provider.addReview(wordId: 'w3', deckId: 'd1', wasCorrect: false, inputType: 'text', gameMode: 'quiz');

      final stats = provider.getGameModeStats();

      expect(stats.length, 2);
      expect(stats.first.type, GameType.classic);
      expect(stats.first.count, 2);
      expect(stats.first.label, 'Classique');
      expect(stats.last.type, GameType.quiz);
      expect(stats.last.count, 1);
    });

    test('getGameModeStats defaults entries with no gameMode to classic', () async {
      final provider = StatisticsProvider();
      await provider.loadHistory();

      await provider.addReview(wordId: 'w1', deckId: 'd1', wasCorrect: true, inputType: 'text', gameMode: 'classic');

      final stats = provider.getGameModeStats();
      expect(stats.single.type, GameType.classic);
    });

    test('getSuccessRate computes the percentage of correct reviews', () async {
      final provider = StatisticsProvider();
      await provider.loadHistory();

      await provider.addReview(wordId: 'w1', deckId: 'd1', wasCorrect: true, inputType: 'text', gameMode: 'classic');
      await provider.addReview(wordId: 'w2', deckId: 'd1', wasCorrect: false, inputType: 'text', gameMode: 'classic');
      await provider.addReview(wordId: 'w3', deckId: 'd1', wasCorrect: true, inputType: 'text', gameMode: 'classic');

      expect(provider.getSuccessRate(), closeTo(66.67, 0.01));
    });

    test('getSuccessRate returns 0 for empty history', () async {
      final provider = StatisticsProvider();
      await provider.loadHistory();
      expect(provider.getSuccessRate(), 0.0);
    });

    test('getTotalWordsLearned counts unique correctly-answered wordIds', () async {
      final provider = StatisticsProvider();
      await provider.loadHistory();

      await provider.addReview(wordId: 'w1', deckId: 'd1', wasCorrect: true, inputType: 'text', gameMode: 'classic');
      await provider.addReview(wordId: 'w1', deckId: 'd1', wasCorrect: true, inputType: 'text', gameMode: 'classic');
      await provider.addReview(wordId: 'w2', deckId: 'd1', wasCorrect: false, inputType: 'text', gameMode: 'classic');

      expect(provider.getTotalWordsLearned(), 1);
    });

    test('clearHistory resets to empty', () async {
      final provider = StatisticsProvider();
      await provider.loadHistory();
      await provider.addReview(wordId: 'w1', deckId: 'd1', wasCorrect: true, inputType: 'text', gameMode: 'classic');

      await provider.clearHistory();

      expect(provider.history.entries, isEmpty);
      expect(provider.getSuccessRate(), 0.0);
    });
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/providers/statistics_provider_test.dart`
Expected: FAIL — `getGameModeStats()` doesn't exist with this signature yet (`GameModeStat` doesn't exist).

- [ ] **Step 3: Update `lib/providers/statistics_provider.dart`**

Add the import: `import 'package:language_learning_app/data/models/game_mode.dart';`

Add near the top (after imports, before the class):

```dart
class GameModeStat {
  final GameType type;
  final String label;
  final int count;

  const GameModeStat({required this.type, required this.label, required this.count});
}
```

Replace `getGameModeStats()` and delete `_formatModeName` entirely:

```dart
  /// Répartition des modes de jeu (pour le graphique), triée par nombre
  /// de parties décroissant.
  List<GameModeStat> getGameModeStats() {
    final Map<GameType, int> counts = {};

    for (final entry in _history.entries) {
      final type = GameTypeIdentity.fromStorageId(entry.gameMode ?? 'classic');
      counts[type] = (counts[type] ?? 0) + 1;
    }

    final stats = counts.entries
        .map((e) => GameModeStat(type: e.key, label: e.key.statsLabel, count: e.value))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    return stats;
  }
```

(Remove the old `_formatModeName(String modeId)` method — it's fully replaced by `GameType.statsLabel`.)

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/providers/statistics_provider_test.dart`
Expected: PASS

- [ ] **Step 5: Update `lib/screens/stats/widgets/game_mode_stats_widget.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:language_learning_app/core/theme/app_colors.dart';
import 'package:language_learning_app/data/models/game_mode.dart';
import 'package:language_learning_app/providers/statistics_provider.dart';
import 'package:language_learning_app/l10n/app_localizations.dart';

class GameModeStatsWidget extends StatelessWidget {
  final List<GameModeStat> data;

  const GameModeStatsWidget({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (data.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(l10n.noGameData),
        ),
      );
    }

    final totalPlays = data.fold(0, (sum, item) => sum + item.count);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: data.map((stat) {
          final percentage = stat.count / totalPlays;

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _getModeIcon(stat.type),
                        const SizedBox(width: 8),
                        Text(
                          stat.label,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${(percentage * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Stack(
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: percentage,
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: _getModeColor(stat.type),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.gamesPlayed(stat.count),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _getModeColor(GameType type) {
    switch (type) {
      case GameType.classic:
        return AppColors.primary;
      case GameType.reverse:
        return AppColors.secondary;
      case GameType.quiz:
        return Colors.orange;
      case GameType.sentence:
      case GameType.memory:
        return Colors.teal;
    }
  }

  Widget _getModeIcon(GameType type) {
    IconData icon;
    switch (type) {
      case GameType.classic:
        icon = Icons.school;
        break;
      case GameType.reverse:
        icon = Icons.swap_horiz;
        break;
      case GameType.quiz:
        icon = Icons.timer;
        break;
      case GameType.sentence:
      case GameType.memory:
        icon = Icons.gamepad;
    }
    final color = _getModeColor(type);

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 16, color: color),
    );
  }
}
```

- [ ] **Step 6: Run `flutter analyze`**

Run: `flutter analyze`
Expected: 0 issues (`lib/screens/stats/statistics_screen.dart` needs no change — `GameModeStatsWidget(data: statsProvider.getGameModeStats())` still type-checks since both sides now agree on `List<GameModeStat>`).

- [ ] **Step 7: Run the full test suite**

Run: `flutter test`
Expected: PASS

- [ ] **Step 8: Commit**

```bash
git add lib/providers/statistics_provider.dart lib/screens/stats/widgets/game_mode_stats_widget.dart test/providers/statistics_provider_test.dart
git commit -m "refactor: statistics use typed GameModeStat instead of label-keyed map entries"
```

---

### Task 10: Final verification

**Files:** none (verification only).

- [ ] **Step 1: Full static analysis**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 2: Full test suite**

Run: `flutter test`
Expected: all tests PASS — the original 6 files plus `test/data/models/game_mode_test.dart`, `test/data/models/sentence_test.dart`, `test/providers/game_provider_test.dart`, `test/providers/statistics_provider_test.dart`, `test/data/repositories/deck_repository_test.dart` (11 files total).

- [ ] **Step 3: Codegen is clean and idempotent**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: no diffs after running (`git status` shows nothing under `lib/data/models/*.g.dart` changed) — confirms the committed generated files match their sources.

- [ ] **Step 4: Deck manifest still generates correctly**

Run: `make generate-manifest`
Expected: same deck count as Task 3's check, no errors.

- [ ] **Step 5: Manual smoke test (not automated — no widget tests were in scope per the spec)**

Run: `flutter run` on a connected device/emulator, or `flutter run -d chrome` / `flutter run -d linux` if no device is available. Manually verify:
- Select a deck, play Classic mode: spin, answer correctly and incorrectly, confirm the word list badge count updates.
- Play Reverse mode: confirm the "REVERSE" badge shows and the question is the *answer* side of a word.
- Play Quiz mode: confirm 4 options show including the correct one, and the "QUIZ MODE" badge shows.
- Play Phrase (sentence) mode: confirm the "PHRASE" badge shows, blocks can be tapped/untapped, and constructing the correct sentence advances.
- Reset a deck's progress (Settings → reset) and confirm progress for *every* mode (including quiz/sentence) is actually cleared — this is the direct manual check for the Task 8 fix.
- Open the Statistics screen and confirm the "Modes de jeu favoris" section still renders correctly with icons/colors/percentages.
- Create a custom deck (add/edit a word) via the deck editor, confirm it saves and loads correctly.

- [ ] **Step 6: Confirm the working tree is clean and every task's commit is present**

Run: `git log --oneline b900bca..HEAD`
Expected: one commit per task (10 commits, Tasks 1–9 producing code + Task 10 producing none since it's verification-only).

- [ ] **Step 7: Confirm `DeckRepository`'s interface stays Phase-2-ready (spec Q5)**

Run: `grep -n "SharedPreferences\|StorageHelper\|rootBundle" lib/providers/*.dart`
Expected: no matches. `DeckRepository` (in `lib/data/repositories/`) is the only place importing `StorageHelper`/`rootBundle` — `GameProvider`, `DeckProvider`, and `StatisticsProvider` only ever call methods on `DeckRepository`/their own storage key, never touch `SharedPreferences` or asset loading directly. This was already true at the start of this plan and nothing in Tasks 1–9 changed it (Task 8 only changed *what* `resetAllProgressForDeck` iterates over, not its signature or callers) — this step is the recorded proof, not a fix. If it ever fails, that regression must be reverted before Phase 2 (Supabase) work starts, since Phase 2 depends on swapping `DeckRepository`'s internals without touching providers.
