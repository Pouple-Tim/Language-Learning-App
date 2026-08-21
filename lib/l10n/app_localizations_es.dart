// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'Aprendizaje de Idiomas';

  @override
  String get homeTitle => 'Aprendizaje de Idiomas';

  @override
  String get decksTitle => 'Mis Mazos';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get spinWheel => 'Girar la rueda';

  @override
  String get spinning => 'Girando...';

  @override
  String get validate => 'Validar';

  @override
  String get skip => 'Saltar esta palabra';

  @override
  String get clear => 'Borrar';

  @override
  String get typeAnswer => 'Escribe tu respuesta...';

  @override
  String get spinFirst => 'Gira la rueda primero';

  @override
  String drawCharacter(String answer) {
    return 'Dibuja el carácter correspondiente a: $answer';
  }

  @override
  String wordsRemaining(int count) {
    return '$count palabras restantes';
  }

  @override
  String totalWords(int count) {
    return 'Palabras aprendidas';
  }

  @override
  String get correct => '¡Correcto! 🎉';

  @override
  String get tryAgain => 'Inténtalo de nuevo';

  @override
  String get completed => '¡Bravo! 🎉';

  @override
  String get completedMessage => '¡Has completado todas las palabras!';

  @override
  String get restart => 'Reiniciar';

  @override
  String get reset => 'Restablecer';

  @override
  String get resetDeck => '¿Restablecer el mazo?';

  @override
  String get resetDeckMessage =>
      'Elige el modo cuyo progreso quieres restablecer para este mazo.';

  @override
  String get resetThisMode => 'Restablecer este modo';

  @override
  String get resetAllModes => 'Restablecer todos los modos';

  @override
  String modeReset(String mode) {
    return '¡$mode restablecido!';
  }

  @override
  String get noSentencesInDeck => 'Este mazo aún no tiene frases.';

  @override
  String get cancel => 'Cancelar';

  @override
  String get decksAvailable => 'Mazos disponibles';

  @override
  String get myDecks => 'Mis mazos';

  @override
  String get createDeck => 'Crear un mazo';

  @override
  String get noCustomDecks => 'No hay mazos personalizados';

  @override
  String get createFirstDeck => '¡Crea tu primer mazo para empezar!';

  @override
  String get deck => 'mazo';

  @override
  String get decks => 'mazos';

  @override
  String get editDeck => 'Editar el mazo';

  @override
  String get createNewDeck => 'Crear un mazo';

  @override
  String get deckName => 'Nombre del mazo';

  @override
  String get deckNameHint => 'Ej: Español - Vocabulario';

  @override
  String get enterName => 'Introduce un nombre';

  @override
  String nameMinLength(int min) {
    return 'El nombre debe tener al menos $min caracteres';
  }

  @override
  String get inputType => 'Tipo de entrada';

  @override
  String get text => 'Texto';

  @override
  String get drawing => 'Dibujo';

  @override
  String get words => 'Palabras';

  @override
  String get addWord => 'Añadir';

  @override
  String get noWords => 'No se han añadido palabras';

  @override
  String get question => 'Pregunta';

  @override
  String get answer => 'Respuesta';

  @override
  String get enterQuestion => 'Introduce una pregunta';

  @override
  String get enterAnswer => 'Introduce una respuesta';

  @override
  String get save => 'Guardar';

  @override
  String get edit => 'Editar';

  @override
  String get delete => 'Eliminar';

  @override
  String get deleteDeck => '¿Eliminar este mazo?';

  @override
  String deleteDeckMessage(String name) {
    return '¿Seguro que quieres eliminar \"$name\"?\nEsta acción es irreversible.';
  }

  @override
  String addMinWords(int min) {
    return '¡Añade al menos $min palabras!';
  }

  @override
  String get wordDeleted => 'Palabra eliminada';

  @override
  String get appearance => 'Apariencia';

  @override
  String get darkMode => 'Modo oscuro';

  @override
  String get darkModeEnabled => 'Modo oscuro activado';

  @override
  String get lightModeEnabled => 'Modo claro activado';

  @override
  String get language => 'Idioma';

  @override
  String get selectLanguage => 'Seleccionar idioma';

  @override
  String get currentDeck => 'Mazo actual';

  @override
  String get progress => 'Progreso';

  @override
  String get total => 'Total';

  @override
  String get remaining => 'Restantes';

  @override
  String get completed_plural => 'Completadas';

  @override
  String get data => 'Datos';

  @override
  String get resetCurrentDeck => 'Restablecer el mazo actual';

  @override
  String get restartFromBeginning => 'Reiniciar desde el principio';

  @override
  String get clearAllData => 'Borrar todos los datos';

  @override
  String get deleteAllProgress => 'Eliminar todo el progreso y los ajustes';

  @override
  String get warning => '⚠️ ¡Atención!';

  @override
  String get clearDataWarning =>
      'Esta acción eliminará:\n• Todos tus mazos personalizados\n• Todo tu progreso\n• Todos tus ajustes\n\n¡Esta acción es IRREVERSIBLE!';

  @override
  String get clearAll => 'Borrar todo';

  @override
  String get about => 'Acerca de';

  @override
  String get version => 'Versión';

  @override
  String get description =>
      'Aplicación de repaso de idiomas con una rueda interactiva.\n\n¡Aprende nuevas palabras cada día y mejora tu vocabulario!';

  @override
  String get madeWithLove => 'Hecho con pasión';

  @override
  String deckSelected(String name) {
    return 'Mazo \"$name\" seleccionado';
  }

  @override
  String deckCreated(String name) {
    return '¡Mazo \"$name\" creado!';
  }

  @override
  String deckModified(String name) {
    return '¡Mazo \"$name\" modificado!';
  }

  @override
  String deckDeleted(String name) {
    return 'Mazo \"$name\" eliminado';
  }

  @override
  String get deckReset => '¡Mazo restablecido!';

  @override
  String get decksReloaded => '¡Mazos recargados!';

  @override
  String get allDataCleared =>
      'Todos los datos han sido borrados.\nReinicia la aplicación.';

  @override
  String get remainingWordsList => 'Palabras restantes';

  @override
  String get toReview => 'Para repasar';

  @override
  String get succeeded => 'Completadas';

  @override
  String get noWordSucceeded => 'Ninguna palabra completada por ahora';

  @override
  String get allWordsSucceeded => '¡Todas las palabras completadas! 🎉';

  @override
  String get close => 'Cerrar';

  @override
  String get beginner => 'Principiante';

  @override
  String get intermediate => 'Intermedio';

  @override
  String get advanced => 'Avanzado';

  @override
  String get noDeck => 'Ningún mazo';

  @override
  String get changeWord => 'Cambiar palabra';

  @override
  String get noDecksAvailable => 'No hay mazos disponibles';

  @override
  String drawingValidationQuestion(String word) {
    return '¿Has dibujado bien: $word?';
  }

  @override
  String get noWrong => 'No, incorrecto';

  @override
  String get yesCorrect => 'Sí, ¡correcto!';

  @override
  String get noWordsAvailable => 'No hay palabras disponibles';

  @override
  String get chooseDeckToStart => 'Elige un mazo para empezar';

  @override
  String get statistics => 'Estadísticas';

  @override
  String get viewStatistics => 'Ver estadísticas';

  @override
  String get trackYourProgress => 'Sigue tu progreso';

  @override
  String get noStatistics => 'No hay estadísticas disponibles';

  @override
  String get startReviewing => 'Comienza a repasar para ver tus estadísticas';

  @override
  String get currentStreak => 'Racha actual';

  @override
  String get days => 'días';

  @override
  String get learned => 'aprendidas';

  @override
  String get last7Days => 'Últimos 7 días';

  @override
  String get monthlyActivity => 'Actividad mensual';

  @override
  String get topDecks => 'Top 5 mazos';

  @override
  String reviewsCount(int count) {
    return '$count revisiones';
  }

  @override
  String get dataWillBeDeleted => 'Los datos serán eliminados';

  @override
  String get deckProgress => 'Progreso de los mazos';

  @override
  String get preferences => 'Preferencias';

  @override
  String get statisticsWillBeKept => 'Las estadísticas se conservarán';

  @override
  String get favoriteGameModes => 'Modos de juego favoritos';

  @override
  String get wordsLearned => 'Palabras aprendidas';

  @override
  String get noGameData => 'Sin datos de juego';

  @override
  String gamesPlayed(int count) {
    return '$count partidas jugadas';
  }

  @override
  String get less => 'Menos';

  @override
  String get more => 'Más';

  @override
  String revisionsTooltip(String date, int count) {
    return '$date: $count repasos';
  }

  @override
  String get classicModeTitle => 'Entrenamiento clásico';

  @override
  String get classicModeDesc => 'Ruleta y dibujo/texto';

  @override
  String get gameModesTitle => 'Modos de juego';

  @override
  String get manageDecksDesc => 'Crea y edita tus listas';

  @override
  String get noDeckSelected => 'Ningún mazo seleccionado';

  @override
  String get selectDeck => 'Seleccionar un mazo';

  @override
  String get reverseModeTitle => 'Entrenamiento inverso';

  @override
  String get reverseModeDesc => 'Adivina la pregunta dada la respuesta';

  @override
  String get quizModeTitle => 'Quiz Rápido';

  @override
  String get quizModeDesc => 'Elige la respuesta correcta entre 4 opciones.';
}
