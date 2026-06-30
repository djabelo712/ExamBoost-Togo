// lib/screens/revision/revision_screen.dart
// Écran principal de révision adaptative (flashcard SRS)

import 'package:flutter/material.dart';
import '../../models/question.dart';
import '../../models/review_card.dart';
import '../../theme/app_theme.dart';
import '../../widgets/cards/question_card.dart';
import '../../widgets/buttons/srs_buttons.dart';

class RevisionScreen extends StatefulWidget {
  final String matiere;
  final String userId;

  const RevisionScreen({
    super.key,
    required this.matiere,
    required this.userId,
  });

  @override
  State<RevisionScreen> createState() => _RevisionScreenState();
}

class _RevisionScreenState extends State<RevisionScreen>
    with TickerProviderStateMixin {
  // ─── État ─────────────────────────────────────────────────────
  bool _reponseVisible = false;
  int _currentIndex = 0;
  int _sessionsCorrectes = 0;
  int _sessionsTotales = 0;
  bool _sessionTerminee = false;

  // Animation flip de la carte
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  // Données de la session (à remplacer par le service en production)
  late List<Question> _questions;

  @override
  void initState() {
    super.initState();
    _questions = _getQuestionsForDemo();

    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  // ─── Actions ──────────────────────────────────────────────────

  void _showReponse() {
    setState(() => _reponseVisible = true);
    _flipController.forward();
  }

  void _recordAnswer(int quality) {
    // TODO: appeler SrsService.recordAnswer() en production
    final isCorrect = quality >= 3;
    if (isCorrect) _sessionsCorrectes++;
    _sessionsTotales++;

    // Passer à la question suivante
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _reponseVisible = false;
      });
      _flipController.reset();
    } else {
      setState(() => _sessionTerminee = true);
    }
  }

  // ─── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_sessionTerminee) {
      return _buildSessionSummary();
    }

    final question = _questions[_currentIndex];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Barre de progression
          _buildProgressBar(),
          const SizedBox(height: 8),

          // Carte question/réponse
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                children: [
                  // Chip matière + difficulté
                  _buildQuestionMeta(question),
                  const SizedBox(height: 12),

                  // La carte principale
                  Expanded(
                    child: QuestionCard(
                      question: question,
                      reponseVisible: _reponseVisible,
                      flipAnimation: _flipAnimation,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Boutons d'action
                  if (!_reponseVisible)
                    _buildVoirReponseButton()
                  else
                    SrsButtons(onQualitySelected: _recordAnswer),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text(widget.matiere),
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => _showQuitDialog(),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Center(
            child: Text(
              '${_currentIndex + 1} / ${_questions.length}',
              style: AppTextStyles.label.copyWith(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    final progress = (_currentIndex + (_reponseVisible ? 1 : 0)) / _questions.length;
    return LinearProgressIndicator(
      value: progress,
      minHeight: 4,
      backgroundColor: AppColors.primarySurface,
      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
    );
  }

  Widget _buildQuestionMeta(Question question) {
    return Row(
      children: [
        _buildChip(
          label: question.matiere,
          color: AppColors.primary,
        ),
        const SizedBox(width: 8),
        _buildChip(
          label: _difficulteLabel(question.difficulte),
          color: _difficulteColor(question.difficulte),
        ),
        if (question.annee != null) ...[
          const SizedBox(width: 8),
          _buildChip(
            label: question.annee.toString(),
            color: AppColors.textSecondary,
          ),
        ],
      ],
    );
  }

  Widget _buildChip({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTextStyles.label.copyWith(color: color),
      ),
    );
  }

  Widget _buildVoirReponseButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _showReponse,
        icon: const Icon(Icons.visibility_outlined, size: 20),
        label: const Text('Voir la réponse'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildSessionSummary() {
    final taux = _sessionsTotales > 0
        ? (_sessionsCorrectes / _sessionsTotales * 100).round()
        : 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.emoji_events, size: 80, color: AppColors.accent),
              const SizedBox(height: 24),
              Text('Session terminée !', style: AppTextStyles.h1),
              const SizedBox(height: 8),
              Text(
                'Tu as répondu correctement à $_sessionsCorrectes questions sur $_sessionsTotales',
                style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // Score circulaire
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _scoreColor(taux).withOpacity(0.15),
                  border: Border.all(color: _scoreColor(taux), width: 4),
                ),
                child: Center(
                  child: Text(
                    '$taux%',
                    style: AppTextStyles.h1.copyWith(color: _scoreColor(taux)),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Retour au tableau de bord'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  setState(() {
                    _currentIndex = 0;
                    _reponseVisible = false;
                    _sessionTerminee = false;
                    _sessionsCorrectes = 0;
                    _sessionsTotales = 0;
                    _questions.shuffle();
                  });
                  _flipController.reset();
                },
                child: const Text('Recommencer une session'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuitDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quitter la session ?'),
        content: const Text('Ta progression dans cette session ne sera pas sauvegardée.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Continuer')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────
  Color _scoreColor(int taux) {
    if (taux >= 70) return AppColors.success;
    if (taux >= 40) return AppColors.warning;
    return AppColors.error;
  }

  String _difficulteLabel(DifficulteNiveau d) {
    switch (d) {
      case DifficulteNiveau.facile:   return 'Facile';
      case DifficulteNiveau.moyen:    return 'Moyen';
      case DifficulteNiveau.difficile: return 'Difficile';
    }
  }

  Color _difficulteColor(DifficulteNiveau d) {
    switch (d) {
      case DifficulteNiveau.facile:   return AppColors.facile;
      case DifficulteNiveau.moyen:    return AppColors.info;
      case DifficulteNiveau.difficile: return AppColors.difficile;
    }
  }

  List<Question> _getQuestionsForDemo() {
    // Données codées en dur pour la démo — remplacées par QuestionService en prod
    return [
      Question(
        id: 'demo-001', enonce: 'Résoudre : 3x + 7 = 22',
        reponse: 'x = 5',
        explication: 'On isole x : 3x = 22 - 7 = 15, donc x = 15 ÷ 3 = 5.',
        matiere: 'Mathématiques', chapitre: 'Équations', competenceId: 'eq1d',
        examen: 'BEPC', type: QuestionType.calcul, annee: 2022, irtB: -0.5,
      ),
      Question(
        id: 'demo-002', enonce: 'Quelle est l\'aire d\'un triangle de base 8 cm et hauteur 5 cm ?',
        reponse: '20 cm²',
        explication: 'Aire = (base × hauteur) ÷ 2 = (8 × 5) ÷ 2 = 20 cm².',
        matiere: 'Mathématiques', chapitre: 'Géométrie', competenceId: 'geo01',
        examen: 'BEPC', type: QuestionType.calcul, annee: 2021, irtB: -0.3,
      ),
      Question(
        id: 'demo-003', enonce: 'Conjuguez "finir" au conditionnel présent (1ère personne singulier).',
        reponse: 'Je finirais',
        explication: 'Le conditionnel présent de "finir" : je finirais, tu finirais, il finirait...',
        matiere: 'Français', chapitre: 'Conjugaison', competenceId: 'conj01',
        examen: 'BEPC', type: QuestionType.ouvert, annee: 2023, irtB: -0.4,
      ),
    ];
  }
}
