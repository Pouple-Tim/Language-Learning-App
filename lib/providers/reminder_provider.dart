import 'package:flutter/material.dart';
import 'package:language_learning_app/core/notifications/notification_service.dart';
import 'package:language_learning_app/core/utils/storage_helper.dart';

/// Daily practice-reminder settings (on/off + time of day), persisted locally.
///
/// The localized notification text and "practiced today?" flag live outside the
/// provider — callers pass them in, since a provider has no [BuildContext].
class ReminderProvider extends ChangeNotifier {
  static const _kEnabled = 'reminder_enabled';
  static const _kTime = 'reminder_time'; // "H:M"

  bool _enabled = false;
  int _hour = 19;
  int _minute = 0;

  bool get enabled => _enabled;
  TimeOfDay get time => TimeOfDay(hour: _hour, minute: _minute);

  void load() {
    _enabled = StorageHelper.getBool(_kEnabled) ?? false;
    final raw = StorageHelper.getString(_kTime)?.split(':');
    if (raw != null && raw.length == 2) {
      _hour = int.tryParse(raw[0]) ?? _hour;
      _minute = int.tryParse(raw[1]) ?? _minute;
    }
    notifyListeners();
  }

  /// Turns the reminder on/off. When turning on, asks the OS for permission and
  /// returns `false` (leaving it off) if that's denied.
  Future<bool> setEnabled(
    bool value, {
    required bool practicedToday,
    required String title,
    required String body,
  }) async {
    if (value && !await NotificationService.requestPermission()) return false;

    _enabled = value;
    await StorageHelper.saveBool(_kEnabled, value);
    notifyListeners();
    await _reschedule(practicedToday: practicedToday, title: title, body: body);
    return true;
  }

  Future<void> setTime(
    TimeOfDay value, {
    required bool practicedToday,
    required String title,
    required String body,
  }) async {
    _hour = value.hour;
    _minute = value.minute;
    await StorageHelper.saveString(_kTime, '${value.hour}:${value.minute}');
    notifyListeners();
    await _reschedule(practicedToday: practicedToday, title: title, body: body);
  }

  /// Re-arms the rolling notification window. Call on app start and on resume.
  Future<void> refresh({
    required bool practicedToday,
    required String title,
    required String body,
  }) async {
    if (!_enabled) return;
    await _reschedule(practicedToday: practicedToday, title: title, body: body);
  }

  Future<void> _reschedule({
    required bool practicedToday,
    required String title,
    required String body,
  }) {
    return NotificationService.reschedule(
      enabled: _enabled,
      hour: _hour,
      minute: _minute,
      practicedToday: practicedToday,
      title: title,
      body: body,
    );
  }
}
