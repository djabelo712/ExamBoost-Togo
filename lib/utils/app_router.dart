// lib/utils/app_router.dart
// Routing centralise avec GoRouter (Session 4 — wiring master).
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
// Routes (23 au total) :
//   Session 1-2 (10 routes) :
//     /splash, /onboarding, /, /revision/:matiere, /simulation, /dashboard,
//     /community, /settings, /admin/login, /admin/dashboard
//   Session 3 (13 routes nouvelles) :
//     /admin/content, /settings/notifications, /settings/tts, /settings/sync,
//     /tutor, /badges, /score-prediction, /stats/:matiere,
//     /stats/competence/:competenceId, /search, /search/results,
//     /favorites, /notes
//
// Toutes les routes utilisent buildPageWithTransition() pour des transitions
// coherentes (fade / slideUp / slideRight / scale selon le contexte).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/score_prediction.dart';
import '../providers/user_provider.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/admin_login_screen.dart';
import '../screens/admin/content_management_screen.dart';
import '../screens/auth/onboarding_screen.dart';
import '../screens/badges/badges_screen.dart';
import '../screens/community/community_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/favorites/favorites_screen.dart';
import '../screens/favorites/notes_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/revision/revision_screen.dart';
import '../screens/score/score_prediction_screen.dart';
import '../screens/search/models/search_filters.dart';
import '../screens/search/search_results_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/settings/notification_settings_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/settings/sync_settings_screen.dart';
import '../screens/settings/tts_settings_screen.dart';
import '../screens/simulation/simulation_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/splash/transitions.dart';
import '../screens/stats/competence_detail_screen.dart';
import '../screens/stats/subject_detail_screen.dart';
import '../screens/tutor/tutor_screen.dart';

class AppRouter {
  // Singleton : on garde une seule instance de GoRouter pour eviter
  // de recreer le router (et perdre l'etat de navigation) a chaque rebuild
  // de MaterialApp.router.
  static GoRouter? _instance;
  static GoRouter get router => _instance ??= _buildRouter();

  static GoRouter _buildRouter() {
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
        // ═══════════════════════════════════════════════════════════════
        // SESSION 1-2 : ROUTES EXISTANTES (10)
        // ═══════════════════════════════════════════════════════════════

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

        // ═══════════════════════════════════════════════════════════════
        // SESSION 3 : NOUVELLES ROUTES (13)
        // ═══════════════════════════════════════════════════════════════

        // ─── Gestion de contenu (Agent AV) : fade ───────────────────
        // Requiert un adminToken JWT (compte directeur is_admin=true).
        // state.extra : Map<String, String?> {'adminToken': '...', 'apiBaseUrl'?}
        GoRoute(
          path: AppRoutes.adminContent,
          name: 'adminContent',
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return buildPageWithTransition(
              child: ContentManagementScreen(
                adminToken: (extra?['adminToken'] as String?) ?? '',
                apiBaseUrl: (extra?['apiBaseUrl'] as String?) ??
                    'http://localhost:8000',
              ),
              type: TransitionType.fade,
            );
          },
        ),

        // ─── Sous-ecrans Settings ───────────────────────────────────

        // Notifications locales (Agent Y).
        GoRoute(
          path: AppRoutes.notificationSettings,
          name: 'notificationSettings',
          pageBuilder: (context, state) => buildPageWithTransition(
            child: const NotificationSettingsScreen(),
            type: TransitionType.slideRight,
          ),
        ),

        // Lecture audio TTS (Agent AQ).
        GoRoute(
          path: AppRoutes.ttsSettings,
          name: 'ttsSettings',
          pageBuilder: (context, state) => buildPageWithTransition(
            child: const TtsSettingsScreen(),
            type: TransitionType.slideRight,
          ),
        ),

        // Synchronisation cloud (Agent AC).
        GoRoute(
          path: AppRoutes.syncSettings,
          name: 'syncSettings',
          pageBuilder: (context, state) => buildPageWithTransition(
            child: const SyncSettingsScreen(),
            type: TransitionType.slideRight,
          ),
        ),

