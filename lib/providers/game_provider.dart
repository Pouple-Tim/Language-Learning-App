import 'dart:math';
import 'package:flutter/material.dart';
import 'package:language_learning_app/data/models/deck.dart';
import 'package:language_learning_app/data/models/word.dart';
import 'package:language_learning_app/data/models/sentence.dart';
import 'package:language_learning_app/data/repositories/deck_repository.dart';
import 'package:language_learning_app/core/utils/date_helper.dart';
import 'package:language_learning_app/providers/statistics_provider.dart';

class GameProvider extends ChangeNotifier {
  final DeckRepository _repository = DeckRepository();
  final StatisticsProvider? statisticsProvider;

  // État du jeu en cours
  String? _currentDeckId;
  String? _currentGameMode; // 'classic', 'reverse', 'quiz', 'sentence'
  Deck? _currentProgressDeck;
  
  // État Mode Mots (Classic/Reverse/Quiz)
  Word? _currentWord;
  
  // État Mode Phrase (Sentence)
  Sentence? _currentSentence;
  List<String> _availableBlocks = []; // Blocs disponibles (en bas)
  List<String> _selectedBlocks = [];  // Blocs choisis (en haut)

  // Jeu Quiz
  List<String> _quizOptions = [];
  List<String> get quizOptions => _quizOptions;
  
  // Animation
  bool _isSpinning = false;
  double _wheelRotation = 0.0;

  GameProvider({this.statisticsProvider});

  // ===========================================================================
  // GETTERS (Calculs dynamiques selon le mode)
  // ===========================================================================

  Deck? get currentDeck => _currentProgressDeck;
  Word? get currentWord => _currentWord;
  Sentence? get currentSentence => _currentSentence;
  
  List<String> get availableBlocks => _availableBlocks;
  List<String> get selectedBlocks => _selectedBlocks;
  
  bool get isSpinning => _isSpinning;
  double get wheelRotation => _wheelRotation;
  String? get currentGameMode => _currentGameMode;
  bool get isReverseMode => _currentGameMode == 'reverse';

  /// Nombre total d'éléments à apprendre (Mots ou Phrases)
  int get totalWords {
    if (_currentProgressDeck == null) return 0;
    if (_currentGameMode == 'sentence') {
      return _currentProgressDeck!.sentences.length;
    }
    return _currentProgressDeck!.totalWords;
  }

  /// Nombre d'éléments restants
  int get remainingWords {
    if (_currentProgressDeck == null) return 0;
    if (_currentGameMode == 'sentence') {
      // Compte les phrases qui ne sont PAS complétées
      return _currentProgressDeck!.sentences.where((s) => !s.completed).length;
    }
    return _currentProgressDeck!.remainingWords;
  }

  /// Pourcentage de progression (0 à 100)
  double get progress {
    if (totalWords == 0) return 0.0;
    return ((totalWords - remainingWords) / totalWords) * 100;
  }

  /// Jeu terminé ?
  bool get isCompleted {
    return remainingWords == 0;
  }

  /// Texte de la question à afficher
  String get currentQuestionText {
    // Mode Phrase : Affiche "Bonjour" (Original)
    if (_currentGameMode == 'sentence' && _currentSentence != null) {
      return _currentSentence!.original;
    }
    // Mode Mots
    if (_currentWord == null) return '';
    return isReverseMode ? _currentWord!.answer : _currentWord!.prompt;
  }

  /// Type d'input (Clavier ou Dessin) pour les modes mots
  InputType get activeInputType {
    if (_currentProgressDeck == null) return InputType.text;
    return isReverseMode 
        ? _currentProgressDeck!.effectiveReverseInputType 
        : _currentProgressDeck!.inputType;
  }

  // ===========================================================================
  // INITIALISATION (SetDeck avec Merge)
  // ===========================================================================

