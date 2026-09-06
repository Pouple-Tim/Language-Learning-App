# Session summary on the CompletedCard — Design

**Status:** approved direction, pending spec review
**Date:** 2026-09-06
**Context:** follow-up to roadmap item #7 (daily goal). During the real-device
review the user asked for the end-of-round card to show what happened *this
session*, including which words gave them trouble. #7 deliberately scoped this
out because the game loop tracks nothing per-session — every answer goes
straight into `StatisticsProvider.addReview` and is forgotten.

---

## Goal

When a deck round finishes, the `CompletedCard` shows, for **this session
only**:

1. **N appris** — items (words or sentences) completed during this session
2. **X du premier coup** — of those, how many with zero wrong submissions
3. **M à revoir** — of those, how many with ≥ 2 wrong submissions this session
4. An expandable list of the "à revoir" items: `prompt → réponse`, so the user
   sees exactly which ones to focus on.

"Correct / wrong" for the headline uses the **first-try rule**: an item counts
as clean if solved with no mistake, regardless of how many attempts it took.

---

## Non-goals

- No session duration, XP, or per-mode breakdown.
- No persistence of session data — it lives only in memory for the current
  `GameProvider` session and is gone when a new session starts.
- No change to `StatisticsProvider` / `ReviewHistory` (the long-term log is
  unaffected; this is purely a transient per-session view).
- No new analytics event.

---

## Component 1 — Session tracking in `GameProvider`

`GameProvider` gains transient per-session state. A "session" is one
`setDeck(...)` load; it also restarts on `resetDeck()`.

### State (private fields)

```dart
/// ids (Word.id or Sentence.id) first completed during this session
final Set<String> _sessionCompleted = {};

/// id → number of wrong submissions recorded this session (accumulates only
/// while the item is still active; an item can't reappear once completed)
final Map<String, int> _sessionMistakes = {};
```

Both are cleared at the top of `setDeck(...)` and inside `resetDeck()`.

### Getters

```dart
int get sessionLearnedCount => _sessionCompleted.length;

int get sessionFirstTryCount =>
    _sessionCompleted.where((id) => (_sessionMistakes[id] ?? 0) == 0).length;

int get sessionToReviewCount =>
    _sessionCompleted.where((id) => (_sessionMistakes[id] ?? 0) >= 2).length;

/// The "à revoir" items (≥ 2 mistakes), most-missed first.
/// Resolved against the in-memory session deck. `(prompt, answer)` is the
/// canonical foreign→native pair regardless of game mode (reverse included).
/// For sentence mode: (original, translation).
List<({String prompt, String answer})> get sessionWordsToReview;
```

`sessionWordsToReview` implementation: iterate `_sessionCompleted`, keep ids
with `_sessionMistakes[id] >= 2`, resolve each against
`_currentProgressDeck.words` (by `id`) or `_currentProgressDeck.sentences` (by
`id`), sort by mistake count descending. Ids that no longer resolve (deck
content changed under a saved session — rare) are skipped.

> **Type note:** uses a Dart record `({String prompt, String answer})`. Records
> are available (Dart 3.13). If the implementer prefers, a tiny value class
> `SessionReviewItem { final String prompt, answer; }` is an acceptable
> substitute — the plan may choose.

### Recording — call sites

| Method | On wrong | On correct |
|---|---|---|
| `checkAnswer(userAnswer)` (classic / reverse / quiz / listening / memory) | `_sessionMistakes[_currentWord!.id] = (…) + 1` | `_sessionCompleted.add(_currentWord!.id)` |
| `checkSentenceConstruction()` (sentence) | `_sessionMistakes[_currentSentence!.id] = (…) + 1` | `_sessionCompleted.add(_currentSentence!.id)` |
| `markCurrentWordAsCorrect()` (drawing — manual "oui") | — | `_sessionCompleted.add(_currentWord!.id)` |
| **new** `recordMistakeForCurrentWord()` | `_sessionMistakes[_currentWord!.id] = (…) + 1` | — |

All these methods already call `notifyListeners()` on their success path.
`checkAnswer` / `checkSentenceConstruction` currently return `false` on the
wrong path without notifying; leave that as-is — the card is only built once
`isCompleted`, so nothing observes the mistake counters mid-play, and adding
notifies to the hot wrong path (every failed keystroke-submit) is churn for
no observable benefit. The counters are read once, when the card mounts.

`recordMistakeForCurrentWord()` is a new one-line public method that bumps the
mistake count for `_currentWord` (guarded for null) and does **not** notify.

### Drawing "non" path

`drawing_widget.dart` → `_handleValidation(false)` currently calls only
`statsProvider.addReview(...)` directly. Add one line:
`context.read<GameProvider>().recordMistakeForCurrentWord();` right after the
existing `addReview` call, so drawing mistakes feed the session summary.

---

## Component 2 — `CompletedCard` redesign

File: `lib/screens/games/classic_game/widgets/completed_card.dart`.

### Structure changes

- **`StatelessWidget` → `StatefulWidget`** — needs a `bool _reviewExpanded`
  toggle.
- Constructor unchanged (`CompletedCard({required this.onRestart})`); call
  site in `game_screen.dart` unchanged.
- The card's inner `Column` is wrapped in a `SingleChildScrollView` so a long
  review list scrolls instead of overflowing (the card sits in
  `Expanded > Center` in `game_screen.dart`).

### Layout (top to bottom)

