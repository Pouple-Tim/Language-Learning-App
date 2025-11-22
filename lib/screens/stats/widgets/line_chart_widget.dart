import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection; // ⭐ IMPORTANT: hide TextDirection
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

    final sortedDates = data.keys.toList()..sort();
    final maxValue = data.values.reduce((a, b) => a > b ? a : b).toDouble();
    final adjustedMax = maxValue == 0 ? 10.0 : maxValue * 1.2;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: CustomPaint(
              size: const Size(double.infinity, 200),
              painter: _LineChartPainter(
                data: data,
                sortedDates: sortedDates,
                maxValue: adjustedMax,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildLegend(sortedDates),
        ],
      ),
    );
  }

  Widget _buildLegend(List<DateTime> dates) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: dates.map((date) {
        final dayName = DateFormat('E', 'fr').format(date);
        return Text(
          dayName.substring(0, 3),
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
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

    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final dotPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    final gridPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;

    // Dessiner la grille horizontale
    for (int i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }

    // Calculer les points
    final points = <Offset>[];
    final spacing = size.width / (sortedDates.length - 1);

    for (int i = 0; i < sortedDates.length; i++) {
      final date = sortedDates[i];
      final value = data[date] ?? 0;
      final x = i * spacing;
      final y = size.height - (value / maxValue * size.height);
      points.add(Offset(x, y));
    }

    // Dessiner l'aire sous la courbe
    if (points.length > 1) {
      final path = Path();
      path.moveTo(points.first.dx, size.height);
      for (final point in points) {
        path.lineTo(point.dx, point.dy);
      }
      path.lineTo(points.last.dx, size.height);
      path.close();
      canvas.drawPath(path, fillPaint);
    }

    // Dessiner la ligne
    if (points.length > 1) {
      final path = Path();
      path.moveTo(points.first.dx, points.first.dy);
      
      for (int i = 0; i < points.length - 1; i++) {
        final current = points[i];
        final next = points[i + 1];
        final controlPoint1 = Offset(
          current.dx + (next.dx - current.dx) / 3,
          current.dy,
        );
        final controlPoint2 = Offset(
          current.dx + 2 * (next.dx - current.dx) / 3,
          next.dy,
        );
        path.cubicTo(
          controlPoint1.dx,
          controlPoint1.dy,
          controlPoint2.dx,
          controlPoint2.dy,
          next.dx,
          next.dy,
        );
      }
      
      canvas.drawPath(path, paint);
    }

    // Dessiner les points
    for (final point in points) {
      canvas.drawCircle(point, 5, dotPaint);
      canvas.drawCircle(point, 5, Paint()
        ..color = Colors.white
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke);
    }

    // Dessiner les valeurs
    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      final value = data[sortedDates[i]] ?? 0;
      
      if (value > 0) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: '$value',
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(
            point.dx - textPainter.width / 2,
            point.dy - 20,
          ),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}