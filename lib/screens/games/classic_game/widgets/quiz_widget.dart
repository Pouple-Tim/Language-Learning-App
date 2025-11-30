import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:language_learning_app/providers/game_provider.dart';
import 'package:language_learning_app/core/theme/app_colors.dart';

class QuizWidget extends StatefulWidget {
  const QuizWidget({super.key});

  @override
  State<QuizWidget> createState() => _QuizWidgetState();
}

class _QuizWidgetState extends State<QuizWidget> {
  // Pour gérer l'état visuel des boutons après le clic
  String? _selectedAnswer;
  bool _isChecked = false;

  @override
  Widget build(BuildContext context) {
    final gameProvider = context.watch<GameProvider>();
    final options = gameProvider.quizOptions;

    // Si pas d'options (ex: chargement), on affiche rien
    if (options.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        // Liste des choix
        ...options.map((option) => _buildOptionCard(context, option, gameProvider)),
      ],
    );
  }

  Widget _buildOptionCard(BuildContext context, String option, GameProvider provider) {
    final theme = Theme.of(context);
    
    // Logique de couleur
    Color cardColor = theme.cardTheme.color!;
    Color textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    BorderSide borderSide = BorderSide.none;

    if (_isChecked) {
      final isCorrectAnswer = option.toLowerCase() == provider.currentWord?.answer.toLowerCase();
      final isSelected = option == _selectedAnswer;

      if (isCorrectAnswer) {
        // C'est la bonne réponse -> Vert (toujours affiché pour correction)
        cardColor = AppColors.success.withValues(alpha: 0.2);
        borderSide = const BorderSide(color: AppColors.success, width: 2);
        textColor = AppColors.success;
      } else if (isSelected && !isCorrectAnswer) {
        // C'est la mauvaise réponse qu'on a cliqué -> Rouge
        cardColor = AppColors.error.withValues(alpha: 0.2);
        borderSide = const BorderSide(color: AppColors.error, width: 2);
        textColor = AppColors.error;
      } else {
        // Les autres choix non concernés -> Grisé
        textColor = textColor.withValues(alpha: 0.3);
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      width: double.infinity,
      child: InkWell(
        onTap: _isChecked ? null : () => _handleSelection(option, provider),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.fromBorderSide(borderSide),
            boxShadow: [
              if (!_isChecked)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Text(
            option,
            style: theme.textTheme.titleMedium?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Future<void> _handleSelection(String answer, GameProvider provider) async {
    setState(() {
      _selectedAnswer = answer;
      _isChecked = true;
    });

    // On appelle la vérification du provider.
    // Cela enregistre la statistique (Succès ou Échec).
    // Si c'est un échec, le mot n'est PAS marqué comme "appris" (removed=false) dans le provider.
    await provider.checkAnswer(answer);

    // On attend 1.5 secondes pour que l'utilisateur voit la couleur (Vert ou Rouge)
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    // === MODIFICATION ICI ===
    // On passe au mot suivant dans TOUS les cas (Correct ou Incorrect)
    
    // 1. Reset de l'état visuel local
    setState(() {
      _isChecked = false;
      _selectedAnswer = null;
    });
    
    // 2. On enlève le mot actuel de l'affichage
    provider.resetCurrentWord();
    
    // 3. On lance la roue pour choisir un nouveau mot
    // Note : Si la réponse était fausse, le mot est toujours dans la liste "active"
    // et pourra être sélectionné à nouveau aléatoirement plus tard.
    if (provider.remainingWords > 0) {
      provider.spinWheel();
    }
  }
}