1. `Icons.celebration` + `l10n.completed` + `l10n.completedMessage` — unchanged.
2. **Session stats block — only when `sessionLearnedCount > 0`:**
   - a `Wrap` (spacing) of up to three chips/figures:
     - `l10n.sessionSummaryLearned(sessionLearnedCount)`
     - `l10n.sessionSummaryFirstTry(sessionFirstTryCount)`
     - if `sessionToReviewCount > 0`:
       `l10n.sessionSummaryToReview(sessionToReviewCount)` rendered as an
       `InkWell` (with a chevron that rotates on expand) toggling
       `_reviewExpanded`
     - else: `l10n.sessionSummaryPerfect` (e.g. "Sans faute 🎯"), not tappable
   - `AnimatedSize` (or `AnimatedCrossFade`) revealing, when `_reviewExpanded`,
     a `Column` of rows — one per `sessionWordsToReview` entry:
     `Text(prompt)` · `Icon(Icons.arrow_forward, size: 14)` · `Text(answer)`,
     each row `Flexible` + `TextOverflow.ellipsis`, small vertical padding.
   - When `sessionLearnedCount == 0` (e.g. re-entering an already-finished
     mode) the whole block is omitted — nothing happened this session.
   - When every completed item was clean (`sessionFirstTryCount ==
     sessionLearnedCount`), the "first try" figure duplicates the "learned"
     figure — the plan may drop the "first try" chip in that case and let
     `sessionSummaryPerfect` carry the meaning, or keep both. Implementer's
     call; both are acceptable.
3. Goal progress block (ring + streak) — **unchanged** (Task 6 code).
4. Restart button — unchanged.

### Providers read by the card

Already reads `StatisticsProvider` + `GoalProvider` (Task 6). Add
`context.watch<GameProvider>()` for the session getters. `GameProvider` is
app-scoped (`ChangeNotifierProxyProvider` in `main.dart`), so it resolves.

---

## Component 3 — l10n

Four new keys in all four `lib/l10n/app_{en,fr,es,it}.arb`; the three
count keys get `@` placeholder metadata (`int`) in `app_en.arb` only. Regenerate
with `flutter gen-l10n`.

| key | en | fr | es | it |
|---|---|---|---|---|
| `sessionSummaryLearned` | `{count} learned` | `{count} appris` | `{count} aprendidas` | `{count} imparate` |
| `sessionSummaryFirstTry` | `{count} first try` | `{count} du premier coup` | `{count} a la primera` | `{count} al primo colpo` |
| `sessionSummaryToReview` | `{count} to review` | `{count} à revoir` | `{count} para repasar` | `{count} da rivedere` |
| `sessionSummaryPerfect` | `Flawless 🎯` | `Sans faute 🎯` | `Sin fallos 🎯` | `Senza errori 🎯` |

---

## Testing

**`test/providers/game_provider_test.dart`** — new group `session summary`:

1. fresh session (`setDeck`) → all three counts are 0, `sessionWordsToReview` empty.
2. classic: answer a word correctly first try → `sessionLearnedCount == 1`,
   `sessionFirstTryCount == 1`, `sessionToReviewCount == 0`.
3. classic: one wrong then correct → learned 1, first-try 0, to-review 0
   (1 mistake < 2), `sessionWordsToReview` empty.
4. classic: two wrong then correct → to-review 1, `sessionWordsToReview` has
   one entry with the word's `(prompt, answer)`.
5. two different words, one clean and one missed twice → learned 2,
   first-try 1, to-review 1.
6. `setDeck` again → counts reset to 0.
7. `resetDeck()` → counts reset to 0.
8. sentence mode: two wrong `checkSentenceConstruction` then correct →
   to-review 1 with `(original, translation)`.

(`game_provider_test.dart` already sets up `SharedPreferences.setMockInitialValues`
+ a `DeckRepository`; follow its existing `_buildDeck` helper.)

**UI (`CompletedCard`)** — no widget test, consistent with the daily-goal
tasks. Bar: `flutter analyze` clean + `flutter test` green.

---

## Files touched

- `lib/providers/game_provider.dart` — session state, 4 getters,
  `recordMistakeForCurrentWord()`, recording in `checkAnswer` /
  `checkSentenceConstruction` / `markCurrentWordAsCorrect`, clears in
  `setDeck` / `resetDeck`.
- `lib/screens/games/classic_game/widgets/drawing_widget.dart` — one line in
  the "non" branch.
- `lib/screens/games/classic_game/widgets/completed_card.dart` — StatefulWidget,
  session block, expandable list, scroll wrapper.
- `lib/l10n/app_{en,fr,es,it}.arb` (+ regenerated `app_localizations*.dart`).
- `test/providers/game_provider_test.dart` — session-summary group.

---

## Risks / edge cases

- **Re-entering a finished mode:** `isCompleted` true immediately,
  `sessionLearnedCount == 0` → session block hidden, card shows just the goal
  ring + restart (current behaviour). Fine.
- **Card height:** the `SingleChildScrollView` wrapper handles a long review
  list. Verify on the real phone that the scroll is inside the card, not the
  page.
- **Reverse mode wording:** the review list always shows `prompt → answer`
  (foreign → native), even though reverse mode quizzes native → foreign. This
  is intentional: the canonical pair is the useful thing to re-study.
- **Records vs value class:** `({String prompt, String answer})` — plan may
  swap for a tiny class if it reads better in the widget.
