// lib/core/tutorial/tutorial_service.dart
import 'package:language_learning_app/core/utils/storage_helper.dart';

/// Tracks whether the onboarding intro has already been shown once.
class TutorialService {
  static const String _keySeen = 'tutorial_seen_onboarding';

  static bool hasSeenOnboarding() => StorageHelper.getBool(_keySeen) ?? false;
  static Future<void> markOnboardingSeen() => StorageHelper.saveBool(_keySeen, true);
}
