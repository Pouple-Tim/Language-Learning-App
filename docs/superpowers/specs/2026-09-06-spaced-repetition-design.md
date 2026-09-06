# Spaced Repetition (SM-2) — Design

**Status:** direction approved (grilling 2026-09-06), pending spec review
**Roadmap:** PM/UX growth item #8.
**Context report:** the exploration findings this spec is built on are summarised
in "Current mechanics" below; the full report was produced during grilling.

---

## Problem

Today a deck's word pool refills to *everything* every calendar day (and only
for the one deck+mode currently loaded — see Current mechanics), and each game
picks uniformly at random from `activeWords`. Consequences: words you've
mastered come back exactly as often as words you're failing (wasted reps), and
words you're about to forget aren't brought back at the right moment (you
forget them). Item #8 replaces the daily-reset pool with an SM-2 scheduler:
each word gets a *due date* derived from your answer history, and "today's
session" is the set of words that are actually due, plus whatever you choose to
add via a pre-session filter.

---

## Decisions locked in grilling

| # | Decision |
|---|---|
| Algorithm | **SM-2** (ease factor per word, multiplicative intervals), textbook, **no learning steps** — a new word answered correctly once is due in 1 day. |
| Quality score | **Auto-derived** from the answer, no grade buttons. Mapping in §4. |
| New-word handling | **No daily quota.** All deck words are eligible from day one; volume is controlled by the pre-session filter, not by gating introduction. |
| Pre-session screen | **Always shown** before every game. 4 filter options with live counts. Last choice pre-selected per deck. |
| Card identity | **`Word.id`** (deck-scoped, `<deckId>_wN`). No content-based unification across deck variants. Same hanzi in `chinese_hsk1_part1` and `chinese_hsk1_all` = two independent SM-2 cards. |
| Granularity | **Per `wordId`, mode-agnostic.** A word graded in quiz advances its due date for classic too. |
| Daily reset | **Removed.** `checkDailyReset` / `resetWords`-per-day / the "Nouveau jour" SnackBar all go. SM-2 due dates are the only scheduler. |
| Migration | **Fresh start.** Everyone begins with an empty SM-2 store (all words "new"). `ReviewHistory` is not replayed. |
| Scope | **Words only.** Sentence mode is excluded from SM-2 and from the pre-session filter in v1 (see §8, open item). |

---

## Current mechanics (what this replaces)

- **Daily reset:** `app.dart:50` `gameProvider.checkDailyReset(settings.lastReset)` → `GameProvider.resetDeck()` → `Deck.resetWords()` (all `word.removed = false`) — but only for `_currentProgressDeck` (the selected deck, default mode `classic`). `Settings.lastReset` is rewritten to today by the first `SettingsRepository.loadSettings()` of a new day. A "Nouveau jour ! Deck réinitialisé." SnackBar shows.
- **`Word.removed` / `Sentence.completed`:** mutable bool, "answered correctly this cycle". Persisted inside the whole-`Deck` JSON blob at `progress_<deckId>_<gameMode>` (`DeckRepository.saveProgress`). Restored by id on `GameProvider.setDeck`.
- **Item selection:** `GameProvider.spinWheel()` / `_loadNextSentence()` — uniform random over `words.where((w) => !w.removed)` / `sentences.where((s) => !s.completed)`. Single hook point; called from every input widget after each answer and from the auto-advance in `game_screen.dart`.
- **Answer logging:** `checkAnswer` / `checkSentenceConstruction` call `statisticsProvider?.addReview(...)` **before** the correctness branch, so every wrong attempt + every retry logs a `ReviewEntry`. **Drawing mode under-logs:** `markCurrentWordAsCorrect` does *not* call `addReview` (only the session-mistake map). This spec fixes that (§4).
- **Session-mistake tracking (shipped in the session-summary feature):** `GameProvider._sessionMistakes : Map<String,int>` already counts wrong submissions per `wordId`/`sentenceId` for the current session, cleared in `setDeck`/`resetDeck`. **This is the exact input the SM-2 quality score needs.**
- **No per-word mastery state** exists anywhere. All signal is in `ReviewHistory` (keyed by `wordId`).
- **New settings** follow the `GoalProvider` / `ReminderProvider` pattern: a dedicated `ChangeNotifier` with its own raw SharedPreferences keys, **not** the codegen `Settings` model.

