import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:language_learning_app/core/theme/app_colors.dart';
import 'package:language_learning_app/data/models/game_mode.dart';
import 'package:language_learning_app/providers/game_provider.dart';
import 'package:language_learning_app/providers/deck_provider.dart';
import 'package:language_learning_app/l10n/app_localizations.dart';

class ResetDeckDialog {
  static Future<void> show(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final gameProvider = context.read<GameProvider>();
    final deckProvider = context.read<DeckProvider>();
    final theme = Theme.of(context);
    final deck = deckProvider.selectedDeck;
    if (deck == null) return;

    // Le mode Phrase n'a rien à réinitialiser si ce deck ne contient aucune phrase.
    final resettableModes = [GameType.classic, GameType.reverse, GameType.quiz, GameType.sentence, GameType.listening]
        .where((type) => type != GameType.sentence || deck.sentences.isNotEmpty)
        .toList();
    var selectedMode = gameProvider.currentGameType ?? GameType.classic;
    if (!resettableModes.contains(selectedMode)) {
      selectedMode = resettableModes.first;
    }

    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: theme.cardTheme.color,
          title: Text(
            l10n.resetDeck,
            style: theme.textTheme.titleMedium,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.resetDeckMessage,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<GameType>(
                initialValue: selectedMode,
                decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                items: resettableModes
                    .map((type) => DropdownMenuItem(value: type, child: Text(type.statsLabel)))
                    .toList(),
                onChanged: (type) => setState(() => selectedMode = type!),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 20, color: AppColors.warning),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.statisticsWillBeKept,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.brightness == Brightness.dark
                              ? AppColors.warning
                              : Colors.orange[900],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: theme.textTheme.bodySmall?.color,
              ),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () async {
                await gameProvider.resetAllModesProgress(deck.id);
                await deckProvider.refreshSelectedDeck();
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.deckReset),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: Text(l10n.resetAllModes),
            ),
            FilledButton(
              onPressed: () async {
                await gameProvider.resetModeProgress(deck.id, selectedMode);
                await deckProvider.refreshSelectedDeck();
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.modeReset(selectedMode.statsLabel)),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: Colors.white,
              ),
              child: Text(l10n.resetThisMode),
            ),
          ],
        ),
      ),
    );
  }
}
