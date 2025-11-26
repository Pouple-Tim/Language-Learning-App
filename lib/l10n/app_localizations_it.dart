// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appName => 'Apprendimento delle Lingue';

  @override
  String get homeTitle => 'Apprendimento delle Lingue';

  @override
  String get decksTitle => 'I miei mazzi';

  @override
  String get settingsTitle => 'Impostazioni';

  @override
  String get spinWheel => 'Gira la ruota';

  @override
  String get spinning => 'Girando...';

  @override
  String get validate => 'Conferma';

  @override
  String get skip => 'Salta questa parola';

  @override
  String get clear => 'Cancella';

  @override
  String get typeAnswer => 'Scrivi la tua risposta...';

  @override
  String get spinFirst => 'Gira prima la ruota';

  @override
  String drawCharacter(String answer) {
    return 'Disegna il carattere corrispondente a: $answer';
  }

  @override
  String wordsRemaining(int count) {
    return '$count parole rimanenti';
  }

  @override
  String totalWords(int count) {
    return 'Parole imparate';
  }

  @override
  String get correct => 'Corretto! 🎉';

  @override
  String get tryAgain => 'Riprova';

  @override
  String get completed => 'Bravo! 🎉';

  @override
  String get completedMessage => 'Hai completato tutte le parole!';

  @override
  String get restart => 'Ricomincia';

  @override
  String get reset => 'Reimposta';

  @override
  String get resetDeck => 'Reimpostare il mazzo?';

  @override
  String get resetDeckMessage =>
      'Vuoi ricominciare questo mazzo dall’inizio? Tutti i tuoi progressi andranno persi.';

  @override
  String get cancel => 'Annulla';

  @override
  String get decksAvailable => 'Mazzi disponibili';

  @override
  String get myDecks => 'I miei mazzi';

  @override
  String get createDeck => 'Crea un mazzo';

  @override
  String get noCustomDecks => 'Nessun mazzo personalizzato';

  @override
  String get createFirstDeck => 'Crea il tuo primo mazzo per iniziare!';

  @override
  String get deck => 'mazzo';

  @override
  String get decks => 'mazzi';

  @override
  String get editDeck => 'Modifica il mazzo';

  @override
  String get createNewDeck => 'Crea un mazzo';

  @override
  String get deckName => 'Nome del mazzo';

  @override
  String get deckNameHint => 'Es: Italiano - Vocabolario';

  @override
  String get enterName => 'Inserisci un nome';

  @override
  String nameMinLength(int min) {
    return 'Il nome deve contenere almeno $min caratteri';
  }

  @override
  String get inputType => 'Tipo di input';

  @override
  String get text => 'Testo';

  @override
  String get drawing => 'Disegno';

  @override
  String get words => 'Parole';

  @override
  String get addWord => 'Aggiungi';

  @override
  String get noWords => 'Nessuna parola aggiunta';

  @override
  String get question => 'Domanda';

  @override
  String get answer => 'Risposta';

  @override
  String get enterQuestion => 'Inserisci una domanda';

  @override
  String get enterAnswer => 'Inserisci una risposta';

  @override
  String get save => 'Salva';

  @override
  String get edit => 'Modifica';

  @override
  String get delete => 'Elimina';

  @override
  String get deleteDeck => 'Eliminare questo mazzo?';

  @override
  String deleteDeckMessage(String name) {
    return 'Sei sicuro di voler eliminare \"$name\"?\nQuesta azione è irreversibile.';
  }

  @override
  String addMinWords(int min) {
    return 'Aggiungi almeno $min parole!';
  }

  @override
  String get wordDeleted => 'Parola cancellata';

  @override
  String get appearance => 'Aspetto';

  @override
  String get darkMode => 'Modalità scura';

  @override
  String get darkModeEnabled => 'Modalità scura attivata';

  @override
  String get lightModeEnabled => 'Modalità chiara attivata';

  @override
  String get language => 'Lingua';

  @override
  String get selectLanguage => 'Seleziona lingua';

  @override
  String get currentDeck => 'Mazzo attuale';

  @override
  String get progress => 'Progresso';

  @override
  String get total => 'Totale';

  @override
  String get remaining => 'Rimanenti';

  @override
  String get completed_plural => 'Completate';

  @override
  String get data => 'Dati';

  @override
  String get resetCurrentDeck => 'Reimposta il mazzo attuale';

  @override
  String get restartFromBeginning => 'Ricomincia dall’inizio';

  @override
  String get clearAllData => 'Cancella tutti i dati';

  @override
  String get deleteAllProgress => 'Elimina tutti i progressi e le impostazioni';

  @override
  String get warning => '⚠️ Attenzione!';

  @override
  String get clearDataWarning =>
      'Questa azione eliminerà:\n• Tutti i tuoi mazzi personalizzati\n• Tutti i tuoi progressi\n• Tutte le tue impostazioni\n\nQuesta azione è IRREVERSIBILE!';

  @override
  String get clearAll => 'Elimina tutto';

  @override
  String get about => 'Informazioni';

  @override
  String get version => 'Versione';

  @override
  String get description =>
      'Applicazione per ripassare le lingue con una ruota interattiva.\n\nImpara nuove parole ogni giorno e migliora il tuo vocabolario!';

  @override
  String get madeWithLove => 'Creato con passione';

  @override
  String deckSelected(String name) {
    return 'Mazzo \"$name\" selezionato';
  }

  @override
  String deckCreated(String name) {
    return 'Mazzo \"$name\" creato!';
  }

  @override
  String deckModified(String name) {
    return 'Mazzo \"$name\" modificato!';
  }

  @override
  String deckDeleted(String name) {
    return 'Mazzo \"$name\" eliminato';
  }

  @override
  String get deckReset => 'Mazzo reimpostato!';

  @override
  String get decksReloaded => 'Mazzi ricaricati!';

  @override
  String get allDataCleared =>
      'Tutti i dati sono stati eliminati.\nRiavvia l’applicazione.';

  @override
  String get remainingWordsList => 'Parole rimanenti';

  @override
  String get toReview => 'Da ripassare';

  @override
  String get succeeded => 'Completate';

  @override
  String get noWordSucceeded => 'Nessuna parola completata finora';

  @override
  String get allWordsSucceeded => 'Tutte le parole completate! 🎉';

  @override
  String get close => 'Chiudi';

  @override
  String get beginner => 'Principiante';

  @override
  String get intermediate => 'Intermedio';

  @override
  String get advanced => 'Avanzato';

  @override
  String get noDeck => 'Nessun mazzo';

  @override
  String get changeWord => 'Cambia parola';

  @override
  String get noDecksAvailable => 'Nessun mazzo disponibile';

  @override
  String drawingValidationQuestion(String word) {
    return 'Hai disegnato correttamente: $word?';
  }

  @override
  String get noWrong => 'No, errato';

  @override
  String get yesCorrect => 'Sì, corretto!';

  @override
  String get noWordsAvailable => 'Nessuna parola disponibile';

  @override
  String get chooseDeckToStart => 'Scegli un mazzo per iniziare';

  @override
  String get statistics => 'Statistiche';

  @override
  String get viewStatistics => 'Vedi statistiche';

  @override
  String get trackYourProgress => 'Segui i tuoi progressi';

  @override
  String get noStatistics => 'Nessuna statistica disponibile';

  @override
  String get startReviewing =>
      'Inizia il ripasso per vedere le tue statistiche';

  @override
  String get currentStreak => 'Serie attuale';

  @override
  String get days => 'giorni';

  @override
  String get learned => 'imparate';

  @override
  String get last7Days => 'Ultimi 7 giorni';

  @override
  String get monthlyActivity => 'Attività mensile';

  @override
  String get topDecks => 'Top 5 mazzi';

  @override
  String reviewsCount(int count) {
    return '$count revisioni';
  }

  @override
  String get dataWillBeDeleted => 'I dati saranno eliminati';

  @override
  String get deckProgress => 'Progresso dei mazzi';

  @override
  String get preferences => 'Preferenze';

  @override
  String get statisticsWillBeKept => 'Le statistiche saranno mantenute';

  @override
  String get favoriteGameModes => 'Modalità di gioco preferite';

  @override
  String get wordsLearned => 'Parole imparate';

  @override
  String get noGameData => 'Nessun dato di gioco';

  @override
  String gamesPlayed(int count) {
    return '$count partite giocate';
  }

  @override
  String get less => 'Meno';

  @override
  String get more => 'Più';

  @override
  String revisionsTooltip(String date, int count) {
    return '$date: $count revisioni';
  }

  @override
  String get classicModeTitle => 'Allenamento classico';

  @override
  String get classicModeDesc => 'Ruota e disegno/testo';

  @override
  String get gameModesTitle => 'Modalità di gioco';

  @override
  String get manageDecksDesc => 'Crea e modifica le tue liste';

  @override
  String get noDeckSelected => 'Nessun mazzo selezionato';

  @override
  String get selectDeck => 'Seleziona un mazzo';

  @override
  String get reverseModeTitle => 'Allenamento inverso';

  @override
  String get reverseModeDesc => 'Indovina la domanda dalla risposta';
}
