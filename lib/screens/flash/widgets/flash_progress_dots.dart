// lib/screens/flash/widgets/flash_progress_dots.dart
// 5 points de progression pour la session Flash (un par question).
//
// États possibles pour chaque point :
//   - répondu correctement  -> vert plein
//   - répondu incorrectement -> rouge plein
//   - question courante      -> orange animé (pulsation légère)
//   - à venir                -> gris discret
//
// Le widget est stateless : il reçoit l'index courant et la liste des résultats
// (correct/incorrect/null) depuis le parent.

import 'package:flutter/material.dart';
import '../../../theme/adaptive_colors.dart';
import '../../../theme/app_theme.dart';

class FlashProgressDots extends StatelessWidget {
  /// Index de la question courante (0-based).
  final int indexCourant;

  /// Nombre total de questions (5 par défaut).
  final int total;

  /// Résultats des questions déjà répondues.
  /// Length = total. null = pas encore répondu. true = correct. false = incorrect.
  final List<bool?> resultats;

  const FlashProgressDots({
    super.key,
    required this.indexCourant,
    required this.resultats,
    this.total = 5,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final resultat = i < resultats.length ? resultats[i] : null;
        final estCourant = i == indexCourant;
        return _Dot(
          estCourant: estCourant,
          resultat: resultat,
        );
      }),
    );
  }
}

class _Dot extends StatelessWidget {
  final bool estCourant;
  final bool? resultat; // null = à venir, true = correct, false = incorrect

  const _Dot({
    required this.estCourant,
    required this.resultat,
  });

  @override
  Widget build(BuildContext context) {
    // Couleur et taille selon l'état.
    Color couleur;
    double taille = 10.0;

    if (resultat == true) {
      couleur = AppColors.success;
      taille = 12.0;
    } else if (resultat == false) {
      couleur = AppColors.error;
      taille = 12.0;
    } else if (estCourant) {
      couleur = AppColors.accent;
      taille = 14.0;
    } else {
      // À venir : gris discret.
      couleur = AdaptiveColors.textDisabled(context);
      taille = 10.0;
    }

    // Espacement entre les points.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: taille,
        height: taille,
        decoration: BoxDecoration(
          color: couleur,
          shape: BoxShape.circle,
          // Léger halo sur le point courant pour attirer l'œil.
          boxShadow: estCourant
              ? [
                  BoxShadow(
                    color: couleur.withOpacity(0.45),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}
