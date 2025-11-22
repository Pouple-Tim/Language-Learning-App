import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:language_learning_app/core/theme/app_colors.dart';

class HeatmapWidget extends StatelessWidget {
  final Map<DateTime, int> data;

  const HeatmapWidget({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month - 1, now.day);
    
    // Créer une liste de tous les jours du dernier mois
    final days = <DateTime>[];
    for (int i = 0; i < 30; i++) {
      days.add(DateTime(startDate.year, startDate.month, startDate.day + i));
    }

    // Trouver la valeur maximale pour la normalisation
    final maxValue = data.values.isNotEmpty 
        ? data.values.reduce((a, b) => a > b ? a : b).toDouble()
        : 1.0;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: days.map((day) {
              final value = data[day] ?? 0;
              final intensity = maxValue > 0 ? value / maxValue : 0.0;
              
              return _buildDayCell(day, value, intensity);
            }).toList(),
          ),
          const SizedBox(height: 16),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildDayCell(DateTime day, int value, double intensity) {
    final color = _getColorForIntensity(intensity);
    final isToday = DateTime.now().day == day.day && 
                    DateTime.now().month == day.month;

    return Tooltip(
      message: '${DateFormat('d MMM', 'fr').format(day)}: $value révisions',
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
          border: isToday
              ? Border.all(color: AppColors.primary, width: 2)
              : null,
        ),
        child: value > 0
            ? Center(
                child: Text(
                  '$value',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: intensity > 0.5 ? Colors.white : AppColors.primary,
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Color _getColorForIntensity(double intensity) {
    if (intensity == 0) {
      return Colors.grey.shade200;
    } else if (intensity < 0.25) {
      return AppColors.primary.withValues(alpha: 0.3);
    } else if (intensity < 0.5) {
      return AppColors.primary.withValues(alpha: 0.5);
    } else if (intensity < 0.75) {
      return AppColors.primary.withValues(alpha: 0.7);
    } else {
      return AppColors.primary;
    }
  }

  Widget _buildLegend() {
    return Row(
      children: [
        Text(
          'Moins',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
        const SizedBox(width: 8),
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Plus',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}