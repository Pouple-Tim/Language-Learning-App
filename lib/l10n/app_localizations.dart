import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Language Learning'**
  String get appName;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Language Learning'**
  String get homeTitle;

  /// No description provided for @decksTitle.
  ///
  /// In en, this message translates to:
  /// **'My Decks'**
  String get decksTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @spinWheel.
  ///
  /// In en, this message translates to:
  /// **'Spin the wheel'**
  String get spinWheel;

  /// No description provided for @spinning.
  ///
  /// In en, this message translates to:
  /// **'Spinning...'**
  String get spinning;

  /// No description provided for @validate.
  ///
  /// In en, this message translates to:
  /// **'Validate'**
  String get validate;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip this word'**
  String get skip;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @typeAnswer.
  ///
  /// In en, this message translates to:
  /// **'Type your answer...'**
  String get typeAnswer;

  /// No description provided for @spinFirst.
  ///
  /// In en, this message translates to:
  /// **'Spin the wheel first'**
  String get spinFirst;

  /// No description provided for @drawCharacter.
  ///
  /// In en, this message translates to:
  /// **'Draw the character corresponding to: {answer}'**
  String drawCharacter(String answer);

  /// No description provided for @wordsRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count} words remaining'**
  String wordsRemaining(int count);

  /// No description provided for @totalWords.
  ///
  /// In en, this message translates to:
  /// **'Words learned'**
  String totalWords(int count);

  /// No description provided for @correct.
  ///
  /// In en, this message translates to:
  /// **'Correct! 🎉'**
  String get correct;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Congratulations! 🎉'**
  String get completed;

  /// No description provided for @completedMessage.
  ///
  /// In en, this message translates to:
  /// **'You\'ve mastered all the words!'**
  String get completedMessage;

  /// No description provided for @restart.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get restart;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @resetDeck.
  ///
  /// In en, this message translates to:
  /// **'Reset deck?'**
  String get resetDeck;

  /// No description provided for @resetDeckMessage.
  ///
  /// In en, this message translates to:
  /// **'Choose which mode\'s progress you want to reset for this deck.'**
  String get resetDeckMessage;

  /// No description provided for @resetThisMode.
  ///
  /// In en, this message translates to:
  /// **'Reset this mode'**
  String get resetThisMode;

  /// No description provided for @resetAllModes.
  ///
  /// In en, this message translates to:
  /// **'Reset all modes'**
  String get resetAllModes;

  /// No description provided for @modeReset.
  ///
  /// In en, this message translates to:
  /// **'{mode} reset!'**
  String modeReset(String mode);

  /// No description provided for @noSentencesInDeck.
  ///
  /// In en, this message translates to:
  /// **'This deck doesn\'t have any sentences yet.'**
  String get noSentencesInDeck;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @decksAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available Decks'**
  String get decksAvailable;

  /// No description provided for @myDecks.
  ///
  /// In en, this message translates to:
  /// **'My Decks'**
  String get myDecks;

  /// No description provided for @createDeck.
  ///
  /// In en, this message translates to:
  /// **'Create deck'**
  String get createDeck;

  /// No description provided for @noCustomDecks.
  ///
  /// In en, this message translates to:
  /// **'No custom deck'**
  String get noCustomDecks;

  /// No description provided for @createFirstDeck.
  ///
  /// In en, this message translates to:
  /// **'Create your first deck to start!'**
  String get createFirstDeck;

  /// No description provided for @deck.
  ///
  /// In en, this message translates to:
  /// **'deck'**
  String get deck;

  /// No description provided for @decks.
  ///
  /// In en, this message translates to:
  /// **'decks'**
  String get decks;

  /// No description provided for @editDeck.
  ///
  /// In en, this message translates to:
  /// **'Edit deck'**
  String get editDeck;

  /// No description provided for @createNewDeck.
  ///
  /// In en, this message translates to:
  /// **'Create a deck'**
  String get createNewDeck;

  /// No description provided for @deckName.
  ///
  /// In en, this message translates to:
  /// **'Deck name'**
  String get deckName;

  /// No description provided for @deckNameHint.
  ///
  /// In en, this message translates to:
  /// **'Ex: Spanish - Vocabulary'**
  String get deckNameHint;

  /// No description provided for @enterName.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get enterName;

  /// No description provided for @nameMinLength.
  ///
  /// In en, this message translates to:
  /// **'Name must be at least {min} characters'**
  String nameMinLength(int min);

  /// No description provided for @inputType.
  ///
  /// In en, this message translates to:
  /// **'Input type'**
  String get inputType;

  /// No description provided for @text.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get text;

  /// No description provided for @drawing.
  ///
  /// In en, this message translates to:
  /// **'Drawing'**
  String get drawing;

  /// No description provided for @words.
  ///
  /// In en, this message translates to:
  /// **'Words'**
  String get words;

  /// No description provided for @addWord.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addWord;

  /// No description provided for @noWords.
  ///
  /// In en, this message translates to:
  /// **'No words added'**
  String get noWords;

  /// No description provided for @question.
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get question;

  /// No description provided for @answer.
  ///
  /// In en, this message translates to:
  /// **'Answer'**
  String get answer;

  /// No description provided for @enterQuestion.
  ///
  /// In en, this message translates to:
  /// **'Enter a question'**
  String get enterQuestion;

  /// No description provided for @enterAnswer.
  ///
  /// In en, this message translates to:
  /// **'Enter an answer'**
  String get enterAnswer;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteDeck.
  ///
  /// In en, this message translates to:
  /// **'Delete this deck?'**
  String get deleteDeck;

  /// No description provided for @deleteDeckMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"?\nThis action is irreversible.'**
  String deleteDeckMessage(String name);

  /// No description provided for @addMinWords.
  ///
  /// In en, this message translates to:
  /// **'Add at least {min} words!'**
  String addMinWords(int min);

  /// No description provided for @wordDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted word'**
  String get wordDeleted;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get darkMode;

  /// No description provided for @darkModeEnabled.
  ///
  /// In en, this message translates to:
  /// **'Dark mode enabled'**
  String get darkModeEnabled;

  /// No description provided for @lightModeEnabled.
  ///
  /// In en, this message translates to:
  /// **'Light mode enabled'**
  String get lightModeEnabled;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select language'**
  String get selectLanguage;

  /// No description provided for @currentDeck.
  ///
  /// In en, this message translates to:
  /// **'Current deck'**
  String get currentDeck;

  /// No description provided for @progress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @remaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get remaining;

  /// No description provided for @completed_plural.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed_plural;

  /// No description provided for @data.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get data;

  /// No description provided for @resetCurrentDeck.
  ///
  /// In en, this message translates to:
  /// **'Reset current deck'**
  String get resetCurrentDeck;

  /// No description provided for @restartFromBeginning.
  ///
  /// In en, this message translates to:
  /// **'Restart from the beginning'**
  String get restartFromBeginning;

  /// No description provided for @clearAllData.
  ///
  /// In en, this message translates to:
  /// **'Clear all data'**
  String get clearAllData;

  /// No description provided for @deleteAllProgress.
  ///
  /// In en, this message translates to:
  /// **'Delete all progress and settings'**
  String get deleteAllProgress;

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Warning!'**
  String get warning;

  /// No description provided for @clearDataWarning.
  ///
  /// In en, this message translates to:
  /// **'This action will delete:\n• All your custom decks\n• All your progress\n• All your settings\n\nThis action is IRREVERSIBLE!'**
  String get clearDataWarning;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get clearAll;

  /// No description provided for @helpSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get helpSectionTitle;

  /// No description provided for @sendFeedbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Report an issue or give feedback'**
  String get sendFeedbackTitle;

  /// No description provided for @sendFeedbackSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your feedback helps me improve the app'**
  String get sendFeedbackSubtitle;

  /// No description provided for @feedbackMailError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open a mail app'**
  String get feedbackMailError;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Language learning app with interactive wheel.\n\nLearn new words every day and improve your vocabulary!'**
  String get description;

  /// No description provided for @madeWithLove.
  ///
  /// In en, this message translates to:
  /// **'Made with passion'**
  String get madeWithLove;

  /// No description provided for @deckSelected.
  ///
  /// In en, this message translates to:
  /// **'Deck \"{name}\" selected'**
  String deckSelected(String name);

  /// No description provided for @deckDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t download this deck. Check your connection and try again.'**
  String get deckDownloadFailed;

  /// No description provided for @deckCreated.
  ///
  /// In en, this message translates to:
  /// **'Deck \"{name}\" created!'**
  String deckCreated(String name);

  /// No description provided for @deckModified.
  ///
  /// In en, this message translates to:
  /// **'Deck \"{name}\" modified!'**
  String deckModified(String name);

  /// No description provided for @deckDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deck \"{name}\" deleted'**
  String deckDeleted(String name);

  /// No description provided for @deckReset.
  ///
  /// In en, this message translates to:
  /// **'Deck reset!'**
  String get deckReset;

  /// No description provided for @decksReloaded.
  ///
  /// In en, this message translates to:
  /// **'Decks reloaded!'**
  String get decksReloaded;

  /// No description provided for @allDataCleared.
  ///
  /// In en, this message translates to:
  /// **'All data has been cleared.\nRestart the application.'**
  String get allDataCleared;

  /// No description provided for @remainingWordsList.
  ///
  /// In en, this message translates to:
  /// **'Remaining words'**
  String get remainingWordsList;

  /// No description provided for @toReview.
  ///
  /// In en, this message translates to:
  /// **'To review'**
  String get toReview;

  /// No description provided for @succeeded.
  ///
  /// In en, this message translates to:
  /// **'Succeeded'**
  String get succeeded;

  /// No description provided for @noWordSucceeded.
  ///
  /// In en, this message translates to:
  /// **'No word succeeded yet'**
  String get noWordSucceeded;

  /// No description provided for @allWordsSucceeded.
  ///
  /// In en, this message translates to:
  /// **'All words are succeeded! 🎉'**
  String get allWordsSucceeded;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @beginner.
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get beginner;

  /// No description provided for @intermediate.
  ///
  /// In en, this message translates to:
  /// **'Intermediate'**
  String get intermediate;

  /// No description provided for @advanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get advanced;

  /// No description provided for @noDeck.
  ///
  /// In en, this message translates to:
  /// **'No deck'**
  String get noDeck;

  /// No description provided for @changeWord.
  ///
  /// In en, this message translates to:
  /// **'Change word'**
  String get changeWord;

  /// No description provided for @noDecksAvailable.
  ///
  /// In en, this message translates to:
  /// **'No decks available'**
  String get noDecksAvailable;

  /// No description provided for @drawingValidationQuestion.
  ///
  /// In en, this message translates to:
  /// **'Did you draw correctly: {word}?'**
  String drawingValidationQuestion(String word);

  /// No description provided for @noWrong.
  ///
  /// In en, this message translates to:
  /// **'No, wrong'**
  String get noWrong;

  /// No description provided for @yesCorrect.
  ///
  /// In en, this message translates to:
  /// **'Yes, correct!'**
  String get yesCorrect;

  /// No description provided for @noWordsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No words available'**
  String get noWordsAvailable;

  /// No description provided for @chooseDeckToStart.
  ///
  /// In en, this message translates to:
  /// **'Choose a deck to start'**
  String get chooseDeckToStart;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @viewStatistics.
  ///
  /// In en, this message translates to:
  /// **'View statistics'**
  String get viewStatistics;

  /// No description provided for @trackYourProgress.
  ///
  /// In en, this message translates to:
  /// **'Track your progress'**
  String get trackYourProgress;

  /// No description provided for @noStatistics.
  ///
  /// In en, this message translates to:
  /// **'No statistics available'**
  String get noStatistics;

  /// No description provided for @startReviewing.
  ///
  /// In en, this message translates to:
  /// **'Start reviewing to see your statistics'**
  String get startReviewing;

  /// No description provided for @currentStreak.
  ///
  /// In en, this message translates to:
  /// **'Current streak'**
  String get currentStreak;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get days;

  /// No description provided for @learned.
  ///
  /// In en, this message translates to:
  /// **'learned'**
  String get learned;

  /// No description provided for @last7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get last7Days;

  /// No description provided for @monthlyActivity.
  ///
  /// In en, this message translates to:
  /// **'Monthly activity'**
  String get monthlyActivity;

  /// No description provided for @topDecks.
  ///
  /// In en, this message translates to:
  /// **'Top 5 decks'**
  String get topDecks;

  /// No description provided for @reviewsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} reviews'**
  String reviewsCount(int count);

  /// No description provided for @dataWillBeDeleted.
  ///
  /// In en, this message translates to:
  /// **'Data will be deleted'**
  String get dataWillBeDeleted;

  /// No description provided for @deckProgress.
  ///
  /// In en, this message translates to:
  /// **'Deck progress'**
  String get deckProgress;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @statisticsWillBeKept.
  ///
  /// In en, this message translates to:
  /// **'Statistics will be kept'**
  String get statisticsWillBeKept;

  /// No description provided for @favoriteGameModes.
  ///
  /// In en, this message translates to:
  /// **'Favorite Game Modes'**
  String get favoriteGameModes;

  /// No description provided for @wordsLearned.
  ///
  /// In en, this message translates to:
  /// **'Words learned'**
  String get wordsLearned;

  /// No description provided for @noGameData.
  ///
  /// In en, this message translates to:
  /// **'No game data'**
  String get noGameData;

  /// No description provided for @gamesPlayed.
  ///
  /// In en, this message translates to:
  /// **'{count} games played'**
  String gamesPlayed(int count);

  /// No description provided for @less.
  ///
  /// In en, this message translates to:
  /// **'Less'**
  String get less;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @revisionsTooltip.
  ///
  /// In en, this message translates to:
  /// **'{date}: {count} reviews'**
  String revisionsTooltip(String date, int count);

  /// No description provided for @classicModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Classic Training'**
  String get classicModeTitle;

  /// No description provided for @classicModeDesc.
  ///
  /// In en, this message translates to:
  /// **'Wheel and drawing/text'**
  String get classicModeDesc;

  /// No description provided for @gameModesTitle.
  ///
  /// In en, this message translates to:
  /// **'Game Modes'**
  String get gameModesTitle;

  /// No description provided for @manageDecksDesc.
  ///
  /// In en, this message translates to:
  /// **'Create and edit your lists'**
  String get manageDecksDesc;

  /// No description provided for @noDeckSelected.
  ///
  /// In en, this message translates to:
  /// **'No deck selected'**
  String get noDeckSelected;

  /// No description provided for @selectDeck.
  ///
  /// In en, this message translates to:
  /// **'Select a deck'**
  String get selectDeck;

  /// No description provided for @reverseModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Reverse Training'**
  String get reverseModeTitle;

  /// No description provided for @reverseModeDesc.
  ///
  /// In en, this message translates to:
  /// **'Guess the question from the answer'**
  String get reverseModeDesc;

  /// No description provided for @quizModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick Quiz'**
  String get quizModeTitle;

  /// No description provided for @quizModeDesc.
  ///
  /// In en, this message translates to:
  /// **'Choose the correct answer from 4 options.'**
  String get quizModeDesc;

  /// No description provided for @listeningModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Listening'**
  String get listeningModeTitle;

  /// No description provided for @listeningModeDesc.
  ///
  /// In en, this message translates to:
  /// **'Listen and pick the right character.'**
  String get listeningModeDesc;

  /// No description provided for @listenButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get listenButtonLabel;

  /// No description provided for @listenButtonTooltip.
  ///
  /// In en, this message translates to:
  /// **'Play pronunciation'**
  String get listenButtonTooltip;

  /// No description provided for @sentenceModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Sentence'**
  String get sentenceModeTitle;

  /// No description provided for @classicModeGoal.
  ///
  /// In en, this message translates to:
  /// **'Memorize how words are written in the language you\'re learning.'**
  String get classicModeGoal;

  /// No description provided for @classicModeHowTo.
  ///
  /// In en, this message translates to:
  /// **'The word to learn is shown. Write it, or draw it if the language uses characters (like Chinese), then submit to check your answer.'**
  String get classicModeHowTo;

  /// No description provided for @reverseModeGoal.
  ///
  /// In en, this message translates to:
  /// **'The same training as Classic mode, but in the other direction.'**
  String get reverseModeGoal;

  /// No description provided for @reverseModeHowTo.
  ///
  /// In en, this message translates to:
  /// **'What\'s normally the answer in Classic mode is shown as the question. Write or draw what was normally the question, then submit to check your answer.'**
  String get reverseModeHowTo;

  /// No description provided for @quizModeGoal.
  ///
  /// In en, this message translates to:
  /// **'Quickly recognize a word among several choices, without having to write it.'**
  String get quizModeGoal;

  /// No description provided for @quizModeHowTo.
  ///
  /// In en, this message translates to:
  /// **'The word to learn is shown. Pick the correct answer among the 4 options.'**
  String get quizModeHowTo;

  /// No description provided for @listeningModeGoal.
  ///
  /// In en, this message translates to:
  /// **'Train your ear to recognize a word spoken aloud.'**
  String get listeningModeGoal;

  /// No description provided for @listeningModeHowTo.
  ///
  /// In en, this message translates to:
  /// **'Tap the speaker to hear the word (replay as many times as you like), then pick the correct answer among the 4 options.'**
  String get listeningModeHowTo;

  /// No description provided for @sentenceModeGoal.
  ///
  /// In en, this message translates to:
  /// **'Learn to build correct sentences, not just isolated words.'**
  String get sentenceModeGoal;

  /// No description provided for @sentenceModeHowTo.
  ///
  /// In en, this message translates to:
  /// **'The sentence\'s translation is shown. Rebuild the sentence in the language you\'re learning by placing the word blocks in the right order.'**
  String get sentenceModeHowTo;

  /// No description provided for @tutorialSkipButton.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get tutorialSkipButton;

  /// No description provided for @tutorialWelcomeDeckTitle.
  ///
  /// In en, this message translates to:
  /// **'Your deck'**
  String get tutorialWelcomeDeckTitle;

  /// No description provided for @tutorialWelcomeDeckDesc.
  ///
  /// In en, this message translates to:
  /// **'This shows the deck you\'re currently reviewing. Tap it to browse or manage your decks.'**
  String get tutorialWelcomeDeckDesc;

  /// No description provided for @tutorialWelcomeGamesTitle.
  ///
  /// In en, this message translates to:
  /// **'Game modes'**
  String get tutorialWelcomeGamesTitle;

  /// No description provided for @tutorialWelcomeGamesDesc.
  ///
  /// In en, this message translates to:
  /// **'Pick how you want to practice: classic, reverse, quiz, or build the sentence.'**
  String get tutorialWelcomeGamesDesc;

  /// No description provided for @tutorialWelcomeSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tutorialWelcomeSettingsTitle;

  /// No description provided for @tutorialWelcomeSettingsDesc.
  ///
  /// In en, this message translates to:
  /// **'Change the theme, app language, or reset your progress from here.'**
  String get tutorialWelcomeSettingsDesc;

  /// No description provided for @tutorialDecksSelectTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a deck'**
  String get tutorialDecksSelectTitle;

  /// No description provided for @tutorialDecksSelectDesc.
  ///
  /// In en, this message translates to:
  /// **'Decks are grouped by language and category — tap a category to open it, then tap any deck to select it (it becomes the deck used everywhere). Base decks download automatically the first time you pick them.'**
  String get tutorialDecksSelectDesc;

  /// No description provided for @tutorialDecksCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your own'**
  String get tutorialDecksCreateTitle;

  /// No description provided for @tutorialDecksCreateDesc.
  ///
  /// In en, this message translates to:
  /// **'Tap here to build a custom deck with your own words and sentences.'**
  String get tutorialDecksCreateDesc;

  /// No description provided for @tutorialGameRemainingTitle.
  ///
  /// In en, this message translates to:
  /// **'Track your progress'**
  String get tutorialGameRemainingTitle;

  /// No description provided for @tutorialGameRemainingDesc.
  ///
  /// In en, this message translates to:
  /// **'This shows how many words are left to review in this session.'**
  String get tutorialGameRemainingDesc;

  /// No description provided for @tutorialGamePlayTitle.
  ///
  /// In en, this message translates to:
  /// **'Your deck & mode'**
  String get tutorialGamePlayTitle;

  /// No description provided for @tutorialGamePlayDesc.
  ///
  /// In en, this message translates to:
  /// **'This shows the deck you\'re reviewing and which game mode you\'re in.'**
  String get tutorialGamePlayDesc;

  /// No description provided for @settingsTutorialsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Tutorials'**
  String get settingsTutorialsSectionTitle;

  /// No description provided for @replayWelcomeTutorialTitle.
  ///
  /// In en, this message translates to:
  /// **'Replay welcome tour'**
  String get replayWelcomeTutorialTitle;

  /// No description provided for @replayWelcomeTutorialSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show the home screen tour again'**
  String get replayWelcomeTutorialSubtitle;

  /// No description provided for @replayDecksTutorialTitle.
  ///
  /// In en, this message translates to:
  /// **'Replay decks tutorial'**
  String get replayDecksTutorialTitle;

  /// No description provided for @replayDecksTutorialSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show the deck screen hints again'**
  String get replayDecksTutorialSubtitle;

  /// No description provided for @replayGameTutorialTitle.
  ///
  /// In en, this message translates to:
  /// **'Replay game tutorial'**
  String get replayGameTutorialTitle;

  /// No description provided for @replayGameTutorialSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show the game screen hints again'**
  String get replayGameTutorialSubtitle;

  /// No description provided for @gameGuideSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Game modes guide'**
  String get gameGuideSettingsTitle;

  /// No description provided for @gameGuideSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Understand the goal and rules of each game'**
  String get gameGuideSettingsSubtitle;

  /// No description provided for @gameGuideScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Game guide'**
  String get gameGuideScreenTitle;

  /// No description provided for @gameGuideGoalLabel.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get gameGuideGoalLabel;

  /// No description provided for @gameGuideHowToLabel.
  ///
  /// In en, this message translates to:
  /// **'How to play'**
  String get gameGuideHowToLabel;

  /// No description provided for @tutorialReplaySnackbar.
  ///
  /// In en, this message translates to:
  /// **'You\'ll see it again next time you open that screen'**
  String get tutorialReplaySnackbar;

  /// No description provided for @tutorialReplayWelcomeSnackbar.
  ///
  /// In en, this message translates to:
  /// **'You\'ll see it again next time you open the app'**
  String get tutorialReplayWelcomeSnackbar;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'fr', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
