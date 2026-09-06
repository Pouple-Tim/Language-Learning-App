import 'package:flutter/material.dart';
import 'package:language_learning_app/core/goal/daily_goal.dart';
import 'package:language_learning_app/core/theme/app_colors.dart';
import 'package:language_learning_app/l10n/app_localizations.dart';
import 'package:language_learning_app/providers/goal_provider.dart';

/// Bottom sheet to pick the daily goal level (Léger / Normal / Intense).
/// Mirrors [LanguageBottomSheet]'s presentation.
class GoalBottomSheet {
  static Future<void> show(BuildContext context, GoalProvider goalProvider) async {
    return showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle de drag
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            for (final level in DailyGoalLevel.values)
              _buildGoalItem(context, goalProvider, level),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  static Widget _buildGoalItem(
    BuildContext context,
    GoalProvider provider,
    DailyGoalLevel level,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final isSelected = provider.level == level;
    final name = switch (level) {
      DailyGoalLevel.light => l10n.dailyGoalLight,
      DailyGoalLevel.normal => l10n.dailyGoalNormal,
      DailyGoalLevel.intense => l10n.dailyGoalIntense,
    };

    return ListTile(
      title: Text(
        name,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(l10n.dailyGoalPerDay(goalTarget(level))),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: AppColors.primary)
          : null,
      onTap: () {
        provider.setLevel(level);
        Navigator.pop(context);
      },
    );
  }
}
