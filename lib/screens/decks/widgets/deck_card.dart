import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:language_learning_app/data/models/deck.dart';
import 'package:language_learning_app/core/theme/app_colors.dart';
import 'package:language_learning_app/l10n/app_localizations.dart';
import 'package:language_learning_app/providers/deck_provider.dart';
import 'package:language_learning_app/core/extensions/deck_extensions.dart';

class DeckCard extends StatelessWidget {
  final Deck deck;
  final bool isBase;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final Function(Deck)? onEdit;
  final Function(Deck)? onDelete;

  const DeckCard({
    super.key,
    required this.deck,
    required this.isBase,
    required this.onTap,
    required this.onLongPress,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final deckProvider = context.watch<DeckProvider>();
    final isSelected = deckProvider.selectedDeck?.id == deck.id;
    final metadata = isBase ? deckProvider.repository.getDeckMetadata(deck.id) : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? const BorderSide(color: AppColors.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDeckIcon(isSelected),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // CORRECTION 1 : Le titre s'affiche en entier
                    Text(
                      deck.localizedName(context),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      ),
                      // Pas de maxLines, pas d'overflow ellipsis -> le texte va à la ligne
                    ),
                    const SizedBox(height: 4),
                    
                    // CORRECTION 2 : Utilisation de Wrap au lieu de Row
                    // Cela permet aux éléments de passer à la ligne suivante s'il n'y a pas assez de place
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,    // Espace horizontal entre les éléments
                      runSpacing: 4, // Espace vertical si ça passe à la ligne
                      children: [
                        // Groupe Icône + Texte nombre de mots
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.style, size: 12, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Text(
                              l10n.totalWords(deck.totalWords),
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                        
                        // Difficulté
                        if (metadata?.difficulty != null)
                          _buildDifficultyChip(context, metadata!.difficulty, l10n),
                      ],
                    ),
                    
                    if (deck.progress > 0) ...[
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: deck.progress / 100,
                          minHeight: 4,
                          backgroundColor: Colors.grey.shade300,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            deck.isCompleted ? AppColors.success : AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _buildActions(context, isSelected, l10n),
            ],
          ),
        ),
      ),
    );
  }

  // ... (Le reste : _buildDeckIcon, _buildDifficultyChip, _buildActions reste identique)
  Widget _buildDeckIcon(bool isSelected) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.2)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        deck.inputType == InputType.text ? Icons.keyboard : Icons.draw,
        color: isSelected ? AppColors.primary : Colors.grey.shade600,
        size: 20,
      ),
    );
  }

  Widget _buildDifficultyChip(BuildContext context, String difficulty, AppLocalizations l10n) {
    final (color, label) = switch (difficulty) {
      'beginner' => (AppColors.success, l10n.beginner),
      'intermediate' => (AppColors.warning, l10n.intermediate),
      'advanced' => (AppColors.error, l10n.advanced),
      _ => (Colors.grey, difficulty),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildActions(BuildContext context, bool isSelected, AppLocalizations l10n) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.visibility, size: 20),
          onPressed: onLongPress,
          tooltip: 'Prévisualiser',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 4),
        if (isSelected)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 16),
          ),
        if (!isBase)
          PopupMenuButton(
            icon: const Icon(Icons.more_vert, size: 20),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    const Icon(Icons.edit, size: 18),
                    const SizedBox(width: 12),
                    Text(l10n.edit),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete, color: AppColors.error, size: 18),
                    const SizedBox(width: 12),
                    Text(l10n.delete, style: const TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'edit' && onEdit != null) onEdit!(deck);
              if (value == 'delete' && onDelete != null) onDelete!(deck);
            },
          ),
      ],
    );
  }
}