// test/widget/screens/home_screen_test.dart
// Tests for the HomeScreen — verifies rendering of the 5 action cards and
// the user greeting.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:examboost_togo/models/user.dart';
import 'package:examboost_togo/providers/user_provider.dart';
import 'package:examboost_togo/screens/home/home_screen.dart';

import '../../helpers/mock_services.dart';
import '../../helpers/test_helpers.dart';

void main() {
  group('HomeScreen widget', () {
    testWidgets('Affiche le titre "ExamBoost Togo"', (tester) async {
      final userProvider = FakeUserProvider();
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<UserProvider>.value(
            value: userProvider,
            child: const HomeScreen(),
          ),
        ),
      );
      expect(find.text('ExamBoost Togo'), findsOneWidget);
    });

    testWidgets('Affiche "Que veux-tu faire ?"', (tester) async {
      final userProvider = FakeUserProvider();
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<UserProvider>.value(
            value: userProvider,
            child: const HomeScreen(),
          ),
        ),
      );
      expect(find.text('Que veux-tu faire ?'), findsOneWidget);
    });

    testWidgets('Affiche les 5 cartes d\'action', (tester) async {
      final userProvider = FakeUserProvider();
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<UserProvider>.value(
            value: userProvider,
            child: const HomeScreen(),
          ),
        ),
      );

      expect(find.text('Révision Adaptative'), findsOneWidget);
      expect(find.text('Simulation d\'Examen'), findsOneWidget);
      expect(find.text('Mon Tableau de Bord'), findsOneWidget);
      expect(find.text('Communauté'), findsOneWidget);
      expect(find.text('Paramètres'), findsOneWidget);
    });

    testWidgets('Affiche le sous-titre de chaque carte', (tester) async {
      final userProvider = FakeUserProvider();
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<UserProvider>.value(
            value: userProvider,
            child: const HomeScreen(),
          ),
        ),
      );

      expect(find.text('Questions BEPC et BAC par matière'), findsOneWidget);
      expect(find.text('Entraîne-toi dans les conditions réelles'), findsOneWidget);
      expect(find.text('Voir ma progression et mes statistiques'), findsOneWidget);
      expect(find.text('Classements, défis hebdo et entraide entre élèves'), findsOneWidget);
      expect(find.text('Langue, thème, compte, données et notifications'), findsOneWidget);
    });

    testWidgets('Affiche "Élève" comme prénom par défaut (pas d\'user)',
        (tester) async {
      final userProvider = FakeUserProvider(); // No user.
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<UserProvider>.value(
            value: userProvider,
            child: const HomeScreen(),
          ),
        ),
      );
      // The greeting should mention "Élève" since user is null.
      expect(find.textContaining('Élève'), findsWidgets);
    });

    testWidgets('Affiche le prénom de l\'utilisateur connecté', (tester) async {
      final user = createTestUser(prenom: 'Kofi', nom: 'Komla');
      final userProvider = FakeUserProvider(user: user);
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<UserProvider>.value(
            value: userProvider,
            child: const HomeScreen(),
          ),
        ),
      );
      // "Bonjour, Kofi"
      expect(find.textContaining('Kofi'), findsWidgets);
    });

    testWidgets('Affiche l\'icône profil en header', (tester) async {
      final userProvider = FakeUserProvider();
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<UserProvider>.value(
            value: userProvider,
            child: const HomeScreen(),
          ),
        ),
      );
      expect(find.byIcon(Icons.person_outline), findsOneWidget);
    });

    testWidgets('Affiche l\'icône school en header', (tester) async {
      final userProvider = FakeUserProvider();
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<UserProvider>.value(
            value: userProvider,
            child: const HomeScreen(),
          ),
        ),
      );
      expect(find.byIcon(Icons.school), findsOneWidget);
    });

    testWidgets('Tap sur bouton profil ouvre le dialog', (tester) async {
      final user = createTestUser(prenom: 'Kofi', nom: 'Komla');
      final userProvider = FakeUserProvider(user: user);
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<UserProvider>.value(
            value: userProvider,
            child: const HomeScreen(),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pumpAndSettle();

      // Dialog should be open with "Mon profil" title.
      expect(find.text('Mon profil'), findsOneWidget);
      expect(find.text('Kofi Komla'), findsOneWidget);
    });
  });
}
