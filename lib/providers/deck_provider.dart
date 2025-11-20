import 'package:flutter/material.dart';
import '../data/models/deck.dart';
import '../data/repositories/deck_repository.dart';

class DeckProvider extends ChangeNotifier {
  final DeckRepository _repository = DeckRepository();
  
  List<Deck> _baseDecks = [];
  List<Deck> _customDecks = [];
  Deck? _selectedDeck;
  bool _isLoading = false;
  bool _isInitialized = false;

  // Getters
  List<Deck> get baseDecks => _baseDecks;
  List<Deck> get customDecks => _customDecks;
  List<Deck> get allDecks => [..._baseDecks, ..._customDecks];
  Deck? get selectedDeck => _selectedDeck;
  bool get isLoading => _isLoading;
  DeckRepository get repository => _repository;
  bool get isInitialized => _isInitialized;

  // Charger tous les decks
  Future<void> loadDecks() async {

    if (_isInitialized) {
      print('✅ Decks déjà chargés (cache)');
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Charger tous les decks (ceci charge aussi le manifest et construit les métadonnées)
      _baseDecks = await _repository.loadBaseDecks();
      _customDecks = await _repository.loadCustomDecks();
      
      // Charger le deck sélectionné avec son état
      final selectedId = await _repository.getSelectedDeckId();
      final selectedDeckBase = allDecks.firstWhere(
        (deck) => deck.id == selectedId,
        orElse: () => _baseDecks.isNotEmpty ? _baseDecks.first : _createEmptyDeck(),
      );
      
      // Charger l'état sauvegardé du deck sélectionné
      final savedState = await _repository.loadDeckState(selectedDeckBase.id);
      _selectedDeck = savedState ?? selectedDeckBase;

      _isInitialized = true;
      
      print('✅ DeckProvider: ${_baseDecks.length} decks de base chargés');
      print('✅ Catégories disponibles: ${_repository.getCategories()}');
      
    } catch (e) {
      debugPrint('Erreur lors du chargement des decks: $e');
      _selectedDeck = _createEmptyDeck();
    }

    _isLoading = false;
    notifyListeners();
  }

  // Sélectionner un deck
  Future<void> selectDeck(Deck deck) async {
    // Charger l'état sauvegardé du deck
    final savedState = await _repository.loadDeckState(deck.id);
    _selectedDeck = savedState ?? deck;
    
    await _repository.saveSelectedDeckId(deck.id);
    notifyListeners();
  }

  // Ajouter un deck personnalisé
  Future<void> addCustomDeck(Deck deck) async {
    _customDecks.add(deck);
    await _repository.saveCustomDecks(_customDecks);
    notifyListeners();
  }

  // Modifier un deck personnalisé
  Future<void> updateCustomDeck(Deck deck) async {
    final index = _customDecks.indexWhere((d) => d.id == deck.id);
    if (index != -1) {
      _customDecks[index] = deck;
      await _repository.saveCustomDecks(_customDecks);
      
      // Si c'est le deck sélectionné, le mettre à jour
      if (_selectedDeck?.id == deck.id) {
        _selectedDeck = deck;
      }
      
      notifyListeners();
    }
  }

  // Supprimer un deck personnalisé
  Future<void> deleteCustomDeck(String deckId) async {
    _customDecks.removeWhere((deck) => deck.id == deckId);
    await _repository.saveCustomDecks(_customDecks);
    
    // Si c'était le deck sélectionné, choisir un autre
    if (_selectedDeck?.id == deckId) {
      _selectedDeck = allDecks.isNotEmpty ? allDecks.first : _createEmptyDeck();
      await _repository.saveSelectedDeckId(_selectedDeck!.id);
    }
    
    notifyListeners();
  }

  // Recharger l'état actuel du deck sélectionné
  Future<void> refreshSelectedDeck() async {
    if (_selectedDeck != null) {
      final savedState = await _repository.loadDeckState(_selectedDeck!.id);
      if (savedState != null) {
        _selectedDeck = savedState;
        notifyListeners();
      }
    }
  }

  // Créer un deck vide par défaut
  Deck _createEmptyDeck() {
    return Deck(
      id: 'empty',
      name: 'Aucun deck',
      type: DeckType.base,
      inputType: InputType.text,
      words: [],
    );
  }

  Future<void> reloadDecks() async {
    _isInitialized = false;
    _repository.clearCache();
    await loadDecks();
  }
}