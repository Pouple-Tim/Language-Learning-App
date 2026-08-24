import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:language_learning_app/providers/game_provider.dart';
import 'package:language_learning_app/core/theme/app_colors.dart';
import 'package:language_learning_app/data/models/deck.dart';
import 'package:language_learning_app/data/models/game_mode.dart';
import 'package:language_learning_app/l10n/app_localizations.dart';
import 'package:language_learning_app/core/tutorial/tutorial_service.dart';
import 'package:language_learning_app/core/tutorial/tutorial_coach_mark_helper.dart';

// Imports des widgets d'input
import 'widgets/text_input_widget.dart';
import 'widgets/drawing_widget.dart';
import 'widgets/quiz_widget.dart';
import 'widgets/listen_prompt_card.dart';
import 'widgets/sentence_builder_widget.dart';
import 'widgets/game_header.dart';
import 'widgets/game_progress_bar.dart';
import 'widgets/completed_card.dart';
import 'widgets/no_sentences_card.dart';
import 'widgets/remaining_words_sheet.dart';

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
      body: SafeArea(
        bottom: true,
        child: Consumer<GameProvider>(
          builder: (context, gameProvider, _) {
            if (gameProvider.currentDeck == null) {
              return Center(child: Text(l10n.noDeckSelected));
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onTap: () => FocusScope.of(context).unfocus(),
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              const SizedBox(height: 12),
                              GameHeader(
                                key: _gameHeaderKey,
                                deck: gameProvider.currentDeck!,
                                badgeLabel: gameProvider.currentGameType?.badgeLabel ?? '',
                              ),
                              const SizedBox(height: 8),
                              GameProgressBar(
                                total: gameProvider.totalWords,
                                remaining: gameProvider.remainingWords,
                                progress: gameProvider.progress,
                              ),
                              const SizedBox(height: 12),
                              if (gameProvider.currentGameType == GameType.sentence &&
                                  gameProvider.currentDeck!.sentences.isEmpty)
                                const Expanded(
                                  child: Center(
                                    child: NoSentencesCard(),
                                  ),
                                )
                              else if (gameProvider.isCompleted)
                                Expanded(
                                  child: Center(
                                    child: CompletedCard(onRestart: gameProvider.resetDeck),
                                  ),
                                )
                              else if (gameProvider.currentWord == null && gameProvider.currentSentence == null)
                                Expanded(
                                  child: Builder(
                                    builder: (context) {
                                      // No wheel to spin anymore -- pick the
                                      // first word/sentence automatically as
                                      // soon as we detect there isn't one yet.
                                      WidgetsBinding.instance.addPostFrameCallback((_) {
                                        if (mounted &&
                                            gameProvider.currentWord == null &&
                                            gameProvider.currentSentence == null) {
                                          gameProvider.spinWheel();
                                        }
                                      });
                                      return const Center(child: CircularProgressIndicator());
                                    },
                                  ),
                                )
                              else ...[
                                _buildWordDisplay(context, gameProvider),
                                const Spacer(),
                                const SizedBox(height: 16),
                                _buildGameInputArea(context, gameProvider),
                                const SizedBox(height: 16),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildGameInputArea(BuildContext context, GameProvider gameProvider) {
    switch (gameProvider.currentGameType) {
      case GameType.quiz:
      case GameType.listening:
        return const QuizWidget();
      case GameType.sentence:
        return const SentenceBuilderWidget();
      case GameType.classic:
      case GameType.reverse:
      case GameType.memory:
      case null:
        return gameProvider.activeInputType == InputType.text
            ? const TextInputWidget()
            : const DrawingWidget();
    }
  }

  Widget _buildWordDisplay(BuildContext context, GameProvider gameProvider) {
    final l10n = AppLocalizations.of(context)!;
    final isListening = gameProvider.currentGameType == GameType.listening;

    return Column(
      children: [
        if (isListening)
          const ListenPromptCard()
        else
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    gameProvider.currentQuestionText,
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        if (gameProvider.currentGameType != GameType.quiz &&
            gameProvider.currentGameType != GameType.sentence &&
            gameProvider.currentGameType != GameType.listening)
          TextButton.icon(
            onPressed: gameProvider.resetCurrentWord,
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(l10n.changeWord),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            ),
          ),
      ],
    );
  }

  void _showRemainingWordsBottomSheet(BuildContext context, GameProvider gameProvider) {
    final deck = gameProvider.currentDeck;
    if (deck == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RemainingWordsSheet(deck: deck),
    );
  }
}
