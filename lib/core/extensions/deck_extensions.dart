/// Extension de localisation pour les decks de cartes.
///
/// Ce fichier fournit des extensions et utilitaires pour traduire les noms
/// des decks et catégories en fonction de la langue de l'interface utilisateur.
///
/// **Architecture :**
/// ```
/// lib/
/// ├── core/
/// │   └── extensions/
/// │       └── deck_extension.dart  ← Ce fichier
/// └── data/
///     ├── models/
///     │   └── deck.dart           → Modèle Deck étendu
///     └── translations/
///         ├── deck_chinese.dart   → Traductions chinoises
///         ├── deck_japanese.dart  → Traductions japonaises
///         └── deck_categories.dart → Traductions catégories
/// ```
///
/// **Fonctionnalités :**
/// - Extension [DeckLocalization] pour traduire les noms de decks
/// - Fonction [translateCategory] pour traduire les catégories
/// - Support multilingue (fr, en, es)
/// - Fallback automatique vers le nom original
///
/// **Exemple d'utilisation :**
/// ```dart
/// // Dans un widget avec BuildContext
/// final deck = Deck(id: 'japanese_hiragana', name: 'Hiragana');
/// final localizedName = deck.localizedName(context);
/// // → 'Hiragana' (en), 'Hiragana' (fr)
///
/// // Traduire une catégorie
/// final category = translateCategory('Japonais', context);
/// // → 'Japanese' (en), 'Japonais' (fr)
/// ```
///
/// **Voir aussi :**
/// - [Deck] modèle de données des decks
/// - [LocaleProvider] gestion de la langue de l'app
/// - [DeckProvider] chargement des decks
library;

import 'package:flutter/material.dart';
import 'package:language_learning_app/data/models/deck.dart';

import 'package:language_learning_app/data/translations/deck_chinese.dart';
import 'package:language_learning_app/data/translations/deck_japanese.dart';
import 'package:language_learning_app/data/translations/deck_categories.dart';

// ═════════════════════════════════════════════════════════════════════════════
// Map des traductions des decks
// ═════════════════════════════════════════════════════════════════════════════