        // ─── Tuteur IA (Agent W) : slideUp ─────────────────────────
        // state.extra (optionnel) : Map<String, String?> {'matiere', 'chapitre',
        // 'competenceId', 'authToken', 'baseUrl'}.
        GoRoute(
          path: AppRoutes.tutor,
          name: 'tutor',
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, String?>?;
            return buildPageWithTransition(
              child: TutorScreen(
                matiere: extra?['matiere'],
                chapitre: extra?['chapitre'],
                competenceId: extra?['competenceId'],
                authToken: extra?['authToken'],
                baseUrl: extra?['baseUrl'],
              ),
              type: TransitionType.slideUp,
            );
          },
        ),

        // ─── Badges & gamification (Agent X) : slideRight ──────────
        GoRoute(
          path: AppRoutes.badges,
          name: 'badges',
          pageBuilder: (context, state) => buildPageWithTransition(
            child: const BadgesScreen(),
            type: TransitionType.slideRight,
          ),
        ),

        // ─── Prediction score BEPC/BAC (Agent Z) : fade ────────────
        // state.extra (optionnel) : ScorePrediction (evite le recalcul).
        // On accepte aussi un Map avec la cle 'initialPrediction' pour
        // faciliter les appels context.go(extra: {...}).
        GoRoute(
          path: AppRoutes.scorePrediction,
          name: 'scorePrediction',
          pageBuilder: (context, state) {
            Object? extra = state.extra;
            ScorePrediction? initial;
            if (extra is ScorePrediction) {
              initial = extra;
            } else if (extra is Map<String, dynamic>) {
              final p = extra['initialPrediction'];
              if (p is ScorePrediction) initial = p;
            }
            return buildPageWithTransition(
              child: ScorePredictionScreen(initialPrediction: initial),
              type: TransitionType.fade,
            );
          },
        ),

        // ─── Stats par matiere (Agent AD) : slideRight ─────────────
        // Path param :matiere (URL-encoded, ex : /stats/Math%C3%A9matiques).
        GoRoute(
          path: '${AppRoutes.stats}/:matiere',
          name: 'subjectDetail',
          pageBuilder: (context, state) {
            final matiere = state.pathParameters['matiere'] ?? 'Math%C3%A9matiques';
            return buildPageWithTransition(
              child: SubjectDetailScreen(
                matiere: Uri.decodeComponent(matiere),
              ),
              type: TransitionType.slideRight,
            );
          },
        ),

        // ─── Stats par competence (Agent AD) : slideRight ──────────
        GoRoute(
          path: AppRoutes.competenceDetail,
          name: 'competenceDetail',
          pageBuilder: (context, state) {
            final competenceId =
                state.pathParameters['competenceId'] ?? '';
            return buildPageWithTransition(
              child: CompetenceDetailScreen(competenceId: competenceId),
              type: TransitionType.slideRight,
            );
          },
        ),

        // ─── Recherche & filtres (Agent AM) : slideUp ──────────────
        GoRoute(
          path: AppRoutes.search,
          name: 'search',
          pageBuilder: (context, state) => buildPageWithTransition(
            child: const SearchScreen(),
            type: TransitionType.slideUp,
          ),
        ),

        // ─── Resultats de recherche (Agent AM) : fade ──────────────
        // state.extra : Map<String, dynamic> {'name': String, 'filters': Map}
        // (filters au format SearchFilters.toJson()).
        GoRoute(
          path: AppRoutes.searchResults,
          name: 'searchResults',
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            final name = (extra?['name'] as String?) ?? 'Recherche';
            final filtersJson = extra?['filters'];
            SearchFilters filters = SearchFilters.empty;
            if (filtersJson is Map<String, dynamic>) {
              try {
                filters = SearchFilters.fromJson(filtersJson);
              } catch (_) {
                // Si le JSON est corrompu, on retombe sur des filtres vides.
              }
            } else if (filtersJson is SearchFilters) {
              filters = filtersJson;
            }
            return buildPageWithTransition(
              child: SearchResultsScreen(name: name, filters: filters),
              type: TransitionType.fade,
            );
          },
        ),

        // ─── Favoris (Agent AN) : slideRight ───────────────────────
        GoRoute(
          path: AppRoutes.favorites,
          name: 'favorites',
          pageBuilder: (context, state) => buildPageWithTransition(
            child: const FavoritesScreen(),
            type: TransitionType.slideRight,
          ),
        ),

        // ─── Notes personnelles (Agent AN) : slideRight ────────────
        GoRoute(
          path: AppRoutes.notes,
          name: 'notes',
          pageBuilder: (context, state) => buildPageWithTransition(
            child: const NotesScreen(),
            type: TransitionType.slideRight,
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
  // ─── Session 1-2 (10 routes) ────────────────────────────────────
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

  // ─── Session 3 (13 routes nouvelles) ───────────────────────────
  static const String adminContent          = '/admin/content';
  static const String notificationSettings  = '/settings/notifications';
  static const String ttsSettings           = '/settings/tts';
  static const String syncSettings          = '/settings/sync';
  static const String tutor                 = '/tutor';
  static const String badges                = '/badges';
  static const String scorePrediction       = '/score-prediction';
  static const String stats                 = '/stats';
  static const String competenceDetail      = '/stats/competence/:competenceId';
  static const String search                = '/search';
  static const String searchResults         = '/search/results';
  static const String favorites             = '/favorites';
  static const String notes                 = '/notes';
}
