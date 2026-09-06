# Daily Goal + Session-End Progress Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a configurable daily practice goal (Léger/Normal/Intense) with progress surfaced on the end-of-round card, the statistics screen, and a one-per-day "goal reached" SnackBar during play.

**Architecture:** A pure logic file (`lib/core/goal/daily_goal.dart`) holds the enum, target mapping, and the "should celebrate today" decision — unit-tested with no Flutter deps, mirroring `lib/core/notifications/notification_schedule.dart`. A `GoalProvider` (ChangeNotifier, own SharedPreferences keys, mirroring `ReminderProvider`) holds the chosen level and the celebration date-stamp. The daily count reuses the existing flat `ReviewHistory` log via a new one-line `StatisticsProvider.reviewsToday()` getter — no new persistence for counting. UI reads both providers; nothing in `GameProvider` changes.

**Tech Stack:** Flutter, `provider` package, `shared_preferences` (via `StorageHelper`), `flutter gen-l10n` codegen for 4 locales (en/fr/es/it), `flutter_test`.

**Spec:** No standalone spec doc — this plan implements PM/UX growth roadmap item #7, recorded in the project memory `project-next-chantier-priorities`. The grilling session on 2026-09-06 settled every decision; they are captured in the Global Constraints and per-task notes below.

## Global Constraints

- **Goal metric:** "réponses données aujourd'hui" = count of `ReviewEntry` rows dated today (`ReviewHistory.getReviewsForDay(DateTime.now()).length`). Counts wrong answers and retries. No distinct-word logic.
- **Presets (exact values):** Léger = 10, Normal = 20, Intense = 40. Default = Normal.
- **No enable/disable toggle** — the goal is always active; the only setting is the level.
- **New prefs follow the `ReminderProvider` pattern**: a dedicated `ChangeNotifier` with its own raw `StorageHelper` string keys. Do NOT touch the codegen `Settings` model / `settings.g.dart`.
- **l10n:** every new key goes in all four `lib/l10n/app_{en,fr,es,it}.arb` files; placeholder keys also get an `@key` metadata block in the template `app_en.arb`. Run `flutter gen-l10n` after editing arb files. The generated `lib/l10n/app_localizations*.dart` files are committed.
- **Settings section order:** … → Statistiques → **Objectif quotidien** (new) → Rappels → Aide.
- **Analytics:** fire-and-forget `AnalyticsService.logEvent('daily_goal_reached', {'goal': <target>})`, never awaited, exactly once per day (same trigger as the SnackBar).
- **The ring is `CircularProgressIndicator` (native)** — no `CustomPainter`, no chart library.
- **Test bar:** `flutter analyze` (zero new issues) + `flutter test` (all green). No manual/visual smoke test unless the user asks.
- **Branch:** `feature/daily-goal` off `develop`. The paused `feature/pronunciation-game` worktree has its own copy of the four arb files — an l10n merge conflict there is expected and accepted; do not try to pre-resolve it.
- **`markCurrentWordAsCorrect()` / drawing mode already logs a review** (`drawing_widget.dart:94` calls `addReview` before `markCurrentWordAsCorrect`). No fix needed — drawing answers already count toward the goal.

---

### Task 1: Pure daily-goal logic + unit test

**Files:**
- Create: `lib/core/goal/daily_goal.dart`
- Test: `test/daily_goal_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces:
  - `enum DailyGoalLevel { light, normal, intense }`
  - `int goalTarget(DailyGoalLevel level)` → 10 / 20 / 40
  - `String dailyGoalLevelToString(DailyGoalLevel level)` → `'light'|'normal'|'intense'`
  - `DailyGoalLevel dailyGoalLevelFromString(String? raw)` → parses the above, defaults to `DailyGoalLevel.normal` on null/unknown
  - `String isoDate(DateTime d)` → `'YYYY-MM-DD'` (zero-padded month/day)
  - `bool shouldCelebrateGoal({required int reviewsToday, required int target, required String? lastCelebratedDate, required DateTime now})` → true iff `reviewsToday >= target` AND `lastCelebratedDate != isoDate(now)`

- [ ] **Step 1: Write the failing test**

Create `test/daily_goal_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:language_learning_app/core/goal/daily_goal.dart';