/// Dictionnaire centralisé des traductions pour tous les decks de base.
///
/// **Structure :**
/// ```dart
/// {
///   'deck_id': {
///     'fr': 'Nom français',
///     'en': 'English name',
///     'es': 'Nombre español',
///   }
/// }
/// ```
///
/// **Organisation :**
/// - Les traductions chinoises et japonaises sont dans des fichiers séparés
///   et importées via le spread operator (`...`)
/// - Les traductions simples (coréen, espagnol, français) sont définies inline
///
/// **Ajout d'un nouveau deck :**
/// 1. Ajouter l'ID du deck comme clé
/// 2. Fournir les traductions pour chaque langue supportée
/// 3. Si le deck appartient à une catégorie existante, utiliser le même pattern
///
/// **Exemple :**
/// ```dart
/// 'german_basics': {
///   'fr': 'Allemand - Bases',
///   'en': 'German - Basics',
///   'es': 'Alemán - Básico',
/// },
/// ```
///
/// **Note :** Les IDs doivent correspondre exactement aux IDs des fichiers JSON
/// dans `assets/decks/`.
///
/// **Voir aussi :**
/// - [deckTranslationsChinese] traductions pour les decks chinois
/// - [deckTranslationsJapanese] traductions pour les decks japonais
/// - [deckCategories] traductions des catégories/dossiers
final Map<String, Map<String, String>> _deckTranslations = {

  // ───────────────────────────────────────────────────────────────────────────
  // Chinois (importé depuis deck_chinese.dart)
  // ───────────────────────────────────────────────────────────────────────────
  
  /// Traductions des decks chinois.
  ///
  /// Contient :
  /// - `chinese_hsk1` : Vocabulaire HSK niveau 1
  /// - `chinese_hsk2` : Vocabulaire HSK niveau 2
  /// - `chinese_radicals` : Radicaux chinois de base
  /// - etc.
  ///
  /// **Fichier source :** `data/translations/deck_chinese.dart`
  ...deckTranslationsChinese,
  
  // ───────────────────────────────────────────────────────────────────────────
  // Japonais (importé depuis deck_japanese.dart)
  // ───────────────────────────────────────────────────────────────────────────
  
  /// Traductions des decks japonais.
  ///
  /// Contient :
  /// - `japanese_hiragana` : Syllabaire Hiragana
  /// - `japanese_katakana` : Syllabaire Katakana
  /// - `japanese_kanji_n5` : Kanji JLPT N5
  /// - etc.
  ///
  /// **Fichier source :** `data/translations/deck_japanese.dart`
  ...deckTranslationsJapanese,
  
  // ───────────────────────────────────────────────────────────────────────────
  // Coréen
  // ───────────────────────────────────────────────────────────────────────────
  
  /// Deck d'apprentissage du Hangul (alphabet coréen).
  ///
  /// Contient les 24 lettres de base du Hangul :
  /// - 14 consonnes : ㄱ, ㄴ, ㄷ, ㄹ, ㅁ, ㅂ, ㅅ, ㅇ, ㅈ, ㅊ, ㅋ, ㅌ, ㅍ, ㅎ
  /// - 10 voyelles : ㅏ, ㅑ, ㅓ, ㅕ, ㅗ, ㅛ, ㅜ, ㅠ, ㅡ, ㅣ
  ///
  /// **Fichier JSON :** `assets/decks/korean_hangul.json`
  'korean_hangul': {
    'fr': 'Coréen - Hangul',
    'en': 'Korean - Hangul',
  },
  
  /// Vocabulaire coréen de base.
  ///
  /// Contient environ 100 mots essentiels :
  /// - Salutations : 안녕하세요 (bonjour), 감사합니다 (merci)
  /// - Nombres : 하나 (un), 둘 (deux), 셋 (trois)
  /// - Vie quotidienne : 물 (eau), 밥 (riz), 집 (maison)
  ///
  /// **Fichier JSON :** `assets/decks/korean_basics.json`
  'korean_basics': {
    'fr': 'Coréen - Bases',
    'en': 'Korean - Basics',
  },
  
  // ───────────────────────────────────────────────────────────────────────────
  // Espagnol
  // ───────────────────────────────────────────────────────────────────────────
  
  /// Vocabulaire espagnol de base pour débutants.
  ///
  /// Contient :
  /// - Salutations : Hola, Buenos días, Adiós
  /// - Nombres : Uno, Dos, Tres, Diez, Cien
  /// - Couleurs : Rojo, Azul, Verde, Amarillo
  /// - Aliments : Pan, Agua, Leche, Café
  ///
  /// **Niveau :** A1
  /// **Fichier JSON :** `assets/decks/spanish_basics.json`
  'spanish_basics': {
    'fr': 'Espagnol - Bases',
    'en': 'Spanish - Basics',
  },
  
  /// Conjugaison des verbes espagnols courants.
  ///
  /// Contient les 50 verbes les plus utilisés au présent :
  /// - Ser (être), Estar (être), Haber (avoir)
  /// - Tener (avoir), Hacer (faire), Ir (aller)
  /// - Poder (pouvoir), Decir (dire), Ver (voir)
  ///
  /// **Niveau :** A2-B1
  /// **Fichier JSON :** `assets/decks/spanish_verbs.json`
  'spanish_verbs': {
    'fr': 'Espagnol - Verbes',
    'en': 'Spanish - Verbs',
  },
  
  // ───────────────────────────────────────────────────────────────────────────
  // Français (FLE - Français Langue Étrangère)
  // ───────────────────────────────────────────────────────────────────────────
  
  /// Vocabulaire français de base pour apprenants étrangers.
  ///
  /// Contient :
  /// - Salutations : Bonjour, Merci, Au revoir
  /// - Nombres : Un, Deux, Trois, Dix, Cent
  /// - Couleurs : Rouge, Bleu, Vert, Jaune
  /// - Aliments : Pain, Eau, Lait, Café
  ///
  /// **Niveau :** A1 (CECRL)
  /// **Fichier JSON :** `assets/decks/french_basics.json`
  'french_basics': {
    'fr': 'Français - Bases',
    'en': 'French - Basics',
  },
  
  /// Conjugaison des verbes français essentiels.
  ///
  /// Contient les verbes du 1er, 2ème et 3ème groupe :
  /// - Être, Avoir, Aller, Faire, Dire
  /// - Pouvoir, Vouloir, Savoir, Devoir
  /// - Venir, Prendre, Mettre, Voir
  ///
  /// **Niveau :** A2-B1 (CECRL)
  /// **Fichier JSON :** `assets/decks/french_verbs.json`
  'french_verbs': {
    'fr': 'Français - Verbes',
    'en': 'French - Verbs',
  },
  
  // ───────────────────────────────────────────────────────────────────────────
  // Ajoutez vos autres decks ici
  // ───────────────────────────────────────────────────────────────────────────
  //
  // Template pour un nouveau deck :
  //
  // 'your_deck_id': {
  //   'fr': 'Nom français',
  //   'en': 'English name',
  //   'es': 'Nombre español',
  // },
};

