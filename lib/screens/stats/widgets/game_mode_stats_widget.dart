import 'package:flutter/material.dart';
import 'package:language_learning_app/core/theme/app_colors.dart';
import 'package:language_learning_app/data/models/game_mode.dart';
import 'package:language_learning_app/providers/statistics_provider.dart';
import 'package:language_learning_app/l10n/app_localizations.dart';

class GameModeStatsWidget extends StatelessWidget {
  final List<GameModeStat> data;

  const GameModeStatsWidget({
    super.key,
    required this.data,
  });

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

    final totalPlays = data.fold<int>(0, (sum, item) => sum + item.count);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: data.map((stat) {
          final color = _getModeColor(stat.type);
          final percentage = totalPlays > 0 ? stat.count / totalPlays : 0.0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(_getModeIcon(stat.type), size: 18, color: color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        stat.label,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
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
                Stack(
                  children: [
                    Container(
                      height: 8,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    if (percentage > 0)
                      FractionallySizedBox(
                        widthFactor: percentage,
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    l10n.gamesPlayed(stat.count),
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

  Color _getModeColor(GameType type) {
    switch (type) {
      case GameType.classic:
        return AppColors.primary;
      case GameType.reverse:
        return AppColors.secondary;
      case GameType.quiz:
        return Colors.orange;
      case GameType.sentence:
      case GameType.memory:
        return Colors.teal;
    }
  }

  IconData _getModeIcon(GameType type) {
    switch (type) {
      case GameType.classic:
        return Icons.school;
      case GameType.reverse:
        return Icons.swap_horiz;
      case GameType.quiz:
        return Icons.timer;
      case GameType.sentence:
      case GameType.memory:
        return Icons.gamepad;
    }
  }
}
