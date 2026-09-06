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

    // grade() schedules off the real wall clock, so assert relative to it.
    final today = DateTime.now();
    final b = SrsProvider()..load();
    expect(b.isNew('w1'), isFalse);
    expect(b.isDue('w1', today), isFalse); // due tomorrow, not today
    expect(b.isDue('w1', today.add(const Duration(days: 1))), isTrue);
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