  Future<void> setDeck(Deck baseDeck, {String gameMode = 'classic'}) async {
    _currentDeckId = baseDeck.id;
    _currentGameMode = gameMode;
    
    debugPrint('🎮 Initialisation du jeu');
    debugPrint('   Deck: ${baseDeck.name} (${baseDeck.id})');
    debugPrint('   Mode: $gameMode');

    // 1. Charger la progression sauvegardée
    final savedProgress = await _repository.loadProgress(baseDeck.id, gameMode);
    
    if (savedProgress != null) {
      debugPrint('   ✅ Progression existante détectée. Fusion des données...');
      
      // STRATÉGIE DE FUSION :
      // On prend le deck "frais" (JSON) pour avoir le contenu à jour (nouvelles phrases, corrections orthographe).
      // On applique les états "removed" (mots) et "completed" (phrases) depuis la sauvegarde.

      final freshDeck = baseDeck.copyWith(
        words: baseDeck.words.map((w) => w.copyWith(removed: false)).toList(),
        sentences: baseDeck.sentences.map((s) => Sentence(
          id: s.id,
          original: s.original,
          translation: s.translation,
          blocks: s.blocks,
          completed: false, // Reset par défaut avant application de la sauvegarde
        )).toList(),
      );

      // A. Restauration des mots appris
      for (var savedWord in savedProgress.words) {
        if (savedWord.removed) {
          try {
            final wordToUpdate = freshDeck.words.firstWhere((w) => w.prompt == savedWord.prompt);
            wordToUpdate.removed = true;
          } catch (_) {}
        }
      }

      // B. Restauration des phrases complétées
      if (savedProgress.sentences.isNotEmpty) {
        for (var savedSentence in savedProgress.sentences) {
          if (savedSentence.completed) {
            try {
              final sentenceToUpdate = freshDeck.sentences.firstWhere((s) => s.id == savedSentence.id);
              sentenceToUpdate.completed = true;
            } catch (_) {}
          }
        }
      }
      
      _currentProgressDeck = freshDeck;
      
    } else {
      debugPrint('   🆕 Nouvelle partie créée');
      _currentProgressDeck = baseDeck.copyWith(
        words: baseDeck.words.map((w) => w.copyWith(removed: false)).toList(),
        sentences: baseDeck.sentences, // On garde les phrases du JSON
      );
    }
    
    // Reset des pointeurs
    _currentWord = null;
    _currentSentence = null;
    _wheelRotation = 0.0;
    notifyListeners();
  }

  // ===========================================================================
  // BOUCLE DE JEU PRINCIPALE (SpinWheel)
  // ===========================================================================

  Future<void> spinWheel() async {
    if (_currentProgressDeck == null) return;
    
    // Si une roue tourne déjà, on ne fait rien (sauf si on veut forcer en mode phrase)
    if (_isSpinning && _currentGameMode != 'sentence') return;

    // --- BRANCHE : MODE PHRASE ---
    if (_currentGameMode == 'sentence') {
      // MODIFICATION : Plus d'animation, plus de délai.
      // On charge directement la phrase suivante pour une transition instantanée.
      _loadNextSentence();
      notifyListeners();
      return;
    }

    // --- BRANCHE : MODE MOTS (Classic/Quiz/Reverse) ---
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

    // Préparation Quiz si nécessaire
    if (_currentGameMode == 'quiz') {
      _generateQuizOptions(activeWords);
    }

    // Animation Roue
    final rotations = 5 + random.nextDouble() * 3;
    _wheelRotation = rotations * 2 * pi;

    await Future.delayed(const Duration(milliseconds: 2000));

    _isSpinning = false;
    notifyListeners();
  }

  // ===========================================================================
  // LOGIQUE : MODE PHRASE (SENTENCE)
  // ===========================================================================

  void _loadNextSentence() {
    // Filtrer pour ne garder que les phrases non complétées
    final activeSentences = _currentProgressDeck?.sentences.where((s) => !s.completed).toList() ?? [];
    
    if (activeSentences.isNotEmpty) {
        final random = Random();
        _currentSentence = activeSentences[random.nextInt(activeSentences.length)];
        
        // Mélanger les blocs pour l'affichage
        _availableBlocks = List.from(_currentSentence!.blocks)..shuffle();
        _selectedBlocks = [];
    } else {
        // Cas où tout est fini ou pas de phrases
        _currentSentence = null;
    }
  }

  void addBlockToSentence(String block) {
    _availableBlocks.remove(block);
    _selectedBlocks.add(block);
    notifyListeners();
  }

  void removeBlockFromSentence(String block) {
    _selectedBlocks.remove(block);
    _availableBlocks.add(block);
    notifyListeners();
  }

