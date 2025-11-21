import 'package:flutter_test/flutter_test.dart';
import 'package:language_learning_app/data/models/word.dart'; 

void main() {
  group('Word Model Tests', () {
    const prompt = 'あ';
    const answer = 'a';

    test('Constructor initializes values correctly', () {
      final word = Word(prompt: prompt, answer: answer);
      expect(word.prompt, prompt);
      expect(word.answer, answer);
      expect(word.removed, isFalse); // Default value
    });

    test('JSON Serialization (toJson / fromJson)', () {
      final word = Word(prompt: prompt, answer: answer, removed: true);
      final json = word.toJson();

      expect(json['prompt'], prompt);
      expect(json['answer'], answer);
      expect(json['removed'], true);

      final newWord = Word.fromJson(json);
      expect(newWord, equals(word));
    });

    test('Equality and Hashcode', () {
      final word1 = Word(prompt: prompt, answer: answer);
      final word2 = Word(prompt: prompt, answer: answer);
      final word3 = Word(prompt: 'い', answer: 'i');

      // Test equality operator override
      expect(word1, equals(word2));
      expect(word1, isNot(equals(word3)));

      // Test hashcode
      expect(word1.hashCode, equals(word2.hashCode));
      expect(word1.hashCode, isNot(equals(word3.hashCode)));
    });

    test('copyWith creates a new instance with updated values', () {
      final word = Word(prompt: prompt, answer: answer);
      
      final updatedWord = word.copyWith(removed: true);
      
      expect(updatedWord.prompt, word.prompt); // Unchanged
      expect(updatedWord.answer, word.answer); // Unchanged
      expect(updatedWord.removed, isTrue);     // Changed
      
      // Original instance stays same
      expect(word.removed, isFalse);
    });
  });
}