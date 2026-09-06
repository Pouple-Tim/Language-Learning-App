# Spaced Repetition (SM-2) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the daily-reset word pool with an SM-2 scheduler: every word and sentence gets a due date derived from the auto-graded answer, and each game starts from a pre-session screen where the user picks a filter (all / due today / new / hard) over that schedule.

**Architecture:** Pure `lib/core/srs/sm2.dart` (`SrsCard`, `reviewCard`) — unit-tested, no Flutter. `SrsProvider` (ChangeNotifier, own `srs_state` SharedPreferences blob, key-agnostic string API) holds the schedule. `GameProvider` gains a `SessionFilter`, filters `spinWheel` / `_loadNextSentence` through `SrsProvider`, and calls `SrsProvider.grade` when an item is first solved (quality auto-derived from the session mistake count already tracked). The old daily-reset mechanism (`checkDailyReset`, `Settings.lastReset`, the "Nouveau jour" SnackBar, `removed`/`completed` persistence) is removed. A new `PreSessionScreen` sits between the Home mode-card tap and `GameScreen`.

**Tech Stack:** Flutter, `provider` (`ChangeNotifierProxyProvider2`), `shared_preferences` via `StorageHelper`, `flutter gen-l10n` (en/fr/es/it), `flutter_test`.

**Spec:** `docs/superpowers/specs/2026-09-06-spaced-repetition-design.md` — read it alongside this plan.

## Global Constraints

- **SM-2 textbook, no learning steps.** New item + first correct → due in 1 day; then 6 days; then `round(interval · EF)`. EF starts 2.5, floor 1.3. `quality < 3` → lapse (reps 0, interval 1). This app only ever produces quality {2, 3, 4, 5}.
- **Quality auto-derived** from `GameProvider._sessionMistakes[itemId]` (bare `wordId`/`sentenceId`): 0 → 5, 1 → 4, 2 → 3, ≥3 → 2. No grade buttons.
- **srsKey:** word → `word.id`; sentence → `'<deckId>::<sentenceId>'`. `GameProvider` builds keys; `SrsProvider` treats them as opaque strings.
- **Card identity is deck-scoped** — no content unification across deck variants.
- **`removed` / `Sentence.completed` become pure in-memory session state** — never restored from `progress_*` on `setDeck`. SM-2 `srs_state` is the persistence.
- **The daily reset is fully removed** — `GameProvider.checkDailyReset`, the `app.dart` reset block, `SettingsRepository.needsDailyReset` / `updateLastReset` / the `loadSettings` side effect, `AppConstants.keyLastReset`. `Settings.lastReset` field stays (comment it unused — removing needs build_runner + migration risk).
- **`SessionFilter { all, due, fresh, hard }`**, default `due`. Predicates: `all` = every item; `due` = `isDue` (includes never-seen); `fresh` = `isNew` (`cardFor == null`); `hard` = `isDifficult` (`card.ef < 2.0`).
- **Pre-session screen shown for every mode** including sentence. Last choice persisted per `<deckId>_<gameMode>`.
- **Drawing under-logging fix:** `markCurrentWordAsCorrect()` must call `statisticsProvider?.addReview(... inputType: 'draw' ...)`.
- Branch `feature/spaced-repetition` off `develop`. Toolchain Flutter 3.47.1 / Dart 3.13.1 (analyzer strict; records + pattern switches available).
- Test bar: `flutter analyze` clean (no new issues) + `flutter test` green. New unit tests for `sm2` + `SrsProvider` + `GameProvider` filtering/grading. No widget tests for the new screens (project bar). Manual phone smoke at the end.
- Provider test setup pattern: `SharedPreferences.setMockInitialValues({}); await StorageHelper.init();` in `setUp`.

---

### Task 1: SM-2 pure core

**Files:**
- Create: `lib/core/srs/sm2.dart`
- Test: `test/srs/sm2_test.dart`

**Interfaces:**
- Consumes: nothing (pure Dart).
- Produces:
  - `class SrsCard { final int reps; final double ef; final int intervalDays; final DateTime due; const SrsCard({...}); factory SrsCard.initial(DateTime now); Map<String,dynamic> toJson(); factory SrsCard.fromJson(Map<String,dynamic>); }`
  - `SrsCard reviewCard(SrsCard c, int quality, DateTime now)`
  - `DateTime dateOnly(DateTime d)` (public — `SrsProvider` reuses it)

- [ ] **Step 1: Write the failing test**

Create `test/srs/sm2_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:language_learning_app/core/srs/sm2.dart';

void main() {
  final now = DateTime(2026, 3, 10, 14, 30);
  final today = DateTime(2026, 3, 10);

  group('dateOnly', () {
    test('drops the time component', () {
      expect(dateOnly(now), today);
    });
  });

  group('SrsCard.initial', () {
    test('is a new card due today', () {
      final c = SrsCard.initial(now);
      expect(c.reps, 0);
      expect(c.ef, 2.5);
      expect(c.intervalDays, 0);
      expect(c.due, today);
    });
  });

  group('reviewCard', () {
    test('new card + q5 → reps 1, interval 1, due tomorrow, ef 2.6', () {
      final c = reviewCard(SrsCard.initial(now), 5, now);
      expect(c.reps, 1);
      expect(c.intervalDays, 1);
      expect(c.due, today.add(const Duration(days: 1)));
      expect(c.ef, closeTo(2.6, 1e-9));
    });

    test('reps 1 + q5 → reps 2, interval 6', () {
      var c = reviewCard(SrsCard.initial(now), 5, now); // reps 1
      c = reviewCard(c, 5, now);
      expect(c.reps, 2);
      expect(c.intervalDays, 6);
      expect(c.due, today.add(const Duration(days: 6)));
    });

    test('reps 2 with ef 2.6, interval 6 + q5 → interval round(6*2.6)=16', () {
      var c = reviewCard(SrsCard.initial(now), 5, now);
      c = reviewCard(c, 5, now); // reps 2, interval 6, ef 2.7
      final ef = c.ef;
      c = reviewCard(c, 5, now); // reps 3
      expect(c.intervalDays, (6 * ef).round());
    });

    test('q4 leaves ef unchanged', () {
      final c = reviewCard(SrsCard.initial(now), 4, now);
      expect(c.ef, closeTo(2.5, 1e-9));
      expect(c.intervalDays, 1);
      expect(c.reps, 1);
    });

    test('q3 lowers ef by ~0.14 but still advances the interval', () {
      var c = reviewCard(SrsCard.initial(now), 5, now); // reps 1
      c = reviewCard(c, 5, now); // reps 2, interval 6
      final before = c.ef;
      c = reviewCard(c, 3, now); // reps 3, interval grows
      expect(c.ef, closeTo(before - 0.14, 1e-9));
      expect(c.reps, 3);
      expect(c.intervalDays, greaterThan(6));
    });

    test('q2 is a lapse: reps 0, interval 1, due tomorrow, ef drops ~0.32', () {
      var c = reviewCard(SrsCard.initial(now), 5, now);
      c = reviewCard(c, 5, now);
      c = reviewCard(c, 5, now); // reps 3
      final before = c.ef;
      c = reviewCard(c, 2, now);
      expect(c.reps, 0);
      expect(c.intervalDays, 1);
      expect(c.due, today.add(const Duration(days: 1)));
      expect(c.ef, closeTo(before - 0.32, 1e-9));
    });

    test('ef never drops below 1.3', () {
      var c = SrsCard.initial(now);
      for (var i = 0; i < 20; i++) {
        c = reviewCard(c, 2, now);
      }
      expect(c.ef, 1.3);
    });
  });

  group('SrsCard json round-trip', () {
    test('toJson/fromJson preserves all fields', () {
      final c = reviewCard(SrsCard.initial(now), 3, now);
      final back = SrsCard.fromJson(c.toJson());
      expect(back.reps, c.reps);
      expect(back.ef, c.ef);
      expect(back.intervalDays, c.intervalDays);
      expect(back.due, c.due);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/srs/sm2_test.dart`
