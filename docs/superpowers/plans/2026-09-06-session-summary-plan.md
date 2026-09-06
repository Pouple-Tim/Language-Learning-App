# Session Summary on the CompletedCard — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** When a deck round finishes, the `CompletedCard` shows what happened *this session* — N learned, X first-try, M to review — plus an expandable list (`prompt → réponse`) of the items missed ≥ 2 times.

**Architecture:** `GameProvider` gains transient per-session counters (`_sessionCompleted` set, `_sessionMistakes` map), cleared on `setDeck` / `resetDeck`, updated from the existing answer methods. The `CompletedCard` becomes a `StatefulWidget` that reads those counters via `context.watch<GameProvider>()` and renders a collapsible review list. No persistence, no `StatisticsProvider` change, no new analytics.

**Tech Stack:** Flutter, `provider`, `flutter gen-l10n` (en/fr/es/it), `flutter_test`.

**Spec:** `docs/superpowers/specs/2026-09-06-session-summary-design.md` — read it alongside this plan.

## Global Constraints

- **"Correct / wrong" = first-try rule:** an item is clean iff solved with zero wrong submissions this session, regardless of attempt count.
- **Review-list threshold:** an item appears in the list at **≥ 2** wrong submissions this session.
- **Review-list row:** canonical `prompt → answer` pair (foreign → native) for words, `original → translation` for sentences — the SAME direction even in reverse mode.
- **Session lifetime:** counters are in-memory on `GameProvider`, cleared at the top of `setDeck(...)` and inside `resetDeck()`. No persistence.
- **No change** to `StatisticsProvider` / `ReviewHistory`; no new analytics event.
- **`checkAnswer` / `checkSentenceConstruction` keep returning `false` on the wrong path without an added `notifyListeners()`** — the card only mounts once `isCompleted`, nothing observes the counters mid-play.
- **Constructor `CompletedCard({required this.onRestart})` and its call site in `game_screen.dart` do not change.**
- Branch `feature/session-summary` off `develop`. Toolchain Flutter 3.47.1 / Dart 3.13.1 (analyzer strict, records available).
- Test bar: `flutter analyze` clean (no new issues) + `flutter test` green. No widget test for `CompletedCard` (consistent with the daily-goal work). Manual phone smoke at the end only.

---

### Task 1: GameProvider session tracking

**Files:**
- Modify: `lib/providers/game_provider.dart`
- Modify: `lib/screens/games/classic_game/widgets/drawing_widget.dart` (one line)
- Test: `test/providers/game_provider_test.dart` (new group)

**Interfaces:**
- Consumes: existing `GameProvider` internals — `_currentWord` (`Word?`), `_currentSentence` (`Sentence?`), `_currentProgressDeck` (`Deck?`), and the methods `setDeck`, `resetDeck`, `checkAnswer`, `checkSentenceConstruction`, `markCurrentWordAsCorrect`.
- Produces on `GameProvider`:
  - `int get sessionLearnedCount`
  - `int get sessionFirstTryCount`
  - `int get sessionToReviewCount`
  - `List<({String prompt, String answer})> get sessionWordsToReview`
  - `void recordMistakeForCurrentWord()`

- [ ] **Step 1: Write the failing tests**

Add to `test/providers/game_provider_test.dart` a new group (place it after the `GameProvider.checkAnswer` group). `_buildDeck` / `_oneWordDeck` helpers already exist at the top of the file. `GameProvider()` is constructed with no `statisticsProvider` (null) — session tracking must not depend on it.

