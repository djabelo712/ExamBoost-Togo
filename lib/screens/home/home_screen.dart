// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ExamBoost Togo', style: AppTextStyles.h3),
                      Text('Bonjour, Élève !', style: AppTextStyles.bodySmall),
                    ],
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
                onTap: () => context.go('${AppRoutes.revision}/Mathématiques'),
              ),
              const SizedBox(height: 12),
              _ActionCard(
                icon: Icons.timer,
                title: 'Simulation d\'Examen',
                subtitle: 'Entraîne-toi dans les conditions réelles',
                color: AppColors.accent,
                onTap: () => context.go(AppRoutes.simulation,
                    extra: {'examen': 'BEPC', 'serie': null}),
              ),
              const SizedBox(height: 12),
              _ActionCard(
                icon: Icons.bar_chart,
                title: 'Mon Tableau de Bord',
                subtitle: 'Voir ma progression et mes statistiques',
                color: AppColors.info,
                onTap: () => context.go(AppRoutes.dashboard),
              ),
            ],
          ),
        ),
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
              Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
