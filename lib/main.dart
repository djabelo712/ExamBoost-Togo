// lib/main.dart
// Point d'entrée principal d'ExamBoost Togo
//
// Architecture :
//   - Hive (offline-first) : boxes "users", "review_cards"
//   - Providers : SrsService, QuestionService, UserProvider (global)
//   - Router GoRouter : redirect vers /onboarding si pas d'user connecté
//
// Pour générer les adaptateurs Hive :
//   dart run build_runner build --delete-conflicting-outputs

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'models/question.dart';
import 'models/review_card.dart';
import 'models/user.dart';
import 'providers/user_provider.dart';
import 'services/srs_service.dart';
import 'services/question_service.dart';
import 'theme/app_theme.dart';
import 'utils/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ─── Orientation : portrait uniquement (mobile) ────────────────
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ─── Initialisation Hive (base de données locale) ─────────────
  await Hive.initFlutter();
  Hive.registerAdapter(QuestionAdapter());
  Hive.registerAdapter(ReviewCardAdapter());
  Hive.registerAdapter(AppUserAdapter());
  Hive.registerAdapter(QuestionTypeAdapter());

  // Ouvrir la box "users" tôt (utilisée par UserProvider)
  await Hive.openBox<AppUser>('users');

  // ─── Initialisation des services ──────────────────────────────
  final srsService = SrsService();
  await srsService.init();

  final questionService = QuestionService();
  await questionService.loadQuestions();

  // ─── UserProvider (auth + persistance) ────────────────────────
  final userProvider = UserProvider();
  await userProvider.initialize();

  runApp(
    MultiProvider(
      providers: [
        Provider<SrsService>.value(value: srsService),
        Provider<QuestionService>.value(value: questionService),
        ChangeNotifierProvider<UserProvider>.value(value: userProvider),
      ],
      child: const ExamBoostApp(),
    ),
  );
}

class ExamBoostApp extends StatelessWidget {
  const ExamBoostApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ExamBoost Togo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: AppRouter.router,
    );
  }
}
