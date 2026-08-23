import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:language_learning_app/core/tutorial/tutorial_service.dart';
import 'package:language_learning_app/core/utils/storage_helper.dart';
import 'package:language_learning_app/data/models/deck.dart';
import 'package:language_learning_app/data/models/word.dart';
import 'package:language_learning_app/l10n/app_localizations.dart';
import 'package:language_learning_app/providers/game_provider.dart';
import 'package:language_learning_app/screens/games/classic_game/game_screen.dart';
import '../../../support/pump_tutorial.dart';

Deck _buildDeck() {
  return Deck(
    id: 'deck1',
    name: 'Test Deck',
    type: DeckType.base,
    inputType: InputType.text,
    reverseInputType: InputType.text,
    words: [Word(id: 'w0', prompt: 'un', answer: 'one', removed: false)],
  );
}

Widget _wrap(Widget child, GameProvider gameProvider) {
  return ChangeNotifierProvider<GameProvider>.value(
    value: gameProvider,
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

  testWidgets('shows the game tour once a deck is loaded and marks it seen', (tester) async {
    final gameProvider = GameProvider();
    await gameProvider.setDeck(_buildDeck());

    await tester.pumpWidget(_wrap(const GameScreen(), gameProvider));
    await pumpTutorial(tester);

    expect(find.text('Track your progress'), findsOneWidget);
    expect(TutorialService.hasSeenGame(), isTrue);
  });

  testWidgets('does not show the game tour once it has already been seen', (tester) async {
    await TutorialService.markGameSeen();
    final gameProvider = GameProvider();
    await gameProvider.setDeck(_buildDeck());

    await tester.pumpWidget(_wrap(const GameScreen(), gameProvider));
    await tester.pumpAndSettle();

    expect(find.text('Track your progress'), findsNothing);
  });
}
