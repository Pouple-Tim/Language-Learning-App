import 'dart:math';
import 'package:flutter/material.dart';
import 'package:language_learning_app/data/models/deck.dart';
import 'package:language_learning_app/data/models/word.dart';
import 'package:language_learning_app/data/models/sentence.dart';
import 'package:language_learning_app/data/models/game_mode.dart';
import 'package:language_learning_app/data/repositories/deck_repository.dart';
import 'package:language_learning_app/core/utils/date_helper.dart';
import 'package:language_learning_app/providers/statistics_provider.dart';

class GameProvider extends ChangeNotifier {
  final DeckRepository _repository = DeckRepository();
  final StatisticsProvider? statisticsProvider;

  // État du jeu en cours
  String? _currentDeckId;
  GameType? _currentGameType;
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

  /// Enum-based mode identity -- the single source of truth for behavior.
  GameType? get currentGameType => _currentGameType;

  /// String form kept for callers that persist/display it as text
  /// (SharedPreferences progress keys, ReviewEntry.gameMode).
  String? get currentGameMode => _currentGameType?.storageId;

  bool get isReverseMode => _currentGameType == GameType.reverse;

  /// Nombre total d'éléments à apprendre (Mots ou Phrases)
  int get totalWords {
    if (_currentProgressDeck == null) return 0;
    if (_currentGameType == GameType.sentence) {
      return _currentProgressDeck!.sentences.length;
    }
    return _currentProgressDeck!.totalWords;
  }

