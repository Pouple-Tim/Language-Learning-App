import 'package:json_annotation/json_annotation.dart';

part 'review_history.g.dart';

/// Représente une révision d'un mot à un moment donné
@JsonSerializable()
class ReviewEntry {
  final String wordId;           // ID stable du mot (Word.id)
  final String deckId;           // ID du deck
  final DateTime reviewedAt;     // Date et heure de la révision
  final bool wasCorrect;         // Si la réponse était correcte
  final String inputType;        // 'text' ou 'draw'
  final String? gameMode;

  ReviewEntry({
    required this.wordId,
    required this.deckId,
    required this.reviewedAt,
    required this.wasCorrect,
    required this.inputType,
    this.gameMode,
    
  });

  factory ReviewEntry.fromJson(Map<String, dynamic> json) => _$ReviewEntryFromJson(json);
  Map<String, dynamic> toJson() => _$ReviewEntryToJson(this);

  @override
  String toString() => 'ReviewEntry(word: $wordId, deck: $deckId, correct: $wasCorrect, at: $reviewedAt)';
}

/// Classe pour gérer l'historique complet des révisions
@JsonSerializable()
class ReviewHistory {
  List<ReviewEntry> entries;

  ReviewHistory({
    required this.entries,
  });

  /// Créer un historique vide
  factory ReviewHistory.empty() {
    return ReviewHistory(entries: []);
  }

  /// Ajouter une nouvelle révision
  void addReview(ReviewEntry entry) {
    entries.add(entry);
  }

  /// Obtenir les révisions des N derniers jours
  List<ReviewEntry> getRecentReviews(int days) {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    return entries.where((entry) => entry.reviewedAt.isAfter(cutoffDate)).toList();
  }

  /// Obtenir les révisions d'un jour spécifique
  List<ReviewEntry> getReviewsForDay(DateTime day) {
    return entries.where((entry) {
      return entry.reviewedAt.year == day.year &&
             entry.reviewedAt.month == day.month &&
             entry.reviewedAt.day == day.day;
    }).toList();
  }

  /// Obtenir les révisions d'un deck spécifique
  List<ReviewEntry> getReviewsForDeck(String deckId) {
    return entries.where((entry) => entry.deckId == deckId).toList();
  }

  /// Nettoyer les révisions trop anciennes (> 90 jours)
  void cleanOldReviews() {
    final cutoffDate = DateTime.now().subtract(const Duration(days: 90));
    entries.removeWhere((entry) => entry.reviewedAt.isBefore(cutoffDate));
  }

  factory ReviewHistory.fromJson(Map<String, dynamic> json) => _$ReviewHistoryFromJson(json);
  Map<String, dynamic> toJson() => _$ReviewHistoryToJson(this);

  @override
  String toString() => 'ReviewHistory(total: ${entries.length} reviews)';
}