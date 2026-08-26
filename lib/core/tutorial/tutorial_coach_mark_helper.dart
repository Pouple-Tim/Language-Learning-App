import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:language_learning_app/core/theme/app_colors.dart';

/// Builds one spotlighted step for a tutorial, styled consistently across all tours.
///
/// tutorial_coach_mark (1.3.3) measures [keyTarget]'s RenderBox via
/// `Future.delayed(Duration.zero, ...)` internally (see
/// AnimatedFocusLight._runFocus) -- a timer, not a frame callback. That's
/// only safe once the screen's layout has actually settled; see [showTutorial]
/// for how that's guaranteed regardless of where a tour is triggered from.
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
///
/// Safe to call from anywhere -- a post-frame callback, a provider listener
/// firing mid-rebuild, straight from initState -- because it waits out the
/// frame-timing hazards itself instead of asking every caller to reproduce
/// that wait:
///
/// 1. [WidgetsBinding.endOfFrame] schedules a frame if none is already
///    pending and completes after it, so target rects are always measured
///    against settled layout (see [buildTutorialTarget]'s doc for why that
///    matters).
/// 2. That's still not quite enough on its own: on a real device, system UI
///    insets (status bar height, notably while a transient status icon like
///    the screen-recording indicator is animating in/out) can still settle a
///    frame or two later -- confirmed by locking/unlocking the screen
///    (forces Android to resend metrics, which the package listens for via
///    didChangeMetrics and uses to correct the target rect) fixing an
///    otherwise-misplaced first target. A short extra delay gives that
///    settling time to finish before we ever measure, which is simpler than
///    hooking the same metrics-change signal ourselves.
Future<void> showTutorial({
  required BuildContext context,
  required List<TargetFocus> targets,
  required String skipLabel,
  VoidCallback? onFinish,
}) async {
  await WidgetsBinding.instance.endOfFrame;
  if (!context.mounted) return;

  await Future.delayed(const Duration(milliseconds: 300));
  if (!context.mounted) return;

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
