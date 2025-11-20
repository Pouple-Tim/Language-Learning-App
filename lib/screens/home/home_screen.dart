import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/game_provider.dart';
import '../../core/theme/app_colors.dart';
import 'widgets/text_input_widget.dart';
import '../decks/decks_screen.dart';
import 'widgets/drawing_widget.dart';
import '../../data/models/deck.dart';
import '../settings/settings_screen.dart';
import 'widgets/wheel_widget.dart';
import '../../data/models/word.dart';
import '../../l10n/app_localizations.dart';
import '../../core/extensions/deck_extensions.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(l10n.homeTitle),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const DecksScreen()),
            );
          },
        ),
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
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: l10n.settingsTitle,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
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
              return const Center(child: CircularProgressIndicator());
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final isSmallScreen = constraints.maxWidth < 380;
                // Détermine si on doit afficher la roue ou le jeu actif
                final isPlaying = !gameProvider.isCompleted && gameProvider.currentWord != null;

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
                              // --- HAUT (Titre + Barre) ---
                              const SizedBox(height: 12), // Réduit de 16 à 12
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  gameProvider.currentDeck!.localizedName(context),
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 8), // Réduit de 12 à 8
                              _buildProgressBar(context, gameProvider),

                              const SizedBox(height: 12),
                              
                              // Si le jeu est fini
                              if (gameProvider.isCompleted)
                                Expanded(child: Center(child: _buildCompletedCard(context, gameProvider)))
                              
                              // Si on tourne la roue (pas de mot sélectionné)
                              else if (gameProvider.currentWord == null)
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
                              
                              // Si un mot est sélectionné (Jeu actif)
                              else ...[
                                // Zone du mot à deviner
                                _buildWordDisplay(context, gameProvider, isSmallScreen),
                                
                                // Le Spacer pousse le contenu suivant vers le bas,
                                // mais s'écrase si l'espace manque.
                                const Spacer(), 

                                // --- BAS (Input / Dessin) ---
                                const SizedBox(height: 16),
                                if (gameProvider.currentDeck!.inputType == InputType.text)
                                  const TextInputWidget()
                                else
                                  // Le widget de dessin gérera lui-même sa hauteur max
                                  const DrawingWidget(),
                                
                                // Marge du bas réduite (SafeArea s'en charge déjà en partie)
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

  // ... (Le reste des méthodes _buildProgressBar, _buildWordDisplay, etc. reste inchangé)
  // Assure-toi juste que _buildWordDisplay est assez compact si possible.
  
  Widget _buildProgressBar(BuildContext context, GameProvider gameProvider) {
    // (Code inchangé)
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
  
  // Copie le reste de tes méthodes helper existantes ici...
  Widget _buildWordDisplay(BuildContext context, GameProvider gameProvider, bool isSmallScreen) {
      final l10n = AppLocalizations.of(context)!;
      
      return Column(
        children: [
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 500),
            // Réduction du padding vertical pour gagner de la place
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
                    gameProvider.currentWord!.prompt,
                    style: const TextStyle(
                      fontSize: 40, // Légèrement réduit (48 -> 40)
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: gameProvider.resetCurrentWord,
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(l10n.changeWord),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8), // Padding réduit
            ),
          ),
        ],
      );
    }

    Widget _buildCompletedCard(BuildContext context, GameProvider gameProvider) {
       // (Ton code existant)
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
              mainAxisSize: MainAxisSize.min, // Important pour centrer
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
        // (Ton code existant, inchangé)
        // ...
        final l10n = AppLocalizations.of(context)!;
        final deck = gameProvider.currentDeck;
        if (deck == null) return;
        // Reste de la méthode...
        // Pour la brièveté, je ne recopie pas tout ici, garde ta méthode actuelle.
        // Juste assure-toi d'avoir les imports nécessaires.
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
                      // ... (Header bottom sheet)
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
        // (Ton code existant)
        final l10n = AppLocalizations.of(context)!;
        if (words.isEmpty) {
          return Center(child: Text(isCompleted ? l10n.noWordSucceeded : l10n.allWordsSucceeded));
        }
        return ListView.separated(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: words.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
             final word = words[index];
             return ListTile(title: Text(word.prompt)); // Version simplifiée pour l'exemple
          }
        );
    }
}