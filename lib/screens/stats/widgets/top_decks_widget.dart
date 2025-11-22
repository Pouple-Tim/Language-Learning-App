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
    if (topDecks.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Text('Aucun deck pratiqué'),
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
            padding: const EdgeInsets.only(bottom: 12),
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
    final percentage = maxReviews > 0 ? reviewCount / maxReviews : 0.0;
    final color = _getColorForRank(rank);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Médaille/rang
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: rank <= 3
                    ? Icon(_getMedalIcon(rank), color: color, size: 18)
                    : Text(
                        '$rank',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            
            // Nom du deck
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deckName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$reviewCount révisions',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Barre de progression
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 6,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Color _getColorForRank(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Or
      case 2:
        return const Color(0xFFC0C0C0); // Argent
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return AppColors.primary;
    }
  }

  IconData _getMedalIcon(int rank) {
    switch (rank) {
      case 1:
        return Icons.emoji_events; // Trophée
      case 2:
        return Icons.military_tech; // Médaille
      case 3:
        return Icons.stars; // Étoile
      default:
        return Icons.circle;
    }
  }
}