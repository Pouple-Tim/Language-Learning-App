import 'package:flutter/material.dart';
import 'package:language_learning_app/providers/deck_provider.dart';
import 'package:language_learning_app/core/theme/app_colors.dart';
import 'package:language_learning_app/core/extensions/deck_extensions.dart';

class TopDecksWidget extends StatelessWidget {
  final List<MapEntry<String, int>> topDecks;
  final DeckProvider deckProvider;

  const TopDecksWidget({
    super.key,
    required this.topDecks,
    required this.deckProvider,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (topDecks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(
            'Aucun deck pratiqué', // Idéalement à mettre dans l10n
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
        ),
      );
    }

    final maxReviews = topDecks.first.value;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: topDecks.asMap().entries.map((entry) {
          final index = entry.key;
          final deckId = entry.value.key;
          final reviewCount = entry.value.value;
          
          // Trouver le deck correspondant
          final deck = deckProvider.allDecks.firstWhere(
            (d) => d.id == deckId,
            orElse: () => deckProvider.allDecks.first,
          );

          return Padding(
            padding: const EdgeInsets.only(bottom: 16), // Espacement légèrement augmenté
            child: _buildDeckItem(
              context,
              index + 1,
              deck.localizedName(context),
              reviewCount,
              maxReviews,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDeckItem(
    BuildContext context,
    int rank,
    String deckName,
    int reviewCount,
    int maxReviews,
  ) {
    final theme = Theme.of(context);
    final percentage = maxReviews > 0 ? reviewCount / maxReviews : 0.0;
    final color = _getColorForRank(rank);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Médaille/rang
            Container(
              width: 36, // Un peu plus grand pour l'accessibilité
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: rank <= 3
                    ? Icon(_getMedalIcon(rank), color: color, size: 20)
                    : Text(
                        '$rank',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: color,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Nom du deck et stats
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deckName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$reviewCount révisions',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        
        // Barre de progression
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 6,
            // S'adapte au mode sombre (gris clair vs gris foncé)
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Color _getColorForRank(int rank) {
    switch (rank) {
      case 1:
        return AppColors.gold;
      case 2:
        return AppColors.silver;
      case 3:
        return AppColors.bronze;
      default:
        return AppColors.primary;
    }
  }

  IconData _getMedalIcon(int rank) {
    switch (rank) {
      case 1:
        return Icons.emoji_events_rounded; 
      case 2:
        return Icons.military_tech_rounded; 
      case 3:
        return Icons.stars_rounded; 
      default:
        return Icons.circle;
    }
  }
}