Expected: FAIL — cannot resolve `package:language_learning_app/core/srs/sm2.dart`.

- [ ] **Step 3: Write the implementation**

Create `lib/core/srs/sm2.dart`:

```dart
/// Pure SM-2 scheduling. No Flutter, no storage. Unit-tested in
/// test/srs/sm2_test.dart. Textbook SM-2, no learning steps.
library;

/// Local-date at midnight — the granularity for due dates.
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// One item's scheduling state. Immutable.
class SrsCard {
  final int reps; // successful reviews in a row (SM-2 "n"); 0 = new or just lapsed
  final double ef; // ease factor, starts 2.5, floor 1.3
  final int intervalDays; // current interval; 0 before the first review
  final DateTime due; // next review date, date-only

  const SrsCard({
    required this.reps,
    required this.ef,
    required this.intervalDays,
    required this.due,
  });

  factory SrsCard.initial(DateTime now) =>
      SrsCard(reps: 0, ef: 2.5, intervalDays: 0, due: dateOnly(now));

  Map<String, dynamic> toJson() => {
        'reps': reps,
        'ef': ef,
        'interval': intervalDays,
        'due': dateOnly(due).toIso8601String(),
      };

  factory SrsCard.fromJson(Map<String, dynamic> j) => SrsCard(
        reps: (j['reps'] as num).toInt(),
        ef: (j['ef'] as num).toDouble(),
        intervalDays: (j['interval'] as num).toInt(),
        due: dateOnly(DateTime.parse(j['due'] as String)),
      );
}

/// Apply one review. [quality] is 0–5; this app produces {2,3,4,5}.
SrsCard reviewCard(SrsCard c, int quality, DateTime now) {
  final today = dateOnly(now);

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
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/srs/sm2_test.dart`
Expected: PASS (all groups).

- [ ] **Step 5: Commit**

```bash
git add lib/core/srs/sm2.dart test/srs/sm2_test.dart
git commit -m "feat: add pure SM-2 scheduling core"
```

---

### Task 2: SrsProvider

**Files:**
- Create: `lib/providers/srs_provider.dart`
- Modify: `lib/main.dart` (import + registration)
- Test: `test/providers/srs_provider_test.dart`

**Interfaces:**
- Consumes: `sm2.dart` (`SrsCard`, `reviewCard`, `dateOnly`), `StorageHelper`.
- Produces `class SrsProvider extends ChangeNotifier`:
  - `void load()`
  - `SrsCard? cardFor(String srsKey)`
  - `Future<void> grade(String srsKey, int quality)` — `reviewCard`, persist, `notifyListeners`
  - `bool isDue(String srsKey, DateTime now)` — `cardFor == null || !card.due.isAfter(dateOnly(now))`
  - `bool isNew(String srsKey)` — `cardFor(srsKey) == null`
  - `bool isDifficult(String srsKey)` — `card != null && card.ef < 2.0`
  - `({int all, int due, int fresh, int hard}) counts(Iterable<String> srsKeys, DateTime now)`
  - `int dueOn(Iterable<String> srsKeys, DateTime day)` — cards whose `due == dateOnly(day)`
  - `Future<void> resetKeys(Iterable<String> srsKeys)` — remove those keys, persist, notify
  - `SessionFilter filterFor(String deckId, GameType mode)` / `Future<void> setFilterFor(String deckId, GameType mode, SessionFilter f)` — last-used filter map
  - `bool matches(SessionFilter f, String srsKey, DateTime now)` — the predicate switch (also used by `GameProvider`)

