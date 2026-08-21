import 'package:flutter/material.dart';
import 'package:language_learning_app/l10n/app_localizations.dart';

class NoSentencesCard extends StatelessWidget {
  const NoSentencesCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final iconColor = theme.brightness == Brightness.dark ? Colors.grey[600] : Colors.grey.shade400;
    final textColor = theme.brightness == Brightness.dark ? Colors.grey[400] : Colors.grey.shade600;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.segment_rounded, size: 60, color: iconColor),
          const SizedBox(height: 16),
          Text(
            l10n.noSentencesInDeck,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
          ),
        ],
      ),
    );
  }
}
