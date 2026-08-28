import 'package:flutter_test/flutter_test.dart';
import 'package:language_learning_app/core/notifications/notification_schedule.dart';

void main() {
  group('buildReminderSchedule', () {
    test('morning now, not practiced: starts today at the reminder time', () {
      final now = DateTime(2026, 3, 10, 8, 0);
      final schedule = buildReminderSchedule(
        now: now,
        hour: 19,
        minute: 0,
        practicedToday: false,
      );

      expect(schedule.length, 14);
      expect(schedule.first, DateTime(2026, 3, 10, 19, 0));
      expect(schedule.last, DateTime(2026, 3, 23, 19, 0));
    });

    test('reminder time already passed today: starts tomorrow', () {
      final now = DateTime(2026, 3, 10, 20, 0);
      final schedule = buildReminderSchedule(
        now: now,
        hour: 19,
        minute: 0,
        practicedToday: false,
      );

      expect(schedule.length, 13);
      expect(schedule.first, DateTime(2026, 3, 11, 19, 0));
    });

    test('practiced today: skips today even if the time is still ahead', () {
      final now = DateTime(2026, 3, 10, 8, 0);
      final schedule = buildReminderSchedule(
        now: now,
        hour: 19,
        minute: 0,
        practicedToday: true,
      );

      expect(schedule.length, 13);
      expect(schedule.first, DateTime(2026, 3, 11, 19, 0));
    });

    test('all occurrences are consecutive days, after now, at the set time', () {
      final now = DateTime(2026, 1, 31, 7, 30);
      final schedule = buildReminderSchedule(
        now: now,
        hour: 21,
        minute: 15,
        practicedToday: false,
        windowDays: 5,
      );

      expect(schedule.length, 5);
      for (var i = 0; i < schedule.length; i++) {
        expect(schedule[i].isAfter(now), isTrue);
        expect(schedule[i].hour, 21);
        expect(schedule[i].minute, 15);
        if (i > 0) {
          expect(schedule[i].difference(schedule[i - 1]), const Duration(days: 1));
        }
      }
      // Crosses the month boundary correctly.
      expect(schedule[1], DateTime(2026, 2, 1, 21, 15));
    });
  });
}
