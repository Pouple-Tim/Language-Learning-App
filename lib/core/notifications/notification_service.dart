import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'notification_schedule.dart';

/// Owns the local daily practice reminder. No backend.
///
/// Local notifications run no app code when they fire, so "skip days I've
/// already practiced" can't be decided at fire time. Instead the app re-arms a
/// rolling window of one-shot notifications every time it opens (see
/// [reschedule] and [buildReminderSchedule]). If the app isn't opened for
/// [_windowDays] days straight the reminders go quiet — by then the user has
/// churned and one more notification wouldn't bring them back.
class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const int _windowDays = 14;
  static const int _idBase = 5000; // reminder ids: _idBase .. _idBase+_windowDays-1

  static const NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'daily_reminder',
      'Rappel quotidien',
      channelDescription: 'Rappel pour faire ta session de révision du jour',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    ),
    iOS: DarwinNotificationDetails(),
  );

  static bool _initialised = false;

  /// Idempotent. Safe to call on every app start.
  static Future<void> init() async {
    if (_initialised) return;
    try {
      tz_data.initializeTimeZones();
      final localZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localZone.identifier));

      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
      _initialised = true;
    } catch (e) {
      debugPrint('⚠️ NotificationService.init failed: $e');
    }
  }

  /// Asks the OS for notification permission. Call this when the user turns the
  /// reminder on, not at startup. Returns whether it's granted.
  static Future<bool> requestPermission() async {
    await init();
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        return await android.requestNotificationsPermission() ?? false;
      }
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        return await ios.requestPermissions(alert: true, badge: true, sound: true) ??
            false;
      }
      return true; // desktop / other: no runtime gate
    } catch (e) {
      debugPrint('⚠️ NotificationService.requestPermission failed: $e');
      return false;
    }
  }

  /// Cancels the pending reminder window and, if [enabled], re-arms it from
  /// today. Call on app start, on app resume, and whenever the toggle or time
  /// changes.
  static Future<void> reschedule({
    required bool enabled,
    required int hour,
    required int minute,
    required bool practicedToday,
    required String title,
    required String body,
  }) async {
    await init();
    try {
      for (var id = _idBase; id < _idBase + _windowDays; id++) {
        await _plugin.cancel(id: id);
      }
      if (!enabled) return;

      final occurrences = buildReminderSchedule(
        now: DateTime.now(),
        hour: hour,
        minute: minute,
        practicedToday: practicedToday,
        windowDays: _windowDays,
      );
      for (var i = 0; i < occurrences.length; i++) {
        await _plugin.zonedSchedule(
          id: _idBase + i,
          title: title,
          body: body,
          scheduledDate: tz.TZDateTime.from(occurrences[i], tz.local),
          notificationDetails: _details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    } catch (e) {
      debugPrint('⚠️ NotificationService.reschedule failed: $e');
    }
  }
}
