import 'package:flutter/material.dart';

enum GameType {
  classic,
  reverse,
  quiz,
  sentence,
  listening,
  pronunciation,
  memory, // Futur
}

/// Single source of truth for mode identity: the id used for persistence
/// keys and stats storage, plus the display labels used in different UI
/// contexts. Add a new mode by adding a GameType value and filling in its
/// case in every switch below -- the compiler keeps them exhaustive.
extension GameTypeIdentity on GameType {
  /// Stable string used in SharedPreferences progress keys and in
  /// ReviewEntry.gameMode. Existing values ('classic', 'reverse', 'quiz',
  /// 'sentence') are preserved as-is even though no migration is required,
  /// simply to avoid churn.
  String get storageId => name;

  static GameType fromStorageId(String id) {
    return GameType.values.firstWhere(
      (type) => type.storageId == id,
      orElse: () => GameType.classic,
    );
  }

  /// Short badge shown in GameScreen's header for non-default modes.
  /// Empty means "no badge" (classic mode).
  String get badgeLabel {
    switch (this) {
      case GameType.classic:
        return '';
      case GameType.reverse:
        return 'REVERSE';
      case GameType.quiz:
        return 'QUIZ MODE';
      case GameType.sentence:
        return 'PHRASE';
      case GameType.listening:
        return 'ÉCOUTE';
      case GameType.pronunciation:
        return 'PRONONCIATION';
      case GameType.memory:
        return 'MEMORY';
    }
  }

  /// French display label used on the statistics screen.
  String get statsLabel {
    switch (this) {
      case GameType.classic:
        return 'Classique';
      case GameType.reverse:
        return 'Inversé';
      case GameType.quiz:
        return 'Quiz';
      case GameType.sentence:
        return 'Phrase';
      case GameType.listening:
        return 'Écoute';
      case GameType.pronunciation:
        return 'Prononciation';
      case GameType.memory:
        return 'Mémoire';
    }
  }
}

class GameMode {
  final GameType type;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const GameMode({
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
