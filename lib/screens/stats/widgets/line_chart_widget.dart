import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection; 
import 'package:language_learning_app/core/theme/app_colors.dart';

class LineChartWidget extends StatelessWidget {
  final Map<DateTime, int> data;

  const LineChartWidget({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Text('Aucune donnée disponible'),
        ),
      );
    }

    // Récupération de la locale actuelle pour le formatage
    final locale = Localizations.localeOf(context).toString();
    
    final sortedDates = data.keys.toList()..sort();
    final maxValue = data.values.fold<int>(0, (prev, element) => element > prev ? element : prev).toDouble();
    // Petit ajustement pour éviter que le point le plus haut ne touche le plafond du graphique
    final adjustedMax = maxValue == 0 ? 10.0 : maxValue * 1.2;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: 1.7, // Ratio optimisé pour mobile (plus large que haut)
            child: CustomPaint(
              painter: _LineChartPainter(
                data: data,
                sortedDates: sortedDates,
                maxValue: adjustedMax,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildLegend(sortedDates, locale),
        ],
      ),
    );
  }

  Widget _buildLegend(List<DateTime> dates, String locale) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween, // Mieux réparti
      children: dates.map((date) {
        // 'E' donne le jour abrégé (Lun., Mon., etc.) selon la locale
        final dayName = toBeginningOfSentenceCase(DateFormat.E(locale).format(date));
        
        // On limite à 3 caractères max pour éviter les débordements sur petits écrans
        final shortName = dayName.length > 3 ? dayName.substring(0, 3) : dayName;

        return Expanded(
          child: Text(
            shortName,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final Map<DateTime, int> data;
  final List<DateTime> sortedDates;
  final double maxValue;

  _LineChartPainter({
    required this.data,
    required this.sortedDates,
    required this.maxValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (sortedDates.isEmpty) return;

    // Définition des styles
    final linePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.15) // Légèrement plus visible
      ..style = PaintingStyle.fill;

    final dotPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    final dotBorderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final gridPaint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 1;

    // 1. Dessiner la grille (arrière-plan)
    const int gridLines = 4;
    for (int i = 0; i <= gridLines; i++) {
      final y = size.height * i / gridLines;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }

    // 2. Calculer les coordonnées des points
    final points = <Offset>[];
    // Éviter la division par zéro si un seul point
    final spacing = sortedDates.length > 1 
        ? size.width / (sortedDates.length - 1) 
        : 0.0;

    for (int i = 0; i < sortedDates.length; i++) {
      final date = sortedDates[i];
      final value = data[date] ?? 0;
      
      // Si un seul point, on le centre
      final x = sortedDates.length > 1 ? i * spacing : size.width / 2;
      final y = size.height - (value / maxValue * size.height);
      points.add(Offset(x, y));
    }

    if (points.isEmpty) return;

    // 3. Création du chemin courbe (Path)
    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final current = points[i];
      final next = points[i + 1];
      
      // Lissage de Bézier
      final controlPoint1 = Offset(
        current.dx + (next.dx - current.dx) / 2,
        current.dy,
      );
      final controlPoint2 = Offset(
        current.dx + (next.dx - current.dx) / 2,
        next.dy,
      );

      path.cubicTo(
        controlPoint1.dx, controlPoint1.dy,
        controlPoint2.dx, controlPoint2.dy,
        next.dx, next.dy,
      );
    }

    // 4. Dessiner le remplissage (Fill)
    // On copie le chemin de la ligne pour le fermer vers le bas
    final fillPath = Path.from(path);
    fillPath.lineTo(points.last.dx, size.height);
    fillPath.lineTo(points.first.dx, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);

    // 5. Dessiner la ligne par-dessus le remplissage
    canvas.drawPath(path, linePaint);

    // 6. Dessiner les points et les étiquettes
    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      final value = data[sortedDates[i]] ?? 0;

      // Cercle extérieur (bordure blanche)
      canvas.drawCircle(point, 6, dotBorderPaint);
      // Cercle intérieur
      canvas.drawCircle(point, 4, dotPaint);

      // Afficher la valeur au-dessus du point
      if (value > 0) {
        final textSpan = TextSpan(
          text: '$value',
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        );

        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );
        
        textPainter.layout();
        
        // Centrer le texte horizontalement par rapport au point
        // Et le placer un peu plus haut pour ne pas chevaucher le point
        textPainter.paint(
          canvas,
          Offset(
            point.dx - textPainter.width / 2,
            point.dy - 22, 
          ),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    // Optimisation : on ne repeint que si les données changent
    return oldDelegate.data != data || 
           oldDelegate.maxValue != maxValue ||
           oldDelegate.sortedDates != sortedDates;
  }
}