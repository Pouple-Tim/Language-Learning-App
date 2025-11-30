import 'dart:math';
import 'package:flutter/material.dart';
import 'package:language_learning_app/data/models/deck.dart';
import 'package:language_learning_app/data/models/word.dart';
import 'package:language_learning_app/data/repositories/deck_repository.dart';
import 'package:language_learning_app/core/utils/date_helper.dart';
import 'package:language_learning_app/providers/statistics_provider.dart';

/// GameProvider gère UNIQUEMENT la progression d'une partie en cours
/// pour un deck ET un mode de jeu spécifiques
class GameProvider extends ChangeNotifier {
  final DeckRepository _repository = DeckRepository();
  final StatisticsProvider? statisticsProvider;

  // État du jeu en cours
  String? _currentDeckId;           // ID du deck en cours
  String? _currentGameMode;         // Mode de jeu en cours ('classic', 'reverse', etc.)
  Deck? _currentProgressDeck;       // Deck avec la progression actuelle
  Word? _currentWord;               // Mot actuellement affiché

  // Jeu Quizz
  List<String> _quizOptions = [];
  List<String> get quizOptions => _quizOptions;
  
  // Animation de la roue
  bool _isSpinning = false;
  double _wheelRotation = 0.0;

  GameProvider({this.statisticsProvider});

  // ========== GETTERS ==========

  Deck? get currentDeck => _currentProgressDeck;
  Word? get currentWord => _currentWord;
  bool get isSpinning => _isSpinning;
  double get wheelRotation => _wheelRotation;
  String? get currentGameMode => _currentGameMode;
  
  bool get isReverseMode => _currentGameMode == 'reverse';
  
  int get totalWords => _currentProgressDeck?.totalWords ?? 0;
  int get remainingWords => _currentProgressDeck?.remainingWords ?? 0;
  double get progress => _currentProgressDeck?.progress ?? 0.0;
  bool get isCompleted => _currentProgressDeck?.isCompleted ?? false;

  String get currentQuestionText {
    if (_currentWord == null) return '';
    return isReverseMode ? _currentWord!.answer : _currentWord!.prompt;
  }

  InputType get activeInputType {
    if (_currentProgressDeck == null) return InputType.text;
    return isReverseMode 
        ? _currentProgressDeck!.effectiveReverseInputType 
        : _currentProgressDeck!.inputType;
  }

  // ========== INITIALISATION DU JEU ==========

  /// Initialise une partie pour un deck et un mode de jeu
  /// 1. Charge la progression existante OU crée une nouvelle partie
  /// 2. Sauvegarde les infos de la partie en cours
  Future<void> setDeck(Deck baseDeck, {String gameMode = 'classic'}) async {
    _currentDeckId = baseDeck.id;
    _currentGameMode = gameMode;
    
    debugPrint('🎮 Initialisation du jeu');
    debugPrint('   Deck: ${baseDeck.name} (${baseDeck.id})');
    debugPrint('   Mode: $gameMode');

    // 1. Essayer de charger une progression existante
    final savedProgress = await _repository.loadProgress(baseDeck.id, gameMode);
    
    if (savedProgress != null) {
      // Progression existante trouvée
      debugPrint('   ✅ Progression existante chargée (${savedProgress.progress.toStringAsFixed(0)}%)');
      _currentProgressDeck = savedProgress;
    } else {
      // Nouvelle partie : créer une copie propre du deck
      debugPrint('   🆕 Nouvelle partie créée');
      _currentProgressDeck = baseDeck.copyWith(
        words: baseDeck.words.map((w) => w.copyWith(removed: false)).toList(),
      );
    }
    
    _currentWord = null;
    _wheelRotation = 0.0;
    notifyListeners();
  }

  // ========== LOGIQUE DE JEU ==========

  /// Fait tourner la roue et sélectionne un mot aléatoire
  Future<void> spinWheel() async {
    if (_currentProgressDeck == null || _isSpinning) return;

    final activeWords = _currentProgressDeck!.activeWords;
    if (activeWords.isEmpty) {
      debugPrint('⚠️ Aucun mot actif disponible');
      return;
    }

    _isSpinning = true;
    notifyListeners();

    // Sélection aléatoire
    final random = Random();
    _currentWord = activeWords[random.nextInt(activeWords.length)];

    if (_currentGameMode == 'quiz') {
      _generateQuizOptions(activeWords);
    }

    // Animation
    final rotations = 5 + random.nextDouble() * 3;
    _wheelRotation = rotations * 2 * pi;

    await Future.delayed(const Duration(milliseconds: 2000));

    _isSpinning = false;
    notifyListeners();
  }

