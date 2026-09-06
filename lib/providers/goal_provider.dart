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
