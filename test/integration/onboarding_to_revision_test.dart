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

    testWidgets('Onboarding complet redirige vers home (authenticated)',
        (tester) async {
      // Pre-set a user so the router redirects /onboarding -> /.
      await userProvider.setCurrentUser(createTestUser());

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
      await tester.pumpAndSettle();

      // On /home because the user is authenticated.
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('ExamBoost Togo'), findsOneWidget);
    });

    testWidgets('App démarre sur le splash (pas d\'user)', (tester) async {
      // Without a user, the router's initialLocation is /splash which does
      // NOT redirect (the splash decides itself when to navigate after 2.5s).
      // We just verify the app renders without crashing.
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
      // Pump a single frame (don't wait for the splash animation).
      await tester.pump();

      // The app should render SOMETHING (no exception).
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('Splash redirige vers /onboarding après 2.5s (pas d\'user)',
        (tester) async {
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

      // Advance past the 2.5s splash animation + the 50ms redirect delay.
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Should now be on /onboarding (no user).
      expect(find.byType(OnboardingScreen), findsOneWidget);
    });

    testWidgets('Navigation home -> révision affiche RevisionScreen',
        (tester) async {
      // Set a user so we land on home.
      await userProvider.setCurrentUser(createTestUser());

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
      await tester.pumpAndSettle();

      // Tap on "Révision Adaptative" — this calls context.go('/revision/Mathématiques').
      await tester.tap(find.text('Révision Adaptative'));
      await tester.pumpAndSettle();

      // Should be on the RevisionScreen.
      expect(find.byType(RevisionScreen), findsOneWidget);
    });

    testWidgets('Révision affiche la première question après chargement',
        (tester) async {
      await userProvider.setCurrentUser(createTestUser());

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
      await tester.pumpAndSettle();

      await tester.tap(find.text('Révision Adaptative'));
      await tester.pumpAndSettle();

      // RevisionScreen loads asynchronously.
      await tester.pumpAndSettle();

      // "Voir la réponse" button visible after load.
      expect(find.text('Voir la réponse'), findsOneWidget);
    });
  });
}
