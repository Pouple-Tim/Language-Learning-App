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
  final int lastQuality; // quality of the most recent review; 5 for a new card

  const SrsCard({
    required this.reps,
    required this.ef,
    required this.intervalDays,
    required this.due,
    required this.lastQuality,
  });

  factory SrsCard.initial(DateTime now) => SrsCard(
      reps: 0, ef: 2.5, intervalDays: 0, due: dateOnly(now), lastQuality: 5);

  Map<String, dynamic> toJson() => {
        'reps': reps,
        'ef': ef,
        'interval': intervalDays,
        'due': dateOnly(due).toIso8601String(),
        'lastQuality': lastQuality,
      };

  factory SrsCard.fromJson(Map<String, dynamic> j) => SrsCard(
        reps: (j['reps'] as num).toInt(),
        ef: (j['ef'] as num).toDouble(),
        intervalDays: (j['interval'] as num).toInt(),
        due: dateOnly(DateTime.parse(j['due'] as String)),
        lastQuality: (j['lastQuality'] as num?)?.toInt() ?? 5,
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
    due: dateOnly(today.add(Duration(days: interval))),
    lastQuality: quality,
  );
}

/// Which items a session pulls from. Chosen on the pre-session screen.
enum SessionFilter { all, due, fresh, hard }
