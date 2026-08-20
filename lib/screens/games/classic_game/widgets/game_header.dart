import 'package:flutter/material.dart';
import 'package:language_learning_app/core/theme/app_colors.dart';
import 'package:language_learning_app/data/models/deck.dart';
import 'package:language_learning_app/core/extensions/deck_extensions.dart';

class GameHeader extends StatelessWidget {
  final Deck deck;
  final String badgeLabel;

  const GameHeader({super.key, required this.deck, required this.badgeLabel});

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        children: [
          Text(
            deck.localizedName(context),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          if (badgeLabel.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                badgeLabel,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.secondary),
              ),
            ),
        ],
      ),
    );
  }
}
