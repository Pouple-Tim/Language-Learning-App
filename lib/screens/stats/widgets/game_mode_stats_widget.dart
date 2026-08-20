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
          child: Text(l10n.noGameData),
        ),
      );
    }

    final totalPlays = data.fold(0, (sum, item) => sum + item.count);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: data.map((stat) {
          final percentage = stat.count / totalPlays;

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _getModeIcon(stat.type),
                        const SizedBox(width: 8),
                        Text(
                          stat.label,
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
                Stack(
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: percentage,
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: _getModeColor(stat.type),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.gamesPlayed(stat.count),
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

  Widget _getModeIcon(GameType type) {
    IconData icon;
    switch (type) {
      case GameType.classic:
        icon = Icons.school;
        break;
      case GameType.reverse:
        icon = Icons.swap_horiz;
        break;
      case GameType.quiz:
        icon = Icons.timer;
        break;
      case GameType.sentence:
      case GameType.memory:
        icon = Icons.gamepad;
    }
    final color = _getModeColor(type);

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
