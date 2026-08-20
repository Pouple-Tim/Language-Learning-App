import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:language_learning_app/providers/game_provider.dart';
import 'package:language_learning_app/core/theme/app_colors.dart';
import 'package:language_learning_app/data/models/deck.dart';
import 'package:language_learning_app/data/models/word.dart';
import 'package:language_learning_app/l10n/app_localizations.dart';
import 'package:language_learning_app/core/extensions/deck_extensions.dart';

// Imports des widgets d'input
import 'widgets/text_input_widget.dart';
import 'widgets/drawing_widget.dart';
import 'widgets/wheel_widget.dart';
import 'widgets/quiz_widget.dart';
import 'widgets/sentence_builder_widget.dart'; // <--- 1. IMPORT AJOUTÉ

class GameScreen extends StatelessWidget {
  final String? gameTitle;

  const GameScreen({super.key, this.gameTitle});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = gameTitle ?? l10n.homeTitle; 

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        actions: [
          Consumer<GameProvider>(
            builder: (context, gameProvider, _) {
              return IconButton(
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
            // 1. Cas : Pas de deck sélectionné
            if (gameProvider.currentDeck == null) {
              return Center(child: Text(l10n.noDeckSelected));
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final isSmallScreen = constraints.maxWidth < 380;
                
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
                              
                              // 2. En-tête (Nom du deck + Badge mode)
                              _buildHeader(context, gameProvider),

                              const SizedBox(height: 8),
                              
                              // 3. Barre de progression
                              _buildProgressBar(context, gameProvider),
                              
                              const SizedBox(height: 12),
                              
                              // 4. Contenu central dynamique
                              if (gameProvider.isCompleted)
                                Expanded(child: Center(child: _buildCompletedCard(context, gameProvider)))
                              
                              else if (gameProvider.currentWord == null && gameProvider.currentSentence == null)
                                Expanded(
                                  child: Center(
                                    child: WheelWidget(
                                      words: gameProvider.currentDeck!.activeWords,
                                      isSpinning: gameProvider.isSpinning,
                                      selectedWord: gameProvider.currentWord,
                                      onSpin: () => gameProvider.spinWheel(),
                                    ),
                                  ),
                                )
                              else ...[
                                // Question (Mot ou Phrase originale)
                                _buildWordDisplay(context, gameProvider, isSmallScreen),
                                
                                const Spacer(),
                                const SizedBox(height: 16),
                                
                                // === ZONE DE JEU DYNAMIQUE ===
                                // C'est ici que la magie opère
                                _buildGameInputArea(context, gameProvider),
                                // ==============================
                                
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

  // <--- 3. MODIFICATION ICI : Gestion du widget SentenceBuilder
  Widget _buildGameInputArea(BuildContext context, GameProvider gameProvider) {
    // Mode Quiz
    if (gameProvider.currentGameMode == 'quiz') {
      return const QuizWidget();
    }
    
    // Mode Phrase (AJOUT)
    if (gameProvider.currentGameMode == 'sentence') {
      return const SentenceBuilderWidget();
    }

    // Sinon, on regarde le type d'input configuré dans le deck (Texte ou Dessin)
    if (gameProvider.activeInputType == InputType.text) {
      return const TextInputWidget();
    } else {
      return const DrawingWidget();
    }
  }

  // <--- 4. MODIFICATION ICI : Badge du Header
  Widget _buildHeader(BuildContext context, GameProvider gameProvider) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        children: [
          Text(
            gameProvider.currentDeck!.localizedName(context),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          // Affiche un badge si on n'est pas en mode classique standard
          if (gameProvider.isReverseMode || 
              gameProvider.currentGameMode == 'quiz' || 
              gameProvider.currentGameMode == 'sentence')
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _getModeLabel(gameProvider.currentGameMode), // Helper pour le texte
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.secondary),
              ),
            ),
        ],
      ),
    );
  }
  
  String _getModeLabel(String? mode) {
    if (mode == 'quiz') return "QUIZ MODE";
    if (mode == 'sentence') return "PHRASE";
    if (mode == 'reverse') return "REVERSE";
    return "";
  }

  Widget _buildProgressBar(BuildContext context, GameProvider gameProvider) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${gameProvider.totalWords - gameProvider.remainingWords}/${gameProvider.totalWords}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              '${gameProvider.progress.toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: gameProvider.progress / 100,
            minHeight: 10,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ],
    );
  }

   Widget _buildWordDisplay(BuildContext context, GameProvider gameProvider, bool isSmallScreen) {
      final l10n = AppLocalizations.of(context)!;
      return Column(
        children: [
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
                    // Le getter gère déjà Reverse/Classic et maintenant Sentence (Original Text)
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
          // Bouton pour changer de mot
          // <--- 5. MODIFICATION ICI : On cache le bouton "Change Word" en mode Phrase
          if (gameProvider.currentGameMode != 'quiz' && gameProvider.currentGameMode != 'sentence') 
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

  Widget _buildCompletedCard(BuildContext context, GameProvider gameProvider) {
      final l10n = AppLocalizations.of(context)!;
      return Card(
        elevation: 0,
        color: AppColors.success.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.success, width: 2),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.celebration, size: 60, color: AppColors.success),
              const SizedBox(height: 16),
              Text(
                l10n.completed,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.completedMessage,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: gameProvider.resetDeck,
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.restart),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  void _showRemainingWordsBottomSheet(BuildContext context, GameProvider gameProvider) {
    final l10n = AppLocalizations.of(context)!;
    final deck = gameProvider.currentDeck;
    if (deck == null) return;

    final remainingWords = deck.activeWords;
    final completedWords = deck.words.where((w) => w.removed).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (_, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                    Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.list_alt_rounded, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            deck.localizedName(context),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        )
                      ],
                    ),
                  ),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatCompact(context, l10n.remaining, '${remainingWords.length}', AppColors.warning),
                        Container(width: 1, height: 30, color: Colors.grey.shade300),
                        _buildStatCompact(context, l10n.succeeded, '${completedWords.length}', AppColors.success),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: DefaultTabController(
                      length: 2,
                      child: Column(
                        children: [
                          TabBar(
                            labelColor: AppColors.primary,
                            unselectedLabelColor: Colors.grey,
                            indicatorColor: AppColors.primary,
                            tabs: [
                              Tab(text: l10n.toReview),
                              Tab(text: l10n.succeeded),
                            ],
                          ),
                          Expanded(
                            child: TabBarView(
                              children: [
                                _buildWordsList(context, remainingWords, false, scrollController),
                                _buildWordsList(context, completedWords, true, scrollController),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
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
    );
  }
    
  Widget _buildStatCompact(BuildContext context, String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }
    
  Widget _buildWordsList(BuildContext context, List<Word> words, bool isCompleted, ScrollController scrollController) {
    final l10n = AppLocalizations.of(context)!;
    if (words.isEmpty) {
      return Center(child: Text(isCompleted ? l10n.noWordSucceeded : l10n.allWordsSucceeded));
    }
    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: words.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
          final word = words[index];
          return ListTile(title: Text(word.prompt));
      }
    );
  }
}