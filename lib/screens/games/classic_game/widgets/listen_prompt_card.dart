import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:language_learning_app/core/audio/tts_service.dart';
import 'package:language_learning_app/core/theme/app_colors.dart';
import 'package:language_learning_app/providers/game_provider.dart';
import 'package:language_learning_app/l10n/app_localizations.dart';

/// Replaces the text prompt card for GameType.listening: no word text is
/// shown (that would defeat a listening exercise) — just a speaker button
/// the user taps to play/replay the current word's pronunciation.
class ListenPromptCard extends StatelessWidget {
  const ListenPromptCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final word = context.watch<GameProvider>().currentWord;

    final borderRadius = BorderRadius.circular(20);

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 500),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: word == null ? null : () => TtsService.speak(word.answer),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            child: Semantics(
              button: true,
              label: l10n.listenButtonTooltip,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.volume_up_rounded, size: 56, color: Colors.white),
                  const SizedBox(height: 4),
                  Text(
                    l10n.listenButtonLabel,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
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
