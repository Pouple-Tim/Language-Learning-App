import 'package:flutter/material.dart';
import 'package:language_learning_app/core/theme/app_colors.dart';
import 'package:language_learning_app/screens/decks/decks_screen.dart';
import 'package:language_learning_app/screens/settings/settings_screen.dart';
import 'package:language_learning_app/screens/games/classic_game/game_screen.dart';
import 'package:language_learning_app/l10n/app_localizations.dart';
import 'package:language_learning_app/data/models/game_mode.dart';
import 'package:language_learning_app/data/models/deck.dart';
import 'package:language_learning_app/core/extensions/strings_extensions.dart';
import 'package:provider/provider.dart';
import 'package:language_learning_app/providers/deck_provider.dart';
import 'package:language_learning_app/providers/game_provider.dart';
import 'package:language_learning_app/providers/statistics_provider.dart';
import 'package:language_learning_app/providers/reminder_provider.dart';
import 'package:language_learning_app/core/tutorial/tutorial_service.dart';
import 'package:language_learning_app/screens/onboarding/onboarding_screen.dart';

List<GameMode> _buildGameModes(AppLocalizations l10n) {
  return [
    GameMode(
      type: GameType.classic,
      title: l10n.classicModeTitle,
      description: l10n.classicModeDesc,
    ),
    GameMode(
      type: GameType.reverse,
      title: l10n.reverseModeTitle,
      description: l10n.reverseModeDesc,
    ),
    GameMode(
      type: GameType.quiz,
      title: l10n.quizModeTitle,
      description: l10n.quizModeDesc,
    ),
    GameMode(
      type: GameType.listening,
      title: l10n.listeningModeTitle,
      description: l10n.listeningModeDesc,
    ),
    GameMode(
      type: GameType.sentence,
      title: "Phrase",
      description: "Reconstitue la phrase correcte.",
    ),
  ];
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowOnboarding();
      _refreshReminder();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshReminder();
  }

  void _maybeShowOnboarding() {
    if (!mounted || TutorialService.hasSeenOnboarding()) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
    );
  }

  /// Re-arms the rolling daily-reminder window (skips today if already
  /// practiced). Cheap no-op when the reminder is off.
  void _refreshReminder() {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    context.read<ReminderProvider>().refresh(
          practicedToday: context.read<StatisticsProvider>().hasPracticedToday(),
          title: l10n.reminderNotificationTitle,
          body: l10n.reminderNotificationBody,
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
          _buildStreakBadge(context, l10n),
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: IconButton(
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
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: padding, vertical: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDeckManagementBanner(context, l10n),

                const SizedBox(height: 32),

                Column(
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

  Widget _buildStreakBadge(BuildContext context, AppLocalizations l10n) {
    final streak = context.watch<StatisticsProvider>().getCurrentStreak();

    return Tooltip(
      message: l10n.currentStreak,
      child: Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.local_fire_department, color: Colors.orange, size: 20),
              const SizedBox(width: 4),
              Text(
                '$streak',
                style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeckManagementBanner(BuildContext context, AppLocalizations l10n) {
    final deckProvider = context.watch<DeckProvider>();
    final selectedDeckName = deckProvider.selectedDeck?.name ?? l10n.noDeckSelected;

    return Container(
      constraints: const BoxConstraints(minHeight: 140), 
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const DecksScreen()),
          ),
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.8),
                  AppColors.primary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        capitalizeFirst(l10n.decks),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        selectedDeckName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.edit, color: Colors.white, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              l10n.manageDecksDesc.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.library_books_outlined,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameModeCard(BuildContext context, GameMode mode) {
    final theme = Theme.of(context);
    final cardColor = theme.cardTheme.color;
    // On utilise une ombre plus légère définie dans le thème si possible, sinon défaut
    final shadowColor = theme.cardTheme.shadowColor ?? Colors.black.withValues(alpha: 0.05);
    final deckProvider = context.watch<DeckProvider>();
    final selectedDeck = deckProvider.selectedDeck;
    final hasSentences = selectedDeck == null
        ? false
        : selectedDeck.type == DeckType.custom
            ? selectedDeck.sentences.isNotEmpty
            : (deckProvider.repository.getDeckMetadata(selectedDeck.id)?.hasSentences ?? false);
    final isUnavailable = mode.type == GameType.sentence && !hasSentences;

    return Opacity(
      opacity: isUnavailable ? 0.4 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: cardColor,
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              final deckProvider = context.read<DeckProvider>();
              final gameProvider = context.read<GameProvider>();
              final l10n = AppLocalizations.of(context)!;

              if (deckProvider.selectedDeck == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.noDeckSelected),
                    backgroundColor: AppColors.error,
                    action: SnackBarAction(
                      label: l10n.selectDeck,
                      textColor: Colors.white,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const DecksScreen()),
                      ),
                    ),
                  ),
                );
                return;
              }

              if (isUnavailable) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.noSentencesInDeck),
                    backgroundColor: AppColors.warning,
                  ),
                );
                return;
              }

              var deck = deckProvider.selectedDeck!;
              if (deck.type == DeckType.base && deck.words.isEmpty && deck.sentences.isEmpty) {
                await deckProvider.selectDeck(deck);
                if (!context.mounted) return;
                final error = deckProvider.downloadError;
                if (error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.deckDownloadFailed),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }
                deck = deckProvider.selectedDeck!;
              }

              gameProvider.setDeck(
                deck,
                gameMode: mode.type,
              );

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GameScreen(
                    gameTitle: mode.title,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(14), // Padding légèrement ajusté
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // Important pour éviter que le contenu s'étire bizarrement
                children: [
                  // En-tête avec Icone
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: mode.type.color.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          mode.type.icon,
                          size: 20,
                          color: mode.type.color,
                        ),
                      ),
                    ],
                  ),

                  const Spacer(), // Pousse le texte vers le bas, mais s'adapte à la hauteur fixe

                  // Titre
                  Text(
                    mode.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      height: 1.1,
                    ),
                    // maxLines: 1,
                    // overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  // Description
                  Text(
                    mode.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      height: 1.2,
                    ),
                    // maxLines: 2,
                    // overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}