// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Language Learning';

  @override
  String get homeTitle => 'Language Learning';

  @override
  String get decksTitle => 'My Decks';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get spinWheel => 'Spin the wheel';

  @override
  String get spinning => 'Spinning...';

  @override
  String get validate => 'Validate';

  @override
  String get skip => 'Skip this word';

  @override
  String get clear => 'Clear';

  @override
  String get typeAnswer => 'Type your answer...';

  @override
  String get spinFirst => 'Spin the wheel first';

  @override
  String drawCharacter(String answer) {
    return 'Draw the character corresponding to: $answer';
  }

  @override
  String wordsRemaining(int count) {
    return '$count words remaining';
  }

  @override
  String totalWords(int count) {
    return 'Words learned';
  }

  @override
  String get correct => 'Correct! 🎉';

  @override
  String get tryAgain => 'Try again';

  @override
  String get completed => 'Congratulations! 🎉';

  @override
  String get completedMessage => 'You\'ve mastered all the words!';

  @override
  String get restart => 'Restart';

  @override
  String get reset => 'Reset';

  @override
  String get resetDeck => 'Reset deck?';

  @override
  String get resetDeckMessage =>
      'Choose which mode\'s progress you want to reset for this deck.';

  @override
  String get resetThisMode => 'Reset this mode';

  @override
  String get resetAllModes => 'Reset all modes';

  @override
  String modeReset(String mode) {
    return '$mode reset!';
  }

  @override
  String get noSentencesInDeck => 'This deck doesn\'t have any sentences yet.';

  @override
  String get cancel => 'Cancel';

  @override
  String get decksAvailable => 'Available Decks';

  @override
  String get myDecks => 'My Decks';

  @override
  String get createDeck => 'Create deck';

  @override
  String get noCustomDecks => 'No custom deck';

  @override
  String get createFirstDeck => 'Create your first deck to start!';

  @override
  String get deck => 'deck';

  @override
  String get decks => 'decks';

  @override
  String get editDeck => 'Edit deck';

  @override
  String get createNewDeck => 'Create a deck';

  @override
  String get deckName => 'Deck name';

  @override
  String get deckNameHint => 'Ex: Spanish - Vocabulary';

  @override
  String get enterName => 'Enter a name';

  @override
  String nameMinLength(int min) {
    return 'Name must be at least $min characters';
  }

  @override
  String get inputType => 'Input type';

  @override
  String get text => 'Text';

  @override
  String get drawing => 'Drawing';

  @override
  String get words => 'Words';

  @override
  String get addWord => 'Add';

  @override
  String get noWords => 'No words added';

  @override
  String get question => 'Question';

  @override
  String get answer => 'Answer';

  @override
  String get enterQuestion => 'Enter a question';

  @override
  String get enterAnswer => 'Enter an answer';

  @override
  String get save => 'Save';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get deleteDeck => 'Delete this deck?';

  @override
  String deleteDeckMessage(String name) {
    return 'Are you sure you want to delete \"$name\"?\nThis action is irreversible.';
  }

  @override
  String addMinWords(int min) {
    return 'Add at least $min words!';
  }

  @override
  String get wordDeleted => 'Deleted word';

  @override
  String get appearance => 'Appearance';

  @override
  String get darkMode => 'Dark mode';

  @override
  String get darkModeEnabled => 'Dark mode enabled';

  @override
  String get lightModeEnabled => 'Light mode enabled';

  @override
  String get language => 'Language';

  @override
  String get selectLanguage => 'Select language';

  @override
  String get currentDeck => 'Current deck';

  @override
  String get progress => 'Progress';

  @override
  String get total => 'Total';

  @override
  String get remaining => 'Remaining';

  @override
  String get completed_plural => 'Completed';

  @override
  String get data => 'Data';

  @override
  String get resetCurrentDeck => 'Reset current deck';

  @override
  String get restartFromBeginning => 'Restart from the beginning';

  @override
  String get clearAllData => 'Clear all data';

  @override
  String get deleteAllProgress => 'Delete all progress and settings';

  @override
  String get warning => '⚠️ Warning!';

  @override
  String get clearDataWarning =>
      'This action will delete:\n• All your custom decks\n• All your progress\n• All your settings\n\nThis action is IRREVERSIBLE!';

  @override
  String get clearAll => 'Clear all';

  @override
  String get about => 'About';

  @override
  String get version => 'Version';

  @override
  String get description =>
      'Language learning app with interactive wheel.\n\nLearn new words every day and improve your vocabulary!';

  @override
  String get madeWithLove => 'Made with passion';

  @override
  String deckSelected(String name) {
    return 'Deck \"$name\" selected';
  }

  @override
  String get deckDownloadFailed =>
      'Couldn\'t download this deck. Check your connection and try again.';

  @override
  String deckCreated(String name) {
    return 'Deck \"$name\" created!';
  }

  @override
  String deckModified(String name) {
    return 'Deck \"$name\" modified!';
  }

  @override
  String deckDeleted(String name) {
    return 'Deck \"$name\" deleted';
  }

  @override
  String get deckReset => 'Deck reset!';

  @override
  String get decksReloaded => 'Decks reloaded!';

  @override
  String get allDataCleared =>
      'All data has been cleared.\nRestart the application.';

  @override
  String get remainingWordsList => 'Remaining words';

  @override
  String get toReview => 'To review';

  @override
  String get succeeded => 'Succeeded';

  @override
  String get noWordSucceeded => 'No word succeeded yet';

  @override
  String get allWordsSucceeded => 'All words are succeeded! 🎉';

  @override
  String get close => 'Close';

  @override
  String get beginner => 'Beginner';

  @override
  String get intermediate => 'Intermediate';

  @override
  String get advanced => 'Advanced';

  @override
  String get noDeck => 'No deck';

  @override
  String get changeWord => 'Change word';

  @override
  String get noDecksAvailable => 'No decks available';

  @override
  String drawingValidationQuestion(String word) {
    return 'Did you draw correctly: $word?';
  }

  @override
  String get noWrong => 'No, wrong';

  @override
  String get yesCorrect => 'Yes, correct!';

  @override
  String get noWordsAvailable => 'No words available';

  @override
  String get chooseDeckToStart => 'Choose a deck to start';

  @override
  String get statistics => 'Statistics';

  @override
  String get viewStatistics => 'View statistics';

  @override
  String get trackYourProgress => 'Track your progress';

  @override
  String get noStatistics => 'No statistics available';

  @override
  String get startReviewing => 'Start reviewing to see your statistics';

  @override
  String get currentStreak => 'Current streak';

  @override
  String get days => 'days';

  @override
  String get learned => 'learned';

  @override
  String get last7Days => 'Last 7 days';

  @override
  String get monthlyActivity => 'Monthly activity';

  @override
  String get topDecks => 'Top 5 decks';

  @override
  String reviewsCount(int count) {
    return '$count reviews';
  }

  @override
  String get dataWillBeDeleted => 'Data will be deleted';

  @override
  String get deckProgress => 'Deck progress';

  @override
  String get preferences => 'Preferences';

  @override
  String get statisticsWillBeKept => 'Statistics will be kept';

  @override
  String get favoriteGameModes => 'Favorite Game Modes';

  @override
  String get wordsLearned => 'Words learned';

  @override
  String get noGameData => 'No game data';

  @override
  String gamesPlayed(int count) {
    return '$count games played';
  }

  @override
  String get less => 'Less';

  @override
  String get more => 'More';

  @override
  String revisionsTooltip(String date, int count) {
    return '$date: $count reviews';
  }

  @override
  String get classicModeTitle => 'Classic Training';

  @override
  String get classicModeDesc => 'Wheel and drawing/text';

  @override
  String get gameModesTitle => 'Game Modes';

  @override
  String get manageDecksDesc => 'Create and edit your lists';

  @override
  String get noDeckSelected => 'No deck selected';

  @override
  String get selectDeck => 'Select a deck';

  @override
  String get reverseModeTitle => 'Reverse Training';

  @override
  String get reverseModeDesc => 'Guess the question from the answer';

  @override
  String get quizModeTitle => 'Quick Quiz';

  @override
  String get quizModeDesc => 'Choose the correct answer from 4 options.';

  @override
  String get tutorialSkipButton => 'Skip';

  @override
  String get tutorialWelcomeDeckTitle => 'Your deck';

  @override
  String get tutorialWelcomeDeckDesc =>
      'This shows the deck you\'re currently reviewing. Tap it to browse or manage your decks.';

  @override
  String get tutorialWelcomeGamesTitle => 'Game modes';

  @override
  String get tutorialWelcomeGamesDesc =>
      'Pick how you want to practice: classic, reverse, quiz, or build the sentence.';

  @override
  String get tutorialWelcomeSettingsTitle => 'Settings';

  @override
  String get tutorialWelcomeSettingsDesc =>
      'Change the theme, app language, or reset your progress from here.';

  @override
  String get tutorialDecksSelectTitle => 'Choose a deck';

  @override
  String get tutorialDecksSelectDesc =>
      'Tap any deck to select it — it becomes the deck used in every game mode.';

  @override
  String get tutorialDecksCreateTitle => 'Create your own';

  @override
  String get tutorialDecksCreateDesc =>
      'Tap here to build a custom deck with your own words and sentences.';

  @override
  String get tutorialGameRemainingTitle => 'Track your progress';

  @override
  String get tutorialGameRemainingDesc =>
      'This shows how many words are left to review in this session.';

  @override
  String get tutorialGamePlayTitle => 'Answer here';

  @override
  String get tutorialGamePlayDesc =>
      'Spin, type, draw, or pick the right answer depending on the mode — then move to the next word.';

  @override
  String get settingsTutorialsSectionTitle => 'Tutorials';

  @override
  String get replayWelcomeTutorialTitle => 'Replay welcome tour';

  @override
  String get replayWelcomeTutorialSubtitle => 'Show the home screen tour again';

  @override
  String get replayDecksTutorialTitle => 'Replay decks tutorial';

  @override
  String get replayDecksTutorialSubtitle => 'Show the deck screen hints again';

  @override
  String get replayGameTutorialTitle => 'Replay game tutorial';

  @override
  String get replayGameTutorialSubtitle => 'Show the game screen hints again';

  @override
  String get tutorialReplaySnackbar =>
      'You\'ll see it again next time you open that screen';
}
