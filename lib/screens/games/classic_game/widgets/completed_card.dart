import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:language_learning_app/core/theme/app_colors.dart';
import 'package:language_learning_app/l10n/app_localizations.dart';
import 'package:language_learning_app/providers/statistics_provider.dart';
import 'package:language_learning_app/providers/goal_provider.dart';

class CompletedCard extends StatelessWidget {
  final VoidCallback onRestart;

  const CompletedCard({super.key, required this.onRestart});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      elevation: 0,
      color: AppColors.success.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.success, width: 2),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.celebration, size: 60, color: AppColors.success),
            const SizedBox(height: 16),
            Text(
              l10n.completed,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.completedMessage,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _buildGoalProgress(context),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onRestart,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.restart),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalProgress(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final stats = context.watch<StatisticsProvider>();
    final done = stats.reviewsToday();
    final streak = stats.getCurrentStreak();
    final target = context.watch<GoalProvider>().target;
    final reached = done >= target;
    final ratio = target == 0 ? 1.0 : (done / target).clamp(0.0, 1.0);

    return Column(
      children: [
        SizedBox(
          height: 96,
          width: 96,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: ratio,
                  strokeWidth: 8,
                  backgroundColor: AppColors.success.withValues(alpha: 0.15),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.success),
                ),
              ),
              Text(
                '$done / $target',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          reached
              ? l10n.dailyGoalReached
              : l10n.dailyGoalReviewsToday(done, target),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: reached ? FontWeight.bold : FontWeight.normal,
                color: reached ? AppColors.success : null,
              ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_fire_department,
                color: Colors.orange, size: 18),
            const SizedBox(width: 4),
            Text(l10n.dayCount(streak),
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ],
    );
  }
}
