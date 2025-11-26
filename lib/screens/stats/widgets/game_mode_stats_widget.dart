import 'package:flutter/material.dart';
import 'package:language_learning_app/core/theme/app_colors.dart';
import 'package:language_learning_app/l10n/app_localizations.dart';

class GameModeStatsWidget extends StatelessWidget {
  final List<MapEntry<String, int>> data;

  const GameModeStatsWidget({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (data.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Text(l10n.noGameData),
        ),
      );
    }

    // Calculer le total pour faire des pourcentages globaux (Camembert aplati)
    final totalPlays = data.fold(0, (sum, item) => sum + item.value);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: data.map((entry) {
          final modeName = entry.key;
          final count = entry.value;
          final percentage = count / totalPlays;

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête : Nom du mode + Pourcentage
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _getModeIcon(modeName),
                        const SizedBox(width: 8),
                        Text(
                          modeName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${(percentage * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                
                // Barre de progression
                Stack(
                  children: [
                    // Fond gris
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    // Barre colorée
                    FractionallySizedBox(
                      widthFactor: percentage,
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: _getModeColor(modeName),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 4),
                
                // Sous-titre : Nombre de parties
                Text(
                  l10n.gamesPlayed(count),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // Helper pour les couleurs
  Color _getModeColor(String modeName) {
    final name = modeName.toLowerCase();
    if (name.contains('classique') || name.contains('classic')) {
      return AppColors.primary;
    } else if (name.contains('inversé') || name.contains('reverse')) {
      return AppColors.secondary;
    } else if (name.contains('quiz')) {
      return Colors.orange;
    }
    return Colors.teal;
  }

  // Helper pour les icônes
  Widget _getModeIcon(String modeName) {
    final name = modeName.toLowerCase();
    IconData icon = Icons.gamepad;
    Color color = _getModeColor(modeName);

    if (name.contains('classique') || name.contains('classic')) {
      icon = Icons.school;
    } else if (name.contains('inversé') || name.contains('reverse')) {
      icon = Icons.swap_horiz;
    } else if (name.contains('quiz')) {
      icon = Icons.timer;
    }

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 16, color: color),
    );
  }
}