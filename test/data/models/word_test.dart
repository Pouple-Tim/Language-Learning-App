import 'package:flutter_test/flutter_test.dart';
import 'package:language_learning_app/data/models/word.dart';

void main() {
  group('Word Model Tests', () {
    const id = 'w1';
    const prompt = 'あ';
    const answer = 'a';

    test('Constructor initializes values correctly', () {
      final word = Word(id: id, prompt: prompt, answer: answer);
      expect(word.id, id);
      expect(word.prompt, prompt);
      expect(word.answer, answer);
      expect(word.removed, isFalse); // Default value
    });

    test('JSON Serialization (toJson / fromJson)', () {
      final word = Word(id: id, prompt: prompt, answer: answer, removed: true);
      final json = word.toJson();

      expect(json['id'], id);
      expect(json['prompt'], prompt);
      expect(json['answer'], answer);
      expect(json['removed'], true);

      final newWord = Word.fromJson(json);
      expect(newWord, equals(word));
    });

    test('fromJson throws when the required id is missing (fails loudly on malformed data)', () {
      final json = {'prompt': prompt, 'answer': answer};
      expect(() => Word.fromJson(json), throwsA(isA<TypeError>()));
    });

    test('Equality and hashCode are based on the stable id, not content', () {
      final word1 = Word(id: id, prompt: prompt, answer: answer);
      final word2 = Word(id: id, prompt: 'different prompt', answer: 'different answer');
      final word3 = Word(id: 'w2', prompt: prompt, answer: answer);

      // Same id -> equal, even if prompt/answer differ.
      expect(word1, equals(word2));
      expect(word1.hashCode, equals(word2.hashCode));

      // Different id -> not equal, even if prompt/answer match.
      expect(word1, isNot(equals(word3)));
      expect(word1.hashCode, isNot(equals(word3.hashCode)));
    });

    test('copyWith creates a new instance with updated values', () {
      final word = Word(id: id, prompt: prompt, answer: answer);

      final updatedWord = word.copyWith(removed: true);

      expect(updatedWord.id, word.id);
      expect(updatedWord.prompt, word.prompt);
      expect(updatedWord.answer, word.answer);
      expect(updatedWord.removed, isTrue);

      // Original instance stays same
      expect(word.removed, isFalse);
    });

    test('copyWith can change id', () {
      final word = Word(id: id, prompt: prompt, answer: answer);
      final updatedWord = word.copyWith(id: 'w2');
      expect(updatedWord.id, 'w2');
      expect(updatedWord, isNot(equals(word)));
    });
  });
}
