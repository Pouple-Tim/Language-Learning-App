import 'package:flutter/material.dart';
import 'package:language_learning_app/core/theme/app_colors.dart';
import 'package:language_learning_app/core/tutorial/tutorial_service.dart';
import 'package:language_learning_app/l10n/app_localizations.dart';

class _OnboardingSlide {
  final IconData icon;
  final String title;
  final String description;

  const _OnboardingSlide({required this.icon, required this.title, required this.description});
}

/// One-time (replayable from Settings) intro screen, shown before Home on
/// first launch. Static content only -- no positioning against live widgets,
/// so it can't suffer the real-device spotlight-misalignment bug the
/// previous tutorial_coach_mark-based tours had.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  List<_OnboardingSlide> _slides(AppLocalizations l10n) => [
        _OnboardingSlide(
          icon: Icons.library_books_outlined,
          title: l10n.onboardingSlide1Title,
          description: l10n.onboardingSlide1Desc,
        ),
        _OnboardingSlide(
          icon: Icons.videogame_asset_outlined,
          title: l10n.onboardingSlide2Title,
          description: l10n.onboardingSlide2Desc,
        ),
        _OnboardingSlide(
          icon: Icons.trending_up,
          title: l10n.onboardingSlide3Title,
          description: l10n.onboardingSlide3Desc,
        ),
        _OnboardingSlide(
          icon: Icons.tune,
          title: l10n.onboardingSlide4Title,
          description: l10n.onboardingSlide4Desc,
        ),
      ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() {
    TutorialService.markOnboardingSeen();
    Navigator.of(context).pop();
  }

  void _next(int slideCount) {
    if (_page == slideCount - 1) {
      _finish();
      return;
    }
    _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final slides = _slides(l10n);
    final isLast = _page == slides.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finish,
                child: Text(l10n.onboardingSkip),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: slides.length,
                onPageChanged: (page) => setState(() => _page = page),
                itemBuilder: (context, index) => _SlideView(slide: slides[index]),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                slides.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: index == _page ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: index == _page ? AppColors.primary : Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => _next(slides.length),
                  child: Text(isLast ? l10n.onboardingStart : l10n.onboardingNext),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  final _OnboardingSlide slide;

  const _SlideView({required this.slide});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // A short device height (or a long translated string) can make this
    // content taller than the space PageView leaves after the skip button,
    // dots and next button -- scroll instead of overflowing, but still
    // center when everything fits (LayoutBuilder + minHeight constraint).
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(slide.icon, size: 64, color: AppColors.primary),
                ),
                const SizedBox(height: 32),
                Text(
                  slide.title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  slide.description,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600, height: 1.4),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
