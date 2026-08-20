// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'Apprentissage des Langues';

  @override
  String get homeTitle => 'Language Learning';

  @override
  String get decksTitle => 'Mes Decks';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get spinWheel => 'Lancer la roue';

  @override
  String get spinning => 'Rotation...';

  @override
  String get validate => 'Valider';

  @override
  String get skip => 'Passer ce mot';

  @override
  String get clear => 'Effacer';

  @override
  String get typeAnswer => 'Tape ta réponse...';

  @override
  String get spinFirst => 'Lance la roue d\'abord';

  @override
  String drawCharacter(String answer) {
    return 'Dessine le caractère correspondant à : $answer';
  }

  @override
  String wordsRemaining(int count) {
    return '$count mots restants';
  }

  @override
  String totalWords(int count) {
    return 'Mots appris';
  }

  @override
  String get correct => 'Correct ! 🎉';

  @override
  String get tryAgain => 'Essaye encore';

  @override
  String get completed => 'Bravo ! 🎉';

  @override
  String get completedMessage => 'Tu as réussi tous les mots !';

  @override
  String get restart => 'Recommencer';

  @override
  String get reset => 'Réinitialiser';

  @override
  String get resetDeck => 'Réinitialiser le deck ?';

  @override
  String get resetDeckMessage =>
      'Veux-tu recommencer ce deck depuis le début ? Tous tes progrès seront perdus.';

  @override
  String get cancel => 'Annuler';

  @override
  String get decksAvailable => 'Decks disponibles';

  @override
  String get myDecks => 'Mes decks';

  @override
  String get createDeck => 'Créer un deck';

  @override
  String get noCustomDecks => 'Aucun deck personnalisé';

  @override
  String get createFirstDeck => 'Crée ton premier deck pour commencer !';

  @override
  String get deck => 'deck';

  @override
  String get decks => 'decks';

  @override
  String get editDeck => 'Modifier le deck';

  @override
  String get createNewDeck => 'Créer un deck';

  @override
  String get deckName => 'Nom du deck';

  @override
  String get deckNameHint => 'Ex: Espagnol - Vocabulaire';

  @override
  String get enterName => 'Entre un nom';

  @override
  String nameMinLength(int min) {
    return 'Le nom doit faire au moins $min caractères';
  }

  @override
  String get inputType => 'Type de saisie';

  @override
  String get text => 'Texte';

  @override
  String get drawing => 'Dessin';

  @override
  String get words => 'Mots';

  @override
  String get addWord => 'Ajouter';

  @override
  String get noWords => 'Aucun mot ajouté';

  @override
  String get question => 'Question';

  @override
  String get answer => 'Réponse';

  @override
  String get enterQuestion => 'Entre une question';

  @override
  String get enterAnswer => 'Entre une réponse';

  @override
  String get save => 'Sauvegarder';

  @override
  String get edit => 'Modifier';

  @override
  String get delete => 'Supprimer';

  @override
  String get deleteDeck => 'Supprimer ce deck ?';

  @override
  String deleteDeckMessage(String name) {
    return 'Es-tu sûr de vouloir supprimer \"$name\" ?\nCette action est irréversible.';
  }

  @override
  String addMinWords(int min) {
    return 'Ajoute au moins $min mots !';
  }

  @override
  String get wordDeleted => 'Mot supprimé';

  @override
  String get appearance => 'Apparence';

  @override
  String get darkMode => 'Thème sombre';

  @override
  String get darkModeEnabled => 'Mode sombre activé';

  @override
  String get lightModeEnabled => 'Mode clair activé';

  @override
  String get language => 'Langue';

  @override
  String get selectLanguage => 'Sélectionner la langue';

  @override
  String get currentDeck => 'Deck actuel';

  @override
  String get progress => 'Progression';

  @override
  String get total => 'Total';

  @override
  String get remaining => 'Restants';

  @override
  String get completed_plural => 'Réussis';

  @override
  String get data => 'Données';

  @override
  String get resetCurrentDeck => 'Réinitialiser le deck actuel';

  @override
  String get restartFromBeginning => 'Recommencer depuis le début';

  @override
  String get clearAllData => 'Effacer toutes les données';

  @override
  String get deleteAllProgress => 'Supprimer tous les progrès et paramètres';

  @override
  String get warning => '⚠️ Attention !';

  @override
  String get clearDataWarning =>
      'Cette action va supprimer :\n• Tous tes decks personnalisés\n• Toute ta progression\n• Tous tes paramètres\n\nCette action est IRRÉVERSIBLE !';

  @override
  String get clearAll => 'Tout effacer';

  @override
  String get about => 'À propos';

  @override
  String get version => 'Version';

  @override
  String get description =>
      'Application de révision de langues avec roue interactive.\n\nApprends de nouveaux mots chaque jour et améliore ton vocabulaire !';

  @override
  String get madeWithLove => 'Fait avec passion';

  @override
  String deckSelected(String name) {
    return 'Deck \"$name\" sélectionné';
  }

  @override
  String deckCreated(String name) {
    return 'Deck \"$name\" créé !';
  }

  @override
  String deckModified(String name) {
    return 'Deck \"$name\" modifié !';
  }

  @override
  String deckDeleted(String name) {
    return 'Deck \"$name\" supprimé';
  }

  @override
  String get deckReset => 'Deck réinitialisé !';

  @override
  String get decksReloaded => 'Decks rechargés !';

  @override
  String get allDataCleared =>
      'Toutes les données ont été effacées.\nRedémarre l\'application.';

  @override
  String get remainingWordsList => 'Mots restants';

  @override
  String get toReview => 'À réviser';

  @override
  String get succeeded => 'Réussis';

  @override
  String get noWordSucceeded => 'Aucun mot réussi pour l\'instant';

  @override
  String get allWordsSucceeded => 'Tous les mots sont réussis ! 🎉';

  @override
  String get close => 'Fermer';

  @override
  String get beginner => 'Débutant';

  @override
  String get intermediate => 'Intermédiaire';

  @override
  String get advanced => 'Avancé';

  @override
  String get noDeck => 'Aucun deck';

  @override
  String get changeWord => 'Changer de mot';

  @override
  String get noDecksAvailable => 'Aucun deck disponible';

  @override
  String drawingValidationQuestion(String word) {
    return 'As-tu bien dessiné : $word ?';
  }

  @override
  String get noWrong => 'Non, mauvais';

  @override
  String get yesCorrect => 'Oui, correct !';

  @override
  String get noWordsAvailable => 'Aucun mot disponible';

  @override
  String get chooseDeckToStart => 'Choisis un deck pour commencer';

  @override
  String get statistics => 'Statistiques';

  @override
  String get viewStatistics => 'Voir les statistiques';

  @override
  String get trackYourProgress => 'Suivez votre progression';

  @override
  String get noStatistics => 'Aucune statistique disponible';

  @override
  String get startReviewing => 'Commencez à réviser pour voir vos statistiques';

  @override
  String get currentStreak => 'Série actuelle';

  @override
  String get days => 'jours';

  @override
  String get learned => 'appris';

  @override
  String get last7Days => '7 derniers jours';

  @override
  String get monthlyActivity => 'Activité mensuelle';

  @override
  String get topDecks => 'Top 5 des decks';

  @override
  String reviewsCount(int count) {
    return '$count révisions';
  }

  @override
  String get dataWillBeDeleted => 'Données supprimées';

  @override
  String get deckProgress => 'Progression des decks';

  @override
  String get preferences => 'Préférences';

  @override
  String get statisticsWillBeKept => 'Les statistiques seront conservées';

  @override
  String get favoriteGameModes => 'Modes de jeu favoris';

  @override
  String get wordsLearned => 'Mots appris';

  @override
  String get noGameData => 'Aucune donnée de jeu';

  @override
  String gamesPlayed(int count) {
    return '$count parties jouées';
  }

  @override
  String get less => 'Moins';

  @override
  String get more => 'Plus';

  @override
  String revisionsTooltip(String date, int count) {
    return '$date : $count révisions';
  }

  @override
  String get classicModeTitle => 'Entraînement classique';

  @override
  String get classicModeDesc => 'Roue et dessin/texte';

  @override
  String get gameModesTitle => 'Modes de jeu';

  @override
  String get manageDecksDesc => 'Créer et modifier vos listes';

  @override
  String get noDeckSelected => 'Aucun deck sélectionné';

  @override
  String get selectDeck => 'Choisir un deck';

  @override
  String get reverseModeTitle => 'Entraînement inversé';

  @override
  String get reverseModeDesc => 'Devinez la question via la réponse';

  @override
  String get quizModeTitle => 'Quiz Rapide';

  @override
  String get quizModeDesc => 'Choisis la bonne réponse parmi 4 propositions.';
}