> `SessionFilter` enum is defined in `game_provider.dart` (Task 4). To avoid a
> circular import, define `enum SessionFilter { all, due, fresh, hard }` in
> **`lib/core/srs/sm2.dart`** instead (it's pure and both sides import it).
> Update Task 4 references accordingly — `sm2.dart` owns the enum.

- [ ] **Step 1: Add `SessionFilter` to `sm2.dart`**

Append to `lib/core/srs/sm2.dart`:

```dart
/// Which items a session pulls from. Chosen on the pre-session screen.
enum SessionFilter { all, due, fresh, hard }
```

- [ ] **Step 2: Write the failing test**

Create `test/providers/srs_provider_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:language_learning_app/core/srs/sm2.dart';
import 'package:language_learning_app/core/utils/storage_helper.dart';
import 'package:language_learning_app/data/models/game_mode.dart';
import 'package:language_learning_app/providers/srs_provider.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageHelper.init();
  });

  final now = DateTime(2026, 3, 10, 9);

  test('cardFor is null for an unseen key; isNew true, isDue true', () {
    final p = SrsProvider()..load();
    expect(p.cardFor('w1'), isNull);
    expect(p.isNew('w1'), isTrue);
    expect(p.isDue('w1', now), isTrue);
    expect(p.isDifficult('w1'), isFalse);
  });

  test('grade persists and a fresh provider reads it back', () async {
    final a = SrsProvider()..load();
    await a.grade('w1', 5); // new + q5 → due tomorrow

    final b = SrsProvider()..load();
    expect(b.isNew('w1'), isFalse);
    expect(b.isDue('w1', now), isFalse); // due tomorrow, not today
    expect(b.isDue('w1', now.add(const Duration(days: 1))), isTrue);
  });

  test('isDifficult true once ef drops below 2.0', () async {
    final p = SrsProvider()..load();
    await p.grade('w1', 5);
    await p.grade('w1', 5);
    await p.grade('w1', 2); // lapse, ef 2.7→2.38
    await p.grade('w1', 2); // 2.38→2.06
    await p.grade('w1', 2); // 2.06→1.74
    expect(p.isDifficult('w1'), isTrue);
  });

  test('counts over a mixed key set', () async {
    final p = SrsProvider()..load();
    await p.grade('w1', 5); // seen, due tomorrow
    await p.grade('deck1::s1', 5); // seen, due tomorrow
    final keys = ['w1', 'w2', 'w3', 'deck1::s1'];
    final c = p.counts(keys, now);
    expect(c.all, 4);
    expect(c.fresh, 2); // w2, w3
    expect(c.due, 2); // w2, w3 (never-seen count as due); w1 + s1 are ahead
  });

  test('resetKeys drops the given keys only', () async {
    final p = SrsProvider()..load();
    await p.grade('w1', 5);
    await p.grade('w2', 5);
    await p.resetKeys(['w1']);
    expect(p.isNew('w1'), isTrue);
    expect(p.isNew('w2'), isFalse);
  });

  test('last-used filter round-trips per deck+mode', () async {
    final a = SrsProvider()..load();
    expect(a.filterFor('deck1', GameType.classic), SessionFilter.due); // default
    await a.setFilterFor('deck1', GameType.classic, SessionFilter.hard);

    final b = SrsProvider()..load();
    expect(b.filterFor('deck1', GameType.classic), SessionFilter.hard);
    expect(b.filterFor('deck1', GameType.quiz), SessionFilter.due);
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `flutter test test/providers/srs_provider_test.dart`
Expected: FAIL — cannot resolve `srs_provider.dart`.

- [ ] **Step 4: Write the implementation**

Create `lib/providers/srs_provider.dart`:

```dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:language_learning_app/core/srs/sm2.dart';
import 'package:language_learning_app/core/utils/storage_helper.dart';
import 'package:language_learning_app/data/models/game_mode.dart';

/// The SM-2 schedule. One [SrsCard] per srsKey (word id, or
/// `<deckId>::<sentenceId>` for sentences). Own SharedPreferences keys,
/// GoalProvider pattern — not the codegen Settings model.
class SrsProvider extends ChangeNotifier {
  static const _kState = 'srs_state';
  static const _kFilters = 'session_filter_by_deck';

  final Map<String, SrsCard> _cards = {};
  final Map<String, SessionFilter> _filters = {};

  void load() {
    final raw = StorageHelper.getString(_kState);
    if (raw != null) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        map.forEach((k, v) {
          _cards[k] = SrsCard.fromJson(v as Map<String, dynamic>);
        });
      } catch (e) {
        debugPrint('SrsProvider: corrupt srs_state, ignoring: $e');
      }
    }
    final rawF = StorageHelper.getString(_kFilters);
    if (rawF != null) {
      try {
        final map = jsonDecode(rawF) as Map<String, dynamic>;
        map.forEach((k, v) {
          _filters[k] = SessionFilter.values.firstWhere(
            (f) => f.name == v,
            orElse: () => SessionFilter.due,
          );
        });
      } catch (_) {}
    }
    notifyListeners();
  }

  SrsCard? cardFor(String srsKey) => _cards[srsKey];

  bool isNew(String srsKey) => _cards[srsKey] == null;

  bool isDue(String srsKey, DateTime now) {
    final c = _cards[srsKey];
    return c == null || !c.due.isAfter(dateOnly(now));
  }

  bool isDifficult(String srsKey) {
    final c = _cards[srsKey];
    return c != null && c.ef < 2.0;
  }

  bool matches(SessionFilter f, String srsKey, DateTime now) => switch (f) {
        SessionFilter.all => true,
        SessionFilter.due => isDue(srsKey, now),
        SessionFilter.fresh => isNew(srsKey),
        SessionFilter.hard => isDifficult(srsKey),
      };

  ({int all, int due, int fresh, int hard}) counts(
      Iterable<String> srsKeys, DateTime now) {
    var all = 0, due = 0, fresh = 0, hard = 0;
    for (final k in srsKeys) {
      all++;
      if (isDue(k, now)) due++;
      if (isNew(k)) fresh++;
      if (isDifficult(k)) hard++;
    }
    return (all: all, due: due, fresh: fresh, hard: hard);
  }

  int dueOn(Iterable<String> srsKeys, DateTime day) {
    final d = dateOnly(day);
    var n = 0;
    for (final k in srsKeys) {
      if (_cards[k]?.due == d) n++;
    }
    return n;
  }

  Future<void> grade(String srsKey, int quality) async {
    final current = _cards[srsKey] ?? SrsCard.initial(DateTime.now());
    _cards[srsKey] = reviewCard(current, quality, DateTime.now());
    await _persistState();
    notifyListeners();
  }

  Future<void> resetKeys(Iterable<String> srsKeys) async {
    var changed = false;
    for (final k in srsKeys) {
      if (_cards.remove(k) != null) changed = true;
    }
    if (changed) {
      await _persistState();
      notifyListeners();
    }
  }

  SessionFilter filterFor(String deckId, GameType mode) =>
      _filters['${deckId}_${mode.storageId}'] ?? SessionFilter.due;

  Future<void> setFilterFor(
      String deckId, GameType mode, SessionFilter f) async {
    _filters['${deckId}_${mode.storageId}'] = f;
    await StorageHelper.saveString(
      _kFilters,
      jsonEncode(_filters.map((k, v) => MapEntry(k, v.name))),
    );
    notifyListeners();
  }

  Future<void> _persistState() async {
    await StorageHelper.saveString(
      _kState,
      jsonEncode(_cards.map((k, v) => MapEntry(k, v.toJson()))),
    );
  }
}
```

- [ ] **Step 5: Register in `main.dart`**

Add import after `goal_provider.dart`:

```dart
import 'providers/srs_provider.dart';
```

In the `MultiProvider.providers` list, add after the `GoalProvider` line:

```dart
          ChangeNotifierProvider(create: (_) => SrsProvider()..load()),
