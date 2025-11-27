import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:language_learning_app/providers/game_provider.dart';
import 'package:language_learning_app/core/theme/app_colors.dart';
import 'package:language_learning_app/l10n/app_localizations.dart';

class TextInputWidget extends StatefulWidget {
  const TextInputWidget({super.key});

  @override
  State<TextInputWidget> createState() => _TextInputWidgetState();
}

class _TextInputWidgetState extends State<TextInputWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  bool _isCorrect = false;
  bool _isIncorrect = false;
  bool _showFeedback = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _checkAnswer() async {
    final gameProvider = context.read<GameProvider>();
    final userAnswer = _controller.text.trim().toLowerCase();

    if (userAnswer.isEmpty) return;

    final isCorrect = await gameProvider.checkAnswer(userAnswer);

    setState(() {
      _showFeedback = true;
      _isCorrect = isCorrect;
      _isIncorrect = !isCorrect;
    });

    if (isCorrect) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          _controller.clear();
          setState(() {
            _showFeedback = false;
            _isCorrect = false;
            _isIncorrect = false;
          });
          gameProvider.resetCurrentWord();
          
          if (gameProvider.remainingWords > 0) {
            gameProvider.spinWheel();
          }
        }
      });
    } else {
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          _controller.clear();
          setState(() {
            _showFeedback = false;
            _isIncorrect = false;
          });
          _focusNode.requestFocus();
        }
      });
    }
  }

  Color _getBorderColor() {
    if (!_showFeedback) return Colors.grey.shade300;
    if (_isCorrect) return AppColors.success;
    if (_isIncorrect) return AppColors.error;
    return Colors.grey.shade300;
  }

  // Refactorisé pour gérer le Dark Mode correctement avec la teinte de feedback
  Color _getBackgroundColor(bool isDark) {
    final baseColor = isDark ? Colors.grey[800]! : Colors.white;
    
    if (!_showFeedback) return baseColor;
    
    // En cas de feedback, on mélange la couleur de base avec la couleur de statut
    // On utilise une opacité légèrement plus forte en dark mode pour que ça se voie
    if (_isCorrect) {
      return Color.alphaBlend(
        AppColors.success.withValues(alpha: isDark ? 0.2 : 0.1), 
        baseColor
      );
    }
    if (_isIncorrect) {
      return Color.alphaBlend(
        AppColors.error.withValues(alpha: isDark ? 0.2 : 0.1), 
        baseColor
      );
    }
    return baseColor;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final gameProvider = context.watch<GameProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // LayoutBuilder nous permet de savoir si on a de la place ou non
    return LayoutBuilder(
      builder: (context, constraints) {
        return Center(
          // SingleChildScrollView est CRUCIAL ici pour éviter l'overflow
          // quand le clavier virtuel apparaît.
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              // On limite la largeur pour que sur tablette/PC le champ
              // ne fasse pas 1km de long.
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Message de feedback
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: _showFeedback ? 60 : 0,
                    child: _showFeedback
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isCorrect ? Icons.check_circle : Icons.cancel,
                                color: _isCorrect ? AppColors.success : AppColors.error,
                                size: 32,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _isCorrect ? l10n.correct : l10n.tryAgain,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: _isCorrect ? AppColors.success : AppColors.error,
                                ),
                              ),
                            ],
                          )
                        : const SizedBox(),
                  ),
          
                  const SizedBox(height: 16),
          
                  // Champ de saisie
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      color: _getBackgroundColor(isDark),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _getBorderColor(),
                        width: 3,
                      ),
                      boxShadow: _showFeedback
                          ? [
                              BoxShadow(
                                color: (_isCorrect ? AppColors.success : AppColors.error)
                                    .withValues(alpha: 0.3),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ]
                          : [],
                    ),
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      enabled: gameProvider.currentWord != null && !_showFeedback,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                      // Action "Terminé" sur le clavier mobile lance la validation
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        hintText: gameProvider.currentWord != null
                            ? l10n.typeAnswer
                            : l10n.spinFirst,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 20,
                        ),
                      ),
                      onSubmitted: (_) => _checkAnswer(),
                    ),
                  ),
          
                  const SizedBox(height: 24),
          
                  // Bouton Valider
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: gameProvider.currentWord != null && !_showFeedback
                          ? _checkAnswer
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        l10n.validate,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
          
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}