---

## 1. SM-2 core — `lib/core/srs/sm2.dart` (pure Dart, unit-tested)

```dart
/// One word's scheduling state. Immutable; `review` returns a new instance.
class SrsCard {
  final int reps;          // successful reviews in a row (SM-2 "n"); 0 = new or just lapsed
  final double ef;         // ease factor, starts 2.5, floor 1.3
  final int intervalDays;  // current interval; 0 before the first review
  final DateTime due;      // next review date (date-only, local midnight)

  const SrsCard({required this.reps, required this.ef, required this.intervalDays, required this.due});

  /// A brand-new card, due immediately.
  factory SrsCard.initial(DateTime now) =>
      SrsCard(reps: 0, ef: 2.5, intervalDays: 0, due: _dateOnly(now));
}

/// Apply one review. `quality` is 0–5 (this app produces {2,3,4,5} — see §4).
/// Textbook SM-2, no learning steps.
SrsCard reviewCard(SrsCard c, int quality, DateTime now) {
  final today = _dateOnly(now);
  int reps;
  int interval;

  if (quality >= 3) {
    if (c.reps == 0) {
      interval = 1;
    } else if (c.reps == 1) {
      interval = 6;
    } else {
      interval = (c.intervalDays * c.ef).round();
    }
    reps = c.reps + 1;
  } else {
    // lapse
    reps = 0;
    interval = 1;
  }

  var ef = c.ef + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
  if (ef < 1.3) ef = 1.3;

  return SrsCard(
    reps: reps,
    ef: ef,
    intervalDays: interval,
    due: today.add(Duration(days: interval)),
  );
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
```

