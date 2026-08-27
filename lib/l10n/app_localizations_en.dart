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
  String get helpSectionTitle => 'Help';

  @override
  String get sendFeedbackTitle => 'Report an issue or give feedback';

  @override
  String get sendFeedbackSubtitle => 'Your feedback helps me improve the app';

  @override
  String get feedbackMailError => 'Couldn\'t open a mail app';

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
  String get whatsNewTitle => 'What\'s new';

  @override
  String get newsListeningMode => 'New game mode: Listening (train your ear)';

  @override
  String get newsOnboarding => 'New intro screen and game modes guide';

  @override
  String get newsFeedback => 'A button to report an issue or give feedback';

  @override
  String get newsStreak => 'Your day streak is now visible on the home screen';

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
  String get listeningModeTitle => 'Listening';

  @override
  String get listeningModeDesc => 'Listen and pick the right character.';

  @override
  String get listenButtonLabel => 'Listen';

  @override
  String get listenButtonTooltip => 'Play pronunciation';

  @override
  String get sentenceModeTitle => 'Sentence';

  @override
  String get classicModeGoal =>
      'Memorize how words are written in the language you\'re learning.';

  @override
  String get classicModeHowTo =>
      'The word to learn is shown. Write it, or draw it if the language uses characters (like Chinese), then submit to check your answer.';

  @override
  String get reverseModeGoal =>
      'The same training as Classic mode, but in the other direction.';

  @override
  String get reverseModeHowTo =>
      'What\'s normally the answer in Classic mode is shown as the question. Write or draw what was normally the question, then submit to check your answer.';

  @override
  String get quizModeGoal =>
      'Quickly recognize a word among several choices, without having to write it.';

  @override
  String get quizModeHowTo =>
      'The word to learn is shown. Pick the correct answer among the 4 options.';

  @override
  String get listeningModeGoal =>
      'Train your ear to recognize a word spoken aloud.';

  @override
  String get listeningModeHowTo =>
      'Tap the speaker to hear the word (replay as many times as you like), then pick the correct answer among the 4 options.';

  @override
  String get sentenceModeGoal =>
      'Learn to build correct sentences, not just isolated words.';

  @override
  String get sentenceModeHowTo =>
      'The sentence\'s translation is shown. Rebuild the sentence in the language you\'re learning by placing the word blocks in the right order.';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingStart => 'Get started';

  @override
  String get onboardingSlide1Title => 'Choose a deck';

  @override
  String get onboardingSlide1Desc =>
      'Decks are grouped by language and category. Pick one — it becomes the deck used everywhere, and base decks download automatically the first time you select them.';

  @override
  String get onboardingSlide2Title => '5 game modes';

  @override
  String get onboardingSlide2Desc =>
      'Practice however you like: classic, reverse, quiz, listening, or build the sentence.';

  @override
  String get onboardingSlide3Title => 'Track your progress';

  @override
  String get onboardingSlide3Desc =>
      'Remaining words, your day streak, and detailed stats help you see how far you\'ve come.';

  @override
  String get onboardingSlide4Title => 'Make it yours';

  @override
  String get onboardingSlide4Desc =>
      'Change the theme, the app language, build your own decks, or reset your progress from Settings.';

  @override
  String get settingsTutorialsSectionTitle => 'Tutorials';

  @override
  String get replayOnboardingTitle => 'Replay the intro';

  @override
  String get replayOnboardingSubtitle =>
      'Show the getting-started screens again';

  @override
  String get gameGuideSettingsTitle => 'Game modes guide';

  @override
  String get gameGuideSettingsSubtitle =>
      'Understand the goal and rules of each game';

  @override
  String get gameGuideScreenTitle => 'Game guide';

  @override
  String get gameGuideGoalLabel => 'Goal';

  @override
  String get gameGuideHowToLabel => 'How to play';
}
