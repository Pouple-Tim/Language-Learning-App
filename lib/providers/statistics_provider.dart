import 'package:flutter/material.dart';
import 'package:language_learning_app/data/models/review_history.dart';
import 'package:language_learning_app/core/utils/storage_helper.dart';
import 'package:language_learning_app/data/models/game_mode.dart';

class GameModeStat {
  final GameType type;
  final String label;
  final int count;

  const GameModeStat({required this.type, required this.label, required this.count});
}

class StatisticsProvider extends ChangeNotifier {
  ReviewHistory _history = ReviewHistory.empty();
  bool _isLoading = false;

  // Getters
  ReviewHistory get history => _history;
  bool get isLoading => _isLoading;

  // Clé de stockage
  static const String _storageKey = 'review_history';

  /// Charger l'historique depuis le stockage
  Future<void> loadHistory() async {
    _isLoading = true;
    notifyListeners();

    try {
      final json = StorageHelper.getJson(_storageKey);
      if (json != null) {
        _history = ReviewHistory.fromJson(json);
        // Nettoyer les anciennes révisions (> 90 jours)
        _history.cleanOldReviews();
        await _saveHistory();
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement de l\'historique: $e');
      _history = ReviewHistory.empty();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Ajouter une nouvelle révision
  /// [gameMode] : 'classic', 'reverse', 'quiz', etc.
  Future<void> addReview({
    required String wordId,
    required String deckId,
    required bool wasCorrect,
    required String inputType,
    required String gameMode, // <--- NOUVEAU PARAMÈTRE
  }) async {
    final entry = ReviewEntry(
      wordId: wordId,
      deckId: deckId,
      reviewedAt: DateTime.now(),
      wasCorrect: wasCorrect,
      inputType: inputType,
      gameMode: gameMode, // <--- ENREGISTREMENT
    );

    _history.addReview(entry);
    await _saveHistory();
    notifyListeners();
  }

  /// Sauvegarder l'historique
  Future<void> _saveHistory() async {
    await StorageHelper.saveJson(_storageKey, _history.toJson());
  }

  /// Réinitialiser toutes les statistiques
  Future<void> clearHistory() async {
    _history = ReviewHistory.empty();
    await StorageHelper.remove(_storageKey);
    notifyListeners();
  }

  // ============================================================
  // STATISTIQUES CALCULÉES
  // ============================================================

  /// Répartition des modes de jeu (pour le graphique), triée par nombre
  /// de parties décroissant.
  List<GameModeStat> getGameModeStats() {
    final Map<GameType, int> counts = {};

    for (final entry in _history.entries) {
      final type = GameTypeIdentity.fromStorageId(entry.gameMode ?? 'classic');
      counts[type] = (counts[type] ?? 0) + 1;
    }

    final stats = counts.entries
        .map((e) => GameModeStat(type: e.key, label: e.key.statsLabel, count: e.value))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    return stats;
  }

  /// Nombre de mots révisés par jour (7 derniers jours)
  Map<DateTime, int> getReviewsPerDay(int days) {
    final Map<DateTime, int> reviewsPerDay = {};
    final now = DateTime.now();

    for (int i = days - 1; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      reviewsPerDay[day] = 0;
    }

    final recentReviews = _history.getRecentReviews(days);
    for (final review in recentReviews) {
      final day = DateTime(
        review.reviewedAt.year,
        review.reviewedAt.month,
        review.reviewedAt.day,
      );
      reviewsPerDay[day] = (reviewsPerDay[day] ?? 0) + 1;
    }

    return reviewsPerDay;
  }

  /// Activité mensuelle (pour heatmap)
  Map<DateTime, int> getMonthlyActivity() {
    final Map<DateTime, int> activity = {};
    final now = DateTime.now();
    final monthAgo = DateTime(now.year, now.month - 1, now.day);

    final reviews = _history.entries.where((entry) => 
      entry.reviewedAt.isAfter(monthAgo)
    ).toList();

    for (final review in reviews) {
      final day = DateTime(
        review.reviewedAt.year,
        review.reviewedAt.month,
        review.reviewedAt.day,
      );
      activity[day] = (activity[day] ?? 0) + 1;
    }

    return activity;
  }

  /// Top 5 decks les plus pratiqués
  List<MapEntry<String, int>> getTopDecks() {
    final Map<String, int> deckCounts = {};

    for (final review in _history.entries) {
      deckCounts[review.deckId] = (deckCounts[review.deckId] ?? 0) + 1;
    }

    final sorted = deckCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(5).toList();
  }

  /// Série actuelle (jours consécutifs)
  int getCurrentStreak() {
    if (_history.entries.isEmpty) return 0;

    final now = DateTime.now();
    int streak = 0;
    
    for (int i = 0; i < 365; i++) {
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final reviewsForDay = _history.getReviewsForDay(day);
      
      if (reviewsForDay.isNotEmpty) {
        streak++;
      } else if (i > 0) {
        break;
      }
    }

    return streak;
  }

  /// Total de mots appris (mots corrects uniques)
  int getTotalWordsLearned() {
    final correctWords = _history.entries
        .where((entry) => entry.wasCorrect)
        .map((entry) => entry.wordId)
        .toSet();
    return correctWords.length;
  }

  /// Moyenne de révisions par jour
  double getAverageReviewsPerDay() {
    if (_history.entries.isEmpty) return 0.0;

    final oldestReview = _history.entries
        .reduce((a, b) => a.reviewedAt.isBefore(b.reviewedAt) ? a : b);
    
    final daysSinceStart = DateTime.now().difference(oldestReview.reviewedAt).inDays + 1;
    
    return _history.entries.length / daysSinceStart;
  }

  /// Meilleur jour de la semaine
  int getBestDayOfWeek() {
    final Map<int, int> dayCount = {};

    for (final review in _history.entries) {
      final weekday = review.reviewedAt.weekday;
      dayCount[weekday] = (dayCount[weekday] ?? 0) + 1;
    }

    if (dayCount.isEmpty) return 1;

    return dayCount.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  /// Taux de réussite global
  double getSuccessRate() {
    if (_history.entries.isEmpty) return 0.0;
    
    final correctCount = _history.entries.where((e) => e.wasCorrect).length;
    return (correctCount / _history.entries.length) * 100;
  }
}