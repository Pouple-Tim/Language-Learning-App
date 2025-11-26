import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:language_learning_app/core/theme/app_colors.dart';
import 'package:language_learning_app/l10n/app_localizations.dart';

class HeatmapWidget extends StatelessWidget {
  final Map<DateTime, int> data;

  const HeatmapWidget({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Récupération des outils de localisation une seule fois ici
    final l10n = AppLocalizations.of(context)!;
    final String localeCode = Localizations.localeOf(context).languageCode;
    final DateFormat dateFormatter = DateFormat.MMMd(localeCode);

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
              // Normaliser la date pour correspondre aux clés de la map (sans l'heure)
              final dateKey = DateTime(day.year, day.month, day.day);
              final value = data[dateKey] ?? 0;
              
              final intensity = maxValue > 0 ? value / maxValue : 0.0;
              
              // 2. On passe l10n et dateFormatter aux enfants
              return _buildDayCell(day, value, intensity, l10n, dateFormatter);
            }).toList(),
          ),
          const SizedBox(height: 16),
          _buildLegend(l10n),
        ],
      ),
    );
  }

  Widget _buildDayCell(
    DateTime day, 
    int value, 
    double intensity, 
    AppLocalizations l10n, 
    DateFormat dateFormatter
  ) {
    final color = _getColorForIntensity(intensity);
    final isToday = DateTime.now().day == day.day && 
                    DateTime.now().month == day.month;
    
    // Utilisation du formatteur passé en paramètre
    final String dateStr = dateFormatter.format(day);
    final tooltip = l10n.revisionsTooltip(dateStr, value);

    return Tooltip(
      message: tooltip,
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

  Widget _buildLegend(AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end, // Alignement à droite souvent plus joli pour la légende
      children: [
        Text(
          l10n.less, // Correction : Pas de double Text()
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
        const SizedBox(width: 8),
        _buildLegendBox(Colors.grey.shade200),
        const SizedBox(width: 4),
        _buildLegendBox(AppColors.primary.withValues(alpha: 0.3)),
        const SizedBox(width: 4),
        _buildLegendBox(AppColors.primary.withValues(alpha: 0.6)),
        const SizedBox(width: 4),
        _buildLegendBox(AppColors.primary),
        const SizedBox(width: 8),
        Text(
          l10n.more, // Correction : Pas de double Text()
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildLegendBox(Color color) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}