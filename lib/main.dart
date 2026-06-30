// lib/main.dart
// Point d'entrée principal d'ExamBoost Togo

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'models/question.dart';
import 'models/review_card.dart';
import 'models/user.dart';
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

  // ─── Initialisation des services ──────────────────────────────
  final srsService = SrsService();
  await srsService.init();

  final questionService = QuestionService();
  await questionService.loadQuestions();

  runApp(
    MultiProvider(
      providers: [
        Provider<SrsService>.value(value: srsService),
        Provider<QuestionService>.value(value: questionService),
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
