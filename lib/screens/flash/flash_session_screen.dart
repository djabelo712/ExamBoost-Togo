// lib/screens/flash/flash_session_screen.dart
// Écran principal de la session Flash 5 min.
//
// Affiche :
//   - Le timer 5:00 en haut (rouge si < 1 min)
//   - 5 dots de progression (vert = correct, rouge = incorrect, orange = courant)
//   - La carte question courante (simplifiée, sans flip 350 ms)
//   - Bouton "Passer" pour sauter une question
//
// Logique de temps :
//   - Timer global 5 min (300 s) qui décrémente chaque seconde.
//   - Temps par question : si 60 s sans réponse, on passe à la suivante
//     (auto-validation forcée). Le temps par question est remis à 0
//     à chaque changement de question.
//   - Si le timer global atteint 0, on termine la session immédiatement
//     (les questions non répondues comptent comme incorrectes).
//
// Mises à jour :
//   - SrsService.recordAnswer (qualité 5 si correct, 1 si incorrect).
//   - AppUser.updateBkt pour la compétence concernée (BKT classique).
//   - Persistance Hive asynchrone (non bloquante).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../../models/question.dart';
import '../../models/user.dart';
import '../../services/question_service.dart';
import '../../services/srs_service.dart';
import '../../theme/adaptive_colors.dart';
import '../../theme/app_theme.dart';
import 'flash_results_screen.dart';
import 'services/flash_service.dart';
import 'widgets/flash_progress_dots.dart';
import 'widgets/flash_question_card.dart';
import 'widgets/flash_timer_widget.dart';

class FlashSessionScreen extends StatefulWidget {
  final String userId;
  final AppUser? user; // Peut être null si pas encore de profil

  // Services injectés (construits par l'écran d'intro via Provider).
  final FlashService flashService;
  final SrsService srsService;
  final QuestionService questionService;

  const FlashSessionScreen({
    super.key,
    required this.userId,
    required this.user,
    required this.flashService,
    required this.srsService,
    required this.questionService,
  });

  @override
  State<FlashSessionScreen> createState() => _FlashSessionScreenState();
}

class _FlashSessionScreenState extends State<FlashSessionScreen> {
  // ─── État de chargement ────────────────────────────────────────────
  bool _isLoading = true;
  String? _loadingError;

  // ─── État de la session ────────────────────────────────────────────
  List<Question> _questions = [];
  int _currentIndex = 0;
  List<bool?> _resultats = []; // null = pas répondu, true = correct, false = incorrect
  bool _reponseVisible = false;

  // ─── Timers ────────────────────────────────────────────────────────
  Timer? _timerGlobal; // décrémente _secondesRestantes chaque seconde
  int _secondesRestantes = FlashService.dureeSessionSecondes;
  int _secondesSurQuestionCourante = 0;
  DateTime _debutSession = DateTime.now();

  // ─── Snapshot P(L) avant session (pour mesurer la progression) ────
  Map<String, double> _pLearnAvant = {};

  // ─── Garde anti-double-terminaison ─────────────────────────────────
  // Si l'utilisateur répond à la dernière question exactement quand le
  // timer global atteint 0, _terminerSession pourrait être appelé deux
  // fois. Ce flag garantit qu'on ne navigue qu'une seule fois vers les
  // résultats.
  bool _sessionTerminee = false;

