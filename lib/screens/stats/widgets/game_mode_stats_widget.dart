import 'package:flutter/material.dart';
import 'package:language_learning_app/l10n/app_localizations.dart';
import 'package:language_learning_app/core/extensions/gamemode_extensions.dart';

class GameModeStatsWidget extends StatelessWidget {
  /// Les données sont typées fortement avec l'Enum [GameMode]
  final List<MapEntry<GameMode, int>> data;

  const GameModeStatsWidget({
    super.key,
    required this.data,
  });

  /// Constructeur utilitaire pour transformer des données brutes (String) venant d'une API/BDD
  /// Exemple: {'classic': 10, 'reverse': 5}
  GameModeStatsWidget.fromRawData({
    super.key,
    required Map<String, int> rawData,
  }) : data = rawData.entries
            .map((e) => MapEntry(GameMode.fromString(e.key), e.value))
            // On filtre les modes inconnus vides si nécessaire, ou on les garde
            .where((e) => e.value > 0 || e.key != GameMode.unknown)
            .toList()
          // Tri par nombre de parties (décroissant)
          ..sort((a, b) => b.value.compareTo(a.value));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (data.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(
            l10n.noGameData,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      );
    }

    // Calcul du total pour les pourcentages
    final totalPlays = data.fold<int>(0, (sum, item) => sum + item.value);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: data.map((entry) {
          final mode = entry.key;
          final count = entry.value;
          // Sécurité anti-division par zéro
          final percentage = totalPlays > 0 ? count / totalPlays : 0.0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. En-tête : Icône + Titre + Pourcentage
                Row(
                  children: [
                    // Icône avec fond coloré léger
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: mode.color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        mode.icon, 
                        size: 18, 
                        color: mode.color
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Titre traduit (via extension)
                    Expanded(
                      child: Text(
                        mode.getLocalizedName(l10n),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    // Pourcentage
                    Text(
                      '${(percentage * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // 2. Barre de progression
                Stack(
                  children: [
                    // Fond de la barre
                    Container(
                      height: 8,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    // Remplissage coloré
                    if (percentage > 0)
                      FractionallySizedBox(
                        widthFactor: percentage,
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: mode.color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 4),
                
                // 3. Sous-titre : Nombre de parties
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    l10n.gamesPlayed(count),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}