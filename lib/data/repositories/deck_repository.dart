import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:language_learning_app/data/models/deck.dart';
import 'package:language_learning_app/data/models/deck_manifest.dart';
import 'package:language_learning_app/core/utils/storage_helper.dart';
import 'package:language_learning_app/core/constants/app_constants.dart';

class DeckRepository {
  List<Deck>? _cachedBaseDecks;
  DeckManifest? _manifest;
  Map<String, List<Deck>>? _decksByCategory;
  Map<String, DeckEntry>? _deckMetadata;

  // ========== DECKS DE BASE (STRUCTURE UNIQUEMENT) ==========

  Future<List<Deck>> loadBaseDecks() async {
    if (_cachedBaseDecks != null) return _cachedBaseDecks!;

    try {
      final decks = <Deck>[];
      final manifestJson = await rootBundle.loadString('assets/decks/manifest.json');
      final manifestData = jsonDecode(manifestJson) as Map<String, dynamic>;
      _manifest = DeckManifest.fromJson(manifestData);

      for (final entry in _manifest!.decks) {
        try {
          final jsonString = await rootBundle.loadString(entry.path);
          final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
          decks.add(Deck.fromJson(jsonData));
        } catch (e) {
          debugPrint('❌ Erreur: ${entry.path} - $e');
        }
      }

      _cachedBaseDecks = decks;
      _organizeDecksByCategory(decks);
      _buildMetadataMap(decks);
      return decks;
    } catch (e) {
      debugPrint('💥 Erreur chargement base decks: $e');
      return [];
    }
  }

  void _organizeDecksByCategory(List<Deck> decks) {
    _decksByCategory = {};
    for (int i = 0; i < decks.length && i < _manifest!.decks.length; i++) {
      final deck = decks[i];
      final entry = _manifest!.decks[i];
      final category = entry.category;
      if (!_decksByCategory!.containsKey(category)) {
        _decksByCategory![category] = [];
      }
      _decksByCategory![category]!.add(deck);
    }
  }

  void _buildMetadataMap(List<Deck> decks) {
    _deckMetadata = {};
    for (int i = 0; i < decks.length && i < _manifest!.decks.length; i++) {
      _deckMetadata![decks[i].id] = _manifest!.decks[i];
    }
  }

  DeckEntry? getDeckMetadata(String deckId) => _deckMetadata?[deckId];
  
  Map<String, List<Deck>> getDecksByCategory() => _decksByCategory ?? {};
  
  List<String> getCategories() => _decksByCategory?.keys.toList() ?? [];

  // ========== DECKS PERSONNALISÉS (STRUCTURE UNIQUEMENT) ==========

  Future<List<Deck>> loadCustomDecks() async {
    try {
      final jsonList = StorageHelper.getJsonList(AppConstants.keyCustomDecks);
      if (jsonList == null) return [];
      return jsonList.map((json) => Deck.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Erreur loadCustomDecks: $e');
      return [];
    }
  }

  Future<void> saveCustomDecks(List<Deck> decks) async {
    try {
      final jsonList = decks.map((deck) => deck.toJson()).toList();
      await StorageHelper.saveJsonList(AppConstants.keyCustomDecks, jsonList);
    } catch (e) {
      debugPrint('Erreur saveCustomDecks: $e');
    }
  }

  // ========== DECK SÉLECTIONNÉ (POUR L'UI) ==========

  Future<String> getSelectedDeckId() async {
    return StorageHelper.getString(AppConstants.keyCurrentDeck) ??
           AppConstants.deckJapaneseHiragana;
  }

  Future<void> saveSelectedDeckId(String deckId) async {
    await StorageHelper.saveString(AppConstants.keyCurrentDeck, deckId);
  }

  // ========== PROGRESSION PAR DECK ET MODE DE JEU ==========

  /// Sauvegarde la progression pour un deck et un mode de jeu spécifiques
  /// Format de la clé: "progress_deckId_gameMode"
  /// Ex: "progress_japanese1_classic", "progress_japanese1_reverse"
  Future<void> saveProgress(String deckId, String gameMode, Deck progressDeck) async {
    try {
      final key = 'progress_${deckId}_$gameMode';
      await StorageHelper.saveJson(key, progressDeck.toJson());
      debugPrint('💾 Progression sauvegardée: $key');
    } catch (e) {
      debugPrint('❌ Erreur sauvegarde progression ($deckId, $gameMode): $e');
    }
  }

  /// Charge la progression pour un deck et un mode de jeu spécifiques
  /// Retourne null si aucune progression n'existe
  Future<Deck?> loadProgress(String deckId, String gameMode) async {
    try {
      final key = 'progress_${deckId}_$gameMode';
      final json = StorageHelper.getJson(key);
      if (json != null) {
        debugPrint('📂 Progression chargée: $key');
        return Deck.fromJson(json);
      }
      debugPrint('ℹ️ Aucune progression trouvée pour: $key');
      return null;
    } catch (e) {
      debugPrint('❌ Erreur chargement progression ($deckId, $gameMode): $e');
      return null;
    }
  }

  /// Réinitialise la progression pour un deck et un mode de jeu spécifiques
  Future<void> resetProgress(String deckId, String gameMode) async {
    try {
      final key = 'progress_${deckId}_$gameMode';
      await StorageHelper.remove(key);
      debugPrint('🗑️ Progression supprimée: $key');
    } catch (e) {
      debugPrint('❌ Erreur suppression progression ($deckId, $gameMode): $e');
    }
  }

  /// Réinitialise TOUTES les progressions d'un deck (tous modes confondus)
  Future<void> resetAllProgressForDeck(String deckId) async {
    // Liste des modes connus (à adapter si tu en ajoutes)
    const gameModes = ['classic', 'reverse'];
    for (final mode in gameModes) {
      await resetProgress(deckId, mode);
    }
    debugPrint('🗑️ Toutes les progressions supprimées pour: $deckId');
  }

  void clearCache() {
    _cachedBaseDecks = null;
    _manifest = null;
    _decksByCategory = null;
    _deckMetadata = null;
  }
}