# In-App Tutorial Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a spotlight-style in-app tutorial: a one-time global welcome tour on the Home screen, plus contextual hints on the Decks and Game screens, all replayable individually from Settings.

**Architecture:** A single new dependency (`tutorial_coach_mark`) renders every tour as a sequence of spotlighted `GlobalKey`-targeted widgets with title/description text. A small `TutorialService` wraps the existing `StorageHelper` (shared_preferences) to track a boolean "seen" flag per tour (welcome / decks / game). Each of the three screens is responsible for building its own list of tour targets and calling a shared `showTutorial()` helper once its data has loaded; Settings gets three independent "replay" tiles that just reset the flags (the tour then reappears naturally next time that screen is visited).

**Tech Stack:** Flutter 3.47.1 / Dart 3.13.1, Provider (existing), `shared_preferences` via `StorageHelper` (existing), new package `tutorial_coach_mark: ^1.3.3`.

**Spec:** No separate spec file — this plan was produced directly from a `mattpocock-skills:grilling` interview in this session. Design summary:

- Global welcome tour (Home, first open ever, including for existing installs on upgrade) + contextual coachmarks on **Decks** and **Game** screens only (not Settings/Statistics/Deck editor).
- All tours use the same coachmark/spotlight visual language, are skippable at every step, and mark themselves "seen" the moment they're shown (not only on completion).
- Settings gets three independent replay controls (welcome / decks / game), each just resetting that tour's flag.
- Copy is authored here (French-first, mirrored into en/es/it) and flows through the existing ARB pipeline.
- This is a side task — does not block or reorder the decks/new-game-mode roadmap.

## Global Constraints

- Flutter SDK floor stays `>=3.8.0 <4.0.0` (unchanged) — `tutorial_coach_mark: ^1.3.3` resolves cleanly against it (verified via `dart pub add --dry-run`).
- No hardcoded UI strings — every new user-facing string is a key in all four `lib/l10n/app_{en,fr,es,it}.arb` files.
- Tutorial "seen" flags persist only through the existing `StorageHelper` static API (`saveBool`/`getBool`) — no new storage mechanism.
- Every tour target must point at a widget already visible on screen for that tour's trigger condition (no spotlighting off-screen/unloaded widgets).
- Each tour marks itself seen immediately when `showTutorial()` is invoked, not on completion — so a skip still counts as "seen" (per the confirmed design).

---

## File Structure

- `lib/core/tutorial/tutorial_service.dart` (new) — the three seen/mark/reset flag pairs, one per tour.
- `lib/core/tutorial/tutorial_coach_mark_helper.dart` (new) — `buildTutorialTarget()` (styling for one spotlighted step) and `showTutorial()` (configures and shows a `TutorialCoachMark`). Shared by all three screens so tour styling stays consistent in one place.
- `lib/screens/home/home_screen.dart` (modify) — `StatelessWidget` → `StatefulWidget`, adds 3 `GlobalKey`s and triggers the welcome tour.
- `lib/screens/decks/decks_screen.dart` (modify) — adds 2 `GlobalKey`s and triggers the decks tour once loading finishes.
- `lib/screens/games/classic_game/game_screen.dart` (modify) — `StatelessWidget` → `StatefulWidget`, adds 2 `GlobalKey`s and triggers the game tour once a deck is loaded.
- `lib/screens/settings/settings_screen.dart` (modify) — adds a "Tutorials" section with 3 replay tiles.
- `lib/l10n/app_en.arb`, `app_fr.arb`, `app_es.arb`, `app_it.arb` (modify) — new tutorial copy keys.
- `pubspec.yaml` (modify) — adds `tutorial_coach_mark` dependency.

---

### Task 1: Add the `tutorial_coach_mark` dependency

**Files:**
- Modify: `pubspec.yaml`
- Modify: `pubspec.lock` (generated)

**Interfaces:**
- Produces: the `tutorial_coach_mark` package (`TutorialCoachMark`, `TargetFocus`, `TargetContent`, `ContentAlign`, `ShapeLightFocus`) available to later tasks.

- [ ] **Step 1: Add the dependency**

Run: `flutter pub add tutorial_coach_mark`

Expected: `pubspec.yaml` gains a `tutorial_coach_mark: ^1.3.3` line under `dependencies`, and `pubspec.lock` is updated.

- [ ] **Step 2: Verify it resolves and the app still analyzes cleanly**

Run: `flutter pub get && flutter analyze`
Expected: no errors (pre-existing warnings, if any, are unrelated and unaffected).

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "feat: add tutorial_coach_mark dependency for in-app tutorial"
```

---

### Task 2: `TutorialService` — seen/mark/reset flags

**Files:**
- Create: `lib/core/tutorial/tutorial_service.dart`
- Test: `test/core/tutorial/tutorial_service_test.dart`

**Interfaces:**
- Consumes: `StorageHelper.getBool(String)`, `StorageHelper.saveBool(String, bool)` (existing, `lib/core/utils/storage_helper.dart`).
- Produces (used by Tasks 5–8): `TutorialService.hasSeenWelcome()/markWelcomeSeen()/resetWelcome()`, `.hasSeenDecks()/markDecksSeen()/resetDecks()`, `.hasSeenGame()/markGameSeen()/resetGame()` — all static, `hasSeenX()` returns `bool` synchronously, `markXSeen()`/`resetX()` return `Future<void>`.

- [ ] **Step 1: Write the failing test**

```dart
// test/core/tutorial/tutorial_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:language_learning_app/core/tutorial/tutorial_service.dart';
import 'package:language_learning_app/core/utils/storage_helper.dart';

