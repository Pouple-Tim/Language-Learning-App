import 'package:flutter/material.dart';
import 'package:language_learning_app/core/theme/app_colors.dart';
import 'package:language_learning_app/l10n/app_localizations.dart';

enum GameMode {
  classic,
  reverse,
  quiz,
  unknown; // Sécurité pour les futurs modes non gérés

  // Méthode statique pour convertir une String (API/DB) en Enum
  static GameMode fromString(String value) {
    final normalized = value.toLowerCase().trim();
    if (normalized.contains('classi')) return GameMode.classic;
    if (normalized.contains('revers') || normalized.contains('invers')) return GameMode.reverse;
    if (normalized.contains('quiz')) return GameMode.quiz;
    return GameMode.unknown;
  }
}

// Extension pour gérer les propriétés UI de chaque mode
extension GameModeUI on GameMode {
  
  // 1. Le Nom traduit (l10n)
  String getLocalizedName(AppLocalizations l10n) {
    switch (this) {
      case GameMode.classic:
        return l10n.classicModeTitle; // "Classic Training"
      case GameMode.reverse:
        return l10n.reverseModeTitle; // "Reverse Training"
      case GameMode.quiz:
        return "Quiz Mode"; // Ajoute cette clé dans ton l10n plus tard
      case GameMode.unknown:
        return "Unknown Mode";
    }
  }

  // 2. La Couleur
  Color get color {
    switch (this) {
      case GameMode.classic:
        return AppColors.primary;
      case GameMode.reverse:
        return AppColors.secondary;
      case GameMode.quiz:
        return Colors.orange;
      case GameMode.unknown:
        return Colors.grey;
    }
  }

  // 3. L'icône
  IconData get icon {
    switch (this) {
      case GameMode.classic:
        return Icons.school;
      case GameMode.reverse:
        return Icons.swap_horiz;
      case GameMode.quiz:
        return Icons.timer;
      case GameMode.unknown:
        return Icons.help_outline;
    }
  }
}