void main() {
  group('goalTarget', () {
    test('maps each level to its preset', () {
      expect(goalTarget(DailyGoalLevel.light), 10);
      expect(goalTarget(DailyGoalLevel.normal), 20);
      expect(goalTarget(DailyGoalLevel.intense), 40);
    });
  });

  group('dailyGoalLevel string round-trip', () {
    test('toString / fromString are inverses', () {
      for (final level in DailyGoalLevel.values) {
        expect(dailyGoalLevelFromString(dailyGoalLevelToString(level)), level);
      }
    });

    test('fromString defaults to normal on null or garbage', () {
      expect(dailyGoalLevelFromString(null), DailyGoalLevel.normal);
      expect(dailyGoalLevelFromString('wat'), DailyGoalLevel.normal);
    });
  });

  group('isoDate', () {
    test('zero-pads month and day', () {
      expect(isoDate(DateTime(2026, 3, 7, 23, 59)), '2026-03-07');
      expect(isoDate(DateTime(2026, 12, 25)), '2026-12-25');
    });
  });

  group('shouldCelebrateGoal', () {
    final now = DateTime(2026, 3, 10, 18, 0);

    test('false while below target', () {
      expect(
        shouldCelebrateGoal(
            reviewsToday: 9, target: 10, lastCelebratedDate: null, now: now),
        isFalse,
      );
    });

    test('true when target reached and not celebrated today', () {
      expect(
        shouldCelebrateGoal(
            reviewsToday: 10, target: 10, lastCelebratedDate: null, now: now),
        isTrue,
      );
      expect(
        shouldCelebrateGoal(
            reviewsToday: 25,
            target: 10,
            lastCelebratedDate: '2026-03-09',
            now: now),
        isTrue,
      );
    });

    test('false when already celebrated today', () {
      expect(
        shouldCelebrateGoal(
            reviewsToday: 40,
            target: 10,
            lastCelebratedDate: '2026-03-10',
            now: now),
        isFalse,
      );
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/daily_goal_test.dart`
Expected: FAIL — `Error: Couldn't resolve the package 'language_learning_app/core/goal/daily_goal.dart'` / undefined `DailyGoalLevel`.

- [ ] **Step 3: Write the implementation**

Create `lib/core/goal/daily_goal.dart`:

```dart
/// Pure daily-goal logic — no Flutter, no storage. Unit-tested in
/// test/daily_goal_test.dart. Mirrors lib/core/notifications/notification_schedule.dart.

enum DailyGoalLevel { light, normal, intense }

/// The preset number of reviews per day for each level.
int goalTarget(DailyGoalLevel level) => switch (level) {
      DailyGoalLevel.light => 10,
      DailyGoalLevel.normal => 20,
      DailyGoalLevel.intense => 40,
    };

String dailyGoalLevelToString(DailyGoalLevel level) => level.name;

/// Parses a stored level string. Defaults to [DailyGoalLevel.normal] for
/// null or unrecognised input (covers first launch and forward-compat).
DailyGoalLevel dailyGoalLevelFromString(String? raw) {
  for (final level in DailyGoalLevel.values) {
    if (level.name == raw) return level;
  }
  return DailyGoalLevel.normal;
}

/// `YYYY-MM-DD` in local time — the per-day key for the celebration stamp.
String isoDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Whether to fire the "goal reached" celebration now: target met and not
/// already celebrated on [now]'s calendar day.
bool shouldCelebrateGoal({
  required int reviewsToday,
  required int target,
  required String? lastCelebratedDate,
  required DateTime now,
}) {
  if (reviewsToday < target) return false;
  return lastCelebratedDate != isoDate(now);
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/daily_goal_test.dart`
Expected: PASS (all groups).

- [ ] **Step 5: Commit**

```bash
git add lib/core/goal/daily_goal.dart test/daily_goal_test.dart
git commit -m "feat: add pure daily-goal logic (targets + celebrate decision)"
```

---

### Task 2: `reviewsToday()` getter on StatisticsProvider

**Files:**
- Modify: `lib/providers/statistics_provider.dart` (add method near `hasPracticedToday()` at line 164)
- Test: `test/providers/statistics_provider_test.dart` (add a test to the existing `group('StatisticsProvider', ...)`)

**Interfaces:**
- Consumes: `_history` (`ReviewHistory`), already in the class.
- Produces: `int reviewsToday()` on `StatisticsProvider` — count of review entries whose `reviewedAt` is today.

- [ ] **Step 1: Write the failing test**

Add inside `group('StatisticsProvider', () { ... })` in `test/providers/statistics_provider_test.dart`:

```dart
    test('reviewsToday counts every entry dated today, wrong answers included',
        () async {
      final provider = StatisticsProvider();
      await provider.loadHistory();

      expect(provider.reviewsToday(), 0);

      await provider.addReview(
          wordId: 'w1', deckId: 'd1', wasCorrect: true, inputType: 'text', gameMode: 'classic');
      await provider.addReview(
          wordId: 'w1', deckId: 'd1', wasCorrect: false, inputType: 'text', gameMode: 'classic');
      await provider.addReview(
          wordId: 'w2', deckId: 'd1', wasCorrect: true, inputType: 'text', gameMode: 'classic');

      // 3 answers even though only 2 distinct words.
      expect(provider.reviewsToday(), 3);
    });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/providers/statistics_provider_test.dart -r expanded`
Expected: FAIL — `The method 'reviewsToday' isn't defined for the type 'StatisticsProvider'`.

- [ ] **Step 3: Write the implementation**

In `lib/providers/statistics_provider.dart`, directly below `hasPracticedToday()` (currently ends line 165), add:

```dart
  /// Number of reviews recorded today (every answer, correct or not). Drives
  /// the daily-goal progress. See lib/core/goal/daily_goal.dart.
  int reviewsToday() => _history.getReviewsForDay(DateTime.now()).length;
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/providers/statistics_provider_test.dart -r expanded`
Expected: PASS (whole file).

- [ ] **Step 5: Commit**

```bash
git add lib/providers/statistics_provider.dart test/providers/statistics_provider_test.dart
git commit -m "feat: add StatisticsProvider.reviewsToday()"
```

---

### Task 3: GoalProvider + registration

**Files:**
- Create: `lib/providers/goal_provider.dart`
- Modify: `lib/main.dart` (imports at line 11-16; `MultiProvider.providers` list at line 49-64)
- Test: `test/providers/goal_provider_test.dart`

**Interfaces:**
- Consumes: `daily_goal.dart` (Task 1) — `DailyGoalLevel`, `goalTarget`, `dailyGoalLevelFromString`, `dailyGoalLevelToString`, `isoDate`, `shouldCelebrateGoal`. `StorageHelper` (`getString`, `saveString`).
- Produces:
  - `class GoalProvider extends ChangeNotifier`
  - `DailyGoalLevel get level`
  - `int get target` → `goalTarget(level)`
  - `void load()` — reads both keys from `StorageHelper`, calls `notifyListeners()`
  - `Future<void> setLevel(DailyGoalLevel level)` — persists key `daily_goal_level`, `notifyListeners()`
  - `bool consumeCelebration(int reviewsToday)` — returns true at most once per calendar day (first time `reviewsToday >= target`); stamps `daily_goal_celebrated_date` and does NOT notify

- [ ] **Step 1: Write the failing test**

Create `test/providers/goal_provider_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:language_learning_app/core/goal/daily_goal.dart';
import 'package:language_learning_app/core/utils/storage_helper.dart';
import 'package:language_learning_app/providers/goal_provider.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageHelper.init();
  });

  test('defaults to normal (20) before anything is stored', () {
    final provider = GoalProvider()..load();
    expect(provider.level, DailyGoalLevel.normal);
    expect(provider.target, 20);
  });

  test('setLevel persists and a fresh provider reads it back', () async {
    final a = GoalProvider()..load();
    await a.setLevel(DailyGoalLevel.intense);
    expect(a.target, 40);

    final b = GoalProvider()..load();
    expect(b.level, DailyGoalLevel.intense);
  });

  test('consumeCelebration fires once, then not again the same day', () {
    final provider = GoalProvider()..load(); // target 20

    expect(provider.consumeCelebration(19), isFalse);
    expect(provider.consumeCelebration(20), isTrue);
    expect(provider.consumeCelebration(25), isFalse);
    expect(provider.consumeCelebration(40), isFalse);
  });

  test('celebration stamp survives a provider reload (still not re-fired today)',
      () async {
    final a = GoalProvider()..load();
    expect(a.consumeCelebration(20), isTrue);

    final b = GoalProvider()..load();
    expect(b.consumeCelebration(20), isFalse);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/providers/goal_provider_test.dart`
Expected: FAIL — cannot resolve `package:language_learning_app/providers/goal_provider.dart`.

- [ ] **Step 3: Write the implementation**

Create `lib/providers/goal_provider.dart`:

```dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:language_learning_app/core/goal/daily_goal.dart';
import 'package:language_learning_app/core/utils/storage_helper.dart';

/// The user's daily practice goal (Léger / Normal / Intense), persisted
/// locally. Follows the ReminderProvider pattern: own raw SharedPreferences
/// keys, not the codegen Settings model. Always active — there is no on/off.
class GoalProvider extends ChangeNotifier {
  static const _kLevel = 'daily_goal_level'; // 'light' | 'normal' | 'intense'
  static const _kCelebratedDate = 'daily_goal_celebrated_date'; // 'YYYY-MM-DD'

  DailyGoalLevel _level = DailyGoalLevel.normal;
  String? _celebratedDate;

  DailyGoalLevel get level => _level;
  int get target => goalTarget(_level);

  void load() {
    _level = dailyGoalLevelFromString(StorageHelper.getString(_kLevel));
    _celebratedDate = StorageHelper.getString(_kCelebratedDate);
    notifyListeners();
  }

  Future<void> setLevel(DailyGoalLevel level) async {
    _level = level;
    await StorageHelper.saveString(_kLevel, dailyGoalLevelToString(level));
    notifyListeners();
  }

  /// True at most once per calendar day, the first time today's review count
  /// reaches [target]. Stamps the date so later calls return false. Does not
  /// call notifyListeners — the caller just shows a SnackBar / logs an event.
  bool consumeCelebration(int reviewsToday) {
    final now = DateTime.now();
    if (!shouldCelebrateGoal(
      reviewsToday: reviewsToday,
      target: target,
      lastCelebratedDate: _celebratedDate,
      now: now,
    )) {
      return false;
    }
    _celebratedDate = isoDate(now);
    unawaited(StorageHelper.saveString(_kCelebratedDate, _celebratedDate!));
    return true;
  }
}
```

- [ ] **Step 4: Register the provider**

In `lib/main.dart`:

Add to the import block (after line 15 `import 'providers/reminder_provider.dart';`):

```dart
import 'providers/goal_provider.dart';
```

In the `MultiProvider.providers` list, add after the `ReminderProvider` entry (line 53):

```dart
          ChangeNotifierProvider(create: (_) => GoalProvider()..load()),
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `flutter test test/providers/goal_provider_test.dart`
Expected: PASS (4 tests).

Run: `flutter analyze`
Expected: no new issues.

- [ ] **Step 6: Commit**

```bash
git add lib/providers/goal_provider.dart lib/main.dart test/providers/goal_provider_test.dart
git commit -m "feat: add GoalProvider (level + once-per-day celebration stamp)"
```

---

### Task 4: l10n keys for the daily goal

**Files:**
- Modify: `lib/l10n/app_en.arb` (template — add keys + `@` metadata for placeholder keys)
- Modify: `lib/l10n/app_fr.arb`, `lib/l10n/app_es.arb`, `lib/l10n/app_it.arb`
- Generated (via `flutter gen-l10n`): `lib/l10n/app_localizations*.dart`

**Interfaces:**
- Produces these `AppLocalizations` getters used by Tasks 5–8:
  - `dailyGoalSectionTitle` → "Daily goal" / "Objectif quotidien"
  - `dailyGoalLight` / `dailyGoalNormal` / `dailyGoalIntense` → "Light"/"Normal"/"Intense"
  - `dailyGoalPerDay(int count)` → "{count} reviews per day"
  - `dailyGoalTodayTitle` → "Today" / "Aujourd'hui"
  - `dailyGoalReviewsToday(int done, int target)` → "{done} / {target} reviews today"
  - `dailyGoalReached` → "Daily goal reached 🎯"

- [ ] **Step 1: Add keys to the template `lib/l10n/app_en.arb`**

Insert before the closing `}` (after the last `reminder*` key, line ~320):

```json
  ,
  "dailyGoalSectionTitle": "Daily goal",
  "dailyGoalLight": "Light",
  "dailyGoalNormal": "Normal",
  "dailyGoalIntense": "Intense",
  "dailyGoalPerDay": "{count} reviews per day",
  "@dailyGoalPerDay": {
    "placeholders": {
      "count": {
        "type": "int"
      }
    }
  },
  "dailyGoalTodayTitle": "Today",
  "dailyGoalReviewsToday": "{done} / {target} reviews today",
  "@dailyGoalReviewsToday": {
    "placeholders": {
      "done": {
        "type": "int"
      },
      "target": {
        "type": "int"
      }
    }
  },
  "dailyGoalReached": "Daily goal reached 🎯"
```

(If the file already ends the previous key without a trailing comma, add the comma shown as the first line above; otherwise drop it. Validate with `flutter gen-l10n` in Step 5.)

- [ ] **Step 2: Add the French keys to `lib/l10n/app_fr.arb`**

Insert before the closing `}` (after `reminderNotificationBody`):

```json
  ,
  "dailyGoalSectionTitle": "Objectif quotidien",
  "dailyGoalLight": "Léger",
  "dailyGoalNormal": "Normal",
  "dailyGoalIntense": "Intense",
  "dailyGoalPerDay": "{count} révisions par jour",
  "dailyGoalTodayTitle": "Aujourd'hui",
  "dailyGoalReviewsToday": "{done} / {target} révisions aujourd'hui",
  "dailyGoalReached": "Objectif du jour atteint 🎯"
```

- [ ] **Step 3: Add the Spanish keys to `lib/l10n/app_es.arb`**

Insert before the closing `}` (after `reminderNotificationBody`):

```json
  ,
  "dailyGoalSectionTitle": "Objetivo diario",
  "dailyGoalLight": "Ligero",
  "dailyGoalNormal": "Normal",
  "dailyGoalIntense": "Intenso",
  "dailyGoalPerDay": "{count} repasos por día",
  "dailyGoalTodayTitle": "Hoy",
  "dailyGoalReviewsToday": "{done} / {target} repasos hoy",
  "dailyGoalReached": "¡Objetivo diario alcanzado 🎯!"
```

- [ ] **Step 4: Add the Italian keys to `lib/l10n/app_it.arb`**

Insert before the closing `}` (after `reminderNotificationBody`):

```json
  ,
  "dailyGoalSectionTitle": "Obiettivo giornaliero",
  "dailyGoalLight": "Leggero",
  "dailyGoalNormal": "Normale",
  "dailyGoalIntense": "Intenso",
  "dailyGoalPerDay": "{count} ripassi al giorno",
  "dailyGoalTodayTitle": "Oggi",
  "dailyGoalReviewsToday": "{done} / {target} ripassi oggi",
  "dailyGoalReached": "Obiettivo del giorno raggiunto 🎯"
```

- [ ] **Step 5: Regenerate and verify**

Run: `flutter gen-l10n`
Expected: completes with no error (invalid JSON or a missing placeholder block fails here).

Run: `flutter analyze`
Expected: no new issues. (The generated getters now exist but are unused until later tasks — `flutter analyze` does not flag unused generated code.)

- [ ] **Step 6: Commit**

```bash
git add lib/l10n/
git commit -m "feat: add daily-goal l10n keys (en/fr/es/it)"
```

---

### Task 5: "Objectif quotidien" settings section

**Files:**
- Modify: `lib/screens/settings/settings_screen.dart` — add `_buildGoalSection`; call it between the Statistiques section (ends line 90) and the Données section, i.e. insert a new section + spacer right after line 92's `const SizedBox(height: 24)`. (Order: Statistiques → Objectif quotidien → Données → Tutoriels → Rappels → Aide. The spec says "before Rappels" — placing it after Statistiques satisfies that and keeps it near the other progress-related setting.)
- Add import: `import 'package:language_learning_app/providers/goal_provider.dart';` and `import 'package:language_learning_app/core/goal/daily_goal.dart';`

**Interfaces:**
- Consumes: `GoalProvider` (`level`, `setLevel`), `DailyGoalLevel`, `AppLocalizations` goal getters from Task 4, existing `SettingsSection` widget.
- Produces: nothing consumed by later tasks.

- [ ] **Step 1: Add the imports**

In `lib/screens/settings/settings_screen.dart`, next to the other provider imports (after line 13 `import '...statistics_provider.dart';`):

```dart
import 'package:language_learning_app/providers/goal_provider.dart';
import 'package:language_learning_app/core/goal/daily_goal.dart';
```

- [ ] **Step 2: Insert the section into the `ListView`**

In `build`, immediately after the Statistiques `SettingsSection` block and its trailing `const SizedBox(height: 24)` (line 92), insert:

```dart
                // --- OBJECTIF QUOTIDIEN ---
                _buildGoalSection(context, l10n),

                const SizedBox(height: 24),
```

- [ ] **Step 3: Add the `_buildGoalSection` method**

Add near `_buildReminderSection` (after line 264):

```dart
  Widget _buildGoalSection(BuildContext context, AppLocalizations l10n) {
    return Consumer<GoalProvider>(
      builder: (context, goal, _) {
        String label(DailyGoalLevel level) => switch (level) {
              DailyGoalLevel.light => l10n.dailyGoalLight,
              DailyGoalLevel.normal => l10n.dailyGoalNormal,
              DailyGoalLevel.intense => l10n.dailyGoalIntense,
            };

        return SettingsSection(
          title: l10n.dailyGoalSectionTitle,
          icon: Icons.flag_outlined,
          children: [
            for (final level in DailyGoalLevel.values)
              RadioListTile<DailyGoalLevel>(
                title: Text(
                  label(level),
                  style:
                      const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                subtitle: Text(
                  l10n.dailyGoalPerDay(goalTarget(level)),
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                value: level,
                groupValue: goal.level,
                activeColor: AppColors.primary,
                onChanged: (picked) {
                  if (picked != null) goal.setLevel(picked);
                },
              ),
          ],
        );
      },
    );
  }
```

- [ ] **Step 4: Verify**

Run: `flutter analyze`
Expected: no new issues.

Run: `flutter test`
Expected: all green (no behavior change to existing tests).

- [ ] **Step 5: Commit**

```bash
git add lib/screens/settings/settings_screen.dart
git commit -m "feat: add 'Objectif quotidien' settings section"
```

---

### Task 6: Enrich the end-of-round CompletedCard with goal progress

**Files:**
- Modify: `lib/screens/games/classic_game/widgets/completed_card.dart` — add a progress block; keep the existing icon / message / restart button and the `CompletedCard({required this.onRestart})` constructor unchanged (call site in `game_screen.dart:100` stays as-is; the card reads providers itself).

**Interfaces:**
- Consumes: `StatisticsProvider.reviewsToday()` + `getCurrentStreak()`, `GoalProvider.target`, `AppLocalizations` goal getters, `provider` package `context.watch`.
- Produces: nothing.

- [ ] **Step 1: Add imports**

At the top of `completed_card.dart`, add:

```dart
import 'package:provider/provider.dart';
import 'package:language_learning_app/providers/statistics_provider.dart';
import 'package:language_learning_app/providers/goal_provider.dart';
```

- [ ] **Step 2: Build the progress block and insert it into the Column**

Replace the `SizedBox(height: 20)` at line 42 (the gap before the restart button) with the progress block followed by the gap. Insert this between the `l10n.completedMessage` `Text` (ends line 41) and the restart `SizedBox` (line 43):

```dart
            const SizedBox(height: 20),
            _buildGoalProgress(context),
            const SizedBox(height: 20),
```

(Delete the now-duplicated `const SizedBox(height: 20)` that was already on line 42 so there is exactly one gap on each side of `_buildGoalProgress`.)

- [ ] **Step 3: Add the `_buildGoalProgress` method to `CompletedCard`**

```dart
  Widget _buildGoalProgress(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final done = context.watch<StatisticsProvider>().reviewsToday();
    final streak = context.watch<StatisticsProvider>().getCurrentStreak();
    final target = context.watch<GoalProvider>().target;
    final reached = done >= target;
    final ratio = target == 0 ? 1.0 : (done / target).clamp(0.0, 1.0);

    return Column(
      children: [
        SizedBox(
          height: 96,
          width: 96,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: ratio,
                  strokeWidth: 8,
                  backgroundColor: AppColors.success.withValues(alpha: 0.15),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.success),
                ),
              ),
              Text(
                '$done / $target',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          reached
              ? l10n.dailyGoalReached
              : l10n.dailyGoalReviewsToday(done, target),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: reached ? FontWeight.bold : FontWeight.normal,
                color: reached ? AppColors.success : null,
              ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_fire_department,
                color: Colors.orange, size: 18),
            const SizedBox(width: 4),
            Text('$streak ${l10n.days}',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ],
    );
  }
```

- [ ] **Step 4: Verify**

Run: `flutter analyze`
Expected: no new issues.

Run: `flutter test`
Expected: all green.

- [ ] **Step 5: Commit**

```bash
git add lib/screens/games/classic_game/widgets/completed_card.dart
git commit -m "feat: show daily-goal ring + streak on the completed card"
```

---

### Task 7: One-per-day "goal reached" SnackBar during play

**Files:**
- Modify: `lib/screens/games/classic_game/game_screen.dart` — `_GameScreenState` gains `initState`/`dispose`, a listener on `StatisticsProvider`, and a `_maybeCelebrateGoal` method.

**Interfaces:**
- Consumes: `GoalProvider.consumeCelebration(int)`, `StatisticsProvider.reviewsToday()` + its `notifyListeners` (fired by `addReview`), `AnalyticsService.logEvent`, `AppLocalizations.dailyGoalReached`.
- Produces: nothing.

- [ ] **Step 1: Add imports**

At the top of `game_screen.dart`:

```dart
import 'dart:async';
import 'package:language_learning_app/core/analytics/analytics_service.dart';
import 'package:language_learning_app/providers/goal_provider.dart';
import 'package:language_learning_app/providers/statistics_provider.dart';
```

(`package:provider/provider.dart` is already imported.)

- [ ] **Step 2: Add lifecycle + listener to `_GameScreenState`**

At the start of the `_GameScreenState` class body (before `build`, currently line 31):

```dart
  StatisticsProvider? _stats;

  @override
  void initState() {
    super.initState();
    _stats = context.read<StatisticsProvider>();
    _stats!.addListener(_maybeCelebrateGoal);
  }

  @override
  void dispose() {
    _stats?.removeListener(_maybeCelebrateGoal);
    super.dispose();
  }

  /// Fires once per day, the first time today's review count reaches the goal.
  void _maybeCelebrateGoal() {
    if (!mounted) return;
    final reviewsToday = context.read<StatisticsProvider>().reviewsToday();
    if (!context.read<GoalProvider>().consumeCelebration(reviewsToday)) return;

    final goal = context.read<GoalProvider>().target;
    final l10n = AppLocalizations.of(context)!;
    unawaited(
        AnalyticsService.logEvent('daily_goal_reached', {'goal': goal}));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.dailyGoalReached)),
      );
    });
  }
