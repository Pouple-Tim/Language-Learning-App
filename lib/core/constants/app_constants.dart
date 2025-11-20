/// Constantes globales de l'application Language Learning.
///
/// Cette classe contient toutes les constantes utilisées à travers l'application,
/// organisées par catégories : configuration générale, stockage local, identifiants
/// de decks, animations et validation.
///
/// **Architecture :**
/// ```
/// lib/
/// ├── core/
/// │   └── constants/
/// │       └── app_constants.dart  ← Ce fichier
/// ```
///
/// **Note :** Cette classe ne doit jamais être instanciée. Toutes les constantes
/// sont statiques et accessibles directement via `AppConstants.nomConstante`.
///
/// **Exemple d'utilisation :**
/// ```dart
/// // Utiliser le nom de l'app
/// title: AppConstants.appName,
///
/// // Accéder au stockage
/// final settings = prefs.getString(AppConstants.keySettings);
///
/// // Valider un nom de deck
/// if (name.length < AppConstants.minDeckNameLength) {
///   return 'Nom trop court';
/// }
/// ```
///
/// **Voir aussi :**
/// - [SettingsRepository] qui utilise les clés de stockage
/// - [DeckProvider] qui utilise les IDs de decks
/// - [HomeScreen] qui utilise les constantes d'animation
class AppConstants {
  // ═══════════════════════════════════════════════════════════════════════════
  // Configuration générale
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Nom de l'application affiché dans la barre de titre et les métadonnées.
  ///
  /// Utilisé dans :
  /// - [MaterialApp.title]
  /// - Écran "À propos"
  /// - Notifications système
  ///
  /// **Exemple :**
  /// ```dart
  /// MaterialApp(
  ///   title: AppConstants.appName,
  ///   // ...
  /// )
  /// ```
  static const String appName = 'Language Learning';
  
  // ═══════════════════════════════════════════════════════════════════════════
  // Clés de stockage local (SharedPreferences)
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Clé pour stocker les paramètres de l'application en JSON.
  ///
  /// Contient :
  /// - `isDarkMode` (bool) : Mode sombre activé
  /// - `locale` (String) : Langue de l'interface ('en', 'fr', 'es')
  /// - `lastReset` (String) : Date du dernier reset quotidien (ISO 8601)
  ///
  /// **Utilisation :**
  /// ```dart
  /// final settingsJson = prefs.getString(AppConstants.keySettings);
  /// final settings = Settings.fromJson(jsonDecode(settingsJson));
  /// ```
  ///
  /// **Voir aussi :**
  /// - [SettingsRepository.loadSettings]
  /// - [SettingsRepository.saveSettings]
  static const String keySettings = 'app_settings';
  
  /// Clé pour stocker la liste des decks personnalisés créés par l'utilisateur.
  ///
  /// Format : JSON array de [Deck] sérialisés.
  ///
  /// **Exemple de données :**
  /// ```json
  /// [
  ///   {
  ///     "id": "custom-123",
  ///     "name": "Mon vocabulaire",
  ///     "cards": [...]
  ///   }
  /// ]
  /// ```
  ///
  /// **Utilisation :**
  /// ```dart
  /// final decksJson = prefs.getString(AppConstants.keyCustomDecks);
  /// final decks = (jsonDecode(decksJson) as List)
  ///     .map((e) => Deck.fromJson(e))
  ///     .toList();
  /// ```
  ///
  /// **Voir aussi :**
  /// - [DeckProvider.loadDecks]
  /// - [DeckProvider.saveCustomDecks]
  static const String keyCustomDecks = 'custom_decks';
  
  /// Clé pour stocker l'ID du deck actuellement sélectionné.
  ///
  /// Permet de restaurer le deck actif au redémarrage de l'application.
  ///
  /// **Valeurs possibles :**
  /// - ID d'un deck de base : [deckJapaneseHiragana], [deckKoreanHangul], etc.
  /// - ID d'un deck custom : `"custom-{uuid}"`
  /// - `null` si aucun deck n'est sélectionné
  ///
  /// **Utilisation :**
  /// ```dart
  /// final deckId = prefs.getString(AppConstants.keyCurrentDeck);
  /// if (deckId != null) {
  ///   await deckProvider.loadDeck(deckId);
  /// }
  /// ```
  ///
  /// **Voir aussi :**
  /// - [DeckProvider.selectedDeck]
  /// - [GameProvider.setDeck]
  static const String keyCurrentDeck = 'current_deck';
  
  /// Clé pour stocker la date du dernier reset quotidien (format ISO 8601).
  ///
  /// Utilisée pour détecter le changement de jour et réinitialiser
  /// automatiquement le deck quotidien.
  ///
  /// **Format :** `"2025-11-19T00:00:00.000Z"`
  ///
  /// **Utilisation :**
  /// ```dart
  /// final lastResetStr = prefs.getString(AppConstants.keyLastReset);
  /// final lastReset = DateTime.parse(lastResetStr);
  ///
  /// if (DateTime.now().day != lastReset.day) {
  ///   await gameProvider.resetDailyProgress();
  /// }
  /// ```
  ///
  /// **Voir aussi :**
  /// - [GameProvider.checkDailyReset]
  /// - [SettingsRepository.needsDailyReset]
  static const String keyLastReset = 'last_reset_date';
  
