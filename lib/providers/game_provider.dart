import 'dart:math';
import 'package:flutter/material.dart';
import 'package:language_learning_app/data/models/deck.dart';
import 'package:language_learning_app/data/models/word.dart';
import 'package:language_learning_app/data/repositories/deck_repository.dart';
import 'package:language_learning_app/core/utils/date_helper.dart';

class GameProvider extends ChangeNotifier {
  final DeckRepository _repository = DeckRepository();
  
  Deck? _currentDeck;
  Word? _currentWord;
  bool _isSpinning = false;
  double _wheelRotation = 0.0;

  // Getters
  Deck? get currentDeck => _currentDeck;
  Word? get currentWord => _currentWord;
  bool get isSpinning => _isSpinning;
  double get wheelRotation => _wheelRotation;
  
  // Stats
  int get totalWords => _currentDeck?.totalWords ?? 0;
  int get remainingWords => _currentDeck?.remainingWords ?? 0;
  double get progress => _currentDeck?.progress ?? 0.0;
  bool get isCompleted => _currentDeck?.isCompleted ?? false;

  // Définir le deck actuel
  Future<void> setDeck(Deck deck) async {
    // Charger l'état sauvegardé du deck
    final savedDeck = await _repository.loadDeckState(deck.id);
    
    if (savedDeck != null) {
      // Utiliser l'état sauvegardé
      _currentDeck = savedDeck;
    } else {
      // Utiliser le deck tel quel
      _currentDeck = deck;
    }
    
    _currentWord = null;
    notifyListeners();
  }

  // Lancer la roue
  Future<void> spinWheel() async {
    if (_currentDeck == null || _isSpinning) return;

    final activeWords = _currentDeck!.activeWords;
    if (activeWords.isEmpty) {
      // Tous les mots ont été réussis
      return;
    }

    // Commencer l'animation
    _isSpinning = true;
    notifyListeners();

    // Sélectionner un mot aléatoire
    final random = Random();
    _currentWord = activeWords[random.nextInt(activeWords.length)];

    // Simuler la rotation de la roue (2 secondes)
    final rotations = 5 + random.nextDouble() * 3; // 5-8 tours
    _wheelRotation = rotations * 2 * pi;

    // Attendre la fin de l'animation
    await Future.delayed(const Duration(milliseconds: 2000));

    _isSpinning = false;
    notifyListeners();
  }

  // Vérifier la réponse de l'utilisateur
  bool checkAnswer(String userAnswer) {
    if (_currentWord == null) return false;

    final correctAnswer = _currentWord!.answer.toLowerCase().trim();
    final userAnswerClean = userAnswer.toLowerCase().trim();

    if (correctAnswer == userAnswerClean) {
      // Bonne réponse : retirer le mot
      _currentWord!.removed = true;
      
      // Sauvegarder l'état du deck
      _saveDeckState();
      
      notifyListeners();
      return true;
    }

    // Mauvaise réponse
    return false;
  }

  // Reset le deck (tous les mots redeviennent actifs)
  Future<void> resetDeck() async {
    if (_currentDeck == null) return;
    _currentDeck!.resetWords();
    _currentWord = null;
    _wheelRotation = 0.0;
    
    // Sauvegarder l'état réinitialisé
    await _saveDeckState();
    
    notifyListeners();
  }

  // Reset le mot actuel (relancer sans changer les stats)
  void resetCurrentWord() {
    _currentWord = null;
    _wheelRotation = 0.0;
    notifyListeners();
  }

  // Sauvegarder l'état du deck
  Future<void> _saveDeckState() async {
    if (_currentDeck != null) {
      await _repository.saveDeckState(_currentDeck!);
    }
  }

  // Vérifier et effectuer le reset quotidien si nécessaire
  Future<void> checkDailyReset(DateTime lastReset) async {
    if (_currentDeck == null) return;
    
    if (DateHelper.needsReset(lastReset)) {
      // Reset nécessaire
      await resetDeck();
    }
  }
}