EF deltas for this app's quality values: q5 → +0.10, q4 → 0.00, q3 → −0.14,
q2 → −0.32 (lapse). q3 still grows the interval (it's ≥3) but lowers ease;
q2 is the only interval reset.

**Unit tests** (`test/srs/sm2_test.dart`):
- `SrsCard.initial` → reps 0, ef 2.5, interval 0, due = today.
- new card + q5 → reps 1, interval 1, due today+1, ef 2.6.
- reps 1 + q5 → reps 2, interval 6, due today+6.
- reps 2, interval 6, ef 2.6 + q5 → interval round(6·2.6)=16.
- q4 leaves ef unchanged; q3 lowers ef by 0.14 and still advances the interval.
- q2 on a reps-3 card → reps 0, interval 1, due today+1, ef drops by 0.32.
- ef floor: repeated q2 never takes ef below 1.3.
- `_dateOnly` drops the time component.

---

## 2. State & persistence — `SrsProvider` + `srs_state` key

`lib/providers/srs_provider.dart` — `class SrsProvider extends ChangeNotifier`,
registered in `main.dart` after `GoalProvider` (`SrsProvider()..load()`).

- **Store:** one SharedPreferences key `srs_state`, a JSON object
  `{ "<wordId>": {"reps":N,"ef":F,"interval":D,"due":"YYYY-MM-DD"} }`, loaded
  into an in-memory `Map<String, SrsCard>` on `load()`. Written whole on every
  `grade`. (Same one-blob approach as `review_history`; realistic size is a few
  hundred entries — only words the user has actually answered.)
- **API:**
  ```dart
  SrsCard? cardFor(String wordId);              // null = never reviewed
  Future<void> grade(String wordId, int quality); // reviewCard + persist + notifyListeners
  bool isDue(String wordId, DateTime now);      // cardFor == null || card.due <= dateOnly(now)
  bool isNew(String wordId);                    // cardFor == null
  bool isDifficult(String wordId);              // card != null && card.ef < 2.0
  /// Counts for the pre-session screen, over a given set of word ids.
  ({int all, int due, int fresh, int hard}) counts(Iterable<String> wordIds, DateTime now);
  Future<void> resetDeck(Iterable<String> wordIds); // drop SM-2 state for those ids (Settings "réinitialiser")
  ```
- No coupling to `StatisticsProvider` — `grade` is called by `GameProvider`
  with a quality it computed. `ReviewHistory` logging stays exactly as it is
  (independent; still feeds the daily goal, streak, stats screen).

---

## 3. The 4 pre-session filters

`enum SessionFilter { all, due, fresh, hard }`

| filter | l10n label | predicate over the deck's word ids | notes |
|---|---|---|---|
| `all` | "Réviser tout" | every word | ignores SM-2 entirely — the escape hatch |
| `due` | "À réviser aujourd'hui" | `SrsProvider.isDue(id, now)` (includes never-seen) | the default |
| `fresh` | "Nouveaux mots" | `SrsProvider.isNew(id)` | strict subset of `due` |
| `hard` | "Mots difficiles" | `SrsProvider.isDifficult(id)` | ef < 2.0 (repeatedly lapsed) |

The pre-session screen shows all four with a live count each (from
`SrsProvider.counts`). A filter with count 0 is shown greyed / disabled except
`all` (never 0 for a non-empty deck).

**Edge:** if `due` resolves to 0 words (everything scheduled ahead), the screen
still lets you pick `all` / `fresh` / `hard`. The default selection falls back
to the first non-empty option in order `due → fresh → hard → all`.

---

## 4. Quality score — auto-derived

The score is computed **once per word, when it is first answered correctly in
the session** (in classic/quiz/listening you keep going until right, so there
is exactly one "completed" moment per word per session). Input: the word's
wrong-submission count for this session, already tracked in
`GameProvider._sessionMistakes[wordId]`.

| session mistakes for this word | quality | meaning |
|---|---|---|
| 0 | **5** | first try |
| 1 | **4** | one slip |
| 2 | **3** | hard but got it (interval still grows, ease drops) |
| ≥ 3 | **2** | lapse — interval resets to 1 day |

Drawing mode: the manual "oui" with no prior "non" → mistakes 0 → q5. Each
"non" already increments `_sessionMistakes` via `recordMistakeForCurrentWord()`
(shipped), so the same table applies.

**Also fix the drawing under-logging:** `markCurrentWordAsCorrect()` must call
`statisticsProvider?.addReview(wordId, deckId, wasCorrect: true, inputType: 'draw', gameMode: ...)`
so drawing sessions count toward the daily goal / streak / stats like every
other mode. (Independent of SM-2 but in scope here since we're touching that
method.)

---

## 5. `GameProvider` integration

- `setDeck(Deck, {GameType gameMode, SessionFilter filter = SessionFilter.due})`
  — new `filter` param stored as `_sessionFilter`.
- **`removed` becomes pure in-memory session state.** `setDeck` no longer
  restores `removed` from `savedProgress` for words; every session starts with
  all words un-removed. `_saveProgress` stops writing word `removed` (it may
  keep writing the blob harmlessly, or word-progress persistence is dropped
  entirely — plan's call). SM-2 `srs_state` is the persistence now.
- **`spinWheel()`** picks from
  `_currentProgressDeck.words.where((w) => !w.removed && _matchesFilter(w.id))`
  instead of `activeWords`. `_matchesFilter` switches on `_sessionFilter` using
  `SrsProvider` (injected the same way `statisticsProvider` is — via
  `ChangeNotifierProxyProvider` in `main.dart`). Distractor generation
  (`_generateQuizOptions`) keeps using `_currentProgressDeck.words` (all words)
  — already does, so a small filtered pool still yields 4-option quizzes.
- **On the "completed correctly" branch** of `checkAnswer` (and the drawing
  `markCurrentWordAsCorrect`): after `_sessionCompleted.add(id)` and
  `_currentWord!.removed = true`, compute the quality from
  `_sessionMistakes[id]` per §4 and call `srsProvider?.grade(id, quality)`.
  Fire-and-forget is fine (the write is cheap and local).
- **`isCompleted`** = the filtered pool is exhausted
  (`words.where(!removed && matchesFilter).isEmpty`). The CompletedCard shows
  when the *chosen filter's* words are done, not when the whole deck is done.
- **`resetDeck()`** (CompletedCard "Recommencer" button, `resetModeProgress`,
  `resetAllModesProgress`): re-populates the session pool from the current
  filter (clear `removed`, clear session counters, re-spin). It **does not**
  touch `srs_state` — replaying a session doesn't un-learn anything. Grading
  still happens on the replay (answering a now-not-due word again re-grades it;
  acceptable, and only reachable via `all` or an immediate replay).
- `checkDailyReset` is **deleted**.

---

## 6. Pre-session screen — `lib/screens/games/pre_session_screen.dart`

New screen, pushed between the Home game-mode-card tap and `GameScreen`.

Current flow (`home_screen.dart` `_buildGameModeCard` onTap): validates a deck
is selected / downloads content if needed → `gameProvider.setDeck(deck, gameMode: mode.type)` →
`Navigator.push(GameScreen(...))`.

New flow: … deck ready → `Navigator.push(PreSessionScreen(deck: deck, mode: mode.type, title: mode.title))`.
The pre-session screen:
- reads `SrsProvider` + the deck's word ids, computes the 4 counts.
- shows 4 large tappable rows: label + count + short subtitle; the last-used
  filter for this deck (persisted, see below) is pre-highlighted, or the
  default fallback (§3).
- on tap: persist the choice, `gameProvider.setDeck(deck, gameMode: mode, filter: chosen)`,
  `Navigator.pushReplacement(GameScreen(gameTitle: title))`.
- **Sentence mode** (`GameType.sentence`): the pre-session screen is skipped
  entirely — go straight to `GameScreen` (sentence mode is not SR-scheduled in
  v1). See §8.
- **Last-used filter per deck:** a small SharedPreferences map
  `session_filter_by_deck` `{ deckId: "due" }`, owned by `SrsProvider` or a
  tiny helper. Not the `Settings` model.

`GameScreen` itself is unchanged except that it now trusts `GameProvider` to
have a filter set.

---

## 7. Removing the daily reset — ripple

- `lib/app.dart:48-68` — delete the `checkDailyReset` call, the
  `needsDailyReset` / `updateLastReset` calls, and the "Nouveau jour" SnackBar.
  Keep the `setDeck` call (Home still needs a loaded deck for the "current
  deck" tile), but it now uses the default filter until the user starts a game.
- `GameProvider.checkDailyReset` — deleted. `Deck.resetWords()` — kept (still
  used by `resetDeck()` to clear the in-memory `removed` flags for a replay).
- `SettingsRepository`: `needsDailyReset()` and the `loadSettings()` side
  effect that bumps `lastReset` — remove the side effect; `needsDailyReset` can
  be deleted (no other callers). `Settings.lastReset` field: leave it in the
  model (removing it needs `build_runner` + a migration risk) but stop reading
  and writing it; add a `// unused since #8` comment. `updateLastReset` becomes
  dead — delete it and the `AppConstants.keyLastReset` dead constant.
- `DateHelper` — kept as-is (`_dateOnly`-style helpers still useful; the SM-2
  core has its own private `_dateOnly` to stay pure/dependency-free).

---

## 8. Non-goals / open items for spec review

1. **Sentence mode is out of scope for SM-2 in v1.** Rationale: `Sentence.id`
   is only unique per deck (`s1`, `s2`…), sentence decks are small (10–20),
   and it's a construction task, not recall. **Proposed v1 behaviour:** sentence
   mode skips the pre-session screen; its session pool is all sentences with
   `completed` as pure in-memory session state (every entry replays all
   sentences); no persistence, no daily reset needed. **Confirm at spec
   review** — the alternative is a Leitner-lite on `(deckId, sentenceId)` which
   is more work.
2. **"Réinitialiser le deck actuel"** (Settings → Données). Today it wipes
   `progress_<deck>_*`. **Proposed:** it now calls
   `SrsProvider.resetDeck(deckWordIds)` — drops the SM-2 cards for that deck so
   every word is "new" again. Confirm the wording / that this is the desired
   meaning.
3. **CompletedCard "next review" line** — optionally show "12 mots revus ·
   prochaine session : 8 mots demain". Nice-to-have, can be a follow-up; not in
   the v1 plan unless cheap.
4. **Daily goal (#7) interaction** — the goal counts `reviewsToday()` (raw
   answer submissions), unchanged. If `due` has only 8 words and the goal is
   20, the user won't hit it without also doing `fresh` / `all`. Deemed
   acceptable (nudges more study); no coupling added.
5. **Timezone / midnight** — due dates are date-only in local time, same
   naive model as the current `DateHelper.isToday`. A word due "today" stays
   due until answered or the local date rolls. No change.

---

## 9. Files touched (v1)

**New:**
- `lib/core/srs/sm2.dart` + `test/srs/sm2_test.dart`
- `lib/providers/srs_provider.dart` + `test/providers/srs_provider_test.dart`
- `lib/screens/games/pre_session_screen.dart`

**Modified:**
- `lib/main.dart` — register `SrsProvider`; inject into `GameProvider` via the
  proxy provider.
- `lib/providers/game_provider.dart` — `SessionFilter`, `filter` param on
  `setDeck`, filtered `spinWheel`, `grade` call on completion, `removed` no
  longer restored from save, `checkDailyReset` deleted, drawing `addReview`
  fix.
- `lib/screens/home/home_screen.dart` — route through `PreSessionScreen`
  (except sentence mode).
- `lib/app.dart` — strip the daily-reset block.
- `lib/data/repositories/settings_repository.dart` — drop `needsDailyReset`,
  the `loadSettings` side effect, `updateLastReset`.
- `lib/data/models/settings.dart` — comment `lastReset` as unused (no field
  removal).
- `lib/core/constants/app_constants.dart` — remove dead `keyLastReset`.
- `lib/l10n/app_{en,fr,es,it}.arb` — filter labels + subtitles + the
  pre-session screen title (~9 keys × 4 locales).
- `lib/screens/settings/settings_screen.dart` — "Réinitialiser le deck" now
  hits `SrsProvider.resetDeck` (pending open item #2).

---

## 10. Testing

- **`sm2_test.dart`** — the SM-2 math (§1).
- **`srs_provider_test.dart`** — `SharedPreferences.setMockInitialValues({})` +
  `StorageHelper.init()` setUp (existing pattern). Covers: `cardFor` null for
  unseen; `grade` persists and a fresh provider reads it back; `isDue` /
  `isNew` / `isDifficult` predicates; `counts` over a word-id set; `resetDeck`
  drops the right ids.
- **`game_provider_test.dart`** — extend: `setDeck(filter: due)` limits
  `spinWheel` to due/new words; answering a word calls `grade` with the
  quality matching its session mistake count (inject a fake/real `SrsProvider`,
  or assert via a spy); `isCompleted` true when the filtered pool is exhausted
  even if other deck words remain; `resetDeck` re-opens the filtered pool
  without touching `srs_state`.
- **UI** (`PreSessionScreen`, `GameScreen` wiring) — no widget test, per the
  project bar (`flutter analyze` + `flutter test`). Manual phone smoke: start
  each filter, confirm counts, confirm a session ends when the filter's words
  are done, reopen the app and confirm graded words dropped out of "due".
- Bar: `flutter analyze` clean, `flutter test` green.
