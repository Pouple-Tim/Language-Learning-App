import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:language_learning_app/core/audio/speech_service.dart';
import 'package:language_learning_app/core/theme/app_colors.dart';
import 'package:language_learning_app/providers/game_provider.dart';
import 'package:language_learning_app/l10n/app_localizations.dart';

/// Push-to-talk input for GameType.pronunciation: hold the mic button to
/// record, release to stop and run recognition. Correct -> advance like
/// every other mode. Incorrect -> retry the same word (no tone scoring,
/// no partial credit -- see the pronunciation game design spec).
class PronunciationWidget extends StatefulWidget {
  const PronunciationWidget({super.key});

  @override
  State<PronunciationWidget> createState() => _PronunciationWidgetState();
}

class _PronunciationWidgetState extends State<PronunciationWidget> {
  bool _isListening = false;
  bool _isChecked = false;
  bool _lastCorrect = false;

  Future<void> _handleFinalResult(String recognizedWords, GameProvider provider) async {
    final isCorrect = await provider.checkAnswer(recognizedWords);
    if (!mounted) return;

    setState(() {
      _isListening = false;
      _isChecked = true;
      _lastCorrect = isCorrect;
    });

    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    setState(() => _isChecked = false);

    if (isCorrect) {
      provider.resetCurrentWord();
      if (provider.remainingWords > 0) {
        provider.spinWheel();
      }
    }
    // Incorrect: nothing to reset -- the word stays current, user retries.
  }

  Future<void> _startRecording(GameProvider provider) async {
    setState(() => _isListening = true);
    final started = await SpeechService.startListening((text) => _handleFinalResult(text, provider));
    if (!started && mounted) {
      final l10n = AppLocalizations.of(context)!;
      setState(() => _isListening = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pronunciationMicUnavailable), backgroundColor: AppColors.error),
      );
    }
  }

  void _stopRecording() {
    SpeechService.stopListening();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<GameProvider>();

    Color color = AppColors.primary;
    if (_isChecked) {
      color = _lastCorrect ? AppColors.success : AppColors.error;
    } else if (_isListening) {
      color = AppColors.secondary;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onLongPressStart: _isChecked ? null : (_) => _startRecording(provider),
          onLongPressEnd: _isChecked ? null : (_) => _stopRecording(),
          child: CircleAvatar(
            radius: 40,
            backgroundColor: color,
            child: Icon(
              _isListening ? Icons.mic : Icons.mic_none_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _isListening ? l10n.pronunciationListening : l10n.pronunciationHoldToSpeak,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}
