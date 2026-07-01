// lib/utils/app_router.dart
// Routing centralise avec GoRouter
//
// Logique de redirection :
//   - Splash : aucune redirect (le splash se debrouille, il appelle context.go
//     lui-meme a la fin de l'animation pour aller vers /onboarding ou /).
//   - Espace admin (/admin/*) : AUCUNE redirect UserProvider (auth directeur
//     independante de l'auth eleve).
//   - Sinon : si UserProvider pas init -> on reste ; si user non auth ET
//     route != /onboarding -> /onboarding ; si user auth ET route ==
//     /onboarding -> / (home).
//
// Toutes les routes utilisent buildPageWithTransition() pour des transitions
// coherentes (fade / slideUp / slideRight / scale selon le contexte).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/user_provider.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/admin_login_screen.dart';
import '../screens/auth/onboarding_screen.dart';
import '../screens/community/community_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/revision/revision_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/simulation/simulation_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/splash/transitions.dart';

class AppRouter {
  static GoRouter get router {
    return GoRouter(
      // Le splash est la route initiale : il decide lui-meme d'aller vers
      // /onboarding (si non authentifie) ou / (si authentifie) a la fin de
      // son animation 2.5s.
      initialLocation: AppRoutes.splash,
      debugLogDiagnostics: false,
      refreshListenable: _RouterRefreshNotifier(),
      redirect: (context, state) {
        final loc = state.matchedLocation;

        // ─── Garde 1 : Splash ───────────────────────────────────────
        // Pendant le splash, on ne redirige JAMAIS : l'animation doit jouer
        // entierement. C'est le SplashScreen lui-meme qui declenchera la
        // navigation finale via context.go().
        if (loc == AppRoutes.splash) return null;

        // ─── Garde 2 : Espace admin ─────────────────────────────────
        // Les directeurs ont leur propre auth (JWT separe), on ne les soumet
        // PAS au UserProvider eleve. Aucune redirection vers /onboarding.
        if (loc.startsWith('/admin')) return null;

        final userProvider = Provider.of<UserProvider>(
          context,
          listen: false,
        );

        // Pendant l'init, on reste ou on est (ecran blanc bref pendant que
        // Hive / SharedPreferences se chargent).
        if (!userProvider.isInitialized) return null;

        final isAuthenticated = userProvider.isAuthenticated;
        final isOnOnboarding = loc == AppRoutes.onboarding;

        // Pas connecte + pas sur onboarding -> rediriger vers onboarding
        if (!isAuthenticated && !isOnOnboarding) {
          return AppRoutes.onboarding;
        }

        // Connecte + sur onboarding -> rediriger vers home
        if (isAuthenticated && isOnOnboarding) {
          return AppRoutes.home;
        }

        return null; // pas de redirect
      },
      routes: [
        // ─── Splash : fade (la transition est surtout inerte au demarrage
        // car splash est initialLocation, mais on l'ajoute pour cohérence
        // avec les autres routes et pour le cas où l'user reviendrait sur
        // /splash par erreur.)
        GoRoute(
          path: AppRoutes.splash,
          name: 'splash',
          pageBuilder: (context, state) => buildPageWithTransition(
            child: const SplashScreen(),
            type: TransitionType.fade,
          ),
        ),

        // ─── Onboarding : slideUp (effet modale qui monte) ─────────
        GoRoute(
          path: AppRoutes.onboarding,
          name: 'onboarding',
          pageBuilder: (context, state) => buildPageWithTransition(
            child: const OnboardingScreen(),
            type: TransitionType.slideUp,
          ),
        ),

        // ─── Home : fade (sobre, transition neutre apres splash) ───
        GoRoute(
          path: AppRoutes.home,
          name: 'home',
          pageBuilder: (context, state) => buildPageWithTransition(
            child: const HomeScreen(),
            type: TransitionType.fade,
          ),
        ),

        // ─── Revision : slideRight (push hierarchique classique) ──
        GoRoute(
          path: '${AppRoutes.revision}/:matiere',
          name: 'revision',
          pageBuilder: (context, state) {
            final matiere = state.pathParameters['matiere'] ?? 'Math%C3%A9matiques';
            final userProvider = Provider.of<UserProvider>(
              context,
              listen: false,
            );
            return buildPageWithTransition(
              child: RevisionScreen(
                matiere: Uri.decodeComponent(matiere),
                userId: userProvider.currentUserId,
              ),
              type: TransitionType.slideRight,
            );
          },
        ),

        // ─── Simulation : slideUp (modale plein ecran) ─────────────
        GoRoute(
          path: AppRoutes.simulation,
          name: 'simulation',
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, String?>?;
            return buildPageWithTransition(
              child: SimulationScreen(
                examen: extra?['examen'] ?? 'BEPC',
                serie: extra?['serie'],
              ),
              type: TransitionType.slideUp,
            );
          },
        ),

        // ─── Dashboard : fade ──────────────────────────────────────
        GoRoute(
          path: AppRoutes.dashboard,
          name: 'dashboard',
          pageBuilder: (context, state) => buildPageWithTransition(
            child: const DashboardScreen(),
            type: TransitionType.fade,
          ),
        ),

        // ─── Communaute : slideRight ───────────────────────────────
        GoRoute(
          path: AppRoutes.community,
          name: 'community',
          pageBuilder: (context, state) => buildPageWithTransition(
            child: const CommunityScreen(),
            type: TransitionType.slideRight,
          ),
        ),

        // ─── Settings : slideRight ─────────────────────────────────
        GoRoute(
          path: AppRoutes.settings,
          name: 'settings',
          pageBuilder: (context, state) => buildPageWithTransition(
            child: const SettingsScreen(),
            type: TransitionType.slideRight,
          ),
        ),

        // ─── Espace admin : pas de redirect UserProvider ───────────
        // Login directeur (email + mot de passe). En mode demo : n'importe
        // quel email valide + mot de passe non vide est accepte.
        GoRoute(
          path: AppRoutes.adminLogin,
          name: 'adminLogin',
          pageBuilder: (context, state) => buildPageWithTransition(
            child: const AdminLoginScreen(),
            type: TransitionType.fade,
          ),
        ),

        // Dashboard directeur (KPI etablissement + 3 onglets).
        // Pas de guard auth ici : en mode demo on accepte tout. En prod,
        // l'agent principal pourra ajouter un AdminAuthProvider.
        GoRoute(
          path: AppRoutes.adminDashboard,
          name: 'adminDashboard',
          pageBuilder: (context, state) => buildPageWithTransition(
            child: const AdminDashboardScreen(),
            type: TransitionType.fade,
          ),
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
                child: const Text('Retour a l\'accueil'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Notifie le router quand l'etat du UserProvider change
/// (pour declencher le redirect automatique apres login/logout)
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier() {
    // On ecoute un Provider global — mais comme on n'a pas de context ici,
    // cette classe est juste un placeholder. La redirection se declenchera
    // au prochain rebuild (ex: setState dans HomeScreen apres login).
    // Pour une redirection immediate, appeler context.go() depuis OnboardingScreen.
  }
}

class AppRoutes {
  static const String splash         = '/splash';
  static const String onboarding     = '/onboarding';
  static const String home           = '/';
  static const String revision       = '/revision';
  static const String simulation     = '/simulation';
  static const String dashboard      = '/dashboard';
  static const String community      = '/community';
  static const String settings       = '/settings';
  static const String adminLogin     = '/admin/login';
  static const String adminDashboard = '/admin/dashboard';
}