```dart
  group('GameProvider - session summary', () {
    test('fresh session has zero counts and an empty review list', () async {
      final provider = GameProvider();
      await provider.setDeck(_buildDeck(), gameMode: GameType.classic);

      expect(provider.sessionLearnedCount, 0);
      expect(provider.sessionFirstTryCount, 0);
      expect(provider.sessionToReviewCount, 0);
      expect(provider.sessionWordsToReview, isEmpty);
    });

    test('a word solved on the first try counts as learned + first-try', () async {
      final provider = GameProvider();
      await provider.setDeck(_oneWordDeck(), gameMode: GameType.classic);
      await provider.spinWheel();

      await provider.checkAnswer('one');

      expect(provider.sessionLearnedCount, 1);
      expect(provider.sessionFirstTryCount, 1);
      expect(provider.sessionToReviewCount, 0);
    });

    test('one mistake then correct: learned, not first-try, not to-review', () async {
      final provider = GameProvider();
      await provider.setDeck(_oneWordDeck(), gameMode: GameType.classic);
      await provider.spinWheel();

      await provider.checkAnswer('nope');
      await provider.checkAnswer('one');

      expect(provider.sessionLearnedCount, 1);
      expect(provider.sessionFirstTryCount, 0);
      expect(provider.sessionToReviewCount, 0);
      expect(provider.sessionWordsToReview, isEmpty);
    });

    test('two mistakes then correct: item enters the review list with its pair', () async {
      final provider = GameProvider();
      await provider.setDeck(_oneWordDeck(), gameMode: GameType.classic);
      await provider.spinWheel();

      await provider.checkAnswer('nope');
      await provider.checkAnswer('nope');
      await provider.checkAnswer('one');

      expect(provider.sessionToReviewCount, 1);
      expect(provider.sessionWordsToReview, [(prompt: 'un', answer: 'one')]);
    });

    test('two words: one clean, one missed twice', () async {
      final provider = GameProvider();
      await provider.setDeck(_buildDeck(wordCount: 2), gameMode: GameType.classic);

      await provider.spinWheel();
      final first = provider.currentWord!;
      await provider.checkAnswer('x');
      await provider.checkAnswer('x');
      await provider.checkAnswer(first.answer);

      await provider.spinWheel();
      final second = provider.currentWord!;
      await provider.checkAnswer(second.answer);

      expect(provider.sessionLearnedCount, 2);
      expect(provider.sessionFirstTryCount, 1);
      expect(provider.sessionToReviewCount, 1);
      expect(provider.sessionWordsToReview,
          [(prompt: first.prompt, answer: first.answer)]);
    });

    test('setDeck clears the session counters', () async {
      final provider = GameProvider();
      await provider.setDeck(_oneWordDeck(), gameMode: GameType.classic);
      await provider.spinWheel();
      await provider.checkAnswer('one');
      expect(provider.sessionLearnedCount, 1);

      await provider.setDeck(_oneWordDeck(), gameMode: GameType.classic);
      expect(provider.sessionLearnedCount, 0);
      expect(provider.sessionWordsToReview, isEmpty);
    });

    test('resetDeck clears the session counters', () async {
      final provider = GameProvider();
      await provider.setDeck(_oneWordDeck(), gameMode: GameType.classic);
      await provider.spinWheel();
      await provider.checkAnswer('nope');
      await provider.checkAnswer('nope');
      await provider.checkAnswer('one');
      expect(provider.sessionToReviewCount, 1);

      await provider.resetDeck();
      expect(provider.sessionLearnedCount, 0);
      expect(provider.sessionToReviewCount, 0);
      expect(provider.sessionWordsToReview, isEmpty);
    });

    test('recordMistakeForCurrentWord bumps the mistake count for the current word', () async {
      final provider = GameProvider();
      await provider.setDeck(_oneWordDeck(), gameMode: GameType.classic);
      await provider.spinWheel();

      provider.recordMistakeForCurrentWord();
      provider.recordMistakeForCurrentWord();
      await provider.checkAnswer('one');

      expect(provider.sessionToReviewCount, 1);
      expect(provider.sessionWordsToReview, [(prompt: 'un', answer: 'one')]);
    });

    test('sentence mode: two wrong then correct enters the review list with original -> translation', () async {
      final provider = GameProvider();
      final deck = _buildDeck(sentences: [
        Sentence(id: 's1', original: 'Bonjour', translation: 'nihao', blocks: ['ni', 'hao', 'bu']),
      ]);
      await provider.setDeck(deck, gameMode: GameType.sentence);
      await provider.spinWheel();

      provider.addBlockToSentence('hao');
      provider.addBlockToSentence('ni');
      await provider.checkSentenceConstruction(); // wrong

      provider.removeBlockFromSentence('hao');
      provider.removeBlockFromSentence('ni');
      provider.addBlockToSentence('bu');
      provider.addBlockToSentence('hao');
      await provider.checkSentenceConstruction(); // wrong

      provider.removeBlockFromSentence('bu');
      provider.removeBlockFromSentence('hao');
      provider.addBlockToSentence('ni');
      provider.addBlockToSentence('hao');
      await provider.checkSentenceConstruction(); // correct

      expect(provider.sessionToReviewCount, 1);
      expect(provider.sessionWordsToReview,
          [(prompt: 'Bonjour', answer: 'nihao')]);
    });
  });
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/providers/game_provider_test.dart -r expanded`
Expected: FAIL — `sessionLearnedCount` / `recordMistakeForCurrentWord` not defined on `GameProvider`.