```

(The `GameProvider` proxy is upgraded to inject it in Task 4 — for now `SrsProvider` is just registered.)

- [ ] **Step 6: Run tests + analyze**

Run: `flutter test test/providers/srs_provider_test.dart`
Expected: PASS (6 tests).

Run: `flutter analyze`
Expected: no new issues.

- [ ] **Step 7: Commit**

```bash
git add lib/providers/srs_provider.dart lib/core/srs/sm2.dart lib/main.dart test/providers/srs_provider_test.dart
git commit -m "feat: add SrsProvider (SM-2 schedule store + filter predicates)"
```

---

### Task 3: l10n keys

**Files:**
- Modify: `lib/l10n/app_en.arb` (template — keys + `@` metadata for placeholder keys)
- Modify: `lib/l10n/app_fr.arb`, `lib/l10n/app_es.arb`, `lib/l10n/app_it.arb`
- Generated: `lib/l10n/app_localizations*.dart` via `flutter gen-l10n`

**Interfaces:**
- Produces these `AppLocalizations` members used by Tasks 6 & 7:

| key | en | fr | es | it |
|---|---|---|---|---|
| `preSessionTitle` | `What to review` | `Que réviser ?` | `¿Qué repasar?` | `Cosa ripassare?` |
| `srsFilterAll` | `Review everything` | `Réviser tout` | `Repasar todo` | `Ripassa tutto` |
| `srsFilterAllDesc` | `Every item in the deck` | `Tous les éléments du deck` | `Todos los elementos del mazo` | `Tutti gli elementi del mazzo` |
| `srsFilterDue` | `Due today` | `À réviser aujourd'hui` | `Para hoy` | `Da ripassare oggi` |
| `srsFilterDueDesc` | `Scheduled items plus anything new` | `Éléments programmés plus les nouveautés` | `Elementos programados y novedades` | `Elementi programmati e novità` |
| `srsFilterFresh` | `New items` | `Nouveaux mots` | `Palabras nuevas` | `Parole nuove` |
| `srsFilterFreshDesc` | `Never studied before` | `Jamais étudiés` | `Nunca estudiados` | `Mai studiati` |
| `srsFilterHard` | `Hard items` | `Mots difficiles` | `Palabras difíciles` | `Parole difficili` |
| `srsFilterHardDesc` | `Items you keep missing` | `Ceux que tu rates souvent` | `Los que fallas a menudo` | `Quelli che sbagli spesso` |
| `srsCount` | `{count} items` | `{count} éléments` | `{count} elementos` | `{count} elementi` |
| `nextReviewLine` | `{count, plural, =0{Nothing due tomorrow} =1{1 item due tomorrow} other{{count} items due tomorrow}}` | `{count, plural, =0{Rien de prévu demain} =1{1 élément demain} other{{count} éléments demain}}` | `{count, plural, =0{Nada para mañana} =1{1 elemento mañana} other{{count} elementos mañana}}` | `{count, plural, =0{Niente per domani} =1{1 elemento domani} other{{count} elementi domani}}` |

`srsCount` gets an `@srsCount` int-placeholder block in `app_en.arb`; `nextReviewLine` gets an `@nextReviewLine` int-placeholder block. Template only.

- [ ] **Step 1: Add keys to `lib/l10n/app_en.arb`** (before the closing `}`, comma after the current last value; add `@srsCount` and `@nextReviewLine` blocks after their keys).

- [ ] **Step 2: Add the plain keys to `app_fr.arb`, `app_es.arb`, `app_it.arb`** (before the closing `}`, comma after current last value; no `@` blocks — all 11 keys in each).

- [ ] **Step 3: Regenerate**

Run: `flutter gen-l10n`
Expected: no error, no untranslated-message warning for the new keys.

Run: `flutter analyze`
Expected: no new issues.

- [ ] **Step 4: Commit**

```bash
git add lib/l10n/
git commit -m "feat: add spaced-repetition l10n keys (en/fr/es/it)"
```

---

### Task 4: Remove the daily-reset mechanism

**Files:**
- Modify: `lib/app.dart` (lines ~41-68)
- Modify: `lib/providers/game_provider.dart` (delete `checkDailyReset`; `setDeck` stops restoring `removed`/`completed`)
- Modify: `lib/data/repositories/settings_repository.dart`
- Modify: `lib/data/models/settings.dart` (comment only)
- Modify: `lib/core/constants/app_constants.dart` (remove `keyLastReset`)
- Modify: `test/providers/game_provider_test.dart` (two `setDeck` tests flip)

**Interfaces:**
- Consumes: nothing new.
- Produces: after this task, `setDeck` always yields a fully-active deck (every word `!removed`, every sentence `!completed`) regardless of saved progress; there is no daily reset; the app still boots and plays (pool = everything, every session).

- [ ] **Step 1: Update the two `setDeck` restoration tests**

In `test/providers/game_provider_test.dart`, replace the test at line 66 (`restores removed words from saved progress...`) and line 82 (`does not restore, and does not throw...`) with:

```dart
    test('ignores saved removed flags — every session starts fully active', () async {
      final repo = DeckRepository();
      final saved = _buildDeck()..words.first.removed = true;
      await repo.saveProgress('deck1', GameType.classic.storageId, saved);

      final provider = GameProvider();
      await provider.setDeck(_buildDeck(), gameMode: GameType.classic);

      expect(provider.currentDeck!.words.every((w) => !w.removed), isTrue);
      expect(provider.remainingWords, 3);
    });

    test('setDeck completes cleanly even with unrelated saved progress present', () async {
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
```

- [ ] **Step 2: Run to verify they fail**

Run: `flutter test test/providers/game_provider_test.dart -r expanded`
Expected: FAIL — `ignores saved removed flags` fails (`removed` still restored to true).

- [ ] **Step 3: `GameProvider.setDeck` — stop restoring `removed`/`completed`**

In `lib/providers/game_provider.dart` `setDeck(...)`, the merge block currently loads `savedProgress` and copies `removed`/`completed` by id (roughly lines 190-225 in the current file). Replace that whole block so `setDeck`:
- still builds the fresh deck via `baseDeck.copyWith(words: ...removed:false, sentences: fresh copies completed:false)`
- **does not** call `_repository.loadProgress` and **does not** apply any saved flags
- keeps `_currentProgressDeck = freshDeck; _currentWord = null; _currentSentence = null;` and the `game_started` analytics + `notifyListeners()`

