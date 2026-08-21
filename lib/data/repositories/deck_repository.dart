import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:language_learning_app/data/models/deck.dart';
import 'package:language_learning_app/data/models/deck_manifest.dart';
import 'package:language_learning_app/data/models/game_mode.dart';
import 'package:language_learning_app/core/utils/storage_helper.dart';
import 'package:language_learning_app/core/constants/app_constants.dart';

class DeckRepository {
  List<Deck>? _cachedBaseDecks;
  DeckManifest? _manifest;
  Map<String, List<Deck>>? _decksByCategory;
  Map<String, DeckEntry>? _deckMetadata;

  final Future<Map<String, dynamic>?> Function(String deckId) fetchDeckContent;

  DeckRepository({
    Future<Map<String, dynamic>?> Function(String deckId)? fetchDeckContent,
  }) : fetchDeckContent = fetchDeckContent ?? _defaultFetchDeckContent;

  static Future<Map<String, dynamic>?> _defaultFetchDeckContent(String deckId) async {
    final row = await Supabase.instance.client
        .from('decks')
        .select('content')
        .eq('id', deckId)
        .maybeSingle();
    return row?['content'] as Map<String, dynamic>?;
  }

  // ========== DECKS DE BASE (STRUCTURE UNIQUEMENT) ==========

  Future<List<Deck>> loadBaseDecks() async {
    if (_cachedBaseDecks != null) return _cachedBaseDecks!;

    try {
      final decks = <Deck>[];
      final manifestJson = await rootBundle.loadString('assets/decks/manifest.json');
      final manifestData = jsonDecode(manifestJson) as Map<String, dynamic>;
      _manifest = DeckManifest.fromJson(manifestData);

      for (final entry in _manifest!.decks) {
        final cached = await _loadCachedDeckContent(entry.id);
        decks.add(cached ??
            Deck(
              id: entry.id,
              name: entry.name,
              type: DeckType.base,
              inputType: entry.inputType,
              reverseInputType: entry.reverseInputType,
              words: [],
              sentences: [],
            ));
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

  /// Récupère le contenu (mots/phrases) d'un deck de base depuis Supabase,
  /// le fusionne dans le deck (métadonnées seules) fourni, met le résultat
  /// en cache local, et le renvoie.
  Future<Deck> downloadDeckContent(Deck metadataOnlyDeck) async {
    final content = await fetchDeckContent(metadataOnlyDeck.id);
    if (content == null) {
      throw Exception('Deck content not found on server: ${metadataOnlyDeck.id}');
    }

    final populated = Deck.fromJson({
      ...metadataOnlyDeck.toJson(),
      'words': content['words'],
      'sentences': content['sentences'] ?? [],
    });

    await StorageHelper.saveJson('downloaded_deck_${populated.id}', populated.toJson());
    return populated;
  }

  // Wired into loadBaseDecks() to serve cached content.
  Future<Deck?> _loadCachedDeckContent(String deckId) async {
    final json = StorageHelper.getJson('downloaded_deck_$deckId');
    if (json == null) return null;
    try {
      return Deck.fromJson(json);
    } catch (e) {
      debugPrint('❌ Erreur lecture cache deck ($deckId), ignoré: $e');
      return null;
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
    final jsonList = StorageHelper.getJsonList(AppConstants.keyCustomDecks);
    if (jsonList == null) return [];

    final decks = <Deck>[];
    for (final json in jsonList) {
      try {
        decks.add(Deck.fromJson(json));
      } catch (e) {
        debugPrint('❌ Erreur loadCustomDecks (deck ignoré): $e');
      }
    }
    return decks;
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
    for (final type in GameType.values) {
      await resetProgress(deckId, type.storageId);
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