// lib/widgets/buttons/srs_buttons.dart
// Boutons de qualité SRS (Facile / Correct / Difficile / Oublié)
// S'affichent après que l'élève a vu la réponse

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class SrsButtons extends StatelessWidget {
  final void Function(int quality) onQualitySelected;

  const SrsButtons({super.key, required this.onQualitySelected});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Comment tu t\'en es sorti ?',
          style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12),
        // Ligne 1 : Facile + Correct
        Row(
          children: [
            Expanded(
              child: _SrsButton(
                label: 'Facile',
                sublabel: 'Réponse immédiate',
                quality: 5,
                color: AppColors.facile,
                icon: Icons.sentiment_very_satisfied,
                onTap: onQualitySelected,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SrsButton(
                label: 'Correct',
                sublabel: 'Légère hésitation',
                quality: 4,
                color: AppColors.info,
                icon: Icons.sentiment_satisfied,
                onTap: onQualitySelected,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Ligne 2 : Difficile + Oublié
        Row(
          children: [
            Expanded(
              child: _SrsButton(
                label: 'Difficile',
                sublabel: 'Réponse trouvée',
                quality: 3,
                color: AppColors.difficile,
                icon: Icons.sentiment_neutral,
                onTap: onQualitySelected,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SrsButton(
                label: 'Oublié',
                sublabel: 'Mauvaise réponse',
                quality: 1,
                color: AppColors.echec,
                icon: Icons.sentiment_very_dissatisfied,
                onTap: onQualitySelected,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SrsButton extends StatelessWidget {
  final String label;
  final String sublabel;
  final int quality;
  final Color color;
  final IconData icon;
  final void Function(int) onTap;

  const _SrsButton({
    required this.label,
    required this.sublabel,
    required this.quality,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.10),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => onTap(quality),
        borderRadius: BorderRadius.circular(14),
        splashColor: color.withOpacity(0.2),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.35), width: 1.5),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTextStyles.button.copyWith(color: color, fontSize: 13),
              ),
              Text(
                sublabel,
                style: AppTextStyles.label.copyWith(
                  color: color.withOpacity(0.75),
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
