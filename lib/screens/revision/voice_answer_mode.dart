// lib/screens/revision/voice_answer_mode.dart
// Mode "Révision vocale" : variante de RevisionScreen où l'élève DICTE sa
// réponse au lieu de taper "Voir réponse" puis de s'auto-évaluer via les
// boutons SRS.
//
// Flow :
//   1. Chargement des questions (QuestionService.getByMatiere)
//   2. Affichage de la question courante
//   3. L'élève tape le bouton micro (VoiceAnswerButton) et dicte sa réponse
//   4. speech_to_text transcrit → VoiceComparisonService.compare avec la
//      bonne réponse (question.reponse)
//   5. Affichage du verdict (VoiceResultDisplay) :
//        - correct   → qualité SRS 5 (Facile)
//        - partial   → qualité SRS 3 (Difficile)
//        - incorrect → qualité SRS 1 (Oublié)
//   6. Bouton "Question suivante" : enregistre la qualité via SrsService
//      (SM-2) + met à jour le BKT (AppUser), puis avance.
//   7. Bouton "Voir la réponse" (optionnel) : révèle la réponse attendue
//      avant que l'élève ne dicte, pour les cas où il est bloqué.
//
// Le mode vocal ne remplace PAS le mode révision classique : c'est une
// variante accessible depuis le menu révision (l'agent principal fera le
// wiring du router). La même logique SM-2 + BKT est utilisée pour la
// persistance de la progression.
//
// Dépendances (déjà fournies par l'app via Provider) :
//   - QuestionService (chargement questions)
//   - SrsService (enregistrement qualité SM-2)
//   - VoiceInputService (speech-to-text) — fourni par le routeur de l'app
//   - VoiceComparisonService — instancié localement (stateless)
//
// Contraintes :
//   - Ne pas toucher au router/main.dart/pubspec (task BL-voice-answers)
//   - Le wiring (route vers VoiceAnswerMode) sera fait par l'agent principal

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

import '../../models/question.dart';
import '../../models/user.dart';
import '../../models/voice_settings.dart';
import '../../services/question_service.dart';
import '../../services/srs_service.dart';
import '../../services/voice_comparison_service.dart';
import '../../services/voice_input_service.dart';
import '../../theme/adaptive_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/cards/question_card.dart';
import '../../widgets/voice_answer_button.dart';
import '../../widgets/voice_result_display.dart';

/// Écran de révision en mode vocal.
///
/// L'élève dicte sa réponse, le service compare avec la bonne réponse et
/// en déduit une qualité SRS (5/3/1). La progression SM-2 + BKT est
/// enregistrée comme dans RevisionScreen classique.
class VoiceAnswerMode extends StatefulWidget {
  final String matiere;
  final String userId;

  const VoiceAnswerMode({
    super.key,
    required this.matiere,
    required this.userId,
  });

  @override
  State<VoiceAnswerMode> createState() => _VoiceAnswerModeState();
}

