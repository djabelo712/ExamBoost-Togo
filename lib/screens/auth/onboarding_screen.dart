// lib/screens/auth/onboarding_screen.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bienvenue')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.school, size: 64, color: AppColors.primary),
            const SizedBox(height: 16),
            Text('Bienvenue sur ExamBoost Togo', style: AppTextStyles.h2),
            const SizedBox(height: 8),
            const Text('En cours de développement...'),
          ],
        ),
      ),
    );
  }
}
