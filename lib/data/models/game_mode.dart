import 'package:flutter/material.dart';
import 'package:language_learning_app/core/theme/app_colors.dart';

enum GameType {
  classic,
  reverse,
  quiz,
  sentence,
  listening,
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
      case GameType.memory:
        return 'Mémoire';
    }
  }

  /// Icon shown wherever a mode needs a visual identity (home cards, guide).
  IconData get icon {
    switch (this) {
      case GameType.classic:
        return Icons.school_rounded;
      case GameType.reverse:
        return Icons.swap_horiz_rounded;
      case GameType.quiz:
        return Icons.quiz_rounded;
      case GameType.sentence:
        return Icons.segment_rounded;
      case GameType.listening:
        return Icons.headphones_rounded;
      case GameType.memory:
        return Icons.psychology_rounded;
    }
  }

  /// Accent color shown wherever a mode needs a visual identity (home cards, guide).
  Color get color {
    switch (this) {
      case GameType.classic:
        return AppColors.primary;
      case GameType.reverse:
        return AppColors.secondary;
      case GameType.quiz:
        return Colors.orange;
      case GameType.sentence:
        return Colors.purple;
      case GameType.listening:
        return Colors.teal;
      case GameType.memory:
        return Colors.indigo;
    }
  }
}

class GameMode {
  final GameType type;
  final String title;
  final String description;

  const GameMode({
    required this.type,
    required this.title,
    required this.description,
  });
}