- [ ] **Step 3: Add the session state and getters to `GameProvider`**

In `lib/providers/game_provider.dart`, in the "État du jeu en cours" field block (after `_currentProgressDeck`), add:

```dart
  // Suivi de la session courante (transitoire, jamais persisté).
  // Vidé dans setDeck() et resetDeck().
  final Set<String> _sessionCompleted = {};
  final Map<String, int> _sessionMistakes = {};
```

In the GETTERS section (near `isCompleted`), add:

```dart
  /// Éléments (mots ou phrases) complétés pendant cette session.
  int get sessionLearnedCount => _sessionCompleted.length;

  /// Parmi les complétés, ceux réussis sans aucune faute.
  int get sessionFirstTryCount =>
      _sessionCompleted.where((id) => (_sessionMistakes[id] ?? 0) == 0).length;

  /// Parmi les complétés, ceux ratés au moins 2 fois cette session.
  int get sessionToReviewCount =>
      _sessionCompleted.where((id) => (_sessionMistakes[id] ?? 0) >= 2).length;

  /// Les éléments "à revoir" (>= 2 fautes), les plus ratés d'abord.
  /// Paire canonique prompt -> réponse (phrases : original -> traduction),
  /// quel que soit le mode de jeu.
  List<({String prompt, String answer})> get sessionWordsToReview {
    final deck = _currentProgressDeck;
    if (deck == null) return const [];

    final ids = _sessionCompleted
        .where((id) => (_sessionMistakes[id] ?? 0) >= 2)
        .toList()
      ..sort((a, b) =>
          (_sessionMistakes[b] ?? 0).compareTo(_sessionMistakes[a] ?? 0));

    final result = <({String prompt, String answer})>[];
    for (final id in ids) {
      Word? word;
      for (final w in deck.words) {
        if (w.id == id) {
          word = w;
          break;
        }
      }
      if (word != null) {
        result.add((prompt: word.prompt, answer: word.answer));
        continue;
      }
      for (final s in deck.sentences) {
        if (s.id == id) {
          result.add((prompt: s.original, answer: s.translation));
          break;
        }
      }
    }
    return result;
  }

  /// Enregistre une faute manuelle (mode dessin : bouton "non").
  void recordMistakeForCurrentWord() {
    final id = _currentWord?.id;
    if (id == null) return;
    _sessionMistakes[id] = (_sessionMistakes[id] ?? 0) + 1;
  }
```

- [ ] **Step 4: Clear the counters in `setDeck` and `resetDeck`**

In `setDeck(...)`, right after `_currentGameType = gameMode;` (near the top), add:

```dart
    _sessionCompleted.clear();
    _sessionMistakes.clear();
```

In `resetDeck()`, right after the `if (_currentProgressDeck == null ...) return;` guard, add the same two lines:

```dart
    _sessionCompleted.clear();
    _sessionMistakes.clear();
```

- [ ] **Step 5: Record completions and mistakes in the answer methods**

In `checkAnswer(String userAnswer)`, inside the `if (isCorrect) { ... }` block add `_sessionCompleted.add(_currentWord!.id);` as the first line; on the wrong path (the code after that block, before `debugPrint('❌ Mauvaise réponse')`) add:

```dart
    _sessionMistakes[_currentWord!.id] =
        (_sessionMistakes[_currentWord!.id] ?? 0) + 1;
```

In `checkSentenceConstruction()`, inside the `if (isCorrect) { ... }` block add `_sessionCompleted.add(_currentSentence!.id);` as the first line; just before the final `debugPrint('❌ Phrase incorrecte.'); return false;` add:

```dart
    _sessionMistakes[_currentSentence!.id] =
        (_sessionMistakes[_currentSentence!.id] ?? 0) + 1;
```

In `markCurrentWordAsCorrect()`, add `_sessionCompleted.add(_currentWord!.id);` as the first line after the null guard.

- [ ] **Step 6: Wire the drawing "non" path**