Delete the now-unused `savedProgress` local and the two restoration `for` loops. `_saveProgress()` / `DeckRepository.saveProgress` may stay as-is (still writes the blob on each answer — harmless, just never read back for words/sentences now). `DeckRepository.loadProgress` becomes unused by `GameProvider`; leave the repository method (other callers: none — but removing it is out of scope; a `// no longer used since #8` comment is enough if analyze flags it, which it won't for a public method).

- [ ] **Step 4: Delete `GameProvider.checkDailyReset`**

Remove the whole `checkDailyReset(DateTime lastReset)` method from `game_provider.dart`. `Deck.resetWords()` stays (still called by `resetDeck()`).

- [ ] **Step 5: `lib/app.dart` — strip the reset block**

In `_loadInitialData()`, the block is currently:

```dart
    if (deckProvider.selectedDeck != null) {
      await gameProvider.setDeck(deckProvider.selectedDeck!);
      await gameProvider.checkDailyReset(settings.lastReset);

      final needsReset = await _settingsRepository.needsDailyReset();

      if (needsReset) {
        await _settingsRepository.updateLastReset(DateTime.now());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✨ Nouveau jour ! Deck réinitialisé.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    }
```

Replace with:

```dart
    if (deckProvider.selectedDeck != null) {
      await gameProvider.setDeck(deckProvider.selectedDeck!);
    }
```

`settings` is still used for `themeProvider.setDarkMode(settings.isDarkMode)` — keep the `loadSettings()` call at line 41.

- [ ] **Step 6: `SettingsRepository` cleanup**

In `lib/data/repositories/settings_repository.dart`:
- In `loadSettings()`, delete the `if (DateHelper.needsReset(settings.lastReset)) { ... }` block entirely (the side effect). Return the parsed `settings` directly.
- Delete `updateLastReset(DateTime date)` and `needsDailyReset()`.
- Remove the now-unused `date_helper.dart` import if nothing else in the file uses it (check — after the deletions, nothing does).

- [ ] **Step 7: `Settings` model + `AppConstants`**

In `lib/data/models/settings.dart`, add a comment above `DateTime lastReset;`:
```dart
  // Unused since #8 (spaced repetition). Kept to avoid a build_runner
  // regen + a migration on existing app_settings blobs.
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  DateTime lastReset;
```
In `lib/core/constants/app_constants.dart`, delete `static const String keyLastReset = 'last_reset_date';` and the doc-comment line that references it (line ~138).

- [ ] **Step 8: Run tests + analyze**

Run: `flutter test`
Expected: all green. The two rewritten `setDeck` tests pass; nothing references `checkDailyReset` / `needsDailyReset` / `updateLastReset` / `keyLastReset` any more.

Run: `flutter analyze`
Expected: no new issues (no "unused import", no dead references).

- [ ] **Step 9: Commit**

```bash
git add lib/app.dart lib/providers/game_provider.dart lib/data/repositories/settings_repository.dart lib/data/models/settings.dart lib/core/constants/app_constants.dart test/providers/game_provider_test.dart
git commit -m "refactor: remove the daily-reset mechanism (SM-2 replaces it)"
```

---

### Task 5: GameProvider SM-2 integration

**Files:**
- Modify: `lib/providers/game_provider.dart`
- Modify: `lib/main.dart` (proxy provider → `ChangeNotifierProxyProvider2`)
- Modify: `lib/screens/games/classic_game/widgets/drawing_widget.dart` (addReview fix)
- Test: `test/providers/game_provider_test.dart` (new group)

**Interfaces:**
- Consumes: `SrsProvider` (`matches`, `grade`), `SessionFilter` (from `sm2.dart`).
- Produces on `GameProvider`:
  - constructor gains `SrsProvider? srsProvider`
  - `setDeck(Deck, {GameType gameMode, SessionFilter filter = SessionFilter.due})`
  - `SessionFilter get sessionFilter`
  - `String srsKeyForWord(Word w)` → `w.id`; `String srsKeyForSentence(Sentence s)` → `'${_currentDeckId}::${s.id}'`
  - filtered `spinWheel` / `_loadNextSentence`; `isCompleted` over the filtered pool
  - `grade` call on each first-correct

- [ ] **Step 1: Write the failing tests**

Add to `test/providers/game_provider_test.dart` a new group (after `GameProvider - session summary`). Uses a real `SrsProvider` injected into `GameProvider`.

```dart
  group('GameProvider - SM-2 integration', () {
    test('filter=fresh limits spinWheel to never-seen words', () async {
      final srs = SrsProvider()..load();
      await srs.grade('deck1_w0', 5); // w0 now seen

      final provider = GameProvider(srsProvider: srs);
      await provider.setDeck(
        _buildDeck(wordCount: 3), // ids deck1_w0.. no — _buildDeck uses 'w0'.. see note
        gameMode: GameType.classic,
        filter: SessionFilter.fresh,
      );
      // repeatedly spin; w0 must never come up
      for (var i = 0; i < 30; i++) {
        await provider.spinWheel();
        expect(provider.currentWord!.id, isNot('w0'));
      }
    });

    test('answering a word grades it with quality from the session mistake count', () async {
      final srs = SrsProvider()..load();
      final provider = GameProvider(srsProvider: srs);
      await provider.setDeck(_oneWordDeck(), gameMode: GameType.classic,
          filter: SessionFilter.all);
      await provider.spinWheel();

      await provider.checkAnswer('nope');
      await provider.checkAnswer('nope');
      await provider.checkAnswer('one'); // 2 mistakes → quality 3

      final card = srs.cardFor('w0');
      expect(card, isNotNull);
      expect(card!.reps, 1);
      // q3 lowers ef below the q5 value
      expect(card.ef, lessThan(2.5));
    });

    test('first-try correct grades quality 5', () async {
      final srs = SrsProvider()..load();
      final provider = GameProvider(srsProvider: srs);
      await provider.setDeck(_oneWordDeck(), gameMode: GameType.classic,
          filter: SessionFilter.all);
      await provider.spinWheel();
      await provider.checkAnswer('one');

      expect(srs.cardFor('w0')!.ef, closeTo(2.6, 1e-9));
    });

    test('sentence completion grades the composite key', () async {
      final srs = SrsProvider()..load();
      final provider = GameProvider(srsProvider: srs);
      final deck = _buildDeck(sentences: [
        Sentence(id: 's1', original: 'Bonjour', translation: 'nihao', blocks: ['ni', 'hao', 'bu']),
      ]);
      await provider.setDeck(deck, gameMode: GameType.sentence,
          filter: SessionFilter.all);
      await provider.spinWheel();
      provider.addBlockToSentence('ni');
      provider.addBlockToSentence('hao');
      await provider.checkSentenceConstruction();

      expect(srs.cardFor('deck1::s1'), isNotNull);
    });

    test('isCompleted is true when the filtered pool is exhausted, not the whole deck', () async {
      final srs = SrsProvider()..load();
      await srs.grade('w1', 5);
      await srs.grade('w2', 5); // only w0 is "fresh"

      final provider = GameProvider(srsProvider: srs);
      await provider.setDeck(_buildDeck(wordCount: 3), gameMode: GameType.classic,
          filter: SessionFilter.fresh);
      await provider.spinWheel();
      expect(provider.currentWord!.id, 'w0');
      await provider.checkAnswer('answer0');

      expect(provider.isCompleted, isTrue); // w1/w2 remain in the deck but aren't in the filter
    });
  });
```

> **Note for the implementer:** `_buildDeck` creates word ids `w0`, `w1`, `w2`
> (not `deck1_w0`). The first test's comment is wrong — use `srs.grade('w0', 5)`
> and assert `isNot('w0')`. Fix the test to match `_buildDeck`'s ids before
> running. Real decks use `<deckId>_wN` but the test helper does not, and
> `srsKeyForWord` just returns `w.id` verbatim, so the tests are consistent as
> long as you key on the helper's ids.

- [ ] **Step 2: Run to verify they fail**

Run: `flutter test test/providers/game_provider_test.dart -r expanded`
Expected: FAIL — `GameProvider` has no `srsProvider` param / `setDeck` has no `filter` param.

- [ ] **Step 3: `GameProvider` — constructor, filter, srsKey helpers**

```dart
  final SrsProvider? srsProvider;
  GameProvider({this.statisticsProvider, this.srsProvider});

  SessionFilter _sessionFilter = SessionFilter.due;
  SessionFilter get sessionFilter => _sessionFilter;

  String srsKeyForWord(Word w) => w.id;
  String srsKeyForSentence(Sentence s) => '${_currentDeckId}::${s.id}';

  bool _passesFilter(String srsKey) =>
      srsProvider == null ||
      srsProvider!.matches(_sessionFilter, srsKey, DateTime.now());
```

Import `package:language_learning_app/core/srs/sm2.dart` and
`package:language_learning_app/providers/srs_provider.dart`.

- [ ] **Step 4: `setDeck` — accept the filter**

Change the signature to
`Future<void> setDeck(Deck baseDeck, {GameType gameMode = GameType.classic, SessionFilter filter = SessionFilter.due})`
and set `_sessionFilter = filter;` near the top (with the `_sessionCompleted.clear()` lines).

- [ ] **Step 5: Filter `spinWheel` and `_loadNextSentence`**

In `spinWheel()`, replace the word-mode pool:

```dart
    final pool = _currentProgressDeck!.words
        .where((w) => !w.removed && _passesFilter(srsKeyForWord(w)))
        .toList();
    if (pool.isEmpty) {
      _currentWord = null;
      notifyListeners();
      return;
    }
    _currentWord = pool[Random().nextInt(pool.length)];
```

Keep `_generateQuizOptions(activeWords)` fed from `_currentProgressDeck!.words`
where words are `!removed` — quiz distractors don't need the filter. (Pass the
full `!removed` list, not `pool`.)

