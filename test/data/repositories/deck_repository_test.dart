import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:language_learning_app/data/repositories/deck_repository.dart';
import 'package:language_learning_app/data/models/deck.dart';
import 'package:language_learning_app/data/models/word.dart';
import 'package:language_learning_app/data/models/game_mode.dart';
import 'package:language_learning_app/core/utils/storage_helper.dart';
import 'package:language_learning_app/core/constants/app_constants.dart';

Deck _buildDeck() {
  return Deck(
    id: 'deck1',
    name: 'Test Deck',
    type: DeckType.base,
    inputType: InputType.text,
    words: [Word(id: 'w1', prompt: 'un', answer: 'one')],
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageHelper.init();
  });

  group('DeckRepository - progress persistence', () {
    test('loadProgress returns null when nothing was saved', () async {
      final repo = DeckRepository();
      expect(await repo.loadProgress('deck1', 'classic'), isNull);
    });

    test('saveProgress then loadProgress round-trips the deck', () async {
      final repo = DeckRepository();
      final deck = _buildDeck()..words.first.removed = true;

      await repo.saveProgress('deck1', 'classic', deck);
      final loaded = await repo.loadProgress('deck1', 'classic');

      expect(loaded, isNotNull);
      expect(loaded!.words.first.removed, isTrue);
    });

    test('progress is scoped per game mode', () async {
      final repo = DeckRepository();
      await repo.saveProgress('deck1', 'classic', _buildDeck());

      expect(await repo.loadProgress('deck1', 'quiz'), isNull);
    });

    test('resetProgress removes only the targeted mode', () async {
      final repo = DeckRepository();
      await repo.saveProgress('deck1', 'classic', _buildDeck());
      await repo.saveProgress('deck1', 'quiz', _buildDeck());

      await repo.resetProgress('deck1', 'classic');

      expect(await repo.loadProgress('deck1', 'classic'), isNull);
      expect(await repo.loadProgress('deck1', 'quiz'), isNotNull);
    });

    test('resetAllProgressForDeck clears every known GameType, including quiz and sentence', () async {
      final repo = DeckRepository();
      for (final type in GameType.values) {
        await repo.saveProgress('deck1', type.storageId, _buildDeck());
      }

      await repo.resetAllProgressForDeck('deck1');

      for (final type in GameType.values) {
        expect(await repo.loadProgress('deck1', type.storageId), isNull);
      }
    });
  });

  group('DeckRepository - custom decks', () {
    test('loadCustomDecks returns an empty list when none saved', () async {
      final repo = DeckRepository();
      expect(await repo.loadCustomDecks(), isEmpty);
    });

    test('saveCustomDecks then loadCustomDecks round-trips', () async {
      final repo = DeckRepository();
      await repo.saveCustomDecks([_buildDeck()]);

      final loaded = await repo.loadCustomDecks();
      expect(loaded.length, 1);
      expect(loaded.first.id, 'deck1');
    });

    test('loadCustomDecks skips a malformed entry instead of discarding every custom deck', () async {
      final repo = DeckRepository();
      await StorageHelper.saveJsonList(AppConstants.keyCustomDecks, [
        _buildDeck().toJson(),
        {'not': 'a valid deck'},
      ]);

      final loaded = await repo.loadCustomDecks();

      expect(loaded.length, 1);
      expect(loaded.first.id, 'deck1');
    });
  });

  group('DeckRepository - selected deck id', () {
    test('getSelectedDeckId falls back to the default when unset', () async {
      final repo = DeckRepository();
      expect(await repo.getSelectedDeckId(), isNotEmpty);
    });

    test('saveSelectedDeckId then getSelectedDeckId round-trips', () async {
      final repo = DeckRepository();
      await repo.saveSelectedDeckId('custom-123');
      expect(await repo.getSelectedDeckId(), 'custom-123');
    });
  });
}
