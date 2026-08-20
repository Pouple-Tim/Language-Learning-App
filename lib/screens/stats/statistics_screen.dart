import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:language_learning_app/providers/statistics_provider.dart';
import 'package:language_learning_app/providers/deck_provider.dart';
import 'package:language_learning_app/l10n/app_localizations.dart';
import 'package:language_learning_app/core/theme/app_colors.dart';
import 'widgets/line_chart_widget.dart';
import 'widgets/heatmap_widget.dart';
import 'widgets/top_decks_widget.dart';
import 'widgets/stats_card.dart';
import 'widgets/game_mode_stats_widget.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.statistics),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Consumer2<StatisticsProvider, DeckProvider>(
              builder: (context, statsProvider, deckProvider, _) {
                if (statsProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final hasData = statsProvider.history.entries.isNotEmpty;

                if (!hasData) {
                  return _buildEmptyState(context, l10n);
                }

                return ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Cartes de statistiques principales
                    _buildStatsCards(context, statsProvider, l10n),
                    
                    const SizedBox(height: 24),

                    // Graphique linéaire - 7 derniers jours
                    _buildSection(
                      context,
                      title: l10n.last7Days,
                      icon: Icons.trending_up,
                      child: LineChartWidget(
                        data: statsProvider.getReviewsPerDay(7),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Heatmap - Activité mensuelle
                    _buildSection(
                      context,
                      title: l10n.monthlyActivity,
                      icon: Icons.calendar_today,
                      child: HeatmapWidget(
                        data: statsProvider.getMonthlyActivity(),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Top 5 decks
                    _buildSection(
                      context,
                      title: l10n.topDecks,
                      icon: Icons.emoji_events,
                      child: TopDecksWidget(
                        topDecks: statsProvider.getTopDecks(),
                        deckProvider: deckProvider,
                      ),
                    ),

                    const SizedBox(height: 24),

                    _buildSection(
                      context,
                      title: l10n.favoriteGameModes,
                      icon: Icons.pie_chart,
                      child: GameModeStatsWidget(
                        data: statsProvider.getGameModeStats(),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? Colors.grey[600] : Colors.grey.shade400;
    final titleColor = isDark ? Colors.grey[300] : Colors.grey.shade700;
    final subtitleColor = isDark ? Colors.grey[500] : Colors.grey.shade500;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart,
              size: 80,
              color: iconColor,
            ),
            const SizedBox(height: 24),
            Text(
              l10n.noStatistics,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.startReviewing,
              style: TextStyle(
                fontSize: 14,
                color: subtitleColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards(
    BuildContext context,
    StatisticsProvider provider,
    AppLocalizations l10n,
  ) {
    return Row(
      children: [
        Expanded(
          child: StatsCard(
            title: l10n.currentStreak,
            value: '${provider.getCurrentStreak()}',
            subtitle: l10n.days,
            icon: Icons.local_fire_department,
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatsCard(
            title: l10n.wordsLearned,
            value: '${provider.getTotalWordsLearned()}',
            subtitle: l10n.learned,
            icon: Icons.school,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? Colors.grey[850] : Colors.white;
    final titleColor = isDark ? Colors.white : Colors.black;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}