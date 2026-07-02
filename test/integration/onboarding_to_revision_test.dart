// test/integration/onboarding_to_revision_test.dart
// Integration scenario: onboarding -> home -> tap "Révision" -> RevisionScreen.
//
// Uses FakeUserProvider (no Hive) + MockQuestionService (with sample data)
// + MockSrsService (in-memory). Avoids Hive initialization so the test
// runs even without the generated adapters.
//
// NOTE: This file imports models that use @HiveType, so it requires the
// generated .g.dart adapters. Run:
//   dart run build_runner build --delete-conflicting-outputs

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';

import 'package:examboost_togo/providers/user_provider.dart';
import 'package:examboost_togo/screens/auth/onboarding_screen.dart';
import 'package:examboost_togo/screens/home/home_screen.dart';
import 'package:examboost_togo/screens/revision/revision_screen.dart';
import 'package:examboost_togo/services/question_service.dart';
import 'package:examboost_togo/services/srs_service.dart';
import 'package:examboost_togo/utils/app_router.dart';

import '../helpers/mock_services.dart';
import '../helpers/test_data.dart';
import '../helpers/test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Integration: onboarding -> home -> revision', () {
    late FakeUserProvider userProvider;
    late MockQuestionService questionService;
    late MockSrsService srsService;
    late GoRouter router;

    setUp(() {
      userProvider = FakeUserProvider();
      questionService = MockQuestionService(initialQuestions: sampleQuestions);
      srsService = MockSrsService();
      router = AppRouter.router;
    });

    Future<void> pumpApp(WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<UserProvider>.value(value: userProvider),
            Provider<QuestionService>.value(value: questionService),
            Provider<SrsService>.value(value: srsService),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
    }

    // ─── Step 1: app boots without crashing ──────────────────────
    testWidgets('App démarre sur le splash (pas d\'user)', (tester) async {
      // Without a user, the router's initialLocation is /splash which does
      // NOT redirect (the splash decides itself when to navigate after 2.5s).
      await pumpApp(tester);
      await tester.pump();

      // The app should render SOMETHING (no exception).
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    // ─── Step 2: splash -> onboarding after 2.5s ─────────────────
    testWidgets('Splash redirige vers /onboarding après 2.5s (pas d\'user)',
        (tester) async {
      await pumpApp(tester);

      // Advance past the 2.5s splash animation + the 50ms redirect delay.
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Should now be on /onboarding (no user).
      expect(find.byType(OnboardingScreen), findsOneWidget);
    });

    // ─── Step 3: authenticated user lands on home ────────────────
    testWidgets('Onboarding complet redirige vers home (authenticated)',
        (tester) async {
      // Pre-set a user so the router redirects /onboarding -> /.
      await userProvider.setCurrentUser(createTestUser());

      await pumpApp(tester);
      await tester.pumpAndSettle();

      // On /home because the user is authenticated.
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('ExamBoost Togo'), findsOneWidget);
    });

    // ─── Step 4: home -> revision navigation ─────────────────────
    testWidgets('Navigation home -> révision affiche RevisionScreen',
        (tester) async {
      // Set a user so we land on home.
      await userProvider.setCurrentUser(createTestUser());

      await pumpApp(tester);
      await tester.pumpAndSettle();

      // Tap on "Révision Adaptative" — this calls
      // context.go('/revision/Mathématiques').
      await tester.tap(find.text('Révision Adaptative'));
      await tester.pumpAndSettle();

      // Should be on the RevisionScreen.
      expect(find.byType(RevisionScreen), findsOneWidget);
    });

    // ─── Step 5: first question visible after load ───────────────
    testWidgets('Révision affiche la première question après chargement',
        (tester) async {
      await userProvider.setCurrentUser(createTestUser());

      await pumpApp(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Révision Adaptative'));
      await tester.pumpAndSettle();

      // RevisionScreen loads asynchronously.
      await tester.pumpAndSettle();

      // "Voir la réponse" button visible after load.
      expect(find.text('Voir la réponse'), findsOneWidget);
    });

    // ─── Full E2E scenario: 11 steps ─────────────────────────────
    // Spec: onboarding_to_revision_test.dart — 11 steps.
    //
    // Steps:
    //   1.  Lance app (router starts at /splash)
    //   2.  Splash screen 2.5s
    //   3.  Onboarding welcome step ("Commencer" button visible)
    //   4.  Tap "Commencer" -> identity step
    //   5.  Fill "Prénom" + "Nom"
    //   6.  Tap "Suivant" -> niveau step
    //   7.  Tap "3ème" -> niveau selected
    //   8.  Tap "Suivant" -> matières step (serie step skipped for 3ème)
    //   9.  Tap "Mathématiques" FilterChip + tap "Créer mon profil"
    //   10. Home screen displayed with "Bonjour, [prenom]"
    //   11. Tap "Révision Adaptative" -> RevisionScreen + first question
    testWidgets('E2E : onboarding 5 étapes -> home -> révision (11 étapes)',
        (tester) async {
      // Step 1 — Lance l'app (router starts at /splash).
      await pumpApp(tester);
      await tester.pump();

      // Step 2 — Splash screen 2.5s. Advance the clock past the splash
      // animation + the redirect delay.
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Step 3 — Onboarding welcome step. The "Commencer" button is
      // rendered by _buildNavigationButtons on the welcome step.
      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.text('Commencer'), findsOneWidget);

      // Step 4 — Tap "Commencer" -> identity step.
      await tester.tap(find.text('Commencer'));
      await tester.pumpAndSettle();

      // The identity step displays "Prénom *" and "Nom *" labels.
      expect(find.text('Prénom *'), findsOneWidget);
      expect(find.text('Nom *'), findsOneWidget);

      // Step 5 — Fill the identity fields.
      await tester.enterText(find.widgetWithText(TextField, 'Prénom *'), 'Amina');
      await tester.enterText(find.widgetWithText(TextField, 'Nom *'), 'Kossi');
      await tester.pumpAndSettle();

      // Step 6 — Tap "Suivant" -> niveau step.
      expect(find.text('Suivant'), findsOneWidget);
      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();

      // Step 7 — Tap "3ème" card -> niveau selected.
      // The niveau step shows "Ton niveau scolaire" header.
      expect(find.text('Ton niveau scolaire'), findsOneWidget);
      await tester.tap(find.text('3ème'));
      await tester.pumpAndSettle();

      // Step 8 — Tap "Suivant" -> matières step (serie step is skipped
      // because 3eme is not 1ère/Terminale).
      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();

      // Step 9 — Tap "Mathématiques" FilterChip + tap "Créer mon profil".
      // The matières step header is "Tes matières préférées".
      expect(find.text('Tes matières préférées'), findsOneWidget);
      await tester.tap(find.text('Mathématiques'));
      await tester.pumpAndSettle();

      // The submit button on the matières step reads "Créer mon profil".
      expect(find.text('Créer mon profil'), findsOneWidget);
      await tester.tap(find.text('Créer mon profil'));

      // The success view shows for 1.5s before context.go(home).
      // We pump past that delay then settle any pending frames.
      await tester.pump(const Duration(milliseconds: 1700));
      await tester.pumpAndSettle();

      // Step 10 — Home screen displayed with "Bonjour, Amina".
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.textContaining('Amina'), findsOneWidget);

      // Step 11 — Tap "Révision Adaptative" -> RevisionScreen + question.
      await tester.tap(find.text('Révision Adaptative'));
      await tester.pumpAndSettle();

      expect(find.byType(RevisionScreen), findsOneWidget);
      // First question is loaded: "Voir la réponse" button is visible.
      expect(find.text('Voir la réponse'), findsOneWidget);
      // The progression counter "1 / N" is visible in the AppBar.
      expect(find.textContaining('1 /'), findsOneWidget);
    });
  });
}
