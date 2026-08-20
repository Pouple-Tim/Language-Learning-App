import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:language_learning_app/data/models/deck.dart';
import 'package:language_learning_app/data/models/word.dart';
import 'package:language_learning_app/data/models/sentence.dart';
import 'package:language_learning_app/data/repositories/deck_repository.dart';
import 'package:language_learning_app/providers/game_provider.dart';
import 'package:language_learning_app/core/utils/storage_helper.dart';

Deck _buildDeck({int wordCount = 3, List<Sentence> sentences = const []}) {
  final words = List.generate(
    wordCount,
    (i) => Word(id: 'w$i', prompt: 'prompt$i', answer: 'answer$i', removed: false),
  );
  return Deck(
    id: 'deck1',
    name: 'Test Deck',
    type: DeckType.base,
    inputType: InputType.text,
    reverseInputType: InputType.text,
    words: words,
    sentences: sentences,
  );
}

Deck _oneWordDeck() {
  return Deck(
    id: 'deck1',
    name: 'Test Deck',
    type: DeckType.base,
    inputType: InputType.text,
    words: [Word(id: 'w0', prompt: 'un', answer: 'one', removed: false)],
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageHelper.init();
  });

  group('GameProvider.setDeck', () {
    test('initializes a fresh game with no saved progress', () async {
      final provider = GameProvider();
      await provider.setDeck(_buildDeck(), gameMode: 'classic');

      expect(provider.currentDeck, isNotNull);
      expect(provider.totalWords, 3);
      expect(provider.remainingWords, 3);
      expect(provider.currentGameMode, 'classic');
      expect(provider.isReverseMode, isFalse);
    });

    test('isReverseMode is true only for the reverse mode string', () async {
      final provider = GameProvider();
      await provider.setDeck(_buildDeck(), gameMode: 'reverse');
      expect(provider.isReverseMode, isTrue);

      final classicProvider = GameProvider();
      await classicProvider.setDeck(_buildDeck(), gameMode: 'classic');
      expect(classicProvider.isReverseMode, isFalse);
    });

    test('restores removed words from saved progress by matching prompt text', () async {
      final repo = DeckRepository();
      final saved = _buildDeck()..words.first.removed = true;
      await repo.saveProgress('deck1', 'classic', saved);

      final provider = GameProvider();
      await provider.setDeck(_buildDeck(), gameMode: 'classic');

      expect(provider.currentDeck!.words.first.removed, isTrue);
      expect(provider.remainingWords, 2);
    });

    test('a saved word with no matching prompt in the fresh deck is silently skipped, not restored', () async {
      final repo = DeckRepository();
      final saved = _buildDeck()..words.first.removed = true;
      final renamedFreshDeck = _buildDeck();
      renamedFreshDeck.words[0] = Word(id: 'w0', prompt: 'renamed', answer: 'answer0', removed: false);

      await repo.saveProgress('deck1', 'classic', saved);

      final provider = GameProvider();
      await provider.setDeck(renamedFreshDeck, gameMode: 'classic');

      // Old behavior: content-based match fails silently (id matches, but the
      // current logic still matches on prompt, which no longer matches), nothing restored.
      expect(provider.remainingWords, 3);
    });
  });

  group('GameProvider.checkAnswer', () {
    test('correct answer (classic mode) marks the word removed', () async {
      final provider = GameProvider();
      await provider.setDeck(_oneWordDeck(), gameMode: 'classic');
      await provider.spinWheel();

      final result = await provider.checkAnswer('one');

      expect(result, isTrue);
      expect(provider.currentDeck!.words.first.removed, isTrue);
    });

    test('incorrect answer (classic mode) leaves the word not removed', () async {
      final provider = GameProvider();
      await provider.setDeck(_oneWordDeck(), gameMode: 'classic');
      await provider.spinWheel();

      final result = await provider.checkAnswer('wrong');

      expect(result, isFalse);
      expect(provider.currentDeck!.words.first.removed, isFalse);
    });

    test('reverse mode checks the answer against prompt, not answer', () async {
      final provider = GameProvider();
      await provider.setDeck(_oneWordDeck(), gameMode: 'reverse');
      await provider.spinWheel();

      final result = await provider.checkAnswer('un');

      expect(result, isTrue);
    });
  });

  group('GameProvider - sentence mode', () {
    Sentence buildSentence() => Sentence(
          id: 's1',
          original: 'Bonjour',
          translation: 'nihao',
          blocks: ['ni', 'hao', 'bu'],
        );

    test('spinWheel loads a sentence and shuffles blocks into availableBlocks', () async {
      final provider = GameProvider();
      await provider.setDeck(_buildDeck(sentences: [buildSentence()]), gameMode: 'sentence');
      await provider.spinWheel();

      expect(provider.currentSentence, isNotNull);
      expect(provider.availableBlocks.toSet(), {'ni', 'hao', 'bu'});
      expect(provider.selectedBlocks, isEmpty);
    });

    test('addBlockToSentence / removeBlockFromSentence move blocks between lists', () async {
      final provider = GameProvider();
      await provider.setDeck(_buildDeck(sentences: [buildSentence()]), gameMode: 'sentence');
      await provider.spinWheel();

      provider.addBlockToSentence('ni');
      expect(provider.selectedBlocks, ['ni']);
      expect(provider.availableBlocks.contains('ni'), isFalse);

      provider.removeBlockFromSentence('ni');
      expect(provider.selectedBlocks, isEmpty);
      expect(provider.availableBlocks.contains('ni'), isTrue);
    });

    test('checkSentenceConstruction: correct order marks the sentence completed', () async {
      final provider = GameProvider();
      await provider.setDeck(_buildDeck(sentences: [buildSentence()]), gameMode: 'sentence');
      await provider.spinWheel();

      provider.addBlockToSentence('ni');
      provider.addBlockToSentence('hao');

      final result = await provider.checkSentenceConstruction();

      expect(result, isTrue);
      expect(provider.currentDeck!.sentences.first.completed, isTrue);
    });

    test('checkSentenceConstruction: wrong order does not complete the sentence', () async {
      final provider = GameProvider();
      await provider.setDeck(_buildDeck(sentences: [buildSentence()]), gameMode: 'sentence');
      await provider.spinWheel();

      provider.addBlockToSentence('hao');
      provider.addBlockToSentence('ni');

      final result = await provider.checkSentenceConstruction();

      expect(result, isFalse);
      expect(provider.currentDeck!.sentences.first.completed, isFalse);
    });
  });

  group('GameProvider - quiz mode', () {
    test('spinWheel in quiz mode populates 4 quiz options including the correct answer', () async {
      final provider = GameProvider();
      await provider.setDeck(_buildDeck(wordCount: 5), gameMode: 'quiz');
      await provider.spinWheel();

      expect(provider.quizOptions.length, 4);
      expect(provider.quizOptions.contains(provider.currentWord!.answer), isTrue);
    });
  });

  group('GameProvider.resetDeck', () {
    test('resets all removed words and completed sentences', () async {
      final provider = GameProvider();
      final deck = _buildDeck(sentences: [
        Sentence(id: 's1', original: 'o', translation: 't', blocks: ['t']),
      ]);
      await provider.setDeck(deck, gameMode: 'classic');
      provider.currentDeck!.words.first.removed = true;
      provider.currentDeck!.sentences.first.completed = true;

      await provider.resetDeck();

      expect(provider.currentDeck!.words.every((w) => !w.removed), isTrue);
      expect(provider.currentDeck!.sentences.every((s) => !s.completed), isTrue);
    });
  });
}
