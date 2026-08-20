import 'package:flutter_test/flutter_test.dart';
import 'package:language_learning_app/data/models/sentence.dart';

void main() {
  group('Sentence Model Tests', () {
    test('Constructor initializes values correctly', () {
      final sentence = Sentence(
        id: 's1',
        original: 'Bonjour',
        translation: '你好',
        blocks: ['你', '好', '您'],
      );
      expect(sentence.id, 's1');
      expect(sentence.original, 'Bonjour');
      expect(sentence.translation, '你好');
      expect(sentence.blocks, ['你', '好', '您']);
      expect(sentence.completed, isFalse);
    });

    test('JSON Serialization (toJson / fromJson)', () {
      final sentence = Sentence(
        id: 's1',
        original: 'Bonjour',
        translation: '你好',
        blocks: ['你', '好'],
        completed: true,
      );
      final json = sentence.toJson();

      expect(json['id'], 's1');
      expect(json['original'], 'Bonjour');
      expect(json['translation'], '你好');
      expect(json['blocks'], ['你', '好']);
      expect(json['completed'], true);

      final fromJson = Sentence.fromJson(json);
      expect(fromJson.id, sentence.id);
      expect(fromJson.original, sentence.original);
      expect(fromJson.translation, sentence.translation);
      expect(fromJson.blocks, sentence.blocks);
      expect(fromJson.completed, sentence.completed);
    });

    test('completed defaults to false when absent from JSON', () {
      final json = {
        'id': 's1',
        'original': 'Bonjour',
        'translation': '你好',
        'blocks': ['你', '好'],
      };
      final sentence = Sentence.fromJson(json);
      expect(sentence.completed, isFalse);
    });

    test('fromJson throws on a missing required field (fails loudly on malformed data)', () {
      final json = {
        'id': 's1',
        'original': 'Bonjour',
        // 'translation' missing
        'blocks': ['你', '好'],
      };
      expect(() => Sentence.fromJson(json), throwsA(isA<TypeError>()));
    });
  });
}
