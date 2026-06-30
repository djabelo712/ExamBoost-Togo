// lib/screens/dashboard/dashboard_screen.dart
// TODO: Implémenter l'écran Tableau de Bord

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tableau de Bord')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bar_chart, size: 64, color: AppColors.primary),
            const SizedBox(height: 16),
            Text('Tableau de Bord', style: AppTextStyles.h2),
            const SizedBox(height: 8),
            const Text('En cours de développement...'),
          ],
        ),
      ),
    );
  }
}
