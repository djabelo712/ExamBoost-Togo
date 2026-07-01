// lib/widgets/states/empty_states/first_launch_empty.dart
// Empty state : premier lancement de l'app.
//
// Cas d'usage : ecran de bienvenue affiche apres installation (avant
// onboarding) ou sur le dashboard si l'utilisateur n'a pas encore configure
// son profil.
//
// Bouton "Creer mon profil" : ouvre l'onboarding (profil, niveau scolaire,
// examen cible BEPC / BAC).

import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../empty_state.dart';

class FirstLaunchEmpty extends StatelessWidget {
  /// Callback du bouton "Creer mon profil".
  final VoidCallback? onCreateProfile;

  const FirstLaunchEmpty({
    super.key,
    this.onCreateProfile,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.waving_hand,
      iconColor: AppColors.primary,
      iconSize: 88,
      title: 'Bienvenue sur ExamBoost !',
      description: "On est ravis de t'accueillir. Configure ton profil "
          "pour commencer.",
      actionLabel: 'Créer mon profil',
      onAction: onCreateProfile,
    );
  }
}