  /// Nombre d'éléments restants
  int get remainingWords {
    if (_currentProgressDeck == null) return 0;
    if (_currentGameType == GameType.sentence) {
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
  bool get isCompleted => remainingWords == 0;

  /// Texte de la question à afficher
  String get currentQuestionText {
    if (_currentGameType == GameType.sentence && _currentSentence != null) {
      return _currentSentence!.original;
    }
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

  Future<void> setDeck(Deck baseDeck, {GameType gameMode = GameType.classic}) async {
    _currentDeckId = baseDeck.id;
    _currentGameType = gameMode;

    debugPrint('🎮 Initialisation du jeu');
    debugPrint('   Deck: ${baseDeck.name} (${baseDeck.id})');
    debugPrint('   Mode: ${gameMode.storageId}');

    final savedProgress = await _repository.loadProgress(baseDeck.id, gameMode.storageId);

    // Copie profonde des phrases : chaque partie doit avoir ses propres
    // instances de Sentence, indépendantes du deck en cache dans
    // DeckProvider (sinon compléter une phrase muterait le deck partagé).
    List<Sentence> freshSentences() => baseDeck.sentences.map((s) => Sentence(
          id: s.id,
          original: s.original,
          translation: s.translation,
          blocks: s.blocks,
          completed: false,
        )).toList();

    if (savedProgress != null) {
      debugPrint('   ✅ Progression existante détectée. Fusion des données...');

      // STRATÉGIE DE FUSION :
      // On prend le deck "frais" (JSON) pour avoir le contenu à jour.
      // On applique les états "removed" (mots) et "completed" (phrases)
      // depuis la sauvegarde, en faisant correspondre par id stable
      // (et non plus par contenu, qui casse silencieusement si le texte
      // d'un mot change entre deux révisions du deck).

      final freshDeck = baseDeck.copyWith(
        words: baseDeck.words.map((w) => w.copyWith(removed: false)).toList(),
        sentences: freshSentences(),
      );

      // A. Restauration des mots appris (match par id)
      for (final savedWord in savedProgress.words) {
        if (!savedWord.removed) continue;
        for (final freshWord in freshDeck.words) {
          if (freshWord.id == savedWord.id) {
            freshWord.removed = true;
            break;
          }
        }
      }

      // B. Restauration des phrases complétées (match par id)
      for (final savedSentence in savedProgress.sentences) {
        if (!savedSentence.completed) continue;
        for (final freshSentence in freshDeck.sentences) {
          if (freshSentence.id == savedSentence.id) {
            freshSentence.completed = true;
            break;
          }
        }
      }

      _currentProgressDeck = freshDeck;
    } else {
      debugPrint('   🆕 Nouvelle partie créée');
      _currentProgressDeck = baseDeck.copyWith(
        words: baseDeck.words.map((w) => w.copyWith(removed: false)).toList(),
        sentences: freshSentences(),
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

    if (_isSpinning && _currentGameType != GameType.sentence) return;

    if (_currentGameType == GameType.sentence) {
      _loadNextSentence();
      notifyListeners();
      return;
    }

    final activeWords = _currentProgressDeck!.activeWords;
    if (activeWords.isEmpty) {
      debugPrint('⚠️ Aucun mot actif disponible');
      return;
    }

    _isSpinning = true;
    notifyListeners();

    final random = Random();
    _currentWord = activeWords[random.nextInt(activeWords.length)];

    if (_currentGameType == GameType.quiz) {
      _generateQuizOptions(activeWords);
    }

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
    final activeSentences = _currentProgressDeck?.sentences.where((s) => !s.completed).toList() ?? [];

    if (activeSentences.isNotEmpty) {
      final random = Random();
      _currentSentence = activeSentences[random.nextInt(activeSentences.length)];
      _availableBlocks = List.from(_currentSentence!.blocks)..shuffle();
      _selectedBlocks = [];
    } else {
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

    final userSentence = _selectedBlocks.join('').replaceAll(' ', '').toLowerCase();
    final correctSentence = _currentSentence!.translation.replaceAll(' ', '').toLowerCase();

    final isCorrect = userSentence == correctSentence;

    if (statisticsProvider != null && _currentProgressDeck != null) {
      await statisticsProvider!.addReview(
        wordId: _currentSentence!.id,
        deckId: _currentProgressDeck!.id,
        wasCorrect: isCorrect,
        inputType: 'blocks',
        gameMode: GameType.sentence.storageId,
      );
    }

    if (isCorrect) {
      _currentSentence!.completed = true;
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

    await statisticsProvider?.addReview(
      wordId: _currentWord!.id,
      deckId: _currentProgressDeck!.id,
      wasCorrect: isCorrect,
      inputType: activeInputType == InputType.text ? 'text' : 'draw',
      gameMode: _currentGameType!.storageId,
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
    if (_currentProgressDeck == null || _currentDeckId == null || _currentGameType == null) return;

    _currentProgressDeck!.resetWords();

    for (final s in _currentProgressDeck!.sentences) {
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

  /// Réinitialise la progression sauvegardée d'un seul mode d'un deck.
  /// Si ce mode est celui actuellement chargé en mémoire, la session en
  /// cours est aussi réinitialisée pour rester cohérente avec le disque.
  Future<void> resetModeProgress(String deckId, GameType mode) async {
    if (deckId == _currentDeckId && mode == _currentGameType) {
      await resetDeck();
      return;
    }
    await _repository.resetProgress(deckId, mode.storageId);
  }

  /// Réinitialise la progression sauvegardée de tous les modes d'un deck.
  Future<void> resetAllModesProgress(String deckId) async {
    await _repository.resetAllProgressForDeck(deckId);
    if (deckId == _currentDeckId) {
      await resetDeck();
    }
  }

  Future<void> checkDailyReset(DateTime lastReset) async {
    if (_currentProgressDeck == null) return;

    if (DateHelper.needsReset(lastReset)) {
      debugPrint('📅 Reset quotidien déclenché');
      await resetDeck();
    }
  }

  Future<void> _saveProgress() async {
    if (_currentProgressDeck == null || _currentDeckId == null || _currentGameType == null) {
      return;
    }

    await _repository.saveProgress(
      _currentDeckId!,
      _currentGameType!.storageId,
      _currentProgressDeck!,
    );
    debugPrint('💾 Progression sauvegardée: progress_${_currentDeckId}_${_currentGameType!.storageId}');
  }
}
