// test/integration/navigation_test.dart
// Integration scenario (basic E2E): navigation between main screens.
//
// Scope (reduced): home -> communaute -> home -> parametres -> home.
// 6 steps. Verifies that the main action cards on the home screen route
// to the right screen, and that the AppBar back button returns to home.
//
// We pick Community + Settings (both have a back affordance: Community uses
// the auto BackButton, Settings has an explicit IconButton with
// Icons.arrow_back that calls context.go(AppRoutes.home)). Both screens
// render without crashing under a minimal provider setup.
//
// Uses FakeUserProvider (pre-seeded user) + MockQuestionService +
// MockSrsService. Hive is initialised in a temp directory so any incidental
// Hive reads inside SettingsScreen (account / data sections) don't crash.
//
// NOTE: Requires generated Hive adapters. Run:
//   dart run build_runner build --delete-conflicting-outputs

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:examboost_togo/providers/user_provider.dart';
import 'package:examboost_togo/screens/community/community_screen.dart';
import 'package:examboost_togo/screens/home/home_screen.dart';
import 'package:examboost_togo/screens/settings/settings_screen.dart';
import 'package:examboost_togo/services/question_service.dart';
import 'package:examboost_togo/services/srs_service.dart';
import 'package:examboost_togo/utils/app_router.dart';

import '../helpers/mock_services.dart';
import '../helpers/test_data.dart';
import '../helpers/test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Integration: navigation between main screens (basic E2E)', () {
    late FakeUserProvider userProvider;
    late MockQuestionService questionService;
    late MockSrsService srsService;
    late GoRouter router;

    setUpAll(() {
      // SharedPreferences mock so SettingsScreen._loadSettings() returns
      // the default values instead of touching the plugin channel.
      SharedPreferences.setMockInitialValues({
        'current_user_id': 'test-user',
      });
      // Init Hive in a temp dir + register adapters so any incidental box
      // reads inside SettingsScreen (compte / donnees sections) succeed.
      initHiveForTests();
    });

    setUp(() {
      userProvider = FakeUserProvider(user: createTestUser());
      questionService =
          MockQuestionService(initialQuestions: sampleQuestions);
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
      // Skip the 2.5s splash animation + redirect delay.
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
    }

    // ─── Full E2E scenario: 6 steps ──────────────────────────────
    // Steps:
    //   1. Launch app with pre-seeded user -> lands on /home after splash.
    //   2. Verify HomeScreen visible + "Communaute" action card present.
    //   3. Tap "Communaute" -> CommunityScreen visible.
    //   4. Tap AppBar back arrow (Icons.arrow_back) -> HomeScreen visible.
    //   5. Tap "Parametres" -> SettingsScreen visible.
    //   6. Tap AppBar back arrow (Icons.arrow_back) -> HomeScreen visible.
    testWidgets(
        'E2E : home -> communaute -> home -> parametres -> home (6 etapes)',
        (tester) async {
      // Step 1 — Launch app with pre-seeded user -> lands on /home.
      await pumpApp(tester);

      // Step 2 — Verify HomeScreen visible + "Communaute" card present.
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Communauté'), findsOneWidget);

      // Step 3 — Tap "Communaute" -> CommunityScreen visible.
      await tester.tap(find.text('Communauté'));
      await tester.pumpAndSettle();
      expect(find.byType(CommunityScreen), findsOneWidget);

      // Step 4 — Tap AppBar back arrow -> HomeScreen visible.
      // CommunityScreen uses the auto BackButton (Icons.arrow_back on
      // Android); SettingsScreen has an explicit IconButton with the same
      // icon. find.byIcon matches both.
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);

      // Step 5 — Tap "Parametres" -> SettingsScreen visible.
      await tester.tap(find.text('Paramètres'));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);

      // Step 6 — Tap AppBar back arrow -> HomeScreen visible.
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });
}
