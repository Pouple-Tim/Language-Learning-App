import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:language_learning_app/core/utils/storage_helper.dart';

/// Minimal, anonymous usage logging into Supabase's `app_events` table
/// (insert-only via RLS, see supabase/schema.sql).
///
/// Fire-and-forget by design: callers never await [logEvent] and a failure
/// (offline, RLS misconfigured, etc.) must never break the feature that
/// triggered it.
class AnalyticsService {
  static const _deviceIdKey = 'analytics_device_id';
  static String? _cachedDeviceId;
  static String? _cachedAppVersion;

  static Future<void> logEvent(String name, [Map<String, dynamic> props = const {}]) async {
    try {
      await Supabase.instance.client.from('app_events').insert({
        'event_name': name,
        'event_props': props,
        'anon_device_id': await _deviceId(),
        'app_version': await _appVersion(),
      });
    } catch (e) {
      debugPrint('⚠️ AnalyticsService.logEvent($name) failed: $e');
    }
  }

  static Future<String> _deviceId() async {
    if (_cachedDeviceId case final id?) return id;

    var id = StorageHelper.getString(_deviceIdKey);
    if (id == null) {
      id = const Uuid().v4();
      await StorageHelper.saveString(_deviceIdKey, id);
    }
    return _cachedDeviceId = id;
  }

  static Future<String> _appVersion() async {
    if (_cachedAppVersion case final version?) return version;

    final info = await PackageInfo.fromPlatform();
    return _cachedAppVersion = '${info.version}+${info.buildNumber}';
  }
}