  // ═══════════════════════════════════════════════════════════════════════════
  // Identifiants des decks de base (préinstallés)
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// ID du deck Hiragana japonais de base.
  ///
  /// Contient les 46 caractères Hiragana de base :
  /// - あ (a), い (i), う (u), え (e), お (o)
  /// - か (ka), き (ki), く (ku), け (ke), こ (ko)
  /// - etc.
  ///
  /// **Fichier source :** `assets/decks/japanese_hiragana_base.json`
  ///
  /// **Voir aussi :**
  /// - [DeckProvider.loadPresetDecks]
  static const String deckJapaneseHiragana = 'japanese_hiragana_base';
  
  /// ID du deck Hangul coréen de base.
  ///
  /// Contient les consonnes et voyelles de base du Hangul :
  /// - Consonnes : ㄱ (g/k), ㄴ (n), ㄷ (d/t), ㄹ (r/l), ㅁ (m), etc.
  /// - Voyelles : ㅏ (a), ㅓ (eo), ㅗ (o), ㅜ (u), ㅡ (eu), ㅣ (i)
  ///
  /// **Fichier source :** `assets/decks/korean_hangul_base.json`
  ///
  /// **Voir aussi :**
  /// - [DeckProvider.loadPresetDecks]
  static const String deckKoreanHangul = 'korean_hangul_base';
  
  /// ID du deck d'espagnol de base.
  ///
  /// Contient du vocabulaire espagnol courant :
  /// - Salutations : Hola, Buenos días, Gracias
  /// - Nombres : Uno, Dos, Tres
  /// - Couleurs : Rojo, Azul, Verde
  /// - Nourriture : Pan, Agua, Café
  ///
  /// **Fichier source :** `assets/decks/spanish_basics_base.json`
  ///
  /// **Voir aussi :**
  /// - [DeckProvider.loadPresetDecks]
  static const String deckSpanishBasics = 'spanish_basics_base';
  
  // ═══════════════════════════════════════════════════════════════════════════
  // Paramètres d'animation
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Durée de l'animation de rotation de la roue en millisecondes.
  ///
  /// La roue effectue 3-5 tours complets avec un effet de décélération
  /// progressive avant de s'arrêter sur une carte aléatoire.
  ///
  /// **Valeur recommandée :** 2000ms (2 secondes) pour un effet satisfaisant.
  ///
  /// **Utilisation :**
  /// ```dart
  /// AnimationController(
  ///   duration: Duration(
  ///     milliseconds: AppConstants.wheelSpinDuration,
  ///   ),
  ///   vsync: this,
  /// )..forward();
  /// ```
  ///
  /// **Voir aussi :**
  /// - [HomeScreen] widget de la roue
  /// - [GameProvider.spinWheel]
  static const int wheelSpinDuration = 2000; // millisecondes
  
  /// Nombre de segments visibles sur la roue.
  ///
  /// La roue affiche toujours 10 segments maximum, même si le deck
  /// contient plus de cartes. Les segments sont remplis cycliquement
  /// si nécessaire.
  ///
  /// **Exemples :**
  /// - Deck de 5 cartes → 5 segments utilisés, 5 vides
  /// - Deck de 10 cartes → 10 segments utilisés
  /// - Deck de 15 cartes → 10 segments (cartes 1-10)
  ///
  /// **Utilisation :**
  /// ```dart
  /// final segments = min(
  ///   deck.cards.length,
  ///   AppConstants.wheelSegments,
  /// );
  /// ```
  ///
  /// **Voir aussi :**
  /// - [HomeScreen] calcul des segments
  static const int wheelSegments = 10;
  
  // ═══════════════════════════════════════════════════════════════════════════
  // Règles de validation
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Longueur minimale du nom d'un deck (en caractères).
  ///
  /// Empêche la création de decks avec des noms trop courts ou vides.
  ///
  /// **Utilisation :**
  /// ```dart
  /// String? validateDeckName(String name) {
  ///   if (name.length < AppConstants.minDeckNameLength) {
  ///     return 'Le nom doit contenir au moins ${AppConstants.minDeckNameLength} caractères';
  ///   }
  ///   return null;
  /// }
  /// ```
  ///
  /// **Voir aussi :**
  /// - [DeckCreationScreen] formulaire de création
  /// - [maxDeckNameLength]
  static const int minDeckNameLength = 3;
  
  /// Longueur maximale du nom d'un deck (en caractères).
  ///
  /// Limite la taille des noms pour éviter les problèmes d'affichage
  /// dans l'interface utilisateur.
  ///
  /// **Utilisation :**
  /// ```dart
  /// TextFormField(
  ///   maxLength: AppConstants.maxDeckNameLength,
  ///   validator: (value) {
  ///     if (value != null && value.length > AppConstants.maxDeckNameLength) {
  ///       return 'Nom trop long (max ${AppConstants.maxDeckNameLength} caractères)';
  ///     }
  ///     return null;
  ///   },
  /// )
  /// ```
  ///
  /// **Voir aussi :**
  /// - [DeckCreationScreen] formulaire de création
  /// - [minDeckNameLength]
  static const int maxDeckNameLength = 50;
  
  /// Nombre minimum de cartes requises dans un deck pour être valide.
  ///
  /// Assure qu'un deck contient suffisamment de contenu pour être
  /// utilisé efficacement dans le jeu quotidien.
  ///
  /// **Utilisation :**
  /// ```dart
  /// bool isDeckValid(Deck deck) {
  ///   return deck.cards.length >= AppConstants.minWordsInDeck;
  /// }
  /// ```
  ///
  /// **Voir aussi :**
  /// - [DeckCreationScreen] validation du formulaire
  /// - [DeckProvider.createDeck]
  static const int minWordsInDeck = 5;
}