In `_loadNextSentence()`:

```dart
    final pool = _currentProgressDeck!.sentences
        .where((s) => !s.completed && _passesFilter(srsKeyForSentence(s)))
        .toList();
    if (pool.isEmpty) { _currentSentence = null; return; }
    _currentSentence = pool[Random().nextInt(pool.length)];
```

- [ ] **Step 6: `isCompleted` over the filtered pool**

```dart
  bool get isCompleted {
    if (_currentProgressDeck == null) return false;
    if (_currentGameType == GameType.sentence) {
      return !_currentProgressDeck!.sentences
          .any((s) => !s.completed && _passesFilter(srsKeyForSentence(s)));
    }
    return !_currentProgressDeck!.words
        .any((w) => !w.removed && _passesFilter(srsKeyForWord(w)));
  }
```

(`totalWords` / `remainingWords` / `progress` keep their current whole-deck
meaning for the progress bar — do not change them.)

- [ ] **Step 7: Grade on completion**

Add a helper:

```dart
  int _qualityFromMistakes(int mistakes) => switch (mistakes) {
        0 => 5,
        1 => 4,
        2 => 3,
        _ => 2,
      };

  void _gradeItem(String bareId, String srsKey) {
    final q = _qualityFromMistakes(_sessionMistakes[bareId] ?? 0);
    srsProvider?.grade(srsKey, q); // fire-and-forget
  }
```

In `checkAnswer`, on the correct branch (right after `_sessionCompleted.add(_currentWord!.id);`):
```dart
      _gradeItem(_currentWord!.id, srsKeyForWord(_currentWord!));
```
In `checkSentenceConstruction`, on the correct branch (after `_sessionCompleted.add(_currentSentence!.id);`):
```dart
      _gradeItem(_currentSentence!.id, srsKeyForSentence(_currentSentence!));
```
In `markCurrentWordAsCorrect`, after `_sessionCompleted.add(_currentWord!.id);`:
```dart
      _gradeItem(_currentWord!.id, srsKeyForWord(_currentWord!));
```

- [ ] **Step 8: Drawing under-logging fix**

In `markCurrentWordAsCorrect()`, before the grade call, add:

```dart
    unawaited(statisticsProvider?.addReview(
      wordId: _currentWord!.id,
      deckId: _currentProgressDeck!.id,
      wasCorrect: true,
      inputType: 'draw',
      gameMode: _currentGameType!.storageId,
    ) ?? Future.value());
```

(`dart:async` is already imported in `game_provider.dart`.)

- [ ] **Step 9: `main.dart` proxy provider**

Replace the `ChangeNotifierProxyProvider<StatisticsProvider, GameProvider>`
block with:

```dart
          ChangeNotifierProxyProvider2<StatisticsProvider, SrsProvider, GameProvider>(
            create: (context) => GameProvider(
              statisticsProvider: context.read<StatisticsProvider>(),
              srsProvider: context.read<SrsProvider>(),
            ),
            update: (context, stats, srs, previous) =>
                previous ?? GameProvider(statisticsProvider: stats, srsProvider: srs),
          ),
```

- [ ] **Step 10: Run tests + analyze**

Run: `flutter test`
Expected: all green (the new SM-2 group + everything else). If a pre-existing
`spinWheel`/`checkAnswer` test breaks because it never set a filter: the
default is `SessionFilter.due`, and with a null `srsProvider` (most existing
tests construct `GameProvider()` with no args) `_passesFilter` returns `true`,
so the pool is unchanged. Verify that's the case; if any existing test
constructs `GameProvider` *with* a `statisticsProvider` but no `srsProvider`,
it still works (null srs → no filtering).

Run: `flutter analyze`
Expected: no new issues.

- [ ] **Step 11: Commit**

```bash
git add lib/providers/game_provider.dart lib/main.dart lib/screens/games/classic_game/widgets/drawing_widget.dart test/providers/game_provider_test.dart
git commit -m "feat: filter game sessions by SM-2 schedule and grade on completion"
```

---

### Task 6: Pre-session screen + Home routing

**Files:**
- Create: `lib/screens/games/pre_session_screen.dart`
- Modify: `lib/screens/home/home_screen.dart` (`_buildGameModeCard` onTap)

