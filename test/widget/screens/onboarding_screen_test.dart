// test/widget/screens/onboarding_screen_test.dart
// Tests for the OnboardingScreen — multi-step form (5 steps).
//
// We test:
//   - Step 0 (welcome) renders the title and a "Commencer" button.
//   - Step 1 (identity) requires prenom + nom to enable "Suivant".
//   - Step 2 (niveau) requires selecting a level.
//   - Step 4 (matieres) requires 1-3 matieres selected.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:examboost_togo/providers/user_provider.dart';
import 'package:examboost_togo/screens/auth/onboarding_screen.dart';

import '../../helpers/mock_services.dart';

void main() {
  group('OnboardingScreen widget', () {
    Future<void> pumpOnboarding(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<UserProvider>.value(
            value: FakeUserProvider(),
            child: const OnboardingScreen(),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('Étape welcome : affiche le titre "ExamBoost Togo"',
        (tester) async {
      await pumpOnboarding(tester);
      expect(find.text('ExamBoost Togo'), findsWidgets);
    });

    testWidgets('Étape welcome : affiche le bouton "Commencer"',
        (tester) async {
      await pumpOnboarding(tester);
      expect(find.text('Commencer'), findsOneWidget);
    });

    testWidgets('Étape welcome : pas de bouton "Retour"', (tester) async {
      await pumpOnboarding(tester);
      expect(find.text('Retour'), findsNothing);
    });

    testWidgets('Navigation welcome -> identity avec "Commencer"',
        (tester) async {
      await pumpOnboarding(tester);
      await tester.tap(find.text('Commencer'));
      await tester.pumpAndSettle();

      // On identity step we should see the prenom field.
      expect(find.text('Identité'), findsOneWidget);
      expect(find.text('Prénom *'), findsOneWidget);
      expect(find.text('Nom *'), findsOneWidget);
    });

    testWidgets('Étape identity : "Suivant" désactivé sans prénom/nom',
        (tester) async {
      await pumpOnboarding(tester);
      await tester.tap(find.text('Commencer'));
      await tester.pumpAndSettle();

      // The button exists but should be disabled.
      final nextButton = tester.widget<ElevatedButton>(find.widgetWithText(
        ElevatedButton,
        'Suivant',
      ));
      expect(nextButton.enabled, isFalse);
    });

    testWidgets('Étape identity : "Suivant" activé après saisie prénom + nom',
        (tester) async {
      await pumpOnboarding(tester);
      await tester.tap(find.text('Commencer'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'Kofi');
      await tester.enterText(find.byType(TextField).at(1), 'Komla');
      await tester.pump();

      final nextButton = tester.widget<ElevatedButton>(find.widgetWithText(
        ElevatedButton,
        'Suivant',
      ));
      expect(nextButton.enabled, isTrue);
    });

    testWidgets('Navigation identity -> niveau', (tester) async {
      await pumpOnboarding(tester);
      await tester.tap(find.text('Commencer'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'Kofi');
      await tester.enterText(find.byType(TextField).at(1), 'Komla');
      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();

      expect(find.text('Ton niveau scolaire'), findsOneWidget);
      // 4 niveau cards: 3ème, 2nde, 1ère, Terminale.
      expect(find.text('3ème'), findsOneWidget);
      expect(find.text('2nde'), findsOneWidget);
      expect(find.text('1ère'), findsOneWidget);
      expect(find.text('Terminale'), findsOneWidget);
    });

    testWidgets('Sélection niveau 3ème -> matières (série skipped)',
        (tester) async {
      await pumpOnboarding(tester);
      await tester.tap(find.text('Commencer'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'Kofi');
      await tester.enterText(find.byType(TextField).at(1), 'Komla');
      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();

      // Tap 3ème card.
      await tester.tap(find.text('3ème'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();

      // Should skip série and go directly to matières.
      expect(find.text('Tes matières préférées'), findsOneWidget);
      expect(find.text('Mathématiques'), findsOneWidget);
    });

    testWidgets('Sélection niveau Terminale -> série requise', (tester) async {
      await pumpOnboarding(tester);
      await tester.tap(find.text('Commencer'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'Kofi');
      await tester.enterText(find.byType(TextField).at(1), 'Komla');
      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Terminale'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();

      // Should be on série step.
      expect(find.text('Quelle est ta série ?'), findsOneWidget);
      expect(find.text('Série A'), findsOneWidget);
      expect(find.text('Série C'), findsOneWidget);
    });

    testWidgets('Sélection 0 matière : "Créer mon profil" désactivé',
        (tester) async {
      // Navigate to matieres step.
      await pumpOnboarding(tester);
      await tester.tap(find.text('Commencer'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), 'Kofi');
      await tester.enterText(find.byType(TextField).at(1), 'Komla');
      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('3ème'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();

      // "Créer mon profil" should be disabled.
      final button = tester.widget<ElevatedButton>(find.widgetWithText(
        ElevatedButton,
        'Créer mon profil',
      ));
      expect(button.enabled, isFalse);
    });

    testWidgets('Sélection 1 matière active "Créer mon profil"',
        (tester) async {
      await pumpOnboarding(tester);
      await tester.tap(find.text('Commencer'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), 'Kofi');
      await tester.enterText(find.byType(TextField).at(1), 'Komla');
      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('3ème'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();

      // Tap "Mathématiques" FilterChip.
      await tester.tap(find.text('Mathématiques'));
      await tester.pumpAndSettle();

      final button = tester.widget<ElevatedButton>(find.widgetWithText(
        ElevatedButton,
        'Créer mon profil',
      ));
      expect(button.enabled, isTrue);
    });

    testWidgets('Bouton "Retour" revient à l\'étape précédente',
        (tester) async {
      await pumpOnboarding(tester);
      await tester.tap(find.text('Commencer'));
      await tester.pumpAndSettle();

      // Now on identity, "Retour" should be visible.
      expect(find.text('Retour'), findsOneWidget);

      await tester.tap(find.text('Retour'));
      await tester.pumpAndSettle();

      // Back to welcome.
      expect(find.text('Commencer'), findsOneWidget);
    });
  });
}