In `lib/screens/games/classic_game/widgets/drawing_widget.dart`, method `_handleValidation(bool isCorrect)`: it already does `await statsProvider.addReview(...)`. Immediately after that `addReview` call, add:

```dart
    if (!isCorrect) {
      gameProvider.recordMistakeForCurrentWord();
    }
```

(`gameProvider` is already the local `context.read<GameProvider>()` in that method.)

- [ ] **Step 7: Run tests to verify they pass**

Run: `flutter test test/providers/game_provider_test.dart -r expanded`
Expected: PASS (whole file, including the 9 new session-summary tests).

Run: `flutter analyze`
Expected: no new issues.

- [ ] **Step 8: Commit**

```bash
git add lib/providers/game_provider.dart lib/screens/games/classic_game/widgets/drawing_widget.dart test/providers/game_provider_test.dart
git commit -m "feat: track per-session completions and mistakes in GameProvider"
```

---

### Task 2: l10n keys for the session summary

**Files:**
- Modify: `lib/l10n/app_en.arb` (template — keys + `@` metadata for the 3 count keys)
- Modify: `lib/l10n/app_fr.arb`, `lib/l10n/app_es.arb`, `lib/l10n/app_it.arb`
- Generated: `lib/l10n/app_localizations*.dart` via `flutter gen-l10n`

**Interfaces:**
- Produces these `AppLocalizations` members used by Task 3:
  - `sessionSummaryLearned(int count)` → "{count} learned"
  - `sessionSummaryFirstTry(int count)` → "{count} first try"
  - `sessionSummaryToReview(int count)` → "{count} to review"
  - `sessionSummaryPerfect` → "Flawless 🎯"

- [ ] **Step 1: Add keys to the template `lib/l10n/app_en.arb`**

Append before the closing `}` (previous last keys are the `dayCount` / `dailyGoal*` block — add a comma after the current last value):

```json
  ,
  "sessionSummaryLearned": "{count} learned",
  "@sessionSummaryLearned": {
    "placeholders": { "count": { "type": "int" } }
  },
  "sessionSummaryFirstTry": "{count} first try",
  "@sessionSummaryFirstTry": {
    "placeholders": { "count": { "type": "int" } }
  },
  "sessionSummaryToReview": "{count} to review",
  "@sessionSummaryToReview": {
    "placeholders": { "count": { "type": "int" } }
  },
  "sessionSummaryPerfect": "Flawless 🎯"
```

- [ ] **Step 2: Add the French keys to `lib/l10n/app_fr.arb`** (before the closing `}`, comma after the current last value; no `@` blocks)

```json
  ,
  "sessionSummaryLearned": "{count} appris",
  "sessionSummaryFirstTry": "{count} du premier coup",
  "sessionSummaryToReview": "{count} à revoir",
  "sessionSummaryPerfect": "Sans faute 🎯"
```

- [ ] **Step 3: Add the Spanish keys to `lib/l10n/app_es.arb`**

```json
  ,
  "sessionSummaryLearned": "{count} aprendidas",
  "sessionSummaryFirstTry": "{count} a la primera",
  "sessionSummaryToReview": "{count} para repasar",
  "sessionSummaryPerfect": "Sin fallos 🎯"
```

- [ ] **Step 4: Add the Italian keys to `lib/l10n/app_it.arb`**

```json
  ,
  "sessionSummaryLearned": "{count} imparate",
  "sessionSummaryFirstTry": "{count} al primo colpo",
  "sessionSummaryToReview": "{count} da rivedere",
  "sessionSummaryPerfect": "Senza errori 🎯"
```

- [ ] **Step 5: Regenerate and verify**

Run: `flutter gen-l10n`
Expected: completes with no error and no untranslated-message warning for the new keys.

Run: `flutter analyze`
Expected: no new issues.

- [ ] **Step 6: Commit**

```bash
git add lib/l10n/
git commit -m "feat: add session-summary l10n keys (en/fr/es/it)"
```

---

### Task 3: CompletedCard session-summary UI

**Files:**
- Modify: `lib/screens/games/classic_game/widgets/completed_card.dart`

**Interfaces:**
- Consumes: `GameProvider.sessionLearnedCount` / `sessionFirstTryCount` / `sessionToReviewCount` / `sessionWordsToReview` (Task 1); `AppLocalizations` session keys (Task 2). Keeps using `StatisticsProvider` + `GoalProvider` for the existing goal block.
- Produces: nothing consumed downstream.

