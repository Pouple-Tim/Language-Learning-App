import 'package:flutter/material.dart';
import 'package:language_learning_app/data/models/deck.dart'; // Pour l'enum InputType
import 'package:language_learning_app/core/theme/app_colors.dart';
import 'package:language_learning_app/l10n/app_localizations.dart';

class InputTypeSelector extends StatelessWidget {
  final InputType selectedType;
  final ValueChanged<InputType> onTypeChanged;

  const InputTypeSelector({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: _InputTypeCard(
            icon: Icons.keyboard,
            label: l10n.text,
            isSelected: selectedType == InputType.text,
            onTap: () => onTypeChanged(InputType.text),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _InputTypeCard(
            icon: Icons.draw,
            label: l10n.drawing,
            isSelected: selectedType == InputType.draw,
            onTap: () => onTypeChanged(InputType.draw),
          ),
        ),
      ],
    );
  }
}

class _InputTypeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _InputTypeCard({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: isSelected ? AppColors.primary : Colors.grey.shade600,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.primary : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}