```

Rationale for `addPostFrameCallback`: `_maybeCelebrateGoal` runs inside `StatisticsProvider.notifyListeners()`, which can be mid-build; deferring the SnackBar to after the frame avoids "setState/markNeedsBuild called during build".

- [ ] **Step 3: Verify**

Run: `flutter analyze`
Expected: no new issues.

Run: `flutter test`
Expected: all green (`test/providers/game_provider_test.dart` drives `GameProvider` directly, not the widget, so it is unaffected).

- [ ] **Step 4: Commit**

```bash
git add lib/screens/games/classic_game/game_screen.dart
git commit -m "feat: SnackBar when the daily goal is reached mid-session"
```

---

### Task 8: "Aujourd'hui" block on the statistics screen

**Files:**
- Modify: `lib/screens/stats/statistics_screen.dart` — swap `Consumer2<StatisticsProvider, DeckProvider>` for `Consumer3<StatisticsProvider, DeckProvider, GoalProvider>`; replace `_buildStatsCards` (the streak + words-learned row, lines 151-179) so the streak card is replaced by a today/goal block above a full-width "words learned" card.
- Add imports: `import 'package:language_learning_app/providers/goal_provider.dart';`

**Interfaces:**
- Consumes: `GoalProvider.target`, `StatisticsProvider.reviewsToday()` + `getCurrentStreak()` + `getTotalWordsLearned()`, `AppLocalizations` goal getters, existing `StatsCard` + `_buildSection` helpers.
- Produces: nothing.

- [ ] **Step 1: Add the import**

After line 3 (`import '...statistics_provider.dart';`):

```dart
import 'package:language_learning_app/providers/goal_provider.dart';
```

- [ ] **Step 2: Widen the Consumer**

Line 31: change

```dart
            child: Consumer2<StatisticsProvider, DeckProvider>(
              builder: (context, statsProvider, deckProvider, _) {
```

to

```dart
            child: Consumer3<StatisticsProvider, DeckProvider, GoalProvider>(
              builder: (context, statsProvider, deckProvider, goalProvider, _) {
```

- [ ] **Step 3: Swap the top block in the `ListView`**

Line 48: replace

```dart
                    // Cartes de statistiques principales
                    _buildStatsCards(context, statsProvider, l10n),
```

with

```dart
                    _buildTodayBlock(context, statsProvider, goalProvider, l10n),

                    const SizedBox(height: 16),

                    StatsCard(
                      title: l10n.wordsLearned,
                      value: '${statsProvider.getTotalWordsLearned()}',
                      subtitle: l10n.learned,
                      icon: Icons.school,
                      color: AppColors.primary,
                    ),
```

- [ ] **Step 4: Replace `_buildStatsCards` with `_buildTodayBlock`**

Delete the whole `_buildStatsCards` method (lines 151-179) and add:

```dart
  Widget _buildTodayBlock(
    BuildContext context,
    StatisticsProvider stats,
    GoalProvider goal,
    AppLocalizations l10n,
  ) {
    final done = stats.reviewsToday();
    final target = goal.target;
    final streak = stats.getCurrentStreak();
    final ratio = target == 0 ? 1.0 : (done / target).clamp(0.0, 1.0);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            height: 72,
            width: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: ratio,
                    strokeWidth: 7,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
                Text('$done/$target',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.dailyGoalTodayTitle,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(l10n.dailyGoalReviewsToday(done, target),
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey.shade600)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.local_fire_department,
                        color: Colors.orange, size: 18),
                    const SizedBox(width: 4),
                    Text('$streak ${l10n.days}',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
```

Note: the empty-state guard (`statsProvider.history.entries.isNotEmpty`, line 37-41) is unchanged — on a brand-new install the screen still shows `_buildEmptyState`, so `_buildTodayBlock` only renders once there is at least one review. Acceptable for this iteration.

- [ ] **Step 5: Verify**

Run: `flutter analyze`
Expected: no new issues (in particular, no "unused method `_buildStatsCards`").

Run: `flutter test`
Expected: all green.

- [ ] **Step 6: Commit**

```bash
git add lib/screens/stats/statistics_screen.dart
git commit -m "feat: add 'Aujourd'hui' goal + streak block to stats screen"
```

---

### Task 9: Make the Home streak badge open the statistics screen

**Files:**
- Modify: `lib/screens/home/home_screen.dart` — wrap the badge `Container` in `_buildStreakBadge` (lines 216-238) with an `InkWell`; add the `StatisticsScreen` import.

**Interfaces:**
- Consumes: `StatisticsScreen` (existing screen, no args).
- Produces: nothing.

- [ ] **Step 1: Add the import**

After line 4 (`import '...settings_screen.dart';`):

```dart
import 'package:language_learning_app/screens/stats/statistics_screen.dart';
```

- [ ] **Step 2: Wrap the badge with a tap target**

In `_buildStreakBadge`, wrap the existing `Container(...)` (the one with `padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)`) in a `Material` + `InkWell` so it navigates on tap and shows a ripple. The `Tooltip` and outer `Padding` stay outermost. Result:

```dart
  Widget _buildStreakBadge(BuildContext context, AppLocalizations l10n) {
    final streak = context.watch<StatisticsProvider>().getCurrentStreak();

    return Tooltip(
      message: l10n.currentStreak,
      child: Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StatisticsScreen()),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_fire_department,
                      color: Colors.orange, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '$streak',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
```

- [ ] **Step 3: Verify**

Run: `flutter analyze`
Expected: no new issues.

Run: `flutter test`
Expected: all green.

- [ ] **Step 4: Commit**

```bash
git add lib/screens/home/home_screen.dart
git commit -m "feat: tap the Home streak badge to open statistics"
```

---

### Task 10: Full verification pass

**Files:** none (verification only).

- [ ] **Step 1: Analyze**

Run: `flutter analyze`
Expected: `No issues found!` (or unchanged from the pre-branch baseline — capture the baseline with `git stash` + analyze on `develop` if in doubt).

- [ ] **Step 2: Test**

Run: `flutter test`
Expected: all tests pass, including the three new files (`test/daily_goal_test.dart`, `test/providers/goal_provider_test.dart`) and the added case in `test/providers/statistics_provider_test.dart`.

- [ ] **Step 3: Confirm the l10n build is clean**

Run: `flutter gen-l10n`
Expected: no warnings about untranslated messages for the new keys in fr/es/it (all four arb files carry every new key).

- [ ] **Step 4: Report**

Summarise for the user: what shipped, the preset values, where the goal shows (settings / completed card / stats "Aujourd'hui" block / Home badge tap / mid-session SnackBar), and the two deferred items (per-session correct/wrong recap; the wider stats-page redesign of 4d).

---

## Self-Review

**1. Spec coverage** (roadmap item #7 + the 2026-09-06 grilling decisions):

| Decision | Task |
|---|---|
| Goal metric = reviews today, no new persistence | Task 2 (`reviewsToday()`) |
| Presets 10/20/40, default Normal | Task 1 (`goalTarget`), Task 3 (default) |
| Always active, no toggle | Task 3 (no enable flag), Task 5 (level-only UI) |
| Prefs via ReminderProvider pattern | Task 3 (`GoalProvider`, raw keys) |
| Settings section before Rappels | Task 5 |
| Enrich existing CompletedCard in place | Task 6 |
| Mid-session SnackBar, once/day | Task 7 + Task 3 (`consumeCelebration`) |
| Analytics `daily_goal_reached {goal}` | Task 7 |
| Stats screen: today/goal + streak block, replace streak card, keep words-learned | Task 8 |
| Home streak badge → stats screen | Task 9 |
| Ring = native `CircularProgressIndicator` | Tasks 6, 8 |
| Pure logic + unit test like `notification_schedule` | Task 1 |
| `flutter analyze` + `flutter test` bar | every task + Task 10 |
| Branch `feature/daily-goal` off `develop` | pre-work (see below) |
| Drawing mode already logs — no fix | Global Constraints (verified `drawing_widget.dart:94`) |

No gaps.

**2. Placeholder scan:** No "TBD"/"add error handling"/"similar to Task N" — every code step has literal code. The one conditional instruction (Task 4 Step 1 trailing comma) is resolved by the `flutter gen-l10n` check in the same task.

**3. Type consistency:**
- `DailyGoalLevel`, `goalTarget(DailyGoalLevel)→int`, `dailyGoalLevelFromString(String?)→DailyGoalLevel`, `dailyGoalLevelToString(DailyGoalLevel)→String`, `isoDate(DateTime)→String`, `shouldCelebrateGoal({int reviewsToday, int target, String? lastCelebratedDate, DateTime now})→bool` — defined Task 1, used identically in Tasks 3, 5.
- `GoalProvider.level→DailyGoalLevel`, `.target→int`, `.setLevel(DailyGoalLevel)→Future<void>`, `.consumeCelebration(int)→bool`, `.load()→void` — defined Task 3, used identically in Tasks 5, 6, 7, 8.
- `StatisticsProvider.reviewsToday()→int` — defined Task 2, used in Tasks 6, 7, 8.
- l10n getters `dailyGoalSectionTitle`, `dailyGoalLight/Normal/Intense`, `dailyGoalPerDay(int)`, `dailyGoalTodayTitle`, `dailyGoalReviewsToday(int,int)`, `dailyGoalReached` — defined Task 4, used in Tasks 5, 6, 8, 7. `dailyGoalReviewsToday` takes `(done, target)` in that order everywhere.

Consistent.

---

## Pre-work (before Task 1)

```bash
git checkout develop && git pull
git checkout -b feature/daily-goal
```

Confirm `git branch --show-current` prints `feature/daily-goal` before the first commit (per the project branch-workflow memory).

## Execution Handoff

Two execution options:

1. **Subagent-Driven (recommended)** — a fresh subagent per task, review between tasks, fast iteration.
2. **Inline Execution** — tasks run in this session via `superpowers:executing-plans`, batched with checkpoints.

Which approach?