  @override
  void initState() {
    super.initState();
    // Chargement différé pour que Provider soit disponible dans le contexte.
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialiserSession());
  }

  @override
  void dispose() {
    _timerGlobal?.cancel();
    super.dispose();
  }

  // ─── Initialisation : sélection des 5 questions + lancement timer ─
  Future<void> _initialiserSession() async {
    try {
      // 1. Charge les questions (si pas déjà fait).
      await widget.questionService.loadQuestions();

      // 2. Récupère ou crée l'utilisateur (pour P(L) + theta).
      AppUser? user = widget.user;
      if (user == null) {
        try {
          final box = Hive.isBoxOpen('users')
              ? Hive.box<AppUser>('users')
              : await Hive.openBox<AppUser>('users');
          user = box.get(widget.userId);
        } catch (_) {
          // Non bloquant : on continue avec un user "vide".
        }
      }

      // Snapshot P(L) AVANT session (pour mesurer la progression à la fin).
      // On ne capture que la map bktMaitrise (légère) — l'AppUser complet
      // n'est pas nécessaire car l'écran de résultats compare pLearnAvant
      // avec userApres (relu depuis Hive après mise à jour BKT).
      if (user != null) {
        _pLearnAvant = Map<String, double>.from(user.bktMaitrise);
      }

      // 3. Sélection des 5 questions via FlashService.
      final userEffectif = user ??
          AppUser(
            id: widget.userId,
            nom: 'Invité',
            prenom: 'Élève',
            niveauScolaire: '3eme',
            dateInscription: DateTime.now(),
          );
      final questions =
          widget.flashService.selectFlashQuestions(user: userEffectif);

      if (questions.isEmpty) {
        setState(() {
          _loadingError =
              'Aucune question disponible pour le mode Flash. '
              'Réessaie plus tard.';
          _isLoading = false;
        });
        return;
      }

      // 4. Enrichit le snapshot P(L) avec les compétences qu'on va voir
      // (pour pouvoir mesurer la progression même sur de nouvelles compétences).
      for (final q in questions) {
        _pLearnAvant.putIfAbsent(
            q.competenceId, () => userEffectif.getMaitrise(q.competenceId));
      }

      setState(() {
        _questions = questions;
        _resultats = List<bool?>.filled(questions.length, null);
        _isLoading = false;
      });

      // 5. Lance le timer global (1 tick / seconde).
      _demarrerTimerGlobal();
    } catch (e) {
      setState(() {
        _loadingError = e.toString();
        _isLoading = false;
      });
    }
  }

  // ─── Timer global 5 min ────────────────────────────────────────────
  void _demarrerTimerGlobal() {
    _timerGlobal?.cancel();
    _timerGlobal = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        _timerGlobal?.cancel();
        return;
      }

      setState(() {
        _secondesRestantes--;
        _secondesSurQuestionCourante++;
      });

      // Timer global écoulé -> fin de session.
      if (_secondesRestantes <= 0) {
        _terminerSession();
        return;
      }

      // Auto-validation : 60 s sur la même question sans réponse -> on passe.
      if (_secondesSurQuestionCourante >=
          FlashService.tempsMaxParQuestionSecondes) {
        _autoValiderQuestionCourante();
      }
    });
  }

  // ─── Actions utilisateur ───────────────────────────────────────────

  void _voirReponse() {
    // On affiche la réponse ET on remet le compteur de temps par question à 0.
    // L'élève dispose ainsi de 60 s supplémentaires pour lire la réponse et
    // s'auto-évaluer. Compromis UX raisonnable pour le mode transport.
    setState(() {
      _reponseVisible = true;
      _secondesSurQuestionCourante = 0;
    });
  }

  /// L'élève a cliqué "Correct" ou "Incorrect" sur la réponse.
  void _enregistrerReponse(bool correct) {
    final question = _questions[_currentIndex];
    setState(() {
      _resultats[_currentIndex] = correct;
    });

    // Avance immédiatement (UX réactive).
    _passerALaSuivante();

    // Enregistrement asynchrone (SRS + BKT) en arrière-plan.
    _enregistrerEnArrierePlan(question: question, correct: correct);
  }

  /// L'élève clique "Passer" sans répondre.
  void _passerQuestion() {
    // Marque comme incorrect (équivalent à "je ne sais pas du tout").
    final question = _questions[_currentIndex];
    setState(() {
      _resultats[_currentIndex] = false;
    });
    _passerALaSuivante();
    _enregistrerEnArrierePlan(question: question, correct: false);
  }

  /// Auto-validation : 60 s écoulées sur la question, on force le passage.
  ///
  /// Que la réponse soit visible ou non, on marque la question comme
  /// incorrecte (l'élève n'a pas eu le temps de répondre ou d'auto-évaluer)
  /// et on passe à la suivante.
  void _autoValiderQuestionCourante() {
    final question = _questions[_currentIndex];
    setState(() {
      _resultats[_currentIndex] = false;
    });
    _passerALaSuivante();
    _enregistrerEnArrierePlan(question: question, correct: false);
  }

  void _passerALaSuivante() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _reponseVisible = false;
        _secondesSurQuestionCourante = 0;
      });
    } else {
      // Dernière question : on termine.
      _terminerSession();
    }
  }

  void _terminerSession() {
    // Garde anti-double-terminaison (timer + dernière question simultanés).
    if (_sessionTerminee) return;
    _sessionTerminee = true;

    _timerGlobal?.cancel();

    // Navigation vers l'écran de résultats.
    if (!mounted) return;
    final tempsUtilise = DateTime.now().difference(_debutSession);
    final score = _resultats.where((r) => r == true).length;

    // Récupère l'utilisateur à jour (après mise à jour BKT) pour mesurer
    // la progression réelle.
    _naviguerVersResultats(score, tempsUtilise);
  }

  Future<void> _naviguerVersResultats(int score, Duration tempsUtilise) async {
    AppUser? userApres;
    try {
      final box = Hive.isBoxOpen('users')
          ? Hive.box<AppUser>('users')
          : await Hive.openBox<AppUser>('users');
      userApres = box.get(widget.userId);
    } catch (_) {
      // Non bloquant.
    }

    if (!mounted) return;

    // Push le results screen EN REMPLAÇANT la session (pour que "Retour"
    // ne revienne pas sur une session terminée).
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => FlashResultsScreen(
          userId: widget.userId,
          score: score,
          total: _questions.length,
          tempsUtilise: tempsUtilise,
          pLearnAvant: _pLearnAvant,
          userApres: userApres,
          flashService: widget.flashService,
          questionsVues: _questions,
          resultats: _resultats,
        ),
      ),
    );
  }

  // ─── Enregistrement asynchrone (SRS SM-2 + BKT) ────────────────────
  Future<void> _enregistrerEnArrierePlan({
    required Question question,
    required bool correct,
  }) async {
    try {
      // 1. SRS SM-2 : qualité 5 si correct, 1 si incorrect.
      await widget.srsService.recordAnswer(
        userId: widget.userId,
        questionId: question.id,
        quality: correct ? 5 : 1,
      );

      // 2. BKT : met à jour P(L) de la compétence.
      await _updateBkt(
        competenceId: question.competenceId,
        correct: correct,
      );
    } catch (e) {
      // Erreur non bloquante : la session continue.
      debugPrint('Erreur enregistrement SRS/BKT (flash) : $e');
    }
  }

  Future<void> _updateBkt({
    required String competenceId,
    required bool correct,
  }) async {
    try {
      final Box<AppUser> usersBox;
      if (Hive.isBoxOpen('users')) {
        usersBox = Hive.box<AppUser>('users');
      } else {
        usersBox = await Hive.openBox<AppUser>('users');
      }

      AppUser? user = usersBox.get(widget.userId);
      if (user == null) {
        user = AppUser(
          id: widget.userId,
          nom: 'Invité',
          prenom: 'Élève',
          niveauScolaire: '3eme',
          dateInscription: DateTime.now(),
        );
        await usersBox.put(widget.userId, user);
      }

      user.updateBkt(competenceId: competenceId, correct: correct);
    } catch (e) {
      debugPrint('Erreur mise à jour BKT (flash) : $e');
    }
  }

  // ─── Dialog quitter la session ─────────────────────────────────────
  void _showQuitDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quitter la session ?'),
        content: const Text(
          'Ta progression sera perdue et les questions non répondues '
          'compteront comme incorrectes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Continuer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _timerGlobal?.cancel();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════
  // Build
  // ════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildLoading();
    if (_loadingError != null) return _buildError();
    if (_questions.isEmpty) return _buildEmpty();

    final question = _questions[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flash 5 min'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _showQuitDialog,
        ),
        // Timer visible directement dans l'AppBar (toujours à l'écran).
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: FlashTimerWidget(secondesRestantes: _secondesRestantes),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              const SizedBox(height: 8),

              // ─── Dots de progression ──────────────────────────────
              FlashProgressDots(
                indexCourant: _currentIndex,
                resultats: _resultats,
                total: _questions.length,
              ),
              const SizedBox(height: 8),

              // ─── Indice "Question X / 5" ──────────────────────────
              Text(
                'Question ${_currentIndex + 1} / ${_questions.length}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AdaptiveColors.textSecondary(context),
                ),
              ),
              const SizedBox(height: 12),

              // ─── Carte question/réponse ───────────────────────────
              Expanded(
                child: FlashQuestionCard(
                  question: question,
                  reponseVisible: _reponseVisible,
                  onVoirReponse: _voirReponse,
                  onReponse: _enregistrerReponse,
                ),
              ),
              const SizedBox(height: 12),

              // ─── Bouton "Passer" ──────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: _passerQuestion,
                  icon: const Icon(Icons.skip_next, size: 20),
                  label: const Text('Passer cette question'),
                  style: TextButton.styleFrom(
                    foregroundColor: AdaptiveColors.textSecondary(context),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ─── États spéciaux ────────────────────────────────────────────────

  Widget _buildLoading() {
    return Scaffold(
      appBar: AppBar(title: const Text('Flash 5 min')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Préparation de tes 5 questions...',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AdaptiveColors.textSecondary(context)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Scaffold(
      appBar: AppBar(title: const Text('Flash 5 min')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                'Oups, une erreur est survenue',
                style: AppTextStyles.h2
                    .copyWith(color: AdaptiveColors.textPrimary(context)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _loadingError ?? 'Erreur inconnue',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AdaptiveColors.textSecondary(context)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Retour'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Scaffold(
      appBar: AppBar(title: const Text('Flash 5 min')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox,
                size: 80,
                color: AdaptiveColors.textSecondary(context),
              ),
              const SizedBox(height: 24),
              Text(
                'Aucune question disponible',
                style: AppTextStyles.h2
                    .copyWith(color: AdaptiveColors.textPrimary(context)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Le mode Flash a besoin d\'au moins une question dans la '
                'banque. Réessaie plus tard.',
                style: AppTextStyles.body
                    .copyWith(color: AdaptiveColors.textSecondary(context)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Retour'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
