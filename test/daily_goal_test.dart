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
