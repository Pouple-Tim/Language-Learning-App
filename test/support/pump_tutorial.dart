import 'package:flutter_test/flutter_test.dart';

/// Pumps enough frames for an `initState`/`addPostFrameCallback`-triggered
/// tutorial_coach_mark tour to finish its two-hop async setup and animation.
///
/// `pumpAndSettle()` doesn't work here: the package schedules a
/// `Future.delayed(Duration.zero, ...)` to insert its overlay, and building
/// that overlay schedules a second, independent `Future.delayed` to start
/// the focus animation. `pumpAndSettle()`'s settle-detection loop exits
/// after firing the first hop but before the second one has scheduled a
/// ticker, so it reports "settled" before any tour content is built. This
/// only affects tours triggered outside a user-gesture callback — a tap
/// (as in `tutorial_coach_mark_helper_test.dart`) already flushes the first
/// hop before `pumpAndSettle()` starts, so it doesn't need this helper.
Future<void> pumpTutorial(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