**Interfaces:**
- Consumes: `SrsProvider` (`counts`, `filterFor`, `setFilterFor`, `matches`),
  `GameProvider.setDeck(..., filter:)`, `AppLocalizations` srs keys (Task 3),
  `SessionFilter`.
- Produces: `class PreSessionScreen extends StatelessWidget` with
  `const PreSessionScreen({required this.deck, required this.mode, required this.title})`.

- [ ] **Step 1: Build `PreSessionScreen`**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:language_learning_app/core/srs/sm2.dart';
import 'package:language_learning_app/core/theme/app_colors.dart';
import 'package:language_learning_app/data/models/deck.dart';
import 'package:language_learning_app/data/models/game_mode.dart';
import 'package:language_learning_app/l10n/app_localizations.dart';
import 'package:language_learning_app/providers/game_provider.dart';
import 'package:language_learning_app/providers/srs_provider.dart';
import 'package:language_learning_app/screens/games/classic_game/game_screen.dart';

class PreSessionScreen extends StatelessWidget {
  final Deck deck;
  final GameType mode;
  final String title;

  const PreSessionScreen({
    super.key,
    required this.deck,
    required this.mode,
    required this.title,
  });

  List<String> _srsKeys() => mode == GameType.sentence
      ? deck.sentences.map((s) => '${deck.id}::${s.id}').toList()
      : deck.words.map((w) => w.id).toList();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final srs = context.watch<SrsProvider>();
    final now = DateTime.now();
    final keys = _srsKeys();
    final c = srs.counts(keys, now);

    final rows = <(SessionFilter, String, String, int)>[
      (SessionFilter.due, l10n.srsFilterDue, l10n.srsFilterDueDesc, c.due),
      (SessionFilter.fresh, l10n.srsFilterFresh, l10n.srsFilterFreshDesc, c.fresh),
      (SessionFilter.hard, l10n.srsFilterHard, l10n.srsFilterHardDesc, c.hard),
      (SessionFilter.all, l10n.srsFilterAll, l10n.srsFilterAllDesc, c.all),
    ];

    final last = srs.filterFor(deck.id, mode);
    final preselect = rows.any((r) => r.$1 == last && r.$4 > 0)
        ? last
        : rows.firstWhere((r) => r.$4 > 0, orElse: () => rows.last).$1;

