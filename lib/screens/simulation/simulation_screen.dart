// lib/screens/simulation/simulation_screen.dart
// TODO: Implémenter l'écran Simulation d'Examen

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class SimulationScreen extends StatelessWidget {
  const SimulationScreen({super.key, this.examen, this.serie});
  final String? examen;
  final String? serie;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Simulation d'Examen")),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.timer, size: 64, color: AppColors.primary),
            const SizedBox(height: 16),
            Text("Simulation d'Examen", style: AppTextStyles.h2),
            const SizedBox(height: 8),
            const Text('En cours de développement...'),
          ],
        ),
      ),
    );
  }
}