// ═════════════════════════════════════════════════════════════════════════════
// Extension DeckLocalization
// ═════════════════════════════════════════════════════════════════════════════

/// Extension pour ajouter la localisation aux objets [Deck].
///
/// Permet d'obtenir le nom traduit d'un deck en fonction de la langue
/// de l'interface utilisateur, tout en préservant les noms personnalisés
/// des decks créés par l'utilisateur.
///
/// **Comportement :**
/// - **Decks personnalisés** ([DeckType.custom]) : retourne le nom original
/// - **Decks de base** ([DeckType.preset]) : cherche la traduction correspondante
/// - **Fallback** : si aucune traduction n'existe, retourne le nom du JSON
///
/// **Exemple :**
/// ```dart
/// final deck = Deck(
///   id: 'japanese_hiragana',
///   name: 'Hiragana',
///   type: DeckType.preset,
/// );
///
/// // En français
/// print(deck.localizedName(context)); // → 'Hiragana'
///
/// // En anglais
/// print(deck.localizedName(context)); // → 'Hiragana'
///
/// // Deck personnalisé
/// final customDeck = Deck(
///   id: 'custom-123',
///   name: 'Mon vocabulaire perso',
///   type: DeckType.custom,
/// );
/// print(customDeck.localizedName(context)); // → 'Mon vocabulaire perso'
/// ```
///
/// **Voir aussi :**
/// - [Deck] modèle de données
/// - [DeckType] énumération des types de decks
/// - [translateCategory] pour traduire les catégories
extension DeckLocalization on Deck {
  /// Obtient le nom traduit du deck selon la langue actuelle de l'interface.
  ///
  /// Cette méthode utilise le [BuildContext] pour déterminer la locale active
  /// via [Localizations.localeOf] et retourne la traduction appropriée.
  ///
  /// **Logique de résolution :**
  /// 1. Si `type == DeckType.custom` → retourne [name] tel quel
  /// 2. Récupère la langue actuelle (`fr`, `en`, `es`)
  /// 3. Cherche dans [_deckTranslations] une entrée pour `[id][languageCode]`
  /// 4. Si trouvé → retourne la traduction
  /// 5. Sinon → retourne [name] (fallback)
  ///
  /// **Paramètres :**
  /// - [context] : BuildContext Flutter pour accéder à la locale
  ///
  /// **Retourne :**
  /// Le nom du deck dans la langue de l'interface, ou le nom original
  /// si aucune traduction n'est disponible.
  ///
  /// **Exemple complet :**
  /// ```dart
  /// // Dans un Widget
  /// @override
  /// Widget build(BuildContext context) {
  ///   final deck = context.watch<DeckProvider>().selectedDeck;
  ///   
  ///   return Text(
  ///     deck.localizedName(context),
  ///     style: Theme.of(context).textTheme.headlineMedium,
  ///   );
  /// }
  /// ```
  ///
  /// **Performance :**
  /// - Opération O(1) : simple lookup dans une Map
  /// - Peut être appelée dans `build()` sans problème
  /// - Pas de calcul coûteux
  ///
  /// **Gestion d'erreurs :**
  /// - Si `context` n'a pas de [Localizations], utilise la locale système
  /// - Si le deck n'a pas d'ID, retourne [name] (cas rare)
  /// - Aucune exception levée, toujours un String retourné
  ///
  /// **Voir aussi :**
  /// - [LocaleProvider.locale] pour changer la langue
  /// - [_deckTranslations] dictionnaire de traductions
  String localizedName(BuildContext context) {
    // ─────────────────────────────────────────────────────────────────────────
    // Cas 1 : Deck personnalisé → conserver le nom original
    // ─────────────────────────────────────────────────────────────────────────
    
    if (type == DeckType.custom) {
      return name;
    }
    
    // ─────────────────────────────────────────────────────────────────────────
    // Cas 2 : Deck de base → chercher une traduction
    // ─────────────────────────────────────────────────────────────────────────
    
    // Récupérer la locale actuelle depuis le contexte Flutter
    final locale = Localizations.localeOf(context);
    final languageCode = locale.languageCode; // 'fr', 'en', 'es', etc.
    
    // Chercher la traduction pour ce deck spécifique
    final translations = _deckTranslations[id];
    
    // Si une traduction existe pour cette langue, l'utiliser
    if (translations != null && translations.containsKey(languageCode)) {
      return translations[languageCode]!;
    }
    
    // ─────────────────────────────────────────────────────────────────────────
    // Fallback : retourner le nom du JSON
    // ─────────────────────────────────────────────────────────────────────────
    
    // Utile pour les nouveaux decks pas encore traduits
    // ou pour les langues non supportées
    return name;
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Fonction utilitaire : translateCategory
// ═════════════════════════════════════════════════════════════════════════════

/// Traduit le nom d'une catégorie/dossier de decks selon la langue active.
///
/// Les catégories permettent d'organiser les decks par thème ou langue
/// (ex: "Japonais", "Chinois", "Langues européennes").
///
/// **Fonctionnement :**
/// 1. Récupère la langue actuelle via [Localizations.localeOf]
/// 2. Cherche dans [deckCategories] la traduction correspondante
/// 3. Retourne la traduction ou le nom original si non trouvée
///
/// **Paramètres :**
/// - [categoryName] : Nom de la catégorie à traduire (clé)
/// - [context] : BuildContext pour accéder à la locale
///
/// **Retourne :**
/// Le nom de la catégorie dans la langue de l'interface.
///
/// **Exemple d'utilisation :**
/// ```dart
/// // Dans DeckListScreen
/// final categories = ['Japonais', 'Chinois', 'Coréen'];
///
/// for (final category in categories) {
///   print(translateCategory(category, context));
/// }
/// // En français : Japonais, Chinois, Coréen
/// // En anglais : Japanese, Chinese, Korean
/// // En espagnol : Japonés, Chino, Coreano
/// ```
///
/// **Cas d'usage :**
/// - Navigation par catégories dans [DeckListScreen]
/// - Filtres de recherche de decks
/// - Titres de sections dans l'interface
/// - Export/Import de decks avec métadonnées traduites
///
/// **Structure de deckCategories :**
/// ```dart
/// final deckCategories = {
///   'Japonais': {
///     'fr': 'Japonais',
///     'en': 'Japanese',
///     'es': 'Japonés',
///   },
///   'Chinois': {
///     'fr': 'Chinois',
///     'en': 'Chinese',
///     'es': 'Chino',
///   },
/// };
/// ```
///
/// **Performance :**
/// - Opération O(1) : simple lookup dans une Map
/// - Aucune allocation mémoire supplémentaire
/// - Peut être appelée fréquemment sans problème
///
/// **Gestion des erreurs :**
/// - Si [categoryName] n'existe pas dans [deckCategories] → retourne [categoryName]
/// - Si la langue n'est pas supportée → retourne [categoryName]
/// - Aucune exception levée
///
/// **Voir aussi :**
/// - [deckCategories] dictionnaire des traductions de catégories
/// - [DeckProvider.getCategorizedDecks] regroupement par catégories
/// - [localizedName] pour traduire les noms de decks
String translateCategory(String categoryName, BuildContext context) {
  // Récupérer la locale actuelle
  final locale = Localizations.localeOf(context);
  final languageCode = locale.languageCode;
  
  // Chercher la traduction pour cette catégorie
  final translations = deckCategories[categoryName];
  
  // Si une traduction existe, l'utiliser
  if (translations != null && translations.containsKey(languageCode)) {
    return translations[languageCode]!;
  }
  
  // Fallback : retourner le nom original
  // Utile pour les catégories personnalisées ou non traduites
  return categoryName;
}