// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/user_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.currentUser;
    final prenom = user?.prenom ?? 'Élève';
    final niveauLabel = _niveauLabel(user?.niveauScolaire, user?.serie);

    return Scaffold(
      backgroundColor: AppColors.background,
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
                        Text('ExamBoost Togo', style: AppTextStyles.h3),
                        Text(
                          niveauLabel != null
                              ? 'Bonjour, $prenom · $niveauLabel'
                              : 'Bonjour, $prenom !',
                          style: AppTextStyles.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Bouton profil / déconnexion
                  IconButton(
                    icon: const Icon(Icons.person_outline, color: AppColors.textSecondary),
                    onPressed: () => _showProfileDialog(context, userProvider),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              Text('Que veux-tu faire ?', style: AppTextStyles.h2),
              const SizedBox(height: 16),

              // Cartes d'action
              _ActionCard(
                icon: Icons.flash_on,
                title: 'Révision Adaptative',
                subtitle: 'Questions BEPC et BAC par matière',
                color: AppColors.primary,
                // Bug fix : encodage URL de l'accent pour éviter le crash
                // "invalid arguments" sur /revision/Mathématiques.
                onTap: () => context.go(
                  '${AppRoutes.revision}/${Uri.encodeComponent('Mathématiques')}',
                ),
              ),
              const SizedBox(height: 12),
              _ActionCard(
                icon: Icons.timer,
                title: 'Simulation d\'Examen',
                subtitle: 'Entraîne-toi dans les conditions réelles',
                color: AppColors.accent,
                onTap: () => context.go(
                  AppRoutes.simulation,
                  extra: {'examen': 'BEPC', 'serie': null},
                ),
              ),
              const SizedBox(height: 12),
              _ActionCard(
                icon: Icons.bar_chart,
                title: 'Mon Tableau de Bord',
                subtitle: 'Voir ma progression et mes statistiques',
                color: AppColors.info,
                onTap: () => context.go(AppRoutes.dashboard),
              ),
              const SizedBox(height: 12),
              _ActionCard(
                icon: Icons.groups,
                title: 'Communauté',
                subtitle: 'Classements, défis hebdo et entraide entre élèves',
                color: AppColors.accent,
                onTap: () => context.go(AppRoutes.community),
              ),
              const SizedBox(height: 12),
              _ActionCard(
                icon: Icons.settings,
                title: 'Paramètres',
                subtitle: 'Langue, thème, compte, données et notifications',
                color: AppColors.textSecondary,
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
              Text('${user.prenom} ${user.nom}', style: AppTextStyles.h3),
              const SizedBox(height: 4),
              Text('Niveau : ${user.niveauScolaire}${user.serie != null ? ' (série ${user.serie})' : ''}',
                  style: AppTextStyles.body),
              if (user.etablissement != null) ...[
                const SizedBox(height: 4),
                Text('Établissement : ${user.etablissement}', style: AppTextStyles.body),
              ],
              if (user.ville != null) ...[
                const SizedBox(height: 4),
                Text('Ville : ${user.ville}', style: AppTextStyles.body),
              ],
              const SizedBox(height: 8),
              Text('Inscrit depuis le ${user.dateInscription.day.toString().padLeft(2, '0')}/${user.dateInscription.month.toString().padLeft(2, '0')}/${user.dateInscription.year}',
                  style: AppTextStyles.bodySmall),
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
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.h3.copyWith(fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
