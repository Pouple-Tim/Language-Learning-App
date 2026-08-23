// test/core/tutorial/tutorial_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:language_learning_app/core/tutorial/tutorial_service.dart';
import 'package:language_learning_app/core/utils/storage_helper.dart';

void main() {
  group('TutorialService', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await StorageHelper.init();
    });

    test('welcome tour is unseen by default, then seen after marking', () async {
      expect(TutorialService.hasSeenWelcome(), isFalse);

      await TutorialService.markWelcomeSeen();

      expect(TutorialService.hasSeenWelcome(), isTrue);
    });

    test('resetWelcome makes the welcome tour unseen again', () async {
      await TutorialService.markWelcomeSeen();
      await TutorialService.resetWelcome();

      expect(TutorialService.hasSeenWelcome(), isFalse);
    });

    test('decks tour flag is independent from welcome and game', () async {
      await TutorialService.markDecksSeen();

      expect(TutorialService.hasSeenDecks(), isTrue);
      expect(TutorialService.hasSeenWelcome(), isFalse);
      expect(TutorialService.hasSeenGame(), isFalse);
    });

    test('game tour is unseen by default, then seen after marking, then reset', () async {
      expect(TutorialService.hasSeenGame(), isFalse);

      await TutorialService.markGameSeen();
      expect(TutorialService.hasSeenGame(), isTrue);

      await TutorialService.resetGame();
      expect(TutorialService.hasSeenGame(), isFalse);
    });
  });
}
