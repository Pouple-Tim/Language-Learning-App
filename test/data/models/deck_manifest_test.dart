import 'package:flutter_test/flutter_test.dart';
import 'package:language_learning_app/data/models/deck_manifest.dart';

void main() {
  group('DeckEntry Model Tests', () {
    test('Category logic works correctly', () {
      // Cas 1: Une seule catégorie
      final entry1 = DeckEntry(path: 'p1', categories: ['Hiragana']);
      expect(entry1.category, 'Hiragana');
      expect(entry1.subcategory, 'Hiragana'); // Fallback si pas de sous-catégorie

      // Cas 2: Catégorie hiérarchique
      final entry2 = DeckEntry(path: 'p2', categories: ['Japonais', 'Grammaire', 'N5']);
      expect(entry2.category, 'Japonais');
      expect(entry2.subcategory, 'Grammaire > N5');

      // Cas 3: Liste vide (Edge case)
      final entry3 = DeckEntry(path: 'p3', categories: []);
      expect(entry3.category, 'Autres');
      expect(entry3.subcategory, 'Autres');
    });

    test('Default values work in Constructor and JSON', () {
      // Constructor default
      final entry = DeckEntry(path: 'path', categories: ['Test']);
      expect(entry.difficulty, 'beginner');

      // JSON defaultValue check
      final jsonMap = {
        'path': 'path',
        'categories': ['Test'],
        // 'difficulty' is missing
      };
      final fromJson = DeckEntry.fromJson(jsonMap);
      expect(fromJson.difficulty, 'beginner');
    });

    test('Full JSON Serialization', () {
      final entry = DeckEntry(
        path: 'assets/deck.json', 
        categories: ['A', 'B'], 
        difficulty: 'hard'
      );
      
      final json = entry.toJson();
      expect(json['difficulty'], 'hard');
      expect(json['categories'], ['A', 'B']);
      
      final reconstructed = DeckEntry.fromJson(json);
      expect(reconstructed.path, entry.path);
    });
  });

  group('DeckManifest Model Tests', () {
    test('Parses nested DeckEntry list correctly', () {
      final json = {
        'version': '1.0',
        'lastUpdate': '2023-01-01',
        'decks': [
          {'path': 'd1', 'categories': ['C1']},
          {'path': 'd2', 'categories': ['C2'], 'difficulty': 'expert'}
        ]
      };

      final manifest = DeckManifest.fromJson(json);

      expect(manifest.version, '1.0');
      expect(manifest.decks.length, 2);
      expect(manifest.decks[0].category, 'C1');
      expect(manifest.decks[1].difficulty, 'expert');
    });
  });
}