- [ ] **Step 1: Convert `CompletedCard` to a `StatefulWidget`**

Replace the class declaration and `build` signature:

```dart
class CompletedCard extends StatefulWidget {
  final VoidCallback onRestart;

  const CompletedCard({super.key, required this.onRestart});

  @override
  State<CompletedCard> createState() => _CompletedCardState();
}

class _CompletedCardState extends State<CompletedCard> {
  bool _reviewExpanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // ... existing Card body, but see Steps 2-3 ...
  }
```

Every existing `onRestart` reference in the body becomes `widget.onRestart`. `_buildGoalProgress(context)` stays a method on the State class, unchanged.

- [ ] **Step 2: Wrap the card content in a scroll view**

The `Card`'s `child` is currently `Padding(padding: EdgeInsets.all(24), child: Column(mainAxisSize: min, ...))`. Wrap that `Column` in a `SingleChildScrollView`:

```dart
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ... existing children, plus the session block from Step 3 ...
          ],
        ),
      ),
```

(Remove the old `Padding` wrapper — the padding moves onto the `SingleChildScrollView`.)

- [ ] **Step 3: Insert the session-stats block**

Between the `l10n.completedMessage` `Text` (+ its trailing `SizedBox(height: 20)`) and the `_buildGoalProgress(context)` call, insert `_buildSessionSummary(context)`:

```dart
            const SizedBox(height: 20),
            _buildSessionSummary(context),
            _buildGoalProgress(context),
```

Keep exactly one `SizedBox(height: 20)` before `_buildSessionSummary` and rely on `_buildSessionSummary` to add its own bottom spacing (or return `SizedBox.shrink()` contributing nothing when there is no session). Concretely: `_buildGoalProgress` already has no leading gap of its own, so `_buildSessionSummary` must end with a `SizedBox(height: 20)` when it renders content, and return `const SizedBox.shrink()` when `sessionLearnedCount == 0`.

- [ ] **Step 4: Implement `_buildSessionSummary`**

Add this method to `_CompletedCardState`:

```dart
  Widget _buildSessionSummary(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final game = context.watch<GameProvider>();
    final learned = game.sessionLearnedCount;
    if (learned == 0) return const SizedBox.shrink();

    final firstTry = game.sessionFirstTryCount;
    final toReview = game.sessionToReviewCount;
    final reviewItems = game.sessionWordsToReview;
    final textTheme = Theme.of(context).textTheme;

    Widget chip(String label, {VoidCallback? onTap, bool trailingChevron = false}) {
      final content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: textTheme.bodyMedium),
          if (trailingChevron)
            Icon(
              _reviewExpanded ? Icons.expand_less : Icons.expand_more,
              size: 18,
            ),
        ],
      );
      final padded = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: content,
      );
      final decorated = Container(
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: onTap == null
            ? padded
            : InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: onTap,
                child: padded,
              ),
      );
      return decorated;
    }

    return Column(
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            chip(l10n.sessionSummaryLearned(learned)),
            if (firstTry < learned)
              chip(l10n.sessionSummaryFirstTry(firstTry)),
            if (toReview > 0)
              chip(
                l10n.sessionSummaryToReview(toReview),
                trailingChevron: true,
                onTap: () =>
                    setState(() => _reviewExpanded = !_reviewExpanded),
              )
            else
              chip(l10n.sessionSummaryPerfect),
          ],
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: _reviewExpanded && reviewItems.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    children: [
                      for (final item in reviewItems)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  item.prompt,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                              const Padding(
                                padding:
                                    EdgeInsets.symmetric(horizontal: 8),
                                child: Icon(Icons.arrow_forward, size: 14),
                              ),
                              Flexible(
                                child: Text(
                                  item.answer,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
```

- [ ] **Step 5: Add the import**

At the top of `completed_card.dart`, add:

```dart
import 'package:language_learning_app/providers/game_provider.dart';
```

- [ ] **Step 6: Verify**

Run: `flutter analyze`
Expected: no new issues (in particular: no leftover `CompletedCard.build` on the old class, no unused import, no `use_build_context_synchronously`).

Run: `flutter test`
Expected: all green (no widget test for this file; the full suite must still pass — `game_provider_test.dart` from Task 1 included).

- [ ] **Step 7: Commit**

