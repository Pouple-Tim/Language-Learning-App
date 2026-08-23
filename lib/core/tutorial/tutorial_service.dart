// lib/core/tutorial/tutorial_service.dart
import 'package:language_learning_app/core/utils/storage_helper.dart';

/// Tracks whether each in-app tutorial has already been shown.
class TutorialService {
  static const String _keyWelcome = 'tutorial_seen_welcome';
  static const String _keyDecks = 'tutorial_seen_decks';
  static const String _keyGame = 'tutorial_seen_game';

  static bool hasSeenWelcome() => StorageHelper.getBool(_keyWelcome) ?? false;
  static Future<void> markWelcomeSeen() => StorageHelper.saveBool(_keyWelcome, true);
  static Future<void> resetWelcome() => StorageHelper.saveBool(_keyWelcome, false);

  static bool hasSeenDecks() => StorageHelper.getBool(_keyDecks) ?? false;
  static Future<void> markDecksSeen() => StorageHelper.saveBool(_keyDecks, true);
  static Future<void> resetDecks() => StorageHelper.saveBool(_keyDecks, false);

  static bool hasSeenGame() => StorageHelper.getBool(_keyGame) ?? false;
  static Future<void> markGameSeen() => StorageHelper.saveBool(_keyGame, true);
  static Future<void> resetGame() => StorageHelper.saveBool(_keyGame, false);
}
