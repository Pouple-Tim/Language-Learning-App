import 'package:flutter/material.dart';
import 'package:language_learning_app/data/models/word.dart';
import 'package:language_learning_app/core/theme/app_colors.dart';
import 'package:language_learning_app/l10n/app_localizations.dart';


class WordListTile extends StatelessWidget {
  final int index;
  final Word word;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const WordListTile({
    super.key,
    required this.index,
    required this.word,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Dismissible(
      key: ValueKey(word.hashCode), // Idéalement utiliser word.id si disponible
      direction: DismissDirection.endToStart,
      background: Container(
        color: AppColors.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            word.prompt,
            style: const TextStyle(fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            word.answer,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: IconButton(
            icon: const Icon(Icons.edit, size: 20),
            onPressed: onEdit,
            tooltip: l10n.edit,
          ),
        ),
      ),
    );
  }
}