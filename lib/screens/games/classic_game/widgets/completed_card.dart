import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:language_learning_app/core/theme/app_colors.dart';
import 'package:language_learning_app/data/models/game_mode.dart';
import 'package:language_learning_app/l10n/app_localizations.dart';
import 'package:language_learning_app/providers/game_provider.dart';
import 'package:language_learning_app/providers/statistics_provider.dart';
import 'package:language_learning_app/providers/goal_provider.dart';
import 'package:language_learning_app/providers/srs_provider.dart';

class CompletedCard extends StatefulWidget {
  final VoidCallback onRestart;

  const CompletedCard({super.key, required this.onRestart});

  @override
  State<CompletedCard> createState() => _CompletedCardState();
}

class _CompletedCardState extends State<CompletedCard> {
  bool _reviewExpanded = false;

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
      child: SingleChildScrollView(
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
            _buildSessionSummary(context),
            _buildGoalProgress(context),
            _buildNextReview(context),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: widget.onRestart,
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

  Widget _buildSessionSummary(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final game = context.watch<GameProvider>();
    final learned = game.sessionLearnedCount;
    if (learned == 0) return const SizedBox.shrink();

    final firstTry = game.sessionFirstTryCount;
    final toReview = game.sessionToReviewCount;
    final reviewItems = game.sessionWordsToReview;
    final textTheme = Theme.of(context).textTheme;

    Widget chip(String label, {VoidCallback? onTap, bool trailingChevron = false}) {
      final content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: textTheme.bodyMedium),
          if (trailingChevron)
            Icon(
              _reviewExpanded ? Icons.expand_less : Icons.expand_more,
              size: 18,
            ),
        ],
      );
      final padded = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: content,
      );
      final decorated = Container(
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: onTap == null
            ? padded
            : InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: onTap,
                child: padded,
              ),
      );
      return decorated;
    }

    return Column(
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            chip(l10n.sessionSummaryLearned(learned)),
            if (firstTry < learned)
              chip(l10n.sessionSummaryFirstTry(firstTry)),
            if (toReview > 0)
              chip(
                l10n.sessionSummaryToReview(toReview),
                trailingChevron: true,
                onTap: () =>
                    setState(() => _reviewExpanded = !_reviewExpanded),
              )
            else if (firstTry == learned)
              chip(l10n.sessionSummaryPerfect),
          ],
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: _reviewExpanded && reviewItems.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    children: [
                      for (final item in reviewItems)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  item.prompt,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                              const Padding(
                                padding:
                                    EdgeInsets.symmetric(horizontal: 8),
                                child: Icon(Icons.arrow_forward, size: 14),
                              ),
                              Flexible(
                                child: Text(
                                  item.answer,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildNextReview(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final game = context.watch<GameProvider>();
    final srs = context.watch<SrsProvider>();
    final deck = game.currentDeck;
    if (deck == null || game.currentGameType == null) {
      return const SizedBox.shrink();
    }

    final modeId = game.currentGameType!.storageId;
    final keys = game.currentGameType == GameType.sentence
        ? deck.sentences.map((s) => '${deck.id}::${s.id}::$modeId').toList()
        : deck.words.map((w) => '${w.id}::$modeId').toList();

    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final n = srs.dueOn(keys, tomorrow);

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(
        l10n.nextReviewLine(n),
        style: Theme.of(context).textTheme.bodySmall,
        textAlign: TextAlign.center,
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
