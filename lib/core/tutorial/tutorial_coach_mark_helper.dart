import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:language_learning_app/core/theme/app_colors.dart';

/// Builds one spotlighted step for a tutorial, styled consistently across all tours.
///
/// tutorial_coach_mark (1.3.3) measures [keyTarget]'s RenderBox via
/// `Future.delayed(Duration.zero, ...)` internally (see
/// AnimatedFocusLight._runFocus) -- a timer, not a frame callback. That's
/// only safe once the screen's layout has actually settled. Callers
/// triggered from an async listener (Decks/Game tours, once their provider
/// finishes loading) must call showTutorial() from within a real
/// WidgetsBinding.instance.addPostFrameCallback first, so this always runs
/// against a completed frame.
TargetFocus buildTutorialTarget({
  required String identify,
  required GlobalKey keyTarget,
  required String title,
  required String description,
  ContentAlign align = ContentAlign.bottom,
}) {
  return TargetFocus(
    identify: identify,
    keyTarget: keyTarget,
    shape: ShapeLightFocus.RRect,
    radius: 12,
    contents: [
      TargetContent(
        align: align,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    ],
  );
}

/// Shows a tour made of [targets], one spotlighted step at a time.
void showTutorial({
  required BuildContext context,
  required List<TargetFocus> targets,
  required String skipLabel,
  VoidCallback? onFinish,
}) {
  TutorialCoachMark(
    targets: targets,
    colorShadow: AppColors.primary,
    opacityShadow: 0.85,
    textSkip: skipLabel,
    textStyleSkip: const TextStyle(
      color: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.bold,
    ),
    // Bottom-right is where this app puts its FABs (e.g. "create a deck"),
    // so a bottom-right skip button collides with bottom-right content
    // bubbles. Bottom-left stays clear of every current tour's content.
    alignSkip: Alignment.bottomLeft,
    onFinish: onFinish,
    pulseEnable: false,
  ).show(context: context);
}
