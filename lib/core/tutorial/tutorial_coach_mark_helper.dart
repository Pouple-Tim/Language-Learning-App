import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:language_learning_app/core/theme/app_colors.dart';

/// Measures [key]'s current on-screen rect directly, instead of letting
/// tutorial_coach_mark measure it via [TargetFocus.keyTarget]. The package
/// (1.3.3) schedules that measurement with `Future.delayed(Duration.zero)`
/// (see AnimatedFocusLight._runFocus) -- a timer, not a frame callback, so
/// it can read a stale/mid-layout RenderBox when the tour is triggered from
/// an async listener (as the Decks/Game tours are, once their provider
/// finishes loading) rather than a screen's own first frame. Callers must
/// only call this once a real frame has completed (e.g. from
/// WidgetsBinding.instance.addPostFrameCallback), or it'll just move the
/// same race earlier.
TargetPosition _measureTarget(GlobalKey key) {
  final renderBox = key.currentContext!.findRenderObject() as RenderBox;
  return TargetPosition(renderBox.size, renderBox.localToGlobal(Offset.zero));
}

/// Builds one spotlighted step for a tutorial, styled consistently across all tours.
TargetFocus buildTutorialTarget({
  required String identify,
  required GlobalKey keyTarget,
  required String title,
  required String description,
  ContentAlign align = ContentAlign.bottom,
}) {
  return TargetFocus(
    identify: identify,
    targetPosition: _measureTarget(keyTarget),
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
