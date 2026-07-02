// test/widget/screens/admin_login_screen_test.dart
// Tests for the AdminLoginScreen — espace directeurs / chefs d'établissement.
//
// The screen is a simple login form (email + password) with a "Demander
// une démo" secondary action. Successful login calls context.go(...) which
// requires a GoRouter above — we avoid testing that path and focus on:
//   - Header rendering (ExamBoost Togo + Espace Directeurs)
//   - Email + password fields visible
//   - Validation errors when tapping "Se connecter" with empty fields
//   - "Demander une démo" opens the bottom sheet

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:examboost_togo/screens/admin/admin_login_screen.dart';

void main() {
  group('AdminLoginScreen widget', () {
    Future<void> pumpLogin(WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: AdminLoginScreen()),
      );
      await tester.pump();
    }

    testWidgets('Header : "ExamBoost Togo" + "Espace Directeurs" visibles',
        (tester) async {
      await pumpLogin(tester);
      expect(find.text('ExamBoost Togo'), findsOneWidget);
      expect(find.text('Espace Directeurs'), findsOneWidget);
    });

    testWidgets('Champs email + mot de passe + bouton "Se connecter" visibles',
        (tester) async {
      await pumpLogin(tester);
      expect(find.text('Email professionnel'), findsOneWidget);
      expect(find.text('Mot de passe'), findsOneWidget);
      expect(find.text('Se connecter'), findsOneWidget);
    });

    testWidgets('Tap "Se connecter" avec champs vides : erreurs de validation',
        (tester) async {
      await pumpLogin(tester);

      // Tap the submit button.
      await tester.tap(find.text('Se connecter'));
      await tester.pump();

      // Form validators should fire and display error messages.
      expect(find.text('Veuillez saisir votre email'), findsOneWidget);
      expect(find.text('Mot de passe requis'), findsOneWidget);
    });

    testWidgets('Tap "Demander une démo" : ouvre le bottom sheet',
        (tester) async {
      await pumpLogin(tester);

      await tester.tap(find.text('Demander une démo'));
      await tester.pumpAndSettle();

      // Bottom sheet shows the title + 3 form fields + submit button.
      expect(find.text('Demander une démo'), findsWidgets);
      expect(find.text("Nom de l'établissement"), findsOneWidget);
      expect(find.text('Ville'), findsOneWidget);
      expect(find.text('Email ou téléphone'), findsOneWidget);
      expect(find.text('Envoyer la demande'), findsOneWidget);
    });

    testWidgets('Email invalide : message "Format d\'email invalide"',
        (tester) async {
      await pumpLogin(tester);

      // Enter an invalid email and a non-empty password.
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'not-an-email',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'somepassword',
      );
      await tester.pump();

      // Tap the submit button.
      await tester.tap(find.text('Se connecter'));
      await tester.pump();

      // Email validator should fire "Format d'email invalide".
      expect(find.text("Format d'email invalide"), findsOneWidget);
    });
  });
}
