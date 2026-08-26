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
      'Choisis le mode dont tu veux réinitialiser la progression pour ce deck.';

  @override
  String get resetThisMode => 'Réinitialiser ce mode';

  @override
  String get resetAllModes => 'Réinitialiser tous les modes';

  @override
  String modeReset(String mode) {
    return '$mode réinitialisé !';
  }

  @override
  String get noSentencesInDeck => 'Ce deck ne contient pas encore de phrases.';

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
  String get deckDownloadFailed =>
      'Impossible de télécharger ce deck. Vérifie ta connexion et réessaie.';

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

  @override
  String get listeningModeTitle => 'Écoute';

  @override
  String get listeningModeDesc => 'Écoute et choisis le bon caractère.';

  @override
  String get listenButtonLabel => 'Écouter';

  @override
  String get listenButtonTooltip => 'Jouer la prononciation';

  @override
  String get sentenceModeTitle => 'Phrase';

  @override
  String get classicModeGoal =>
      'Mémoriser l\'écriture des mots dans la langue que tu apprends.';

  @override
  String get classicModeHowTo =>
      'Le mot à retenir s\'affiche. Écris-le, ou dessine-le si la langue utilise des caractères (comme le chinois), puis valide pour vérifier ta réponse.';

  @override
  String get reverseModeGoal =>
      'Le même entraînement que le mode classique, mais dans l\'autre sens.';

  @override
  String get reverseModeHowTo =>
      'Ce qui est normalement la réponse en mode classique s\'affiche comme question. Écris ou dessine ce qui était normalement la question, puis valide pour vérifier ta réponse.';

  @override
  String get quizModeGoal =>
      'Reconnaître rapidement un mot parmi plusieurs choix, sans avoir à l\'écrire.';

  @override
  String get quizModeHowTo =>
      'Le mot à apprendre s\'affiche. Choisis la bonne réponse parmi les 4 propositions.';

  @override
  String get listeningModeGoal =>
      'Entraîner l\'oreille à reconnaître un mot prononcé à voix haute.';

  @override
  String get listeningModeHowTo =>
      'Appuie sur le haut-parleur pour écouter le mot (répète autant de fois que besoin), puis choisis la bonne réponse parmi les 4 propositions.';

  @override
  String get sentenceModeGoal =>
      'Apprendre à construire des phrases correctes, pas seulement des mots isolés.';

  @override
  String get sentenceModeHowTo =>
      'La traduction de la phrase s\'affiche. Reconstruis la phrase dans la langue apprise en plaçant les blocs de mots dans le bon ordre.';

  @override
  String get tutorialSkipButton => 'Passer';

  @override
  String get tutorialWelcomeDeckTitle => 'Ton deck';

  @override
  String get tutorialWelcomeDeckDesc =>
      'Ceci affiche le deck que tu es en train de réviser. Appuie dessus pour parcourir ou gérer tes decks.';

  @override
  String get tutorialWelcomeGamesTitle => 'Modes de jeu';

  @override
  String get tutorialWelcomeGamesDesc =>
      'Choisis comment t\'entraîner : classique, inversé, quiz, ou reconstitue la phrase.';

  @override
  String get tutorialWelcomeSettingsTitle => 'Réglages';

  @override
  String get tutorialWelcomeSettingsDesc =>
      'Change le thème, la langue de l\'appli, ou réinitialise ta progression ici.';

  @override
  String get tutorialDecksSelectTitle => 'Choisis un deck';

  @override
  String get tutorialDecksSelectDesc =>
      'Les decks sont regroupés par langue et catégorie — appuie sur une catégorie pour l\'ouvrir, puis sur un deck pour le sélectionner (il sera utilisé partout). Les decks de base se téléchargent automatiquement dès leur première sélection.';

  @override
  String get tutorialDecksCreateTitle => 'Crée le tien';

  @override
  String get tutorialDecksCreateDesc =>
      'Appuie ici pour créer un deck personnalisé avec tes propres mots et phrases.';

  @override
  String get tutorialGameRemainingTitle => 'Suis ta progression';

  @override
  String get tutorialGameRemainingDesc =>
      'Ceci indique combien de mots il reste à réviser dans cette session.';

  @override
  String get tutorialGamePlayTitle => 'Ton deck et ton mode';

  @override
  String get tutorialGamePlayDesc =>
      'Ceci indique le deck que tu révises et le mode de jeu en cours.';

  @override
  String get settingsTutorialsSectionTitle => 'Tutoriels';

  @override
  String get replayWelcomeTutorialTitle => 'Revoir la visite guidée';

  @override
  String get replayWelcomeTutorialSubtitle =>
      'Réafficher la visite de l\'accueil';

  @override
  String get replayDecksTutorialTitle => 'Revoir le tutoriel des decks';

  @override
  String get replayDecksTutorialSubtitle =>
      'Réafficher les astuces de l\'écran decks';

  @override
  String get replayGameTutorialTitle => 'Revoir le tutoriel du jeu';

  @override
  String get replayGameTutorialSubtitle =>
      'Réafficher les astuces de l\'écran de jeu';

  @override
  String get gameGuideSettingsTitle => 'Guide des modes de jeu';

  @override
  String get gameGuideSettingsSubtitle =>
      'Comprendre le but et les règles de chaque jeu';

  @override
  String get gameGuideScreenTitle => 'Guide des jeux';

  @override
  String get gameGuideGoalLabel => 'Objectif';

  @override
  String get gameGuideHowToLabel => 'Comment jouer';

  @override
  String get tutorialReplaySnackbar =>
      'Tu la reverras la prochaine fois que tu ouvriras cet écran';

  @override
  String get tutorialReplayWelcomeSnackbar =>
      'Tu la reverras la prochaine fois que tu ouvriras l\'application';
}
