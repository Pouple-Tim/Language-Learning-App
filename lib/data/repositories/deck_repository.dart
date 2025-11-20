import 'dart:convert';
import 'package:flutter/foundation.dart'; // Necessary for debugPrint
import 'package:flutter/services.dart';
import '../models/deck.dart';
import '../models/deck_manifest.dart';
import '../../core/utils/storage_helper.dart';
import '../../core/constants/app_constants.dart';

class DeckRepository {
  List<Deck>? _cachedBaseDecks;
  DeckManifest? _manifest;
  Map<String, List<Deck>>? _decksByCategory;
  Map<String, DeckEntry>? _deckMetadata; // Nouveau: métadonnées par deck ID

  // Charger les decks de base depuis les assets
  Future<List<Deck>> loadBaseDecks() async {
    if (_cachedBaseDecks != null) {
      return _cachedBaseDecks!;
    }

    try {
      final decks = <Deck>[];

      // Charger le manifest
      final manifestJson = await rootBundle.loadString('assets/decks/manifest.json');
      final manifestData = jsonDecode(manifestJson) as Map<String, dynamic>;
      _manifest = DeckManifest.fromJson(manifestData);

      debugPrint('📋 Manifest chargé: v${_manifest!.version} (${_manifest!.lastUpdate})');
      debugPrint('📚 ${_manifest!.decks.length} decks à charger...');

      // Charger chaque deck listé dans le manifest
      for (final entry in _manifest!.decks) {
        try {
          final jsonString = await rootBundle.loadString(entry.path);
          final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
          final deck = Deck.fromJson(jsonData);
          decks.add(deck);
          
          debugPrint('✅ ${deck.name} (${entry.difficulty})');
        } catch (e) {
          debugPrint('❌ Erreur: ${entry.path} - $e');
        }
      }

      _cachedBaseDecks = decks;
      _organizeDecksByCategory(decks);
      _buildMetadataMap(decks);

      debugPrint('🎉 ${decks.length} decks chargés avec succès !');
      return decks;
    } catch (e) {
      debugPrint('💥 Erreur lors du chargement des decks de base: $e');
      return [];
    }
  }

  // Organiser les decks par catégorie
  void _organizeDecksByCategory(List<Deck> decks) {
    _decksByCategory = {};

    for (int i = 0; i < decks.length && i < _manifest!.decks.length; i++) {
      final deck = decks[i];
      final entry = _manifest!.decks[i];
      
      // Utiliser la catégorie du manifest
      final category = entry.category;

      if (!_decksByCategory!.containsKey(category)) {
        _decksByCategory![category] = [];
      }
      _decksByCategory![category]!.add(deck);
    }
  }

  // Construire une map des métadonnées par deck ID
  void _buildMetadataMap(List<Deck> decks) {
    _deckMetadata = {};
    
    for (int i = 0; i < decks.length && i < _manifest!.decks.length; i++) {
      final deck = decks[i];
      final entry = _manifest!.decks[i];
      _deckMetadata![deck.id] = entry;
    }
  }

  // Obtenir les métadonnées d'un deck
  DeckEntry? getDeckMetadata(String deckId) {
    return _deckMetadata?[deckId];
  }

  // Obtenir les decks par difficulté
  List<Deck> getDecksByDifficulty(String difficulty) {
    if (_cachedBaseDecks == null || _manifest == null) return [];
    
    final filtered = <Deck>[];
    for (int i = 0; i < _cachedBaseDecks!.length && i < _manifest!.decks.length; i++) {
      if (_manifest!.decks[i].difficulty == difficulty) {
        filtered.add(_cachedBaseDecks![i]);
      }
    }
    return filtered;
  }

  // Obtenir les decks par catégorie
  Map<String, List<Deck>> getDecksByCategory() {
    return _decksByCategory ?? {};
  }

  // Obtenir les catégories disponibles
  List<String> getCategories() {
    return _decksByCategory?.keys.toList() ?? [];
  }

  // Obtenir les decks d'une catégorie spécifique
  List<Deck> getDecksForCategory(String category) {
    return _decksByCategory?[category] ?? [];
  }

  // Obtenir la version du manifest
  String? getManifestVersion() {
    return _manifest?.version;
  }

  // Charger les decks personnalisés
  Future<List<Deck>> loadCustomDecks() async {
    try {
      final jsonList = StorageHelper.getJsonList(AppConstants.keyCustomDecks);
      if (jsonList == null) return [];

      return jsonList.map((json) => Deck.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Erreur lors du chargement des decks personnalisés: $e');
      return [];
    }
  }

  // Sauvegarder les decks personnalisés
  Future<void> saveCustomDecks(List<Deck> decks) async {
    try {
      final jsonList = decks.map((deck) => deck.toJson()).toList();
      await StorageHelper.saveJsonList(AppConstants.keyCustomDecks, jsonList);
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde des decks personnalisés: $e');
    }
  }

  // Récupérer l'ID du deck sélectionné
  Future<String> getSelectedDeckId() async {
    return StorageHelper.getString(AppConstants.keyCurrentDeck) ??
           AppConstants.deckJapaneseHiragana;
  }

  // Sauvegarder l'ID du deck sélectionné
  Future<void> saveSelectedDeckId(String deckId) async {
    await StorageHelper.saveString(AppConstants.keyCurrentDeck, deckId);
  }

  // Sauvegarder l'état d'un deck
  Future<void> saveDeckState(Deck deck) async {
    try {
      final customDecks = await loadCustomDecks();
      final index = customDecks.indexWhere((d) => d.id == deck.id);
      
      if (index != -1) {
        customDecks[index] = deck;
        await saveCustomDecks(customDecks);
      } else {
        final key = 'deck_state_${deck.id}';
        await StorageHelper.saveJson(key, deck.toJson());
      }
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde de l\'état du deck: $e');
    }
  }

  // Charger l'état d'un deck
  Future<Deck?> loadDeckState(String deckId) async {
    try {
      final key = 'deck_state_$deckId';
      final json = StorageHelper.getJson(key);
      if (json != null) {
        return Deck.fromJson(json);
      }
      return null;
    } catch (e) {
      debugPrint('Erreur lors du chargement de l\'état du deck: $e');
      return null;
    }
  }

  // Vider le cache
  void clearCache() {
    _cachedBaseDecks = null;
    _manifest = null;
    _decksByCategory = null;
    _deckMetadata = null;
  }
}