import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:language_learning_app/core/tutorial/tutorial_service.dart';
import 'package:language_learning_app/core/utils/storage_helper.dart';
import 'package:language_learning_app/l10n/app_localizations.dart';
import 'package:language_learning_app/providers/deck_provider.dart';
import 'package:language_learning_app/providers/statistics_provider.dart';
import 'package:language_learning_app/screens/home/home_screen.dart';
import '../../support/pump_tutorial.dart';

Widget _wrap(Widget child) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => DeckProvider()),
      ChangeNotifierProvider(create: (_) => StatisticsProvider()),
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

  testWidgets('shows the welcome tour on first open and marks it seen', (tester) async {
    await tester.pumpWidget(_wrap(const HomeScreen()));
    await pumpTutorial(tester);

    expect(find.text('Your deck'), findsOneWidget);
    expect(TutorialService.hasSeenWelcome(), isTrue);
  });

  testWidgets('does not show the welcome tour once it has already been seen', (tester) async {
    await TutorialService.markWelcomeSeen();

    await tester.pumpWidget(_wrap(const HomeScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Your deck'), findsNothing);
  });
}
