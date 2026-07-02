// lib/screens/classroom/classroom_menu_screen.dart
// Ecran de choix initial du module Classe Temps Reel.
//
// Affiche 2 grandes cartes :
//   - "Rejoindre une classe" (vert) -> /classroom/join
//   - "Créer une session (enseignant)" (orange) -> /classroom/teacher/create
//
// Pas de logique metier ici : juste de la navigation. L'ecran est stateless
// pour rester leger.

import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import 'join_class_screen.dart';
import 'teacher_create_screen.dart';

class ClassroomMenuScreen extends StatelessWidget {
  const ClassroomMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Classe temps reel'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // En-tete
            const _MenuHeader(),
            const SizedBox(height: 24),

            // Carte Rejoindre
            _MenuCard(
              icon: Icons.group_add,
              iconColor: AppColors.primary,
              iconBackground: AppColors.primarySurface,
              title: 'Rejoindre une classe',
              subtitle:
                  'Saisis le code a 6 chiffres donne par ton enseignant pour '
                  'participer au quiz en direct.',
              cta: 'Rejoindre',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const JoinClassScreen(),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Carte Créer
            _MenuCard(
              icon: Icons.cast_for_education,
              iconColor: AppColors.accent,
              iconBackground: AppColors.accentSurface,
              title: 'Créer une session (enseignant)',
              subtitle:
                  'Lance un quiz en direct avec tes élèves ou crée un devoir '
                  'asynchrone. Classement live + podium final.',
              cta: 'Créer',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const TeacherCreateScreen(),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Bloc info
            const _InfoBanner(),
          ],
        ),
      ),
    );
  }
}

// ─── En-tete ────────────────────────────────────────────────────────
class _MenuHeader extends StatelessWidget {
  const _MenuHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.bolt,
                    color: Colors.white, size: 28),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Quiz en direct',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Un enseignant lance une session, les élèves rejoignent avec un code '
            'à 6 chiffres, les questions défilent en direct et un classement '
            'temps réel s\'affiche. Mode devoir disponible pour les révisions '
            'à la maison.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Carte de menu ──────────────────────────────────────────────────
class _MenuCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final String cta;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.cta,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: iconColor, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: AppTextStyles.h3.copyWith(fontSize: 17)),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySmall,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          cta,
                          style: AppTextStyles.label.copyWith(
                            color: iconColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward,
                            color: iconColor, size: 16),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Bannière d'info ────────────────────────────────────────────────
class _InfoBanner extends StatelessWidget {
  const _InfoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accentSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.accent.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.accent, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Le mode devoir permet aux élèves de répondre à leur rythme '
              'dans les 7 jours. Idéal pour les révisions à la maison.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
