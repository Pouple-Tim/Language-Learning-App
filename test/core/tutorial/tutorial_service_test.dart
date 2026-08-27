// test/core/tutorial/tutorial_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:language_learning_app/core/tutorial/tutorial_service.dart';
import 'package:language_learning_app/core/utils/storage_helper.dart';

void main() {
  group('TutorialService', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await StorageHelper.init();
    });

    test('onboarding is unseen by default, then seen after marking', () async {
      expect(TutorialService.hasSeenOnboarding(), isFalse);

      await TutorialService.markOnboardingSeen();

      expect(TutorialService.hasSeenOnboarding(), isTrue);
    });
  });
}
