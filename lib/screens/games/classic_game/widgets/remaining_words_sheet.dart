import 'package:flutter/material.dart';
import 'package:language_learning_app/core/theme/app_colors.dart';
import 'package:language_learning_app/data/models/deck.dart';
import 'package:language_learning_app/data/models/word.dart';
import 'package:language_learning_app/l10n/app_localizations.dart';
import 'package:language_learning_app/core/extensions/deck_extensions.dart';

class RemainingWordsSheet extends StatelessWidget {
  final Deck deck;

  const RemainingWordsSheet({super.key, required this.deck});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final remainingWords = deck.activeWords;
    final completedWords = deck.words.where((w) => w.removed).toList();

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
                    ),
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
      },
    );
  }
}