    return Scaffold(
      appBar: AppBar(title: Text(title), centerTitle: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(l10n.preSessionTitle,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            for (final (filter, label, desc, count) in rows)
              _FilterCard(
                label: label,
                desc: desc,
                count: count,
                countLabel: l10n.srsCount(count),
                selected: filter == preselect,
                enabled: count > 0 || filter == SessionFilter.all,
                onTap: () => _start(context, filter),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _start(BuildContext context, SessionFilter filter) async {
    final srs = context.read<SrsProvider>();
    final game = context.read<GameProvider>();
    await srs.setFilterFor(deck.id, mode, filter);
    await game.setDeck(deck, gameMode: mode, filter: filter);
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => GameScreen(gameTitle: title)),
    );
  }
}

class _FilterCard extends StatelessWidget {
  final String label, desc, countLabel;
  final int count;
  final bool selected, enabled;
  final VoidCallback onTap;
  const _FilterCard({
    required this.label,
    required this.desc,
    required this.count,
    required this.countLabel,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Card(
        elevation: 0,
        color: selected
            ? AppColors.primary.withValues(alpha: 0.1)
            : Theme.of(context).cardTheme.color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          title: Text(label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          subtitle: Text(desc),
          trailing: Text(countLabel,
              style: TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.bold)),
          onTap: enabled ? onTap : null,
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Route Home through it**

In `lib/screens/home/home_screen.dart`, `_buildGameModeCard`'s `onTap`: after
the deck-ready / download logic, the current tail is
`gameProvider.setDeck(deck, gameMode: mode.type);` then
`Navigator.push(... GameScreen(gameTitle: mode.title) ...)`. Replace those two
with:

```dart
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PreSessionScreen(
                    deck: deck,
                    mode: mode.type,
                    title: mode.title,
                  ),
                ),
              );
```

Remove the now-unused `gameProvider` local if analyze flags it (it's still used
earlier in the handler for the `deckProvider.selectedDeck == null` path — check;
likely keep it). Add the import for `pre_session_screen.dart`; drop the
`game_screen.dart` import from `home_screen.dart` if it's now unused.

- [ ] **Step 3: Analyze + test**

Run: `flutter analyze` → no new issues.
Run: `flutter test` → all green (no widget test added; existing suite unaffected).

- [ ] **Step 4: Commit**

```bash
git add lib/screens/games/pre_session_screen.dart lib/screens/home/home_screen.dart
git commit -m "feat: pre-session filter screen (all / due / new / hard)"
```

---

### Task 7: CompletedCard "next session" line + Settings reset wiring

**Files:**
- Modify: `lib/screens/games/classic_game/widgets/completed_card.dart`
- Modify: `lib/screens/settings/settings_screen.dart`

**Interfaces:**
- Consumes: `SrsProvider.dueOn`, `GameProvider` (deck + mode → srsKeys),
  `AppLocalizations.nextReviewLine`, `SrsProvider.resetKeys`.

- [ ] **Step 1: `CompletedCard` — "prochaine session" line**

`CompletedCard` is a `StatefulWidget` that already
`context.watch<GameProvider>()` and reads `StatisticsProvider` / `GoalProvider`.
Add a method and call it between `_buildGoalProgress(context)` and the restart
button:

```dart
  Widget _buildNextReview(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final game = context.watch<GameProvider>();
    final srs = context.watch<SrsProvider>();
    final deck = game.currentDeck;
    if (deck == null) return const SizedBox.shrink();

    final keys = game.currentGameType == GameType.sentence
        ? deck.sentences.map((s) => srs /* key */ => 0).isEmpty ? <String>[] : deck.sentences.map((s) => '${deck.id}::${s.id}').toList()
        : deck.words.map((w) => w.id).toList();

    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final n = srs.dueOn(keys, tomorrow);

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(
        l10n.nextReviewLine(n),
        style: Theme.of(context).textTheme.bodySmall,
        textAlign: TextAlign.center,
      ),
    );
  }
```

> Clean the key-list expression up when implementing — it should be simply:
> ```dart
> final keys = game.currentGameType == GameType.sentence
>     ? deck.sentences.map((s) => '${deck.id}::${s.id}').toList()
>     : deck.words.map((w) => w.id).toList();
> ```

Add imports for `srs_provider.dart` and `game_mode.dart` if not present.
`nextReviewLine` handles the 0 case (`=0{...}` plural branch), so no
conditional hiding is needed — always render the line.

- [ ] **Step 2: Settings "Réinitialiser le deck actuel"**

In `lib/screens/settings/settings_screen.dart`, the "Réinitialiser le deck
actuel" tile currently does `ResetDeckDialog.show(context)`. Find where the
reset is actually performed (`ResetDeckDialog` → likely
`gameProvider.resetModeProgress` / `resetAllModesProgress`, or
`DeckRepository.resetAllProgressForDeck`). Add, alongside the existing progress
wipe, a call to clear the SM-2 schedule for that deck:

```dart
    final deck = context.read<DeckProvider>().selectedDeck;
    if (deck != null) {
      final keys = <String>[
        ...deck.words.map((w) => w.id),
        ...deck.sentences.map((s) => '${deck.id}::${s.id}'),
      ];
      await context.read<SrsProvider>().resetKeys(keys);
    }
```

Place it in `ResetDeckDialog`'s confirm handler (open that file, add the
`SrsProvider` call next to the existing reset call). Import `srs_provider.dart`.
If `deck.words` is empty because the base deck is metadata-only at that point,
fall back to `context.read<GameProvider>().currentDeck` which holds the
populated deck.

- [ ] **Step 3: Analyze + test**

Run: `flutter analyze` → no new issues.
Run: `flutter test` → all green.

- [ ] **Step 4: Commit**

```bash
git add lib/screens/games/classic_game/widgets/completed_card.dart lib/screens/settings/settings_screen.dart lib/screens/settings/widgets/reset_deck_dialog.dart
git commit -m "feat: next-session line on completed card + SM-2 wipe on deck reset"
```

---

### Task 8: Verification + phone smoke

**Files:** none.

- [ ] **Step 1: Full analyze + test**

Run: `flutter analyze` → `No issues found!`
Run: `flutter test` → all pass (new: `sm2_test.dart`, `srs_provider_test.dart`, the SM-2 `game_provider_test.dart` group; two rewritten `setDeck` tests).

- [ ] **Step 2: l10n**

Run: `flutter gen-l10n` → clean, no untranslated-message warnings for `srs*` / `preSessionTitle` / `nextReviewLine`.

- [ ] **Step 3: Build + install**

```bash
flutter build apk --debug
adb -s <device> install -r build/app/outputs/flutter-apk/app-debug.apk
adb -s <device> shell am force-stop com.timouss.linguo
adb -s <device> shell monkey -p com.timouss.linguo -c android.intent.category.LAUNCHER 1
```

- [ ] **Step 4: Ask the user to smoke-test**

- Start a game → the pre-session screen shows 4 options with counts; "À réviser aujourd'hui" (or the fallback) is pre-selected.
- Pick "Nouveaux mots" → play a few, get one wrong twice → finish → CompletedCard shows the session summary + "X éléments demain" line.
- Back out, start the same deck again → "Nouveaux mots" count dropped by what you did; "À réviser aujourd'hui" is smaller (the ones you graded are scheduled ahead).
- Confirm no "Nouveau jour" SnackBar ever appears.
- Settings → Réinitialiser le deck actuel → confirm the pre-session counts reset to all-new.

Screenshot read-only; do not drive the phone.

- [ ] **Step 5: Report** — what shipped, the SM-2 model, the 4 filters, that the daily reset is gone; branch ready to merge into `develop`.

---

## Self-Review

**1. Spec coverage:**

| Spec section | Task |
|---|---|
| §1 SM-2 core | Task 1 |
| §2 SrsProvider + `srs_state` + filter map | Task 2 |
| §3 4 filters / predicates / fallback | Task 2 (`matches`, `counts`), Task 6 (fallback UI) |
| §4 quality auto-derived + drawing addReview fix | Task 5 Steps 7–8 |
| §5 GameProvider integration (filter param, filtered pools, grade, isCompleted, removed not restored) | Task 4 Step 3 (removed), Task 5 |
| §6 PreSessionScreen + Home routing | Task 6 |
| §6bis CompletedCard next-review line | Task 7 Step 1 |
| §7bis sentence scheduling (composite key, completed not persisted) | Task 4 Step 3 (completed), Task 5 (`srsKeyForSentence`, filtered `_loadNextSentence`, grade) |
| §7 daily reset removal ripple (app.dart, settings_repo, settings model, app_constants) | Task 4 |
| §8 non-goals | n/a (nothing to build) |
| §9 files | covered across tasks |
| §10 testing | Tasks 1,2,4,5 tests + Task 8 |

No gaps.

**2. Placeholder scan:** Task 5 Step 1 and Task 7 Step 1 contain deliberately-flagged
"clean this up" notes with the corrected code shown immediately after — the
implementer has the exact final form. All other steps are literal. No "TBD" /
"similar to Task N" / bare "add error handling".

**3. Type consistency:**
- `SessionFilter` — defined in `sm2.dart` (Task 2 Step 1), imported by
  `SrsProvider` (Task 2) and `GameProvider` (Task 5) and `PreSessionScreen`
  (Task 6). One definition, no duplication.
- `SrsCard` / `reviewCard` / `dateOnly` — Task 1, consumed by Task 2 only.
- `SrsProvider` API — `cardFor` / `grade(String,int)` / `isDue(String,DateTime)`
  / `isNew(String)` / `isDifficult(String)` / `matches(SessionFilter,String,DateTime)`
  / `counts(Iterable<String>,DateTime)→({int all,int due,int fresh,int hard})`
  / `dueOn(Iterable<String>,DateTime)→int` / `resetKeys(Iterable<String>)`
  / `filterFor(String,GameType)→SessionFilter` / `setFilterFor(String,GameType,SessionFilter)`
  — defined Task 2, used with those exact signatures in Tasks 5, 6, 7.
- `GameProvider` — `srsProvider` ctor param, `setDeck(..., {SessionFilter filter})`,
  `srsKeyForWord(Word)→String`, `srsKeyForSentence(Sentence)→String`,
  `sessionFilter` getter — defined Task 5, used in Task 6.
- l10n `srsCount(int)` / `nextReviewLine(int)` / `srsFilter*` getters / `preSessionTitle`
  — defined Task 3, used Tasks 6, 7.

Consistent.

---

## Pre-work

```bash
git checkout develop && git pull
git checkout -b feature/spaced-repetition
git branch --show-current   # must print feature/spaced-repetition
```

## Execution Handoff

Two options:

1. **Subagent-Driven (recommended)** — fresh subagent per task, review between tasks. (8 tasks; Tasks 4 and 5 are the load-bearing ones.)
2. **Inline Execution** — via `superpowers:executing-plans`.

Which approach?
