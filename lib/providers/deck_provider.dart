import 'package:flutter/material.dart';
import 'package:language_learning_app/data/models/deck.dart';
import 'package:language_learning_app/data/repositories/deck_repository.dart';

/// DeckProvider gère UNIQUEMENT:
/// 1. Les decks disponibles (base + custom)
/// 2. Le deck actuellement sélectionné dans l'UI
/// 
/// Il NE gère PAS la progression des jeux (c'est le rôle de GameProvider)
class DeckProvider extends ChangeNotifier {
  final DeckRepository _repository;

  DeckProvider({DeckRepository? repository}) : _repository = repository ?? DeckRepository();

  List<Deck> _baseDecks = [];
  List<Deck> _customDecks = [];
  Deck? _selectedDeck;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _downloadingDeckId;
  String? _downloadError;

  // Getters
  List<Deck> get baseDecks => _baseDecks;
  List<Deck> get customDecks => _customDecks;
  List<Deck> get allDecks => [..._baseDecks, ..._customDecks];
  Deck? get selectedDeck => _selectedDeck;
  bool get isLoading => _isLoading;
  DeckRepository get repository => _repository;
  bool get isInitialized => _isInitialized;
  bool isDownloadingDeck(String deckId) => _downloadingDeckId == deckId;
  String? get downloadError => _downloadError;

  /// Charge tous les decks disponibles et sélectionne le dernier utilisé
  Future<void> loadDecks() async {
    if (_isInitialized) return;

    _isLoading = true;
    notifyListeners();

    try {
      // 1. Charger les decks de base et personnalisés
      _baseDecks = await _repository.loadBaseDecks();
      _customDecks = await _repository.loadCustomDecks();
      
      // 2. Récupérer le dernier deck sélectionné
      final selectedId = await _repository.getSelectedDeckId();
      
      // 3. Trouver le deck correspondant (STRUCTURE UNIQUEMENT, sans progression)
      _selectedDeck = allDecks.firstWhere(
        (deck) => deck.id == selectedId,
        orElse: () => _baseDecks.isNotEmpty ? _baseDecks.first : _createEmptyDeck(),
      );

      _isInitialized = true;
      debugPrint('✅ DeckProvider initialisé. Deck sélectionné: ${_selectedDeck?.name}');
      
    } catch (e) {
      debugPrint('❌ Erreur chargement decks: $e');
      _selectedDeck = _createEmptyDeck();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Sélectionne un deck pour l'utiliser dans les jeux. Si c'est un deck de
  /// base sans contenu chargé/en cache, télécharge son contenu depuis
  /// Supabase avant de le sélectionner.
  Future<void> selectDeck(Deck deck) async {
    _downloadError = null;
    final needsDownload = deck.type == DeckType.base && deck.words.isEmpty && deck.sentences.isEmpty;

    if (!needsDownload) {
      _selectedDeck = deck;
      await _repository.saveSelectedDeckId(deck.id);
      debugPrint('✅ Deck sélectionné: ${deck.name}');
      notifyListeners();
      return;
    }

    _downloadingDeckId = deck.id;
    notifyListeners();

    try {
      final populated = await _repository.downloadDeckContent(deck);
      final index = _baseDecks.indexWhere((d) => d.id == populated.id);
      if (index != -1) _baseDecks[index] = populated;

      _selectedDeck = populated;
      await _repository.saveSelectedDeckId(populated.id);
      debugPrint('✅ Deck téléchargé et sélectionné: ${populated.name}');
    } catch (e) {
      _downloadError = e.toString();
      debugPrint('❌ Erreur téléchargement deck ${deck.id}: $e');
    } finally {
      _downloadingDeckId = null;
      notifyListeners();
    }
  }

  /// Ajoute un deck personnalisé
  Future<void> addCustomDeck(Deck deck) async {
    _customDecks.add(deck);
    await _repository.saveCustomDecks(_customDecks);
    debugPrint('✅ Deck personnalisé ajouté: ${deck.name}');
    notifyListeners();
  }

  /// Met à jour un deck personnalisé
  Future<void> updateCustomDeck(Deck deck) async {
    final index = _customDecks.indexWhere((d) => d.id == deck.id);
    if (index != -1) {
      _customDecks[index] = deck;
      await _repository.saveCustomDecks(_customDecks);
      
      if (_selectedDeck?.id == deck.id) {
        _selectedDeck = deck;
      }
      debugPrint('✅ Deck personnalisé mis à jour: ${deck.name}');
      notifyListeners();
    }
  }

  /// Supprime un deck personnalisé
  Future<void> deleteCustomDeck(String deckId) async {
    _customDecks.removeWhere((deck) => deck.id == deckId);
    await _repository.saveCustomDecks(_customDecks);
    
    // Si c'était le deck sélectionné, en choisir un autre
    if (_selectedDeck?.id == deckId) {
      _selectedDeck = allDecks.isNotEmpty ? allDecks.first : _createEmptyDeck();
      await _repository.saveSelectedDeckId(_selectedDeck!.id);
    }
    
    debugPrint('✅ Deck personnalisé supprimé: $deckId');
    notifyListeners();
  }

  /// Recharge les decks (utile après des modifications)
  Future<void> reloadDecks() async {
    _isInitialized = false;
    await _repository.clearDownloadedDeckContent();
    _repository.clearCache();
    await loadDecks();
  }

  /// Rafraîchit le deck sélectionné (pas de progression, juste la structure)
  Future<void> refreshSelectedDeck() async {
    if (_selectedDeck != null) {
      final freshDeck = allDecks.firstWhere(
        (deck) => deck.id == _selectedDeck!.id,
        orElse: () => _selectedDeck!,
      );
      _selectedDeck = freshDeck;
      notifyListeners();
    }
  }

  /// Crée un deck vide par défaut
  Deck _createEmptyDeck() {
    return Deck(
      id: 'empty',
      name: 'Aucun deck',
      type: DeckType.base,
      inputType: InputType.text,
      words: [],
    );
  }
}