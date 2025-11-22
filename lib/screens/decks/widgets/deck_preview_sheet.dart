import 'package:flutter/material.dart';
import 'package:language_learning_app/data/models/deck.dart';
import 'package:language_learning_app/data/models/word.dart';
import 'package:language_learning_app/core/theme/app_colors.dart';
import 'package:language_learning_app/l10n/app_localizations.dart';
import 'package:language_learning_app/core/extensions/deck_extensions.dart';

class DeckPreviewSheet extends StatelessWidget {
  final Deck deck;

  const DeckPreviewSheet({super.key, required this.deck});

  @override
  Widget build(BuildContext context) {
    final words = deck.words.toList();
    final l10n = AppLocalizations.of(context)!;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              _buildHeader(context, l10n),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: words.length,
                  itemBuilder: (context, index) => _buildWordCard(words[index], index + 1),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  deck.localizedName(context),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.style, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(l10n.totalWords(deck.totalWords),
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
              const SizedBox(width: 16),
              Icon(deck.inputType == InputType.text ? Icons.keyboard : Icons.draw,
                  size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(deck.inputType == InputType.text ? l10n.text : l10n.drawing,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWordCard(Word word, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text('$index',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLine('Prompt:', word.prompt, 16, FontWeight.bold),
                  const SizedBox(height: 4),
                  _buildLine('Réponse:', word.answer, 14, FontWeight.normal),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLine(String label, String content, double size, FontWeight weight) {
    return Row(
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(content, style: TextStyle(fontSize: size, fontWeight: weight)),
        ),
      ],
    );
  }
}