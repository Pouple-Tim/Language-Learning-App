import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:language_learning_app/providers/deck_provider.dart';
import 'package:language_learning_app/data/repositories/deck_repository.dart';
import 'package:language_learning_app/data/models/deck.dart';
import 'package:language_learning_app/data/models/word.dart';
import 'package:language_learning_app/core/utils/storage_helper.dart';

Deck metadataOnlyDeck() => Deck(
      id: 'deck1',
      name: 'Test Deck',
      type: DeckType.base,
      inputType: InputType.text,
      words: [],
    );

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageHelper.init();
  });

  group('DeckProvider.selectDeck', () {
    test('downloads content for a base deck with no content yet, then selects it', () async {
      final repo = DeckRepository(
        fetchDeckContent: (id) async => {
          'words': [
            {'id': 'w1', 'prompt': 'un', 'answer': 'one'},
          ],
          'sentences': [],
        },
      );
      final provider = DeckProvider(repository: repo);

      await provider.selectDeck(metadataOnlyDeck());

      expect(provider.selectedDeck?.words.length, 1);
      expect(provider.isDownloadingDeck('deck1'), isFalse);
      expect(provider.downloadError, isNull);
    });

    test('sets isDownloadingDeck while the fetch is in flight, clears it after', () async {
      final completer = Completer<Map<String, dynamic>?>();
      final repo = DeckRepository(fetchDeckContent: (id) => completer.future);
      final provider = DeckProvider(repository: repo);

      final future = provider.selectDeck(metadataOnlyDeck());
      expect(provider.isDownloadingDeck('deck1'), isTrue);

      completer.complete({'words': [], 'sentences': []});
      await future;

      expect(provider.isDownloadingDeck('deck1'), isFalse);
    });

    test('surfaces an error and leaves selectedDeck unset when the download fails', () async {
      final repo = DeckRepository(fetchDeckContent: (id) async => null);
      final provider = DeckProvider(repository: repo);

      await provider.selectDeck(metadataOnlyDeck());

      expect(provider.selectedDeck, isNull);
      expect(provider.downloadError, isNotNull);
      expect(provider.isDownloadingDeck('deck1'), isFalse);
    });

    test('selects a custom deck synchronously without attempting a download', () async {
      final repo = DeckRepository(
        fetchDeckContent: (id) async => throw Exception('should not be called for a custom deck'),
      );
      final provider = DeckProvider(repository: repo);
      final customDeck = Deck(
        id: 'custom1',
        name: 'Custom',
        type: DeckType.custom,
        inputType: InputType.text,
        words: [Word(id: 'w1', prompt: 'a', answer: 'b')],
      );

      await provider.selectDeck(customDeck);

      expect(provider.selectedDeck?.id, 'custom1');
    });

    test('selects a base deck with content already loaded synchronously, no download', () async {
      final repo = DeckRepository(
        fetchDeckContent: (id) async => throw Exception('should not be called, already has content'),
      );
      final provider = DeckProvider(repository: repo);
      final alreadyLoaded = Deck(
        id: 'deck1',
        name: 'Test Deck',
        type: DeckType.base,
        inputType: InputType.text,
        words: [Word(id: 'w1', prompt: 'un', answer: 'one')],
      );

      await provider.selectDeck(alreadyLoaded);

      expect(provider.selectedDeck?.id, 'deck1');
    });
  });
}
