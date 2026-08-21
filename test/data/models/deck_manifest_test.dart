import 'package:flutter_test/flutter_test.dart';
import 'package:language_learning_app/data/models/deck_manifest.dart';
import 'package:language_learning_app/data/models/deck.dart';

void main() {
  group('DeckEntry Model Tests', () {
    test('Category logic works correctly', () {
      final entry1 = DeckEntry(
        path: 'p1',
        categories: ['Hiragana'],
        id: 'd1',
        name: 'D1',
        inputType: InputType.text,
        wordCount: 5,
        hasSentences: false,
      );
      expect(entry1.category, 'Hiragana');
      expect(entry1.subcategory, 'Hiragana');

      final entry2 = DeckEntry(
        path: 'p2',
        categories: ['Japonais', 'Grammaire', 'N5'],
        id: 'd2',
        name: 'D2',
        inputType: InputType.text,
        wordCount: 5,
        hasSentences: false,
      );
      expect(entry2.category, 'Japonais');
      expect(entry2.subcategory, 'Grammaire > N5');

      final entry3 = DeckEntry(
        path: 'p3',
        categories: [],
        id: 'd3',
        name: 'D3',
        inputType: InputType.text,
        wordCount: 5,
        hasSentences: false,
      );
      expect(entry3.category, 'Autres');
      expect(entry3.subcategory, 'Autres');
    });

    test('Default values work in Constructor and JSON', () {
      final entry = DeckEntry(
        path: 'path',
        categories: ['Test'],
        id: 'd1',
        name: 'D1',
        inputType: InputType.text,
        wordCount: 5,
        hasSentences: false,
      );
      expect(entry.difficulty, 'beginner');

      final jsonMap = {
        'path': 'path',
        'categories': ['Test'],
        'id': 'd1',
        'name': 'D1',
        'inputType': 'text',
        'wordCount': 5,
        'hasSentences': false,
        // 'difficulty' is missing
      };
      final fromJson = DeckEntry.fromJson(jsonMap);
      expect(fromJson.difficulty, 'beginner');
    });

    test('Full JSON Serialization', () {
      final entry = DeckEntry(
        path: 'assets/deck.json',
        categories: ['A', 'B'],
        difficulty: 'hard',
        id: 'd1',
        name: 'D1',
        inputType: InputType.draw,
        reverseInputType: InputType.text,
        wordCount: 12,
        hasSentences: true,
      );

      final json = entry.toJson();
      expect(json['difficulty'], 'hard');
      expect(json['categories'], ['A', 'B']);
      expect(json['wordCount'], 12);
      expect(json['hasSentences'], true);

      final reconstructed = DeckEntry.fromJson(json);
      expect(reconstructed.path, entry.path);
      expect(reconstructed.wordCount, 12);
      expect(reconstructed.hasSentences, isTrue);
    });
  });

  group('DeckManifest Model Tests', () {
    test('Parses nested DeckEntry list correctly', () {
      final json = {
        'version': '1.0',
        'lastUpdate': '2023-01-01',
        'decks': [
          {
            'path': 'd1',
            'categories': ['C1'],
            'id': 'd1',
            'name': 'D1',
            'inputType': 'text',
            'wordCount': 3,
            'hasSentences': false,
          },
          {
            'path': 'd2',
            'categories': ['C2'],
            'difficulty': 'expert',
            'id': 'd2',
            'name': 'D2',
            'inputType': 'draw',
            'wordCount': 8,
            'hasSentences': true,
          },
        ],
      };

      final manifest = DeckManifest.fromJson(json);

      expect(manifest.version, '1.0');
      expect(manifest.decks.length, 2);
      expect(manifest.decks[0].category, 'C1');
      expect(manifest.decks[1].difficulty, 'expert');
      expect(manifest.decks[1].wordCount, 8);
      expect(manifest.decks[1].hasSentences, isTrue);
    });
  });
}
