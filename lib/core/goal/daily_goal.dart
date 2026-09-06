/// Pure daily-goal logic — no Flutter, no storage. Unit-tested in
/// test/daily_goal_test.dart. Mirrors lib/core/notifications/notification_schedule.dart.
library;

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
