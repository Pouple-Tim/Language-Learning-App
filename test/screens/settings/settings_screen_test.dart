import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:language_learning_app/core/tutorial/tutorial_service.dart';
import 'package:language_learning_app/core/utils/storage_helper.dart';
import 'package:language_learning_app/l10n/app_localizations.dart';
import 'package:language_learning_app/providers/deck_provider.dart';
import 'package:language_learning_app/providers/game_provider.dart';
import 'package:language_learning_app/providers/locale_provider.dart';
import 'package:language_learning_app/providers/theme_provider.dart';
import 'package:language_learning_app/screens/settings/settings_screen.dart';

Widget _wrap(Widget child) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider(create: (_) => DeckProvider()),
      ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ChangeNotifierProvider(create: (_) => GameProvider()),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      home: child,
    ),
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageHelper.init();
  });

  testWidgets('replaying the welcome tutorial resets its seen flag and confirms', (tester) async {
    await TutorialService.markWelcomeSeen();

    await tester.pumpWidget(_wrap(const SettingsScreen()));
    await tester.pumpAndSettle();

    // The Tutorials section sits below the screen's initial lazy-build
    // range, so scroll it into view before interacting with it.
    await tester.dragUntilVisible(
      find.text('Replay welcome tour'),
      find.byType(ListView),
      const Offset(0, -300),
    );
    await tester.ensureVisible(find.text('Replay welcome tour'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Replay welcome tour'));
    await tester.pumpAndSettle();

    expect(TutorialService.hasSeenWelcome(), isFalse);
    expect(find.text("You'll see it again next time you open the app"), findsOneWidget);
  });

  testWidgets('replaying the decks tutorial only resets the decks flag', (tester) async {
    await TutorialService.markWelcomeSeen();
    await TutorialService.markDecksSeen();
    await TutorialService.markGameSeen();

    await tester.pumpWidget(_wrap(const SettingsScreen()));
    await tester.pumpAndSettle();

    await tester.dragUntilVisible(
      find.text('Replay decks tutorial'),
      find.byType(ListView),
      const Offset(0, -300),
    );
    await tester.ensureVisible(find.text('Replay decks tutorial'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Replay decks tutorial'));
    await tester.pumpAndSettle();

    expect(TutorialService.hasSeenDecks(), isFalse);
    expect(TutorialService.hasSeenWelcome(), isTrue);
    expect(TutorialService.hasSeenGame(), isTrue);
  });
}
