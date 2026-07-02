// lib/screens/flash/widgets/flash_timer_widget.dart
// Timer visible en haut de l'écran de session Flash.
//
// Affiche le temps restant au format MM:SS. Devient rouge (et pulse légèrement)
// quand il reste moins de 60 secondes — pour créer un sentiment d'urgence sans
// stresser l'élève.
//
// Le widget reçoit le temps restant en secondes depuis le parent
// (FlashSessionScreen) qui gère le Timer.periodic. Le widget est donc pur
// (stateless) et se contente de l'affichage.

import 'package:flutter/material.dart';
import '../../../theme/adaptive_colors.dart';
import '../../../theme/app_theme.dart';

class FlashTimerWidget extends StatelessWidget {
  /// Temps restant en secondes.
  final int secondesRestantes;

  /// Seuil critique (en secondes) en-dessous duquel le timer devient rouge.
  /// Par défaut : 60 s (1 min).
  final int seuilCritique;

  const FlashTimerWidget({
    super.key,
    required this.secondesRestantes,
    this.seuilCritique = 60,
  });

  @override
  Widget build(BuildContext context) {
    final estCritique = secondesRestantes <= seuilCritique;
    final couleur = estCritique ? AppColors.error : AppColors.primary;

    // Formatage MM:SS (ex : 5:00, 4:32, 0:58).
    final minutes = (secondesRestantes ~/ 60).clamp(0, 99);
    final secondes = (secondesRestantes % 60).clamp(0, 59);
    final texte =
        '${minutes.toString().padLeft(1, '0')}:${secondes.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: couleur.withOpacity(context.isDark ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: couleur.withOpacity(context.isDark ? 0.55 : 0.40),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            estCritique ? Icons.timer_outlined : Icons.timer,
            color: couleur,
            size: 22,
          ),
          const SizedBox(width: 8),
          // Le texte pulse légèrement en mode critique (AnimatedScale géré
          // par le parent via rebuild toutes les secondes — pas d'animation
          // lourde pour rester fluide sur téléphone d'entrée de gamme).
          Text(
            texte,
            style: AppTextStyles.h3.copyWith(
              color: couleur,
              fontFeatures: const [FontFeature.tabularFigures()],
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