```bash
git add lib/screens/games/classic_game/widgets/completed_card.dart
git commit -m "feat: session summary + review list on the completed card"
```

---

### Task 4: Verification + phone smoke

**Files:** none (verification only).

- [ ] **Step 1: Analyze + test**

Run: `flutter analyze` → `No issues found!`
Run: `flutter test` → all pass, including the 9 new `game_provider_test.dart` session-summary tests.

- [ ] **Step 2: l10n build**

Run: `flutter gen-l10n` → clean, no untranslated-message warnings for `sessionSummary*`.

- [ ] **Step 3: Build + install on the phone**

```bash
flutter build apk --debug
adb -s <device> install -r build/app/outputs/flutter-apk/app-debug.apk
adb -s <device> shell am force-stop com.timouss.linguo
adb -s <device> shell monkey -p com.timouss.linguo -c android.intent.category.LAUNCHER 1
```

Then ask the user to: play a short round in classic mode, deliberately mistyping one word 2+ times before getting it right, finish the deck, and confirm on the CompletedCard: the "N appris · X du premier coup · M à revoir" row shows, tapping "M à revoir" expands the `prompt → réponse` list, and the card scrolls if the list is long. Screenshot read-only for the report; do not drive the phone.

- [ ] **Step 4: Report**

Summarise: what shipped, the first-try rule, the ≥ 2 threshold, and note the branch is ready to merge into `develop`.

---

## Self-Review

**1. Spec coverage:**

| Spec item | Task |
|---|---|
| `_sessionCompleted` / `_sessionMistakes`, cleared on setDeck/resetDeck | Task 1 Steps 3–4 |
| `sessionLearnedCount` / `sessionFirstTryCount` / `sessionToReviewCount` / `sessionWordsToReview` | Task 1 Step 3 |
| Recording in checkAnswer / checkSentenceConstruction / markCurrentWordAsCorrect | Task 1 Step 5 |
| `recordMistakeForCurrentWord()` + drawing "non" wiring | Task 1 Steps 3, 6 |
| First-try rule (0 mistakes = clean) | `sessionFirstTryCount` definition, Task 1 Step 3 |
| ≥ 2 threshold for the review list | `sessionToReviewCount` / `sessionWordsToReview`, Task 1 Step 3 |
| Canonical `prompt → answer` / `original → translation`, reverse included | `sessionWordsToReview`, Task 1 Step 3 |
| No StatisticsProvider / analytics change | nothing in any task touches them |
| No wrong-path `notifyListeners()` added | Task 1 Step 5 adds only map writes, no notify |
| l10n: 4 keys × 4 locales, `@` in template only | Task 2 |
| CompletedCard → StatefulWidget, session block, expandable list | Task 3 Steps 1, 3–4 |
| Card scrollable | Task 3 Step 2 |
| Session block hidden when `sessionLearnedCount == 0` | Task 3 Step 4 (`return const SizedBox.shrink()`) |
| "first try" chip dropped when it equals "learned" | Task 3 Step 4 (`if (firstTry < learned)`) |
| Constructor + `game_screen.dart` call site unchanged | not touched in any task |
| Manual phone smoke | Task 4 Step 3 |

No gaps.

**2. Placeholder scan:** no TBD / "add error handling" / "similar to Task N" — every code step is literal. The one conditional (Task 2 trailing comma) is resolved by the `flutter gen-l10n` check in the same task.

**3. Type consistency:**
- `sessionWordsToReview` returns `List<({String prompt, String answer})>` in Task 1; Task 1's tests compare against `(prompt: ..., answer: ...)` records; Task 3 reads `item.prompt` / `item.answer`. Consistent.
- `recordMistakeForCurrentWord()` → `void`, defined Task 1 Step 3, called Task 1 Step 6. Consistent.
- l10n: `sessionSummaryLearned(int)` / `sessionSummaryFirstTry(int)` / `sessionSummaryToReview(int)` / `sessionSummaryPerfect` (getter) defined Task 2, used Task 3 Step 4 with those exact arities.

---

## Pre-work

```bash
git checkout develop && git pull
git checkout -b feature/session-summary
git branch --show-current   # must print feature/session-summary
```

## Execution Handoff

Two options:

1. **Subagent-Driven (recommended)** — fresh subagent per task, review between tasks.
2. **Inline Execution** — tasks in this session via `superpowers:executing-plans`.

Which approach?
