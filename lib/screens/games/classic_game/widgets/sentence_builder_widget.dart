import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:language_learning_app/providers/game_provider.dart';
import 'package:language_learning_app/core/theme/app_colors.dart';
import 'package:language_learning_app/l10n/app_localizations.dart';

class SentenceBuilderWidget extends StatefulWidget {
  const SentenceBuilderWidget({super.key});

  @override
  State<SentenceBuilderWidget> createState() => _SentenceBuilderWidgetState();
}

class _SentenceBuilderWidgetState extends State<SentenceBuilderWidget> {
  // Suppression de _isIncorrect
  bool _isCorrect = false;
  bool _showFeedback = false;

  void _handleBlockTap(String block, bool isSelected) {
    HapticFeedback.lightImpact();
    
    final provider = context.read<GameProvider>();
    if (isSelected) {
      provider.removeBlockFromSentence(block);
    } else {
      provider.addBlockToSentence(block);
    }
  }

  void _handleLongPress(String block) {
    HapticFeedback.mediumImpact();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(block, textAlign: TextAlign.center),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.translate, color: AppColors.primary, size: 32),
            SizedBox(height: 16),
            Text(
              "Traduction...", 
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkAnswer() async {
    final provider = context.read<GameProvider>();
    
    if (provider.selectedBlocks.isEmpty) return;

    final isCorrect = await provider.checkSentenceConstruction();

    setState(() {
      _showFeedback = true;
      _isCorrect = isCorrect;
      // On n'a plus besoin de définir _isIncorrect
    });

    if (isCorrect) {
       HapticFeedback.heavyImpact();
       await Future.delayed(const Duration(milliseconds: 1500));
       if (mounted) {
         setState(() {
            _showFeedback = false;
            _isCorrect = false;
         });
         provider.resetCurrentSentence();
         provider.spinWheel();
       }
    } else {
      HapticFeedback.vibrate();
      await Future.delayed(const Duration(milliseconds: 1000));
      if (mounted) {
        setState(() {
          // On cache juste le feedback, l'utilisateur peut réessayer
          _showFeedback = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameProvider = context.watch<GameProvider>();
    final l10n = AppLocalizations.of(context)!;
    
    Color statusColor = Colors.transparent;
    if (_showFeedback) {
      // Si feedback actif : vert si correct, rouge sinon (donc incorrect)
      statusColor = _isCorrect ? AppColors.success : AppColors.error;
    }

    return Column(
      children: [
        // === ZONE DE RÉPONSE ===
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 140),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _showFeedback ? statusColor : Colors.grey.withValues(alpha: 0.3),
              width: _showFeedback ? 2 : 1,
            ),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 12,
            children: gameProvider.selectedBlocks.map((block) {
              return _buildBlock(context, block, isSelected: true);
            }).toList(),
          ),
        ),

        const SizedBox(height: 12),
        
        // Indicateur de feedback
        AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: _showFeedback ? 1.0 : 0.0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_isCorrect ? Icons.check : Icons.close, color: statusColor),
              const SizedBox(width: 8),
              Text(
                _isCorrect ? l10n.correct : l10n.tryAgain,
                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // === ZONE DE CHOIX ===
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 100),
          alignment: Alignment.topCenter,
          child: Wrap(
            spacing: 8,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: gameProvider.availableBlocks.map((block) {
              return _buildBlock(context, block, isSelected: false);
            }).toList(),
          ),
        ),

        const SizedBox(height: 32),

        // === BOUTON VALIDER ===
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: !_showFeedback && gameProvider.selectedBlocks.isNotEmpty 
                ? _checkAnswer 
                : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 4,
            ),
            child: Text(l10n.validate.toUpperCase(), 
              style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          ),
        ),
        
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildBlock(BuildContext context, String text, {required bool isSelected}) {
    return GestureDetector(
      onTap: !_showFeedback ? () => _handleBlockTap(text, isSelected) : null,
      onLongPress: () => _handleLongPress(text),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade300,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              offset: const Offset(0, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}