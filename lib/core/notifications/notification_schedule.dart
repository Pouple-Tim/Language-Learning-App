/// Pure scheduling logic for the daily practice reminder.
///
/// Local notifications run no app code when they fire, so "skip days I've
/// already practiced" can't be a decision made at fire time. Instead the app
/// re-arms a rolling window of one-shot notifications every time it opens
/// (see [NotificationService.reschedule]). This function computes that window.
///
/// Returns the datetimes to schedule, one per day starting today, at
/// [hour]:[minute]. Today is skipped when the time has already passed or when
/// [practicedToday] is true.
List<DateTime> buildReminderSchedule({
  required DateTime now,
  required int hour,
  required int minute,
  required bool practicedToday,
  int windowDays = 14,
}) {
  final result = <DateTime>[];
  for (var i = 0; i < windowDays; i++) {
    final day = DateTime(now.year, now.month, now.day + i, hour, minute);
    if (!day.isAfter(now)) continue;
    if (i == 0 && practicedToday) continue;
    result.add(day);
  }
  return result;
}
