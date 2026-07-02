// lib/screens/revision/revision_screen.dart
// Écran principal de révision adaptative (flashcard SRS)
// Branché sur QuestionService (chargement), SrsService (SM-2) et BKT (AppUser)

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

import '../../models/question.dart';
import '../../models/user.dart';
import '../../services/question_service.dart';
import '../../services/srs_service.dart';
import '../../theme/adaptive_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/buttons/srs_buttons.dart';
import '../../widgets/cards/question_card.dart';

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
  // ─── État de chargement ────────────────────────────────────────
  bool _isLoading = true;
  String? _loadingError;

  // ─── État de la session ────────────────────────────────────────
  List<Question> _questions = [];
  bool _reponseVisible = false;
  int _currentIndex = 0;
  int _sessionsCorrectes = 0;
  int _sessionsTotales = 0;
  int _cartesARevoirDemain = 0; // cartes notées < 4 (intervalle = 1 jour)
  bool _sessionTerminee = false;

  // ─── Animation flip de la carte ────────────────────────────────
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
    // Chargement différé pour que Provider soit disponible dans le contexte
    WidgetsBinding.instance.addPostFrameCallback((_) => _chargerQuestions());
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  // ─── Chargement des questions depuis QuestionService ───────────
  Future<void> _chargerQuestions() async {
    try {
      final questionService =
          Provider.of<QuestionService>(context, listen: false);
      await questionService.loadQuestions();
      final questions = questionService.getByMatiere(widget.matiere);
      questions.shuffle();
      setState(() {
        _questions = questions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _loadingError = e.toString();
        _isLoading = false;
      });
    }
  }

  // ─── Actions ──────────────────────────────────────────────────

  void _showReponse() {
    setState(() => _reponseVisible = true);
    _flipController.forward();
  }

  /// Enregistre une réponse SRS (qualité 0-5) :
  /// - Met à jour la carte SM-2 via SrsService.recordAnswer
  /// - Met à jour le BKT de l'élève via AppUser.updateBkt
  /// - Avance à la question suivante ou termine la session
  void _recordAnswer(int quality) {
    final question = _questions[_currentIndex];
    final srsService = Provider.of<SrsService>(context, listen: false);

    final isCorrect = quality >= 3;
    if (isCorrect) _sessionsCorrectes++;
    _sessionsTotales++;

    // Estimation locale : cartes notées < 4 auront un intervalle de 1 jour
    // (donc dues demain). Complétée par SrsStats à l'écran de fin.
    if (quality < 4) _cartesARevoirDemain++;

    // Avancer immédiatement à la question suivante (UX réactive)
    _prochaineQuestion();

    // Enregistrement asynchrone en arrière-plan (sans bloquer l'UI).
    // Le Future n'est pas attendu volontairement : on veut que la session
    // avance immédiatement à la question suivante.
    _enregistrerReponseEnArrierePlan(
      question: question,
      quality: quality,
      isCorrect: isCorrect,
      srsService: srsService,
    );
  }

  /// Passe à la question suivante sans enregistrer de réponse
  void _passerQuestion() {
    _prochaineQuestion();
  }

  void _prochaineQuestion() {
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

  // ─── Enregistrement asynchrone (SM-2 + BKT) ────────────────────

  Future<void> _enregistrerReponseEnArrierePlan({
    required Question question,
    required int quality,
    required bool isCorrect,
    required SrsService srsService,
  }) async {
    try {
      // 1. SM-2 : enregistre la qualité et planifie la prochaine révision
      await srsService.recordAnswer(
        userId: widget.userId,
        questionId: question.id,
        quality: quality,
      );

      // 2. BKT : met à jour P(L) de la compétence concernée
      await _updateBkt(
        competenceId: question.competenceId,
        correct: isCorrect,
      );
    } catch (e) {
      // Erreur non bloquante : la session continue même si la persistance échoue
      debugPrint('Erreur enregistrement SRS/BKT : $e');
    }
  }

  /// Charge ou crée un AppUser depuis la box Hive "users",
  /// met à jour le BKT pour la compétence, puis sauvegarde.
  ///
  /// Note : cette méthode utilitaire est locale à l'écran pour cette tâche.
  /// L'agent principal remplacera par un UserProvider global ensuite.
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
        // Création d'un utilisateur de session s'il n'existe pas encore
        user = AppUser(
          id: widget.userId,
          nom: 'Invité',
          prenom: 'Élève',
          niveauScolaire: '3eme',
          dateInscription: DateTime.now(),
        );
        await usersBox.put(widget.userId, user);
      }

      // updateBkt calcule P(L|observation) + transition, puis appelle save()
      user.updateBkt(competenceId: competenceId, correct: correct);
    } catch (e) {
      debugPrint('Erreur mise à jour BKT : $e');
    }
  }

  // ─── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // ─── États spéciaux (avant la session) ──────────────────────
    if (_isLoading) return _buildLoadingScreen();
    if (_loadingError != null) return _buildErrorScreen();
    if (_questions.isEmpty) return _buildEmptyState();
    if (_sessionTerminee) return _buildSessionSummary();

    final question = _questions[_currentIndex];

    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Barre de progression
          _buildProgressBar(),
          const SizedBox(height: 8),

          // Corps : carte question/réponse + boutons
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                children: [
                  // Chips matière + difficulté + année
                  _buildQuestionMeta(question),
                  const SizedBox(height: 12),

                  // La carte principale (avec animation flip)
                  Expanded(
                    child: QuestionCard(
                      question: question,
                      reponseVisible: _reponseVisible,
                      flipAnimation: _flipAnimation,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Boutons d'action (Voir réponse OU Boutons SRS)
                  if (!_reponseVisible)
                    _buildVoirReponseButton()
                  else
                    SrsButtons(onQualitySelected: _recordAnswer),

                  const SizedBox(height: 8),

                  // Bouton "Passer la question"
                  _buildPasserButton(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── AppBar & progression ─────────────────────────────────────

  AppBar _buildAppBar() {
    final l10n = AppLocalizations.of(context)!;
    return AppBar(
      title: Text(_matiereLabel(context, widget.matiere)),
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
                color: AdaptiveColors.textSecondary(context),
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    final progress =
        (_currentIndex + (_reponseVisible ? 1 : 0)) / _questions.length;
    return LinearProgressIndicator(
      value: progress,
      minHeight: 4,
      backgroundColor: AdaptiveColors.primarySurface(context),
      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
    );
  }

  // ─── Méta-info de la question ─────────────────────────────────

  Widget _buildQuestionMeta(Question question) {
    return Row(
      children: [
        _buildChip(label: _matiereLabel(context, question.matiere), color: AppColors.primary),
        const SizedBox(width: 8),
        _buildChip(
          label: _difficulteLabel(question.difficulte),
          color: _difficulteColor(question.difficulte),
        ),
        if (question.annee != null) ...[
          const SizedBox(width: 8),
          _buildChip(
            label: question.annee.toString(),
            color: AdaptiveColors.textSecondary(context),
          ),
        ],
      ],
    );
  }

  Widget _buildChip({required String label, required Color color}) {
    return Builder(
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(context.isDark ? 0.20 : 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTextStyles.label.copyWith(color: color),
        ),
      ),
    );
  }

  // ─── Boutons d'action ─────────────────────────────────────────

  Widget _buildVoirReponseButton() {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _showReponse,
        icon: const Icon(Icons.visibility_outlined, size: 20),
        label: Text(l10n.revisionSeeAnswer),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildPasserButton() {
    final l10n = AppLocalizations.of(context)!;
    return Align(
      alignment: Alignment.center,
      child: TextButton.icon(
        onPressed: _passerQuestion,
        icon: const Icon(Icons.skip_next, size: 18),
        label: Text(l10n.revisionSkip),
        style: TextButton.styleFrom(
          foregroundColor: AdaptiveColors.textSecondary(context),
          textStyle: AppTextStyles.label.copyWith(fontSize: 13),
        ),
      ),
    );
  }

  // ─── États spéciaux : loading / error / empty ─────────────────

  Widget _buildLoadingScreen() {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(_matiereLabel(context, widget.matiere))),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              l10n.revisionLoading,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AdaptiveColors.textSecondary(context)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(_matiereLabel(context, widget.matiere))),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                l10n.commonError,
                style: AppTextStyles.h2
                    .copyWith(color: AdaptiveColors.textPrimary(context)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _loadingError ?? l10n.commonError,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AdaptiveColors.textSecondary(context)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _loadingError = null;
                  });
                  _chargerQuestions();
                },
                icon: const Icon(Icons.refresh),
                label: Text(l10n.commonRetry),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(_matiereLabel(context, widget.matiere))),
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
                l10n.revisionNoQuestions(widget.matiere),
                style: AppTextStyles.h2
                    .copyWith(color: AdaptiveColors.textPrimary(context)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.revisionNoQuestionsHint,
                style: AppTextStyles.body.copyWith(
                  color: AdaptiveColors.textSecondary(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: Text(l10n.revisionBack),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Écran de fin de session ──────────────────────────────────

  Widget _buildSessionSummary() {
    final l10n = AppLocalizations.of(context)!;
    final taux = _sessionsTotales > 0
        ? (_sessionsCorrectes / _sessionsTotales * 100).round()
        : 0;

    // Estimation des cartes à revoir demain via SrsService.getStats
    // + estimation locale (cartes notées < 4 dans cette session)
    int aRevoirDemain = _cartesARevoirDemain;
    try {
      final srsService = Provider.of<SrsService>(context, listen: false);
      final stats = srsService.getStats(widget.userId);
      // Cartes en phase d'apprentissage (intervalle = 1 jour) +
      // cartes déjà dues non révisées aujourd'hui => à revoir demain
      aRevoirDemain = _cartesARevoirDemain + stats.learning + stats.dueToday;
    } catch (_) {
      // On conserve l'estimation locale si le service échoue
    }

    final messageMotivant = _messageMotivant(taux);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              const Icon(Icons.emoji_events, size: 80, color: AppColors.accent),
              const SizedBox(height: 24),
              Text(
                l10n.revisionSessionEnded,
                style: AppTextStyles.h1
                    .copyWith(color: AdaptiveColors.textPrimary(context)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.revisionCorrectAnswers(_sessionsCorrectes, _sessionsTotales),
                style: AppTextStyles.body.copyWith(
                  color: AdaptiveColors.textSecondary(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Score circulaire
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _scoreColor(taux).withOpacity(0.15),
                    border:
                        Border.all(color: _scoreColor(taux), width: 4),
                  ),
                  child: Center(
                    child: Text(
                      '$taux%',
                      style: AppTextStyles.h1
                          .copyWith(color: _scoreColor(taux)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Cartes à revoir demain (estimation SrsService)
              _buildStatRow(
                icon: Icons.event_repeat,
                iconColor: AppColors.accent,
                label: l10n.revisionDueTomorrow,
                value: '$aRevoirDemain',
              ),
              const SizedBox(height: 12),

              // Message motivant
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AdaptiveColors.primarySurface(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.local_fire_department,
                      color: AppColors.accent,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        messageMotivant,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AdaptiveColors.primary(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Boutons de fin
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.revisionBackToDashboard),
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
                    _cartesARevoirDemain = 0;
                    _questions.shuffle();
                  });
                  _flipController.reset();
                },
                child: Text(l10n.revisionRestartSession),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AdaptiveColors.surface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdaptiveColors.divider(context)),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
              child: Text(label,
                  style: AppTextStyles.body
                      .copyWith(color: AdaptiveColors.textPrimary(context)))),
          Text(
            value,
            style: AppTextStyles.h3.copyWith(color: iconColor),
          ),
        ],
      ),
    );
  }

  // ─── Dialog quitter la session ────────────────────────────────

  void _showQuitDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.revisionQuitTitle),
        content: Text(l10n.revisionQuitMsg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.commonContinue),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(l10n.commonQuit),
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

  /// Message motivant personnalisé selon la performance.
  /// Inclut toujours la phrase clé "Tu progresses en X ! Continue !"
  String _messageMotivant(int taux) {
    final l10n = AppLocalizations.of(context)!;
    final matiere = _matiereLabel(context, widget.matiere);
    if (taux >= 80) {
      return l10n.revisionMsgExcellent(matiere);
    } else if (taux >= 50) {
      return l10n.revisionMsgBonTravail(matiere);
    } else if (taux > 0) {
      return l10n.revisionMsgNeLacheRien(matiere);
    } else {
      return l10n.revisionMsgApprendre(matiere);
    }
  }

  String _difficulteLabel(DifficulteNiveau d) {
    final l10n = AppLocalizations.of(context)!;
    switch (d) {
      case DifficulteNiveau.facile:
        return l10n.difficulteFacile;
      case DifficulteNiveau.moyen:
        return l10n.difficulteMoyen;
      case DifficulteNiveau.difficile:
        return l10n.difficulteDifficile;
    }
  }

  Color _difficulteColor(DifficulteNiveau d) {
    switch (d) {
      case DifficulteNiveau.facile:
        return AppColors.facile;
      case DifficulteNiveau.moyen:
        return AppColors.info;
      case DifficulteNiveau.difficile:
        return AppColors.difficile;
    }
  }

  /// Traduit une clé matière (ex : 'Mathématiques') en libellé localisé.
  String _matiereLabel(BuildContext context, String key) {
    final l10n = AppLocalizations.of(context)!;
    switch (key) {
      case 'Mathématiques':
        return l10n.subjectMathematiques;
      case 'Français':
        return l10n.subjectFrancais;
      case 'Sciences Physiques':
        return l10n.subjectSciencesPhysiques;
      case 'SVT':
        return l10n.subjectSVT;
      case 'Histoire-Géographie':
        return l10n.subjectHistoireGeographie;
      case 'Anglais':
        return l10n.subjectAnglais;
      case 'Philosophie':
        return l10n.subjectPhilosophie;
      case 'Économie':
        return l10n.subjectEconomie;
      default:
        return key;
    }
  }
}