class _VoiceAnswerModeState extends State<VoiceAnswerMode>
    with TickerProviderStateMixin {
  // ─── État de chargement ────────────────────────────────────────
  bool _isLoading = true;
  String? _loadingError;

  // ─── État de la session ────────────────────────────────────────
  List<Question> _questions = [];
  int _currentIndex = 0;
  bool _reponseVisible = false;
  bool _sessionTerminee = false;
  int _sessionsCorrectes = 0;
  int _sessionsTotales = 0;

  // ─── État de la saisie vocale courante ─────────────────────────
  /// Dernière transcription reçue du VoiceInputService.
  String _derniereTranscription = '';

  /// Dernier résultat de comparaison (null tant que l'élève n'a pas parlé).
  VoiceComparisonResult? _dernierResultat;

  /// True si on attend la transcription (l'élève vient de parler).
  bool _enAttenteTranscription = false;

  // ─── Service de comparaison (stateless, instancié localement) ──
  late final VoiceComparisonService _comparisonService;

  // ─── Animation flip de la carte (comme RevisionScreen) ─────────
  late final AnimationController _flipController;
  late final Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();
    _comparisonService = VoiceComparisonService();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
    // Chargement différé pour que Provider soit disponible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chargerPreferencesEtQuestions();
    });
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  // ─── Chargement (préférences vocales + questions) ─────────────

  Future<void> _chargerPreferencesEtQuestions() async {
    try {
      // 1. Charge les préférences vocales (langue, seuils) et les applique
      //    au VoiceInputService et au VoiceComparisonService
      final voiceService =
          Provider.of<VoiceInputService>(context, listen: false);
      final settings = await VoiceSettings.load();
      await voiceService.updateSettings(settings);
      _comparisonService.updateSettings(settings);

      // 2. Charge les questions de la matière
      final questionService =
          Provider.of<QuestionService>(context, listen: false);
      await questionService.loadQuestions();
      final questions = questionService.getByMatiere(widget.matiere);
      questions.shuffle();

      if (!mounted) return;
      setState(() {
        _questions = questions;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingError = e.toString();
        _isLoading = false;
      });
    }
  }

  // ─── Réception de la transcription ────────────────────────────

  /// Callback appelé par VoiceAnswerButton quand la transcription finale
  /// est disponible. Lance la comparaison et stocke le résultat.
  void _onTranscriptionRecue(String transcription) {
    if (!mounted) return;
    final question = _questions[_currentIndex];
    final result = _comparisonService.compare(transcription, question.reponse);

    setState(() {
      _derniereTranscription = transcription;
      _dernierResultat = result;
      _enAttenteTranscription = false;
    });
  }

  // ─── Enregistrement de la réponse (SM-2 + BKT) ────────────────

  /// Mappe un verdict de comparaison en qualité SRS (0-5).
  ///   - correct   → 5 (Facile, réponse immédiate)
  ///   - partial   → 3 (Difficile, réponse trouvée avec aide)
  ///   - incorrect → 1 (Oublié, mauvaise réponse)
  int _qualiteDepuisVerdict(VoiceVerdict verdict) {
    switch (verdict) {
      case VoiceVerdict.correct:
        return 5;
      case VoiceVerdict.partial:
        return 3;
      case VoiceVerdict.incorrect:
        return 1;
    }
  }

  /// Enregistre la qualité SRS dérivée du verdict vocal et avance à la
  /// question suivante. Appelé quand l'élève tape "Question suivante".
  Future<void> _enregistrerEtAvancer() async {
    if (_dernierResultat == null) {
      // Pas de réponse vocale : on avance sans enregistrer (l'élève a tapé
      // "Passer" ou "Voir réponse" sans parler)
      _prochaineQuestion();
      return;
    }

    final question = _questions[_currentIndex];
    final quality = _qualiteDepuisVerdict(_dernierResultat!.verdict);
    final isCorrect = quality >= 3;
    if (isCorrect) _sessionsCorrectes++;
    _sessionsTotales++;

    final srsService = Provider.of<SrsService>(context, listen: false);

    // Avance immédiatement (UX réactive, comme RevisionScreen)
    _prochaineQuestion();

    // Enregistrement asynchrone en arrière-plan
    _enregistrerReponseEnArrierePlan(
      question: question,
      quality: quality,
      isCorrect: isCorrect,
      srsService: srsService,
    );
  }

  void _prochaineQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _reponseVisible = false;
        _derniereTranscription = '';
        _dernierResultat = null;
        _enAttenteTranscription = false;
      });
      _flipController.reset();
    } else {
      setState(() => _sessionTerminee = true);
    }
  }

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
      // 2. BKT : met à jour P(L) de la compétence
      await _updateBkt(
        competenceId: question.competenceId,
        correct: isCorrect,
      );
    } catch (e) {
      debugPrint('Erreur enregistrement SRS/BKT (mode vocal) : $e');
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
      debugPrint('Erreur mise à jour BKT (mode vocal) : $e');
    }
  }

  // ─── Actions UI ───────────────────────────────────────────────

  void _showReponse() {
    setState(() => _reponseVisible = true);
    _flipController.forward();
  }

  void _reessayer() {
    setState(() {
      _derniereTranscription = '';
      _dernierResultat = null;
      _enAttenteTranscription = false;
    });
  }

  void _showQuitDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
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

  // ─── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildLoadingScreen();
    if (_loadingError != null) return _buildErrorScreen();
    if (_questions.isEmpty) return _buildEmptyState();
    if (_sessionTerminee) return _buildSessionSummary();

    final question = _questions[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('Révision vocale : ${widget.matiere}'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _showQuitDialog,
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
      ),
      body: Column(
        children: [
          // Barre de progression
          _buildProgressBar(),
          const SizedBox(height: 8),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Méta-info (matière + difficulté)
                  _buildQuestionMeta(question),
                  const SizedBox(height: 12),

                  // Carte question/réponse (avec animation flip)
                  SizedBox(
                    height: 280,
                    child: QuestionCard(
                      question: question,
                      reponseVisible: _reponseVisible,
                      flipAnimation: _flipAnimation,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ─── Zone de saisie vocale OU résultat ────────
                  if (_dernierResultat == null) ...[
                    // Pas encore de réponse vocale : afficher le bouton micro
                    _buildVoiceInputZone(),
                  ] else ...[
                    // Résultat disponible : afficher le verdict + actions
                    VoiceResultDisplay(
                      result: _dernierResultat!,
                      spokenText: _derniereTranscription,
                      expectedText: question.reponse,
                      onRetry: _reessayer,
                      onNext: _enregistrerEtAvancer,
                      showDetails: true,
                    ),
                    const SizedBox(height: 16),
                    // Indication qualité SRS dérivée
                    _buildQualiteInfo(),
                  ],

                  const SizedBox(height: 16),

                  // Bouton "Voir la réponse" (optionnel, disponible avant
                  // et après dictée, pour révéler la correction)
                  if (!_reponseVisible)
                    _buildVoirReponseButton()
                  else if (_dernierResultat != null)
                    _buildSuivanteButton(),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Sous-widgets ─────────────────────────────────────────────

  Widget _buildProgressBar() {
    final progress = (_currentIndex + (_reponseVisible ? 1 : 0)) /
        (_questions.isEmpty ? 1 : _questions.length);
    return LinearProgressIndicator(
      value: progress,
      minHeight: 4,
      backgroundColor: AdaptiveColors.primarySurface(context),
      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
    );
  }

  Widget _buildQuestionMeta(Question question) {
    return Row(
      children: [
        _buildChip(
            label: question.matiere, color: AppColors.primary),
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
        const Spacer(),
        // Badge "Mode vocal"
        _buildChip(label: 'Vocal', color: AppColors.accent),
      ],
    );
  }

  Widget _buildChip({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(Theme.of(context).brightness == Brightness.dark
            ? 0.20
            : 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTextStyles.label.copyWith(color: color),
      ),
    );
  }

  Widget _buildVoiceInputZone() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AdaptiveColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AdaptiveColors.divider(context),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Dicte ta réponse à voix haute',
            style: AppTextStyles.h3.copyWith(
              color: AdaptiveColors.textPrimary(context),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Le micro s\'arrêtera automatiquement après 2 s de silence.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AdaptiveColors.textSecondary(context),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // Le bouton micro (gère lui-même l'animation et l'écoute)
          VoiceAnswerButton(
            onTranscription: _onTranscriptionRecue,
            size: 80,
          ),
        ],
      ),
    );
  }

  Widget _buildQualiteInfo() {
    final verdict = _dernierResultat!.verdict;
    final quality = _qualiteDepuisVerdict(verdict);
    final String label;
    final Color color;
    switch (verdict) {
      case VoiceVerdict.correct:
        label = 'Qualité SRS enregistrée : 5/5 (Facile)';
        color = AppColors.success;
        break;
      case VoiceVerdict.partial:
        label = 'Qualité SRS enregistrée : 3/5 (Difficile)';
        color = AppColors.accent;
        break;
      case VoiceVerdict.incorrect:
        label = 'Qualité SRS enregistrée : 1/5 (Oublié)';
        color = AppColors.error;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.assignment_turned_in, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoirReponseButton() {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: _showReponse,
        icon: const Icon(Icons.visibility_outlined, size: 20),
        label: Text(l10n.revisionSeeAnswer),
        style: TextButton.styleFrom(
          foregroundColor: AdaptiveColors.textSecondary(context),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildSuivanteButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _enregistrerEtAvancer,
        icon: const Icon(Icons.arrow_forward, size: 20),
        label: const Text('Question suivante'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  // ─── États spéciaux ───────────────────────────────────────────

  Widget _buildLoadingScreen() {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text('Révision vocale : ${widget.matiere}')),
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
      appBar: AppBar(title: Text('Révision vocale : ${widget.matiere}')),
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
                  _chargerPreferencesEtQuestions();
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
      appBar: AppBar(title: Text('Révision vocale : ${widget.matiere}')),
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

  Widget _buildSessionSummary() {
    final l10n = AppLocalizations.of(context)!;
    final taux = _sessionsTotales > 0
        ? (_sessionsCorrectes / _sessionsTotales * 100).round()
        : 0;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              const Icon(Icons.mic, size: 80, color: AppColors.accent),
              const SizedBox(height: 24),
              Text(
                'Session vocale terminée',
                style: AppTextStyles.h1
                    .copyWith(color: AdaptiveColors.textPrimary(context)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.revisionCorrectAnswers(
                    _sessionsCorrectes, _sessionsTotales),
                style: AppTextStyles.body.copyWith(
                  color: AdaptiveColors.textSecondary(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Center(
                child: Container(
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
                      style: AppTextStyles.h1
                          .copyWith(color: _scoreColor(taux)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
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
                    _derniereTranscription = '';
                    _dernierResultat = null;
                    _questions.shuffle();
                  });
                  _flipController.reset();
                },
                child: Text(l10n.revisionRestartSession),
              ),
            ],
          ),
        ),
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
}
