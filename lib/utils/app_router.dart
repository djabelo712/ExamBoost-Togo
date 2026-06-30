// lib/utils/app_router.dart
// Routing centralisé avec GoRouter

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/home/home_screen.dart';
import '../screens/revision/revision_screen.dart';
import '../screens/simulation/simulation_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/auth/onboarding_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.revision}/:matiere',
        name: 'revision',
        builder: (context, state) {
          final matiere = state.pathParameters['matiere'] ?? 'Mathématiques';
          return RevisionScreen(
            matiere: Uri.decodeComponent(matiere),
            userId: 'user_demo', // TODO: récupérer depuis le state
          );
        },
      ),
      GoRoute(
        path: AppRoutes.simulation,
        name: 'simulation',
        builder: (context, state) {
          final extra = state.extra as Map<String, String?>?;
          return SimulationScreen(
            examen: extra?['examen'] ?? 'BEPC',
            serie: extra?['serie'],
          );
        },
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Page introuvable : ${state.uri}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Retour à l\'accueil'),
            ),
          ],
        ),
      ),
    ),
  );
}

class AppRoutes {
  static const String onboarding = '/onboarding';
  static const String home       = '/';
  static const String revision   = '/revision';
  static const String simulation = '/simulation';
  static const String dashboard  = '/dashboard';
  static const String settings   = '/settings';
}