  Future<bool> checkSentenceConstruction() async {
    if (_currentSentence == null) return false;

    // Validation "Loose" : On retire les espaces pour supporter le chinois/japonais
    // Ex: "ni hao" == "nihao" ou "你 好" == "你好"
    final userSentence = _selectedBlocks.join('').replaceAll(' ', '').toLowerCase();
    final correctSentence = _currentSentence!.translation.replaceAll(' ', '').toLowerCase();
    
    final isCorrect = userSentence == correctSentence;

    // 1. Enregistrement Stats
    if (statisticsProvider != null && _currentProgressDeck != null) {
      await statisticsProvider!.addReview(
        wordId: _currentSentence!.original, // ID = La phrase originale
        deckId: _currentProgressDeck!.id,
        wasCorrect: isCorrect,
        inputType: 'blocks',
        gameMode: 'sentence',
      );
    }

    if (isCorrect) {
      // 2. Marquer comme fait
      _currentSentence!.completed = true;
      // 3. Sauvegarder
      await _saveProgress();
      
      debugPrint('✅ Phrase correcte !');
      notifyListeners();
      return true;
    }
    
    debugPrint('❌ Phrase incorrecte.');
    return false;
  }
  
  void resetCurrentSentence() {
    _currentSentence = null;
    _selectedBlocks = [];
    _availableBlocks = [];
    notifyListeners();
  }

  // ===========================================================================
  // LOGIQUE : MODE MOTS (Classic / Quiz / Reverse)
  // ===========================================================================

  Future<bool> checkAnswer(String userAnswer) async {
    if (_currentWord == null || _currentProgressDeck == null) return false;

    final userAnswerClean = userAnswer.toLowerCase().trim();
    String expectedAnswer;
    
    if (isReverseMode) {
      expectedAnswer = _currentWord!.prompt.toLowerCase().trim();
    } else {
      expectedAnswer = _currentWord!.answer.toLowerCase().trim();
    }

    final isCorrect = expectedAnswer == userAnswerClean;

    // Enregistrement Stats
    await statisticsProvider?.addReview(
      wordId: _currentWord!.prompt,
      deckId: _currentProgressDeck!.id,
      wasCorrect: isCorrect,
      inputType: activeInputType == InputType.text ? 'text' : 'draw',
      gameMode: _currentGameMode!,
    );

    if (isCorrect) {
      _currentWord!.removed = true;
      await _saveProgress();
      debugPrint('✅ Bonne réponse !');
      notifyListeners();
      return true;
    }

    debugPrint('❌ Mauvaise réponse');
    return false;
  }

  // Pour le mode Dessin (validation manuelle)
  Future<void> markCurrentWordAsCorrect() async {
    if (_currentWord == null || _currentProgressDeck == null) return;
    
    _currentWord!.removed = true;
    await _saveProgress();
    debugPrint('✅ Dessin validé !');
    notifyListeners();
  }

  void resetCurrentWord() {
    _currentWord = null;
    _wheelRotation = 0.0;
    notifyListeners();
  }

  void _generateQuizOptions(List<Word> activeWords) {
    if (_currentWord == null) return;

    final correctAnswer = _currentWord!.answer;
    final allWords = _currentProgressDeck!.words;

    final distractors = allWords
        .where((w) => w.answer.toLowerCase() != correctAnswer.toLowerCase())
        .map((w) => w.answer)
        .toList();

    distractors.shuffle();
    final selectedDistractors = distractors.take(3).toList();

    // Remplissage si pas assez de mots
    while (selectedDistractors.length < 3) {
      selectedDistractors.add("Option ${selectedDistractors.length + 1}");
    }

    _quizOptions = [...selectedDistractors, correctAnswer];
    _quizOptions.shuffle();
  }

  // ===========================================================================
  // MAINTENANCE & SAUVEGARDE
  // ===========================================================================

  Future<void> resetDeck() async {
    if (_currentProgressDeck == null || _currentDeckId == null || _currentGameMode == null) return;
    
    // Reset Mots
    _currentProgressDeck!.resetWords();
    
    // Reset Phrases (important pour le mode Sentence)
    for (var s in _currentProgressDeck!.sentences) {
      s.completed = false;
    }
    
    _currentWord = null;
    _currentSentence = null;
    _wheelRotation = 0.0;
    
    await _saveProgress();
    debugPrint('🔄 Deck réinitialisé');
    notifyListeners();
    spinWheel();
  }

  Future<void> checkDailyReset(DateTime lastReset) async {
    if (_currentProgressDeck == null) return;
    
    if (DateHelper.needsReset(lastReset)) {
      debugPrint('📅 Reset quotidien déclenché');
      await resetDeck();
    }
  }

  Future<void> _saveProgress() async {
    if (_currentProgressDeck == null || _currentDeckId == null || _currentGameMode == null) {
      return;
    }

    await _repository.saveProgress(
      _currentDeckId!,
      _currentGameMode!,
      _currentProgressDeck!,
    );
    debugPrint('💾 Progression sauvegardée: progress_${_currentDeckId}_$_currentGameMode');
  }
}