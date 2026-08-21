import 'package:language_learning_app/data/models/deck.dart';
import 'package:language_learning_app/providers/deck_provider.dart';

class DeckHierarchyUtils {
  /// Construit la map hiérarchique des decks
  static Map<String, dynamic> buildHierarchyMap(DeckProvider deckProvider) {
    final hierarchy = <String, dynamic>{};
    final repository = deckProvider.repository;
    
    for (final deck in deckProvider.baseDecks) {
      final metadata = repository.getDeckMetadata(deck.id);
      final categories = metadata?.categories ?? 
          [deck.name.split(' - ').firstOrNull ?? 'Autres'];
      
      _addToHierarchy(hierarchy, categories, deck);
    }
    
    return hierarchy;
  }

  static void _addToHierarchy(Map<String, dynamic> hierarchy, List<String> categories, Deck deck) {
    if (categories.isEmpty) {
      (hierarchy['_decks'] ??= <Deck>[]).add(deck);
      return;
    }
    
    final category = categories.first;
    hierarchy[category] ??= <String, dynamic>{};
    
    if (categories.length == 1) {
      (hierarchy[category]['_decks'] ??= <Deck>[]).add(deck);
    } else {
      _addToHierarchy(hierarchy[category], categories.sublist(1), deck);
    }
  }

  /// Compte le nombre total de decks dans un nœud et ses enfants
  static int countTotalDecks(Map<String, dynamic> node) {
    int count = (node['_decks'] as List?)?.length ?? 0;
    
    for (final key in node.keys) {
      if (key != '_decks') {
        count += countTotalDecks(node[key] as Map<String, dynamic>);
      }
    }
    
    return count;
  }
}