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
    return '$count words';
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
      'Do you want to restart this deck from the beginning? All your progress will be lost.';

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
}