void main() {
  group('TutorialService', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await StorageHelper.init();
    });

    test('welcome tour is unseen by default, then seen after marking', () async {
      expect(TutorialService.hasSeenWelcome(), isFalse);

      await TutorialService.markWelcomeSeen();

      expect(TutorialService.hasSeenWelcome(), isTrue);
    });

    test('resetWelcome makes the welcome tour unseen again', () async {
      await TutorialService.markWelcomeSeen();
      await TutorialService.resetWelcome();

      expect(TutorialService.hasSeenWelcome(), isFalse);
    });

    test('decks tour flag is independent from welcome and game', () async {
      await TutorialService.markDecksSeen();

      expect(TutorialService.hasSeenDecks(), isTrue);
      expect(TutorialService.hasSeenWelcome(), isFalse);
      expect(TutorialService.hasSeenGame(), isFalse);
    });

    test('game tour is unseen by default, then seen after marking, then reset', () async {
      expect(TutorialService.hasSeenGame(), isFalse);

      await TutorialService.markGameSeen();
      expect(TutorialService.hasSeenGame(), isTrue);

      await TutorialService.resetGame();
      expect(TutorialService.hasSeenGame(), isFalse);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/tutorial/tutorial_service_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:language_learning_app/core/tutorial/tutorial_service.dart'`.

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/core/tutorial/tutorial_service.dart
import 'package:language_learning_app/core/utils/storage_helper.dart';

/// Tracks whether each in-app tutorial has already been shown.
class TutorialService {
  static const String _keyWelcome = 'tutorial_seen_welcome';
  static const String _keyDecks = 'tutorial_seen_decks';
  static const String _keyGame = 'tutorial_seen_game';

  static bool hasSeenWelcome() => StorageHelper.getBool(_keyWelcome) ?? false;
  static Future<void> markWelcomeSeen() => StorageHelper.saveBool(_keyWelcome, true);
  static Future<void> resetWelcome() => StorageHelper.saveBool(_keyWelcome, false);

  static bool hasSeenDecks() => StorageHelper.getBool(_keyDecks) ?? false;
  static Future<void> markDecksSeen() => StorageHelper.saveBool(_keyDecks, true);
  static Future<void> resetDecks() => StorageHelper.saveBool(_keyDecks, false);

  static bool hasSeenGame() => StorageHelper.getBool(_keyGame) ?? false;
  static Future<void> markGameSeen() => StorageHelper.saveBool(_keyGame, true);
  static Future<void> resetGame() => StorageHelper.saveBool(_keyGame, false);
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/tutorial/tutorial_service_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/core/tutorial/tutorial_service.dart test/core/tutorial/tutorial_service_test.dart
git commit -m "feat: add TutorialService to track seen tutorials"
```

---

### Task 3: Tutorial copy in all four ARB files

**Files:**
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_fr.arb`
- Modify: `lib/l10n/app_es.arb`
- Modify: `lib/l10n/app_it.arb`

**Interfaces:**
- Produces (used by Tasks 4–8 via generated `AppLocalizations`): `tutorialSkipButton`, `tutorialWelcomeDeckTitle/Desc`, `tutorialWelcomeGamesTitle/Desc`, `tutorialWelcomeSettingsTitle/Desc`, `tutorialDecksSelectTitle/Desc`, `tutorialDecksCreateTitle/Desc`, `tutorialGameRemainingTitle/Desc`, `tutorialGamePlayTitle/Desc`, `settingsTutorialsSectionTitle`, `replayWelcomeTutorialTitle/Subtitle`, `replayDecksTutorialTitle/Subtitle`, `replayGameTutorialTitle/Subtitle`, `tutorialReplaySnackbar` — all plain `String` getters, no placeholders.

- [ ] **Step 1: Add the keys to `lib/l10n/app_en.arb`**

Append these keys just before the file's final closing `}` (comma-join with the preceding `quizModeDesc` entry, matching the file's existing style):

```json
  ,
  "tutorialSkipButton": "Skip",
  "tutorialWelcomeDeckTitle": "Your deck",
  "tutorialWelcomeDeckDesc": "This shows the deck you're currently reviewing. Tap it to browse or manage your decks.",
  "tutorialWelcomeGamesTitle": "Game modes",
  "tutorialWelcomeGamesDesc": "Pick how you want to practice: classic, reverse, quiz, or build the sentence.",
  "tutorialWelcomeSettingsTitle": "Settings",
  "tutorialWelcomeSettingsDesc": "Change the theme, app language, or reset your progress from here.",
  "tutorialDecksSelectTitle": "Choose a deck",
  "tutorialDecksSelectDesc": "Tap any deck to select it — it becomes the deck used in every game mode.",
  "tutorialDecksCreateTitle": "Create your own",
  "tutorialDecksCreateDesc": "Tap here to build a custom deck with your own words and sentences.",
  "tutorialGameRemainingTitle": "Track your progress",
  "tutorialGameRemainingDesc": "This shows how many words are left to review in this session.",
  "tutorialGamePlayTitle": "Answer here",
  "tutorialGamePlayDesc": "Spin, type, draw, or pick the right answer depending on the mode — then move to the next word.",
  "settingsTutorialsSectionTitle": "Tutorials",
  "replayWelcomeTutorialTitle": "Replay welcome tour",
  "replayWelcomeTutorialSubtitle": "Show the home screen tour again",
  "replayDecksTutorialTitle": "Replay decks tutorial",
  "replayDecksTutorialSubtitle": "Show the deck screen hints again",
  "replayGameTutorialTitle": "Replay game tutorial",
  "replayGameTutorialSubtitle": "Show the game screen hints again",
  "tutorialReplaySnackbar": "You'll see it again next time you open that screen"
```

- [ ] **Step 2: Add the equivalent keys to `lib/l10n/app_fr.arb`**

```json
  ,
  "tutorialSkipButton": "Passer",
  "tutorialWelcomeDeckTitle": "Ton deck",
  "tutorialWelcomeDeckDesc": "Ceci affiche le deck que tu es en train de réviser. Appuie dessus pour parcourir ou gérer tes decks.",
  "tutorialWelcomeGamesTitle": "Modes de jeu",
  "tutorialWelcomeGamesDesc": "Choisis comment t'entraîner : classique, inversé, quiz, ou reconstitue la phrase.",
  "tutorialWelcomeSettingsTitle": "Réglages",
  "tutorialWelcomeSettingsDesc": "Change le thème, la langue de l'appli, ou réinitialise ta progression ici.",
  "tutorialDecksSelectTitle": "Choisis un deck",
  "tutorialDecksSelectDesc": "Appuie sur un deck pour le sélectionner — il sera utilisé dans tous les modes de jeu.",
  "tutorialDecksCreateTitle": "Crée le tien",
  "tutorialDecksCreateDesc": "Appuie ici pour créer un deck personnalisé avec tes propres mots et phrases.",
  "tutorialGameRemainingTitle": "Suis ta progression",
  "tutorialGameRemainingDesc": "Ceci indique combien de mots il reste à réviser dans cette session.",
  "tutorialGamePlayTitle": "Réponds ici",
  "tutorialGamePlayDesc": "Fais tourner la roue, écris, dessine ou choisis la bonne réponse selon le mode — puis passe au mot suivant.",
  "settingsTutorialsSectionTitle": "Tutoriels",
  "replayWelcomeTutorialTitle": "Revoir la visite guidée",
  "replayWelcomeTutorialSubtitle": "Réafficher la visite de l'accueil",
  "replayDecksTutorialTitle": "Revoir le tutoriel des decks",
  "replayDecksTutorialSubtitle": "Réafficher les astuces de l'écran decks",
  "replayGameTutorialTitle": "Revoir le tutoriel du jeu",
  "replayGameTutorialSubtitle": "Réafficher les astuces de l'écran de jeu",
  "tutorialReplaySnackbar": "Tu la reverras la prochaine fois que tu ouvriras cet écran"
```

- [ ] **Step 3: Add the equivalent keys to `lib/l10n/app_es.arb`**

```json
  ,
  "tutorialSkipButton": "Saltar",
  "tutorialWelcomeDeckTitle": "Tu mazo",
  "tutorialWelcomeDeckDesc": "Aquí se muestra el mazo que estás repasando. Tócalo para explorar o gestionar tus mazos.",
  "tutorialWelcomeGamesTitle": "Modos de juego",
  "tutorialWelcomeGamesDesc": "Elige cómo quieres practicar: clásico, inverso, quiz o construir la frase.",
  "tutorialWelcomeSettingsTitle": "Ajustes",
  "tutorialWelcomeSettingsDesc": "Cambia el tema, el idioma de la app o reinicia tu progreso desde aquí.",
  "tutorialDecksSelectTitle": "Elige un mazo",
  "tutorialDecksSelectDesc": "Toca cualquier mazo para seleccionarlo — se usará en todos los modos de juego.",
  "tutorialDecksCreateTitle": "Crea el tuyo",
  "tutorialDecksCreateDesc": "Toca aquí para crear un mazo personalizado con tus propias palabras y frases.",
  "tutorialGameRemainingTitle": "Sigue tu progreso",
  "tutorialGameRemainingDesc": "Esto muestra cuántas palabras quedan por repasar en esta sesión.",
  "tutorialGamePlayTitle": "Responde aquí",
  "tutorialGamePlayDesc": "Gira, escribe, dibuja o elige la respuesta correcta según el modo — luego pasa a la siguiente palabra.",
  "settingsTutorialsSectionTitle": "Tutoriales",
  "replayWelcomeTutorialTitle": "Repetir la visita guiada",
  "replayWelcomeTutorialSubtitle": "Vuelve a mostrar la visita de inicio",
  "replayDecksTutorialTitle": "Repetir el tutorial de mazos",
  "replayDecksTutorialSubtitle": "Vuelve a mostrar las pistas de la pantalla de mazos",
  "replayGameTutorialTitle": "Repetir el tutorial del juego",
  "replayGameTutorialSubtitle": "Vuelve a mostrar las pistas de la pantalla de juego",
  "tutorialReplaySnackbar": "La volverás a ver la próxima vez que abras esa pantalla"
```

- [ ] **Step 4: Add the equivalent keys to `lib/l10n/app_it.arb`**

```json
  ,
  "tutorialSkipButton": "Salta",
  "tutorialWelcomeDeckTitle": "Il tuo mazzo",
  "tutorialWelcomeDeckDesc": "Qui viene mostrato il mazzo che stai ripassando. Toccalo per sfogliare o gestire i tuoi mazzi.",
  "tutorialWelcomeGamesTitle": "Modalità di gioco",
  "tutorialWelcomeGamesDesc": "Scegli come vuoi allenarti: classica, inversa, quiz o costruzione della frase.",
  "tutorialWelcomeSettingsTitle": "Impostazioni",
  "tutorialWelcomeSettingsDesc": "Cambia il tema, la lingua dell'app o azzera i tuoi progressi da qui.",
  "tutorialDecksSelectTitle": "Scegli un mazzo",
  "tutorialDecksSelectDesc": "Tocca un mazzo per selezionarlo: verrà usato in tutte le modalità di gioco.",
  "tutorialDecksCreateTitle": "Crea il tuo",
  "tutorialDecksCreateDesc": "Tocca qui per creare un mazzo personalizzato con le tue parole e frasi.",
  "tutorialGameRemainingTitle": "Segui i tuoi progressi",
  "tutorialGameRemainingDesc": "Mostra quante parole restano da ripassare in questa sessione.",
  "tutorialGamePlayTitle": "Rispondi qui",
  "tutorialGamePlayDesc": "Gira, scrivi, disegna o scegli la risposta giusta a seconda della modalità, poi passa alla parola successiva.",
  "settingsTutorialsSectionTitle": "Tutorial",
  "replayWelcomeTutorialTitle": "Rivedi il tour di benvenuto",
  "replayWelcomeTutorialSubtitle": "Mostra di nuovo il tour della home",
  "replayDecksTutorialTitle": "Rivedi il tutorial dei mazzi",
  "replayDecksTutorialSubtitle": "Mostra di nuovo i suggerimenti della schermata mazzi",
  "replayGameTutorialTitle": "Rivedi il tutorial del gioco",
  "replayGameTutorialSubtitle": "Mostra di nuovo i suggerimenti della schermata di gioco",
  "tutorialReplaySnackbar": "La rivedrai la prossima volta che aprirai quella schermata"
```

- [ ] **Step 5: Regenerate localizations and verify**

Run: `flutter gen-l10n && flutter analyze`
Expected: `lib/l10n/app_localizations*.dart` regenerate with no errors; `flutter analyze` reports no new errors (all four ARB files must have identical key sets or `gen-l10n` fails with a "missing translation" error — fix any mismatch before proceeding).

- [ ] **Step 6: Commit**

```bash
git add lib/l10n/
git commit -m "feat: add tutorial copy strings (en/fr/es/it)"
```

---

### Task 4: Shared coachmark helper

**Files:**
- Create: `lib/core/tutorial/tutorial_coach_mark_helper.dart`
- Test: `test/core/tutorial/tutorial_coach_mark_helper_test.dart`

**Interfaces:**
- Consumes: `tutorial_coach_mark` package (Task 1), `AppColors.primary` (`lib/core/theme/app_colors.dart`, existing).
- Produces (used by Tasks 5–7):
  - `TargetFocus buildTutorialTarget({required String identify, required GlobalKey keyTarget, required String title, required String description, ContentAlign align = ContentAlign.bottom})`
  - `void showTutorial({required BuildContext context, required List<TargetFocus> targets, required String skipLabel, VoidCallback? onFinish})`

- [ ] **Step 1: Write the failing test**

```dart
// test/core/tutorial/tutorial_coach_mark_helper_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:language_learning_app/core/tutorial/tutorial_coach_mark_helper.dart';

void main() {
  testWidgets('showTutorial displays the target title, description and skip label', (tester) async {
    final targetKey = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return Column(
                children: [
                  Container(key: targetKey, width: 50, height: 50, color: Colors.red),
                  ElevatedButton(
                    onPressed: () {
                      showTutorial(
                        context: context,
                        skipLabel: 'Skip',
                        targets: [
                          buildTutorialTarget(
                            identify: 'test_target',
                            keyTarget: targetKey,
                            title: 'Test Title',
                            description: 'Test Description',
                          ),
                        ],
                      );
                    },
                    child: const Text('Show'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show'));
    await tester.pumpAndSettle();

    expect(find.text('Test Title'), findsOneWidget);
    expect(find.text('Test Description'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/tutorial/tutorial_coach_mark_helper_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:language_learning_app/core/tutorial/tutorial_coach_mark_helper.dart'`.

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/core/tutorial/tutorial_coach_mark_helper.dart
import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:language_learning_app/core/theme/app_colors.dart';

/// Builds one spotlighted step for a tutorial, styled consistently across all tours.
TargetFocus buildTutorialTarget({
  required String identify,
  required GlobalKey keyTarget,
  required String title,
  required String description,
  ContentAlign align = ContentAlign.bottom,
}) {
  return TargetFocus(
    identify: identify,
    keyTarget: keyTarget,
    shape: ShapeLightFocus.RRect,
    radius: 12,
    contents: [
      TargetContent(
        align: align,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    ],
  );
}

/// Shows a tour made of [targets], one spotlighted step at a time.
void showTutorial({
  required BuildContext context,
  required List<TargetFocus> targets,
  required String skipLabel,
  VoidCallback? onFinish,
}) {
  TutorialCoachMark(
    targets: targets,
    colorShadow: AppColors.primary,
    opacityShadow: 0.85,
    textSkip: skipLabel,
    onFinish: onFinish,
  ).show(context: context);
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/tutorial/tutorial_coach_mark_helper_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/tutorial/tutorial_coach_mark_helper.dart test/core/tutorial/tutorial_coach_mark_helper_test.dart
git commit -m "feat: add shared tutorial coachmark helper"
```

---

### Task 5: Wire the welcome tour into `HomeScreen`

**Files:**
- Modify: `lib/screens/home/home_screen.dart:47-102` (class declaration + `build`'s `AppBar`)
- Test: `test/screens/home/home_screen_test.dart`

**Interfaces:**
- Consumes: `TutorialService.hasSeenWelcome()/markWelcomeSeen()` (Task 2), `buildTutorialTarget()/showTutorial()` (Task 4), `AppLocalizations.tutorialWelcome*`/`tutorialSkipButton` (Task 3).
- Produces: no new public interface — this is a leaf wiring task.

- [ ] **Step 1: Write the failing test**

```dart
// test/screens/home/home_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:language_learning_app/core/tutorial/tutorial_service.dart';
import 'package:language_learning_app/core/utils/storage_helper.dart';
import 'package:language_learning_app/l10n/app_localizations.dart';
import 'package:language_learning_app/providers/deck_provider.dart';
import 'package:language_learning_app/screens/home/home_screen.dart';

Widget _wrap(Widget child) {
  return ChangeNotifierProvider(
    create: (_) => DeckProvider(),
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      home: child,
    ),
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageHelper.init();
  });

  testWidgets('shows the welcome tour on first open and marks it seen', (tester) async {
    await tester.pumpWidget(_wrap(const HomeScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Your deck'), findsOneWidget);
    expect(TutorialService.hasSeenWelcome(), isTrue);
  });

  testWidgets('does not show the welcome tour once it has already been seen', (tester) async {
    await TutorialService.markWelcomeSeen();

    await tester.pumpWidget(_wrap(const HomeScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Your deck'), findsNothing);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/screens/home/home_screen_test.dart`
Expected: FAIL — first test finds no "Your deck" text (tour never shown, since `HomeScreen` doesn't trigger it yet).

- [ ] **Step 3: Modify `HomeScreen` to trigger the welcome tour**

Add these imports to `lib/screens/home/home_screen.dart` (after the existing `game_provider.dart` import):

```dart
import 'package:language_learning_app/core/tutorial/tutorial_service.dart';
import 'package:language_learning_app/core/tutorial/tutorial_coach_mark_helper.dart';
```

Replace the class declaration and the start of `build` (currently `lib/screens/home/home_screen.dart:47-102`):

```dart
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey _deckBannerKey = GlobalKey();
  final GlobalKey _gameModesKey = GlobalKey();
  final GlobalKey _settingsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowWelcomeTour());
  }

  void _maybeShowWelcomeTour() {
    if (!mounted || TutorialService.hasSeenWelcome()) return;

    final l10n = AppLocalizations.of(context)!;
    TutorialService.markWelcomeSeen();
    showTutorial(
      context: context,
      skipLabel: l10n.tutorialSkipButton,
      targets: [
        buildTutorialTarget(
          identify: 'welcome_deck',
          keyTarget: _deckBannerKey,
          title: l10n.tutorialWelcomeDeckTitle,
          description: l10n.tutorialWelcomeDeckDesc,
        ),
        buildTutorialTarget(
          identify: 'welcome_games',
          keyTarget: _gameModesKey,
          title: l10n.tutorialWelcomeGamesTitle,
          description: l10n.tutorialWelcomeGamesDesc,
        ),
        buildTutorialTarget(
          identify: 'welcome_settings',
          keyTarget: _settingsKey,
          title: l10n.tutorialWelcomeSettingsTitle,
          description: l10n.tutorialWelcomeSettingsDesc,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context); // Cache le thème pour l'utiliser plus bas

    final List<GameMode> gameModes = _buildGameModes(l10n);

    // --- CALCUL RESPONSIVE POUR LES CARTES ---
    // On veut que les cartes aient toujours environ 140px de hauteur,
    // peu importe la largeur de l'écran.
    final screenWidth = MediaQuery.of(context).size.width;
    const padding = 20.0;
    const spacing = 16.0;
    // La largeur disponible pour les colonnes
    final availableWidth = screenWidth - (padding * 2) - spacing;
    // La largeur d'une seule carte
    final itemWidth = availableWidth / 2;
    // La hauteur fixe désirée (ajustez cette valeur si vous voulez plus/moins haut)
    const targetHeight = 140.0;
    // Le ratio dynamique : Largeur / Hauteur. MediaQuery peut occasionnellement
    // rapporter une taille nulle/dégénérée sur la toute première frame (avant
    // que le gestionnaire de fenêtres n'ait fini d'assigner la taille réelle),
    // ce qui rendrait itemWidth <= 0 et violerait l'assertion childAspectRatio > 0.
    final childAspectRatio = (itemWidth / targetHeight).clamp(0.1, double.infinity);
    // -----------------------------------------

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          l10n.homeTitle.toUpperCase(),
          style: TextStyle(
            color: theme.textTheme.titleLarge?.color,
            fontSize: 22,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: IconButton(
              key: _settingsKey,
              iconSize: 32,
              icon: Icon(Icons.settings_outlined, 
                  color: theme.iconTheme.color),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              ),
            ),
          ),
        ],
      ),
```

Replace the rest of `build` — from `body: SafeArea(` through its closing (`lib/screens/home/home_screen.dart:103-155`) — with:

```dart
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: padding, vertical: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  key: _deckBannerKey,
                  child: _buildDeckManagementBanner(context, l10n),
                ),

                const SizedBox(height: 32),

                Column(
                  key: _gameModesKey,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.videogame_asset_outlined, 
                            color: theme.iconTheme.color?.withValues(alpha: 0.7), 
                            size: 28),
                        const SizedBox(width: 10),
                        Text(
                          l10n.gameModesTitle,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: gameModes.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, 
                        crossAxisSpacing: spacing,
                        mainAxisSpacing: spacing,
                        childAspectRatio: childAspectRatio,
                      ),
                      itemBuilder: (context, index) {
                        return _buildGameModeCard(context, gameModes[index]);
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
```

All other methods (`_buildDeckManagementBanner`, `_buildGameModeCard`, and the top-level `_buildGameModes` function) stay exactly as they are — they remain instance methods of `_HomeScreenState` (unchanged bodies, `context` still passed as a parameter where it already was).

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/screens/home/home_screen_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Run full analyze to catch any missed `context`/`widget.` reference**

Run: `flutter analyze lib/screens/home/home_screen.dart`
Expected: no errors.

- [ ] **Step 6: Commit**

```bash
git add lib/screens/home/home_screen.dart test/screens/home/home_screen_test.dart
git commit -m "feat: show welcome tour on first app open"
```

---

### Task 6: Wire the decks tour into `DecksScreen`

**Files:**
- Modify: `lib/screens/decks/decks_screen.dart:16-67` (state class + `build`)
- Test: `test/screens/decks/decks_screen_test.dart`

**Interfaces:**
- Consumes: `TutorialService.hasSeenDecks()/markDecksSeen()` (Task 2), `buildTutorialTarget()/showTutorial()` (Task 4), `AppLocalizations.tutorialDecks*`/`tutorialSkipButton` (Task 3), `DeckProvider.isLoading` (existing).

- [ ] **Step 1: Write the failing test**

```dart
// test/screens/decks/decks_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:language_learning_app/core/tutorial/tutorial_service.dart';
import 'package:language_learning_app/core/utils/storage_helper.dart';
import 'package:language_learning_app/l10n/app_localizations.dart';
import 'package:language_learning_app/providers/deck_provider.dart';
import 'package:language_learning_app/screens/decks/decks_screen.dart';

Widget _wrap(Widget child) {
  return ChangeNotifierProvider(
    create: (_) => DeckProvider(),
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      home: child,
    ),
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageHelper.init();
  });

  testWidgets('shows the decks tour once loading is done and marks it seen', (tester) async {
    await tester.pumpWidget(_wrap(const DecksScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Choose a deck'), findsOneWidget);
    expect(TutorialService.hasSeenDecks(), isTrue);
  });

  testWidgets('does not show the decks tour once it has already been seen', (tester) async {
    await TutorialService.markDecksSeen();

    await tester.pumpWidget(_wrap(const DecksScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Choose a deck'), findsNothing);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/screens/decks/decks_screen_test.dart`
Expected: FAIL — "Choose a deck" is never shown.

- [ ] **Step 3: Modify `DecksScreen` to trigger the decks tour**

Add these imports to `lib/screens/decks/decks_screen.dart` (after the existing `deck_hierarchy_utils.dart` import):

```dart
import 'package:language_learning_app/core/tutorial/tutorial_service.dart';
import 'package:language_learning_app/core/tutorial/tutorial_coach_mark_helper.dart';
```

Replace `_DecksScreenState`'s field declarations and `build` method (currently `lib/screens/decks/decks_screen.dart:23-67`):

```dart
class _DecksScreenState extends State<DecksScreen> {
  // Sets pour garder en mémoire quels accordéons sont ouverts
  final Set<String> _expandedNodes = {};

  final GlobalKey _decksListKey = GlobalKey();
  final GlobalKey _createDeckKey = GlobalKey();
  VoidCallback? _decksLoadListener;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowDecksTour());
  }

  @override
  void dispose() {
    final listener = _decksLoadListener;
    if (listener != null) {
      context.read<DeckProvider>().removeListener(listener);
    }
    super.dispose();
  }

  void _maybeShowDecksTour() {
    if (!mounted || TutorialService.hasSeenDecks()) return;

    final deckProvider = context.read<DeckProvider>();
    if (deckProvider.isLoading) {
      _decksLoadListener = () {
        if (!deckProvider.isLoading) {
          deckProvider.removeListener(_decksLoadListener!);
          _decksLoadListener = null;
          _maybeShowDecksTour();
        }
      };
      deckProvider.addListener(_decksLoadListener!);
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    TutorialService.markDecksSeen();
    showTutorial(
      context: context,
      skipLabel: l10n.tutorialSkipButton,
      targets: [
        buildTutorialTarget(
          identify: 'decks_select',
          keyTarget: _decksListKey,
          title: l10n.tutorialDecksSelectTitle,
          description: l10n.tutorialDecksSelectDesc,
        ),
        buildTutorialTarget(
          identify: 'decks_create',
          keyTarget: _createDeckKey,
          title: l10n.tutorialDecksCreateTitle,
          description: l10n.tutorialDecksCreateDesc,
          align: ContentAlign.top,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myDecks),
      ),
      body: Consumer<DeckProvider>(
        builder: (context, deckProvider, _) {
          if (deckProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () => _handleRefresh(context),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      key: _decksListKey,
                      child: _buildBaseDecksSection(context, deckProvider),
                    ),
                    const SizedBox(height: 32),
                    _buildCustomDecksSection(context, deckProvider),
                    const SizedBox(height: 80), // Espace pour le FAB
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: _createDeckKey,
        onPressed: () => _navigateToEditor(context, null),
        icon: const Icon(Icons.add),
        label: Text(l10n.createDeck),
      ),
    );
  }
```

Everything below `build` (from `_handleRefresh` at `lib/screens/decks/decks_screen.dart:69` onward) stays unchanged.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/screens/decks/decks_screen_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Run full analyze**

Run: `flutter analyze lib/screens/decks/decks_screen.dart`
Expected: no errors.

- [ ] **Step 6: Commit**

```bash
git add lib/screens/decks/decks_screen.dart test/screens/decks/decks_screen_test.dart
git commit -m "feat: show decks tour once the deck list has loaded"
```

---

### Task 7: Wire the game tour into `GameScreen`

**Files:**
- Modify: `lib/screens/games/classic_game/game_screen.dart:21-129` (class + `build`)
- Test: `test/screens/games/classic_game/game_screen_test.dart`

**Interfaces:**
- Consumes: `TutorialService.hasSeenGame()/markGameSeen()` (Task 2), `buildTutorialTarget()/showTutorial()` (Task 4), `AppLocalizations.tutorialGame*`/`tutorialSkipButton` (Task 3), `GameProvider.currentDeck` (existing).

- [ ] **Step 1: Write the failing test**

```dart
// test/screens/games/classic_game/game_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:language_learning_app/core/tutorial/tutorial_service.dart';
import 'package:language_learning_app/core/utils/storage_helper.dart';
import 'package:language_learning_app/data/models/deck.dart';
import 'package:language_learning_app/data/models/word.dart';
import 'package:language_learning_app/l10n/app_localizations.dart';
import 'package:language_learning_app/providers/game_provider.dart';
import 'package:language_learning_app/screens/games/classic_game/game_screen.dart';

Deck _buildDeck() {
  return Deck(
    id: 'deck1',
    name: 'Test Deck',
    type: DeckType.base,
    inputType: InputType.text,
    reverseInputType: InputType.text,
    words: [Word(id: 'w0', prompt: 'un', answer: 'one', removed: false)],
  );
}

Widget _wrap(Widget child, GameProvider gameProvider) {
  return ChangeNotifierProvider<GameProvider>.value(
    value: gameProvider,
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      home: child,
    ),
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageHelper.init();
  });

  testWidgets('shows the game tour once a deck is loaded and marks it seen', (tester) async {
    final gameProvider = GameProvider();
    await gameProvider.setDeck(_buildDeck());

    await tester.pumpWidget(_wrap(const GameScreen(), gameProvider));
    await tester.pumpAndSettle();

    expect(find.text('Track your progress'), findsOneWidget);
    expect(TutorialService.hasSeenGame(), isTrue);
  });

  testWidgets('does not show the game tour once it has already been seen', (tester) async {
    await TutorialService.markGameSeen();
    final gameProvider = GameProvider();
    await gameProvider.setDeck(_buildDeck());

    await tester.pumpWidget(_wrap(const GameScreen(), gameProvider));
    await tester.pumpAndSettle();

    expect(find.text('Track your progress'), findsNothing);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/screens/games/classic_game/game_screen_test.dart`
Expected: FAIL — "Track your progress" is never shown.

- [ ] **Step 3: Modify `GameScreen` to trigger the game tour**

Add these imports to `lib/screens/games/classic_game/game_screen.dart` (after the existing `l10n/app_localizations.dart` import):

```dart
import 'package:language_learning_app/core/tutorial/tutorial_service.dart';
import 'package:language_learning_app/core/tutorial/tutorial_coach_mark_helper.dart';
```

Replace the class declaration through the start of `build`'s `appBar` (currently `lib/screens/games/classic_game/game_screen.dart:21-51`):

```dart
class GameScreen extends StatefulWidget {
  final String? gameTitle;

  const GameScreen({super.key, this.gameTitle});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final GlobalKey _remainingWordsKey = GlobalKey();
  final GlobalKey _gameHeaderKey = GlobalKey();
  VoidCallback? _gameLoadListener;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowGameTour());
  }

  @override
  void dispose() {
    final listener = _gameLoadListener;
    if (listener != null) {
      context.read<GameProvider>().removeListener(listener);
    }
    super.dispose();
  }

  void _maybeShowGameTour() {
    if (!mounted || TutorialService.hasSeenGame()) return;

    final gameProvider = context.read<GameProvider>();
    if (gameProvider.currentDeck == null) {
      _gameLoadListener = () {
        if (gameProvider.currentDeck != null) {
          gameProvider.removeListener(_gameLoadListener!);
          _gameLoadListener = null;
          _maybeShowGameTour();
        }
      };
      gameProvider.addListener(_gameLoadListener!);
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    TutorialService.markGameSeen();
    showTutorial(
      context: context,
      skipLabel: l10n.tutorialSkipButton,
      targets: [
        buildTutorialTarget(
          identify: 'game_remaining',
          keyTarget: _remainingWordsKey,
          title: l10n.tutorialGameRemainingTitle,
          description: l10n.tutorialGameRemainingDesc,
        ),
        buildTutorialTarget(
          identify: 'game_play',
          keyTarget: _gameHeaderKey,
          title: l10n.tutorialGamePlayTitle,
          description: l10n.tutorialGamePlayDesc,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = widget.gameTitle ?? l10n.homeTitle;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        actions: [
          Consumer<GameProvider>(
            builder: (context, gameProvider, _) {
              return IconButton(
                key: _remainingWordsKey,
                icon: Badge(
                  label: Text('${gameProvider.remainingWords}'),
                  isLabelVisible: gameProvider.remainingWords > 0,
                  child: const Icon(Icons.list),
                ),
                tooltip: l10n.remainingWordsList,
                onPressed: () => _showRemainingWordsBottomSheet(context, gameProvider),
              );
            },
          ),
        ],
      ),
```

The rest of `build` (`lib/screens/games/classic_game/game_screen.dart:52-129`) stays the same, except add the header key inside `_buildWordDisplay` (currently `lib/screens/games/classic_game/game_screen.dart:147-194`) — change:

```dart
              GameHeader(
                deck: gameProvider.currentDeck!,
                badgeLabel: gameProvider.currentGameType?.badgeLabel ?? '',
              ),
```
to
```dart
              GameHeader(
                key: _gameHeaderKey,
                deck: gameProvider.currentDeck!,
                badgeLabel: gameProvider.currentGameType?.badgeLabel ?? '',
              ),
```

(this `GameHeader` is the one built inside `build`, right after `SliverFillRemaining`'s `Column`, at `lib/screens/games/classic_game/game_screen.dart:74-77` — not the one inside `_buildWordDisplay`; there is only one `GameHeader` instantiation in the file).

All remaining methods (`_buildGameInputArea`, `_buildWordDisplay`, `_showRemainingWordsBottomSheet`) become instance methods of `_GameScreenState` with unchanged bodies.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/screens/games/classic_game/game_screen_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Run full analyze**

Run: `flutter analyze lib/screens/games/classic_game/game_screen.dart`
Expected: no errors.

- [ ] **Step 6: Commit**

```bash
git add lib/screens/games/classic_game/game_screen.dart test/screens/games/classic_game/game_screen_test.dart
git commit -m "feat: show game tour once a deck is loaded in-game"
```

---

### Task 8: Replay controls in `SettingsScreen`

**Files:**
- Modify: `lib/screens/settings/settings_screen.dart:83-113`
- Test: `test/screens/settings/settings_screen_test.dart`

**Interfaces:**
- Consumes: `TutorialService.resetWelcome()/resetDecks()/resetGame()` (Task 2), `AppLocalizations.settingsTutorialsSectionTitle`, `replay*Title/Subtitle`, `tutorialReplaySnackbar` (Task 3).

- [ ] **Step 1: Write the failing test**

```dart
// test/screens/settings/settings_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:language_learning_app/core/tutorial/tutorial_service.dart';
import 'package:language_learning_app/core/utils/storage_helper.dart';
import 'package:language_learning_app/l10n/app_localizations.dart';
import 'package:language_learning_app/providers/deck_provider.dart';
import 'package:language_learning_app/providers/game_provider.dart';
import 'package:language_learning_app/providers/locale_provider.dart';
import 'package:language_learning_app/providers/theme_provider.dart';
import 'package:language_learning_app/screens/settings/settings_screen.dart';

Widget _wrap(Widget child) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider(create: (_) => DeckProvider()),
      ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ChangeNotifierProvider(create: (_) => GameProvider()),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      home: child,
    ),
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageHelper.init();
  });

  testWidgets('replaying the welcome tutorial resets its seen flag and confirms', (tester) async {
    await TutorialService.markWelcomeSeen();

    await tester.pumpWidget(_wrap(const SettingsScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Replay welcome tour'));
    await tester.pumpAndSettle();

    expect(TutorialService.hasSeenWelcome(), isFalse);
    expect(find.text("You'll see it again next time you open that screen"), findsOneWidget);
  });

  testWidgets('replaying the decks tutorial only resets the decks flag', (tester) async {
    await TutorialService.markWelcomeSeen();
    await TutorialService.markDecksSeen();
    await TutorialService.markGameSeen();

    await tester.pumpWidget(_wrap(const SettingsScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Replay decks tutorial'));
    await tester.pumpAndSettle();

    expect(TutorialService.hasSeenDecks(), isFalse);
    expect(TutorialService.hasSeenWelcome(), isTrue);
    expect(TutorialService.hasSeenGame(), isTrue);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/screens/settings/settings_screen_test.dart`
Expected: FAIL — no "Replay welcome tour" tile exists yet.

- [ ] **Step 3: Add the "Tutorials" section**

Insert a new section into `lib/screens/settings/settings_screen.dart` right after the "DONNÉES" section and before "À PROPOS" (currently between `lib/screens/settings/settings_screen.dart:106` and `:111`):

```dart
                const SizedBox(height: 24),

                // --- TUTORIELS ---
                SettingsSection(
                  title: l10n.settingsTutorialsSectionTitle,
                  icon: Icons.school_outlined,
                  children: [
                    SettingsTile(
                      title: l10n.replayWelcomeTutorialTitle,
                      subtitle: l10n.replayWelcomeTutorialSubtitle,
                      icon: Icons.waving_hand_outlined,
                      iconColor: AppColors.primary,
                      onTap: () => _replayTutorial(context, TutorialService.resetWelcome),
                    ),
                    SettingsTile(
                      title: l10n.replayDecksTutorialTitle,
                      subtitle: l10n.replayDecksTutorialSubtitle,
                      icon: Icons.library_books_outlined,
                      iconColor: AppColors.primary,
                      onTap: () => _replayTutorial(context, TutorialService.resetDecks),
                    ),
                    SettingsTile(
                      title: l10n.replayGameTutorialTitle,
                      subtitle: l10n.replayGameTutorialSubtitle,
                      icon: Icons.videogame_asset_outlined,
                      iconColor: AppColors.primary,
                      showDivider: false,
                      onTap: () => _replayTutorial(context, TutorialService.resetGame),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
```

(this replaces the single `const SizedBox(height: 24),` that currently sits between the "DONNÉES" `SettingsSection` and `_buildAboutSection(context, l10n)`).

Add the import (after the existing `data/models/deck.dart` import):

```dart
import 'package:language_learning_app/core/tutorial/tutorial_service.dart';
```

Add the helper method to the `SettingsScreen` class (e.g. right before `_buildThemeSwitch`):

```dart
  Future<void> _replayTutorial(BuildContext context, Future<void> Function() reset) async {
    await reset();
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.tutorialReplaySnackbar)),
    );
  }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/screens/settings/settings_screen_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Run full analyze**

Run: `flutter analyze lib/screens/settings/settings_screen.dart`
Expected: no errors.

- [ ] **Step 6: Commit**

```bash
git add lib/screens/settings/settings_screen.dart test/screens/settings/settings_screen_test.dart
git commit -m "feat: add tutorial replay controls to settings"
```

---

### Task 9: Full regression pass

**Files:** none (verification only).

- [ ] **Step 1: Run the full analyzer**

Run: `flutter analyze`
Expected: no errors introduced by this feature (pre-existing warnings, if any, are unrelated).

- [ ] **Step 2: Run the full test suite**

Run: `flutter test`
Expected: all tests pass, including the 6 pre-existing suites and the 6 new ones added in Tasks 2, 4–8.

Per stored preference, no manual UI smoke test is needed here — `flutter analyze` + `flutter test` passing is the bar for this repo unless explicitly asked otherwise.
