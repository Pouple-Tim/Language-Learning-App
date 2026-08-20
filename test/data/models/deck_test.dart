import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:language_learning_app/data/models/deck.dart';
import 'package:language_learning_app/data/models/word.dart';

void main() {
  group('Deck Model Logic Tests', () {
    late Deck deck;

    setUp(() {
      // On initialise un deck avant chaque test
      deck = Deck(
        id: 'test_deck',
        name: 'Test Deck',
        type: DeckType.base,
        inputType: InputType.text,
        words: [
          Word(id: 'w1', prompt: '1', answer: 'one', removed: false),
          Word(id: 'w2', prompt: '2', answer: 'two', removed: true), // Déjà fait
          Word(id: 'w3', prompt: '3', answer: 'three', removed: false),
          Word(id: 'w4', prompt: '4', answer: 'four', removed: true), // Déjà fait
        ],
      );
    });

    test('Counters logic (total, active, remaining)', () {
      expect(deck.totalWords, 4);
      expect(deck.activeWords.length, 2); // Mots 1 et 3
      expect(deck.remainingWords, 2);
    });

    test('Progress calculation', () {
      // 4 mots au total, 2 restants => 50% complété
      expect(deck.progress, 50.0);

      // Cas vide
      final emptyDeck = deck.copyWith(words: []);
      expect(emptyDeck.progress, 0.0);
    });

    test('isCompleted getter', () {
      expect(deck.isCompleted, isFalse);


      for (var w in deck.words) {w.removed = true;}
      
      expect(deck.isCompleted, isTrue);
      expect(deck.progress, 100.0);
    });

    test('resetWords resets all removed flags', () {
      expect(deck.remainingWords, 2);
      
      deck.resetWords();
      
      expect(deck.remainingWords, 4);
      expect(deck.words.every((w) => !w.removed), isTrue);
      expect(deck.progress, 0.0);
    });

    test('Enum Serialization (DeckType and InputType)', () {
      final jsonMap = jsonDecode(jsonEncode(deck.toJson()));
      
      // Vérifie que les enums sont convertis en string via @JsonValue
      expect(jsonMap['type'], 'base');
      expect(jsonMap['inputType'], 'text');

      final fromJson = Deck.fromJson(jsonMap);
      expect(fromJson.type, DeckType.base);
    });
    
    test('Unknown Enum Value Fallback', () {
        // Teste la robustesse si le JSON contient une valeur inconnue
        // (nécessite que unknownEnumValue soit configuré correctement dans la génération)
        final jsonMap = {
            'id': '1',
            'name': 'Test',
            'type': 'unknown_type', // Should fall back to base
            'inputType': 'unknown_input', // Should fall back to text
            'words': []
        };
        
        final deckFallback = Deck.fromJson(jsonMap);
        expect(deckFallback.type, DeckType.base);
        expect(deckFallback.inputType, InputType.text);
    });

    test('copyWith works for partial updates', () {
      final newDeck = deck.copyWith(name: 'New Name');
      expect(newDeck.name, 'New Name');
      expect(newDeck.id, deck.id);
      expect(newDeck.words.length, deck.words.length);
    });
  });
}