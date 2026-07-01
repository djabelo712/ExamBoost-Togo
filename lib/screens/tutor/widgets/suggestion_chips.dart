// lib/screens/tutor/widgets/suggestion_chips.dart
// Chips de questions suggérées au démarrage de la conversation.
//
// Affiche 6 chips cliquables (questions par défaut) + un titre "Essaie une
// de ces questions". Si le backend a renvoyé des suggested_followup, on
// les affiche à la place des suggestions par défaut.

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class SuggestionChips extends StatelessWidget {
  const SuggestionChips({
    super.key,
    required this.onSelected,
    this.customSuggestions,
  });

  final ValueChanged<String> onSelected;
  final List<String>? customSuggestions;

  /// 6 suggestions par défaut (couvrent maths, français, sciences).
  static const List<String> defaultSuggestions = [
    'Explique-moi Pythagore',
    'Comment factoriser x²-9 ?',
    'Quelle est la différence entre métaphore et comparaison ?',
    "Aide-moi avec la loi d'Ohm",
    'Comment conjuguer au subjonctif ?',
    'Donne-moi un exemple de Thalès',
  ];

  @override
  Widget build(BuildContext context) {
    final suggestions = (customSuggestions != null && customSuggestions!.isNotEmpty)
        ? customSuggestions!
        : defaultSuggestions;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline,
                  size: 18, color: AppColors.accent),
              const SizedBox(width: 6),
              Text(
                customSuggestions != null && customSuggestions!.isNotEmpty
                    ? 'Questions pour aller plus loin'
                    : 'Essaie une de ces questions',
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions.map((s) {
              return ActionChip(
                label: Text(s),
                backgroundColor: AppColors.primarySurface,
                side: BorderSide(color: AppColors.primary.withOpacity(0.2)),
                labelStyle: AppTextStyles.body.copyWith(
                  fontSize: 13,
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w500,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                onPressed: () => onSelected(s),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
