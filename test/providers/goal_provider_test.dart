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
