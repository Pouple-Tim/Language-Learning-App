import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:language_learning_app/core/theme/app_colors.dart';
import 'package:language_learning_app/providers/game_provider.dart';

/// Replaces the text prompt card for GameType.pronunciation: shows both the
/// hanzi and the pinyin -- unlike the listening game, there's no ambiguity
/// to preserve here, the point is producing the right sound, not recalling
/// the character.
class PronunciationPromptCard extends StatelessWidget {
  const PronunciationPromptCard({super.key});

  @override
  Widget build(BuildContext context) {
    final word = context.watch<GameProvider>().currentWord;

    return Container(
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
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              word?.answer ?? '',
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            word?.prompt ?? '',
            style: const TextStyle(fontSize: 18, color: Colors.white70, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
