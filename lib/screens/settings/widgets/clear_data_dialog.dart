import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:language_learning_app/core/theme/app_colors.dart';
import 'package:language_learning_app/core/utils/storage_helper.dart';
import 'package:language_learning_app/providers/statistics_provider.dart';
import 'package:language_learning_app/l10n/app_localizations.dart';

class ClearDataDialog {
  static Future<void> show(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.warning, style: const TextStyle(color: AppColors.error)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.clearDataWarning),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: AppColors.error),
                      const SizedBox(width: 8),
                      Text(
                        l10n.dataWillBeDeleted,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• ${l10n.deckProgress}\n'
                    '• ${l10n.statistics}\n'
                    '• ${l10n.preferences}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel, style: const TextStyle(color: Colors.grey)),
          ),
          FilledButton(
            onPressed: () async {
              // ⭐ Supprimer les statistiques
              await context.read<StatisticsProvider>().clearHistory();
              
              // ⭐ Supprimer toutes les autres données
              await StorageHelper.clear();
              
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.allDataCleared),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(l10n.clearAll),
          ),
        ],
      ),
    );
  }
}