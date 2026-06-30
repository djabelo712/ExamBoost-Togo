// lib/utils/app_router.dart
// Routing centralisé avec GoRouter
//
// Logique de redirection :
//   - Si UserProvider pas initialisé → écran de chargement
//   - Si user non authentifié ET route != /onboarding → /onboarding
//   - Si user authentifié ET route == /onboarding → / (home)

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/user_provider.dart';
import '../screens/home/home_screen.dart';
import '../screens/revision/revision_screen.dart';
import '../screens/simulation/simulation_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/auth/onboarding_screen.dart';

class AppRouter {
  static GoRouter get router {
    return GoRouter(
      initialLocation: AppRoutes.home,
      debugLogDiagnostics: false,
      refreshListenable: _RouterRefreshNotifier(),
      redirect: (context, state) {
        final userProvider = Provider.of<UserProvider>(
          context,
          listen: false,
        );

        // Pendant l'init, on reste où on est (écran blanc bref)
        if (!userProvider.isInitialized) return null;

        final isAuthenticated = userProvider.isAuthenticated;
        final isOnOnboarding = state.matchedLocation == AppRoutes.onboarding;

        // Pas connecté + pas sur onboarding → rediriger vers onboarding
        if (!isAuthenticated && !isOnOnboarding) {
          return AppRoutes.onboarding;
        }

        // Connecté + sur onboarding → rediriger vers home
        if (isAuthenticated && isOnOnboarding) {
          return AppRoutes.home;
        }

        return null; // pas de redirect
      },
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
            final userProvider = Provider.of<UserProvider>(
              context,
              listen: false,
            );
            return RevisionScreen(
              matiere: Uri.decodeComponent(matiere),
              userId: userProvider.currentUserId,
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
}

/// Notifie le router quand l'état du UserProvider change
/// (pour déclencher le redirect automatique après login/logout)
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier() {
    // On écoute un Provider global — mais comme on n'a pas de context ici,
    // cette classe est juste un placeholder. La redirection se déclenchera
    // au prochain rebuild (ex: setState dans HomeScreen après login).
    // Pour une redirection immédiate, appeler context.go() depuis OnboardingScreen.
  }
}

class AppRoutes {
  static const String onboarding = '/onboarding';
  static const String home       = '/';
  static const String revision   = '/revision';
  static const String simulation = '/simulation';
  static const String dashboard  = '/dashboard';
  static const String settings   = '/settings';
}
