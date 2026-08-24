import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:language_learning_app/core/tutorial/tutorial_service.dart';
import 'package:language_learning_app/core/utils/storage_helper.dart';
import 'package:language_learning_app/l10n/app_localizations.dart';
import 'package:language_learning_app/providers/deck_provider.dart';
import 'package:language_learning_app/screens/decks/decks_screen.dart';
import '../../support/pump_tutorial.dart';

Widget _wrap(Widget child) {
  return ChangeNotifierProvider(
    create: (_) => DeckProvider(),
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

  testWidgets('shows the decks tour once loading is done and marks it seen', (tester) async {
    await tester.pumpWidget(_wrap(const DecksScreen()));
    await pumpTutorial(tester);

    expect(find.text('Choose a deck'), findsOneWidget);
    expect(TutorialService.hasSeenDecks(), isTrue);
  });

  testWidgets('does not show the decks tour once it has already been seen', (tester) async {
    await TutorialService.markDecksSeen();

    await tester.pumpWidget(_wrap(const DecksScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Choose a deck'), findsNothing);
  });
}
