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
      expect(c.lastQuality, 5);
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

    test('stamps lastQuality with the review quality', () {
      final init = SrsCard.initial(now);
      expect(reviewCard(init, 3, now).lastQuality, 3);
      expect(reviewCard(init, 5, now).lastQuality, 5);
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
      expect(back.lastQuality, c.lastQuality);
    });
  });
}