  /// Vérifie la réponse de l'utilisateur
  Future<bool> checkAnswer(String userAnswer) async {
    if (_currentWord == null || _currentProgressDeck == null) {
      debugPrint('❌ Pas de mot ou de deck actif');
      return false;
    }

    final userAnswerClean = userAnswer.toLowerCase().trim();
    
    // Déterminer la bonne réponse selon le mode
    String expectedAnswer;
    if (isReverseMode) {
      expectedAnswer = _currentWord!.prompt.toLowerCase().trim();
    } else {
      expectedAnswer = _currentWord!.answer.toLowerCase().trim();
    }

    final isCorrect = expectedAnswer == userAnswerClean;

    // Enregistrer les statistiques
    await statisticsProvider?.addReview(
      wordId: _currentWord!.prompt,
      deckId: _currentProgressDeck!.id,
      wasCorrect: isCorrect,
      inputType: activeInputType == InputType.text ? 'text' : 'draw',
      gameMode: _currentGameMode!,
    );

    if (isCorrect) {
      // Marquer le mot comme retiré
      _currentWord!.removed = true;
      
      // Sauvegarder la progression
      await _saveProgress();
      
      debugPrint('✅ Bonne réponse ! Progression: ${progress.toStringAsFixed(0)}%');
      notifyListeners();
      return true;
    }

    debugPrint('❌ Mauvaise réponse');
    return false;
  }

  /// ✅ NOUVEAU : Marque le mot actuel comme correct (pour le mode dessin)
  /// Cette méthode ne vérifie pas la réponse mais fait confiance à l'utilisateur
  Future<void> markCurrentWordAsCorrect() async {
    if (_currentWord == null || _currentProgressDeck == null) {
      debugPrint('❌ Pas de mot ou de deck actif');
      return;
    }

    // Marquer le mot comme retiré
    _currentWord!.removed = true;
    
    // Sauvegarder la progression
    await _saveProgress();
    
    debugPrint('✅ Mot marqué comme correct ! Progression: ${progress.toStringAsFixed(0)}%');
    notifyListeners();
  }

  /// Réinitialise le deck (tous les mots redeviennent actifs)
  Future<void> resetDeck() async {
    if (_currentProgressDeck == null || _currentDeckId == null || _currentGameMode == null) {
      debugPrint('⚠️ Impossible de reset : pas de jeu actif');
      return;
    }
    
    _currentProgressDeck!.resetWords();
    _currentWord = null;
    _wheelRotation = 0.0;
    
    await _saveProgress();
    debugPrint('🔄 Deck réinitialisé');
    notifyListeners();
  }

  /// Réinitialise le mot actuel (pour en choisir un autre)
  void resetCurrentWord() {
    _currentWord = null;
    _wheelRotation = 0.0;
    notifyListeners();
  }

  /// Vérifie si un reset quotidien est nécessaire
  Future<void> checkDailyReset(DateTime lastReset) async {
    if (_currentProgressDeck == null) return;
    
    if (DateHelper.needsReset(lastReset)) {
      debugPrint('📅 Reset quotidien déclenché');
      await resetDeck();
    }
  }

  // ========== SAUVEGARDE ==========

  /// Sauvegarde la progression actuelle
  Future<void> _saveProgress() async {
    if (_currentProgressDeck == null || _currentDeckId == null || _currentGameMode == null) {
      debugPrint('⚠️ Impossible de sauvegarder : données manquantes');
      return;
    }

    await _repository.saveProgress(
      _currentDeckId!,
      _currentGameMode!,
      _currentProgressDeck!,
    );
  }

  void _generateQuizOptions(List<Word> activeWords) {
    if (_currentWord == null) return;

    // 1. Identifier la bonne réponse
    final correctAnswer = _currentWord!.answer;

    // 2. Récupérer tous les mots possibles du deck (même ceux déjà appris pour plus de difficulté, ou juste les actifs)
    final allWords = _currentProgressDeck!.words;

    // 3. Filtrer pour ne pas avoir la bonne réponse en double
    final distractors = allWords
        .where((w) => w.answer.toLowerCase() != correctAnswer.toLowerCase())
        .map((w) => w.answer)
        .toList();

    // 4. Mélanger et prendre 3 distracteurs
    distractors.shuffle();
    final selectedDistractors = distractors.take(3).toList();

    // 5. Compléter avec des leurres si on n'a pas assez de mots dans le deck
    while (selectedDistractors.length < 3) {
      selectedDistractors.add("Option ${selectedDistractors.length + 1}");
    }

    // 6. Ajouter la bonne réponse et mélanger le tout
    _quizOptions = [...selectedDistractors, correctAnswer];
    _quizOptions.shuffle();
  }
}