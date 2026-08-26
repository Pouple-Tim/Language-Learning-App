import 'package:flutter/material.dart';
import 'package:language_learning_app/core/theme/app_colors.dart';
import 'package:language_learning_app/l10n/app_localizations.dart';

class _GuidePage {
  final IconData icon;
  final Color color;
  final String title;
  final String goal;
  final String howTo;

  const _GuidePage({
    required this.icon,
    required this.color,
    required this.title,
    required this.goal,
    required this.howTo,
  });
}

/// Full-screen, swipeable explanation of each game mode's goal and rules --
/// reachable from Settings > Tutoriels. Separate from the in-game coachmark
/// tours, which only orient the player to on-screen UI elements.
class GameGuideScreen extends StatefulWidget {
  const GameGuideScreen({super.key});

  @override
  State<GameGuideScreen> createState() => _GameGuideScreenState();
}

class _GameGuideScreenState extends State<GameGuideScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_GuidePage> _pages(AppLocalizations l10n) => [
        _GuidePage(
          icon: Icons.school_rounded,
          color: AppColors.primary,
          title: l10n.classicModeTitle,
          goal: l10n.classicModeGoal,
          howTo: l10n.classicModeHowTo,
        ),
        _GuidePage(
          icon: Icons.swap_horiz_rounded,
          color: AppColors.secondary,
          title: l10n.reverseModeTitle,
          goal: l10n.reverseModeGoal,
          howTo: l10n.reverseModeHowTo,
        ),
        _GuidePage(
          icon: Icons.quiz_rounded,
          color: Colors.orange,
          title: l10n.quizModeTitle,
          goal: l10n.quizModeGoal,
          howTo: l10n.quizModeHowTo,
        ),
        _GuidePage(
          icon: Icons.headphones_rounded,
          color: Colors.teal,
          title: l10n.listeningModeTitle,
          goal: l10n.listeningModeGoal,
          howTo: l10n.listeningModeHowTo,
        ),
        _GuidePage(
          icon: Icons.segment_rounded,
          color: Colors.purple,
          title: l10n.sentenceModeTitle,
          goal: l10n.sentenceModeGoal,
          howTo: l10n.sentenceModeHowTo,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pages = _pages(l10n);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.gameGuideScreenTitle)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) => _buildPage(context, pages[i]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(pages.length, (i) {
                  final active = i == _page;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: active ? pages[_page].color : Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(BuildContext context, _GuidePage page) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: page.color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(page.icon, size: 48, color: page.color),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              page.title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 28),
          _buildLabel(l10n.gameGuideGoalLabel, page.color),
          const SizedBox(height: 8),
          Text(page.goal, style: const TextStyle(fontSize: 15, height: 1.4)),
          const SizedBox(height: 24),
          _buildLabel(l10n.gameGuideHowToLabel, page.color),
          const SizedBox(height: 8),
          Text(page.howTo, style: const TextStyle(fontSize: 15, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, Color color) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.8,
        color: color,
      ),
    );
  }
}
