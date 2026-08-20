import 'package:flutter/material.dart';
import 'package:language_learning_app/core/theme/app_colors.dart';

class GameProgressBar extends StatelessWidget {
  final int total;
  final int remaining;
  final double progress;

  const GameProgressBar({
    super.key,
    required this.total,
    required this.remaining,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${total - remaining}/$total', style: Theme.of(context).textTheme.bodyMedium),
            Text(
              '${progress.toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress / 100,
            minHeight: 10,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ],
    );
  }
}
