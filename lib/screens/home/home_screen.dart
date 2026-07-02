// lib/screens/home/home_screen.dart
// Ecran d'accueil — Session 4 (wiring master).
//
// 11 cartes d'action couvrant tous les modules Session 1+2+3 :
//   1. Revision Adaptative  (vert)   — /revision/Mathematiques
//   2. Simulation d'Examen  (orange) — /simulation
//   3. Mon Tableau de Bord  (bleu)   — /dashboard
//   4. Tuteur IA            (violet) — /tutor                          [Session 3, Agent W]
//   5. Mes Badges           (or)     — /badges                          [Session 3, Agent X]
//   6. Prediction Score     (vert c) — /score-prediction                [Session 3, Agent Z]
//   7. Rechercher           (gris)   — /search                          [Session 3, Agent AM]
//   8. Mes Favoris          (rouge)  — /favorites                       [Session 3, Agent AN]
//   9. Mes Notes            (orange) — /notes                           [Session 3, Agent AN]
//  10. Communaute           (rose)   — /community                       [Session 2, Agent R]
//  11. Parametres           (gris f) — /settings                        [Session 2, Agent V]
//
// Layout : liste scrollable verticale (SingleChildScrollView) — chaque carte
// est pleine largeur, plus lisible qu'une grille 2 colonnes sur mobile.

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/user_provider.dart';
import '../../theme/adaptive_colors.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.currentUser;
    final prenom = user?.prenom ?? 'Élève';
    final niveauLabel = _niveauLabel(user?.niveauScolaire, user?.serie);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                // Header
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.school, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Titre de l'application (i18n)
                          Text(l10n.appTitle,
                              style: AppTextStyles.h3.copyWith(
                                  color: AdaptiveColors.textPrimary(context))),
                          Text(
                            // Salutation localisée avec ou sans niveau scolaire
                            niveauLabel != null
                                ? l10n.welcomeGreetingWithLevel(
                                    prenom, niveauLabel)
                                : l10n.welcomeGreeting(prenom),
                            style: AppTextStyles.bodySmall.copyWith(
                                color: AdaptiveColors.textSecondary(context)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Bouton profil / déconnexion
                    IconButton(
                      icon: Icon(Icons.person_outline,
                          color: AdaptiveColors.textSecondary(context)),
                      onPressed: () => _showProfileDialog(context, userProvider),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Titre de section localisé
                Text(l10n.homeWhatDoYouWant,
                    style: AppTextStyles.h2
                        .copyWith(color: AdaptiveColors.textPrimary(context))),
                const SizedBox(height: 16),

                // ─── Cartes d'action (11 modules Session 1+2+3) ──────
                _ActionCard(
                  icon: Icons.flash_on,
                  title: l10n.homeRevisionAdaptive,
                  subtitle: l10n.homeRevisionAdaptiveSubtitle,
                  color: AppColors.primary,
                  // Bug fix (Session 2) : encodage URL de l'accent pour
                  // éviter le crash "invalid arguments" sur /revision/Mathématiques.
                  onTap: () => context.go(
                    '${AppRoutes.revision}/${Uri.encodeComponent('Mathématiques')}',
                  ),
                ),
                const SizedBox(height: 12),
                _ActionCard(
                  icon: Icons.timer,
                  title: l10n.homeSimulation,
                  subtitle: l10n.homeSimulationSubtitle,
                  color: AppColors.accent,
                  onTap: () => context.go(
                    AppRoutes.simulation,
                    extra: {'examen': 'BEPC', 'serie': null},
                  ),
                ),
                const SizedBox(height: 12),
                _ActionCard(
                  icon: Icons.bar_chart,
                  title: l10n.homeDashboard,
                  subtitle: l10n.homeDashboardSubtitle,
                  color: AppColors.info,
                  onTap: () => context.go(AppRoutes.dashboard),
                ),
                const SizedBox(height: 12),
                _ActionCard(
                  icon: Icons.smart_toy_outlined,
                  title: 'Tuteur IA',
                  subtitle: 'Pose tes questions à un coach pédagogique',
                  color: const Color(0xFF7B1FA2), // violet
                  onTap: () => context.go(AppRoutes.tutor),
                ),
                const SizedBox(height: 12),
                _ActionCard(
                  icon: Icons.emoji_events_outlined,
                  title: 'Mes Badges',
                  subtitle: 'Collectionne 39 badges et grimpe les niveaux',
                  color: const Color(0xFFFFB300), // or
                  onTap: () => context.go(AppRoutes.badges),
                ),
                const SizedBox(height: 12),
                _ActionCard(
                  icon: Icons.analytics_outlined,
                  title: 'Prédiction Score',
                  subtitle: 'Estimation officielle BEPC/BAC avec coefficients MEPST',
                  color: AppColors.success, // vert clair (vs primary plus foncé)
                  onTap: () => context.go(AppRoutes.scorePrediction),
                ),
                const SizedBox(height: 12),
                _ActionCard(
                  icon: Icons.search,
                  title: 'Rechercher',
                  subtitle: 'Filtres avancés : matière, année, difficulté, type',
                  color: AdaptiveColors.textSecondary(context), // gris
                  onTap: () => context.go(AppRoutes.search),
                ),
                const SizedBox(height: 12),
                _ActionCard(
                  icon: Icons.favorite_border,
                  title: 'Mes Favoris',
                  subtitle: 'Questions marquées pour relecture rapide',
                  color: AppColors.error, // rouge
                  onTap: () => context.go(AppRoutes.favorites),
                ),
                const SizedBox(height: 12),
                _ActionCard(
                  icon: Icons.sticky_note_2_outlined,
                  title: 'Mes Notes',
                  subtitle: 'Annotations personnelles sur les questions',
                  color: AppColors.warning, // orange clair
                  onTap: () => context.go(AppRoutes.notes),
                ),
                const SizedBox(height: 12),
                _ActionCard(
                  icon: Icons.groups,
                  title: 'Communauté',
                  subtitle: 'Classements, défis hebdo et entraide entre élèves',
                  color: const Color(0xFFE91E63), // rose
                  onTap: () => context.go(AppRoutes.community),
                ),
                const SizedBox(height: 12),
                _ActionCard(
                  icon: Icons.settings,
                  title: 'Paramètres',
                  subtitle: 'Langue, thème, compte, données, notifications, sync',
                  color: const Color(0xFF424242), // gris foncé
                  onTap: () => context.go(AppRoutes.settings),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _niveauLabel(String? niveau, String? serie) {
    if (niveau == null) return null;
    final niveauFormat = {
      '3eme': '3e',
      '2nde': '2nde',
      '1ere': '1ère',
      'Terminale': 'Term',
    }[niveau] ?? niveau;
    if (serie != null && (niveau == '1ere' || niveau == 'Terminale')) {
      return '$niveauFormat $serie';
    }
    return niveauFormat;
  }

  void _showProfileDialog(BuildContext context, UserProvider userProvider) {
    final user = userProvider.currentUser;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mon profil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (user != null) ...[
              Text('${user.prenom} ${user.nom}',
                  style: AppTextStyles.h3
                      .copyWith(color: AdaptiveColors.textPrimary(context))),
              const SizedBox(height: 4),
              Text('Niveau : ${user.niveauScolaire}${user.serie != null ? ' (série ${user.serie})' : ''}',
                  style: AppTextStyles.body
                      .copyWith(color: AdaptiveColors.textPrimary(context))),
              if (user.etablissement != null) ...[
                const SizedBox(height: 4),
                Text('Établissement : ${user.etablissement}',
                    style: AppTextStyles.body
                        .copyWith(color: AdaptiveColors.textPrimary(context))),
              ],
              if (user.ville != null) ...[
                const SizedBox(height: 4),
                Text('Ville : ${user.ville}',
                    style: AppTextStyles.body
                        .copyWith(color: AdaptiveColors.textPrimary(context))),
              ],
              const SizedBox(height: 8),
              Text('Inscrit depuis le ${user.dateInscription.day.toString().padLeft(2, '0')}/${user.dateInscription.month.toString().padLeft(2, '0')}/${user.dateInscription.year}',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AdaptiveColors.textSecondary(context))),
            ] else
              const Text('Aucun profil chargé'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer'),
          ),
          if (user != null)
            TextButton(
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              onPressed: () async {
                await userProvider.logout();
                if (context.mounted) {
                  Navigator.pop(ctx);
                  context.go(AppRoutes.onboarding);
                }
              },
              child: const Text('Se déconnecter'),
            ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(context.isDark ? 0.20 : 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: AppTextStyles.h3.copyWith(
                          fontSize: 16,
                          color: AdaptiveColors.textPrimary(context),
                        )),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: AppTextStyles.bodySmall.copyWith(
                            color: AdaptiveColors.textSecondary(context))),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  size: 16, color: AdaptiveColors.textSecondary(context)),
            ],
          ),
        ),
      ),
    );
  }
}
