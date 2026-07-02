// lib/screens/simulation/authentic_examen_screen.dart
// Variante enrichie de l'ecran de simulation (SimulationScreen de l'Agent C,
// Session 1) ajoutant une couche d'authenticite au mode examen :
//
//   - En-tete officiel BEPC/BAC (ExamHeaderOfficial) en haut de chaque sujet
//   - Minuterie officielle avec alarmes sonores + vibration (ExamTimerOfficial)
//   - Calculatrice scientifique integree (CalculatorWidget)
//   - Feuille de brouillon tactile (ScratchSheetWidget) sauvegardee par question
//   - Options d'accessibilite (AccessibilityOptionsDialog)
//   - Dialogue de soumission officiel avec cachet anime (ExamSubmitDialog)
//   - Application des AccessibilitySettings a tout le rendu
//   - Mise en page sobre style document officiel (police serif)
//
// NE REMPLACE PAS simulation_screen.dart : variante optionnelle que l'agent
// wiring pourra activer a la place (route /simulation -> AuthenticExamenScreen).
// Voir lib/screens/simulation/README.md.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/question.dart';
import '../../services/accessibility_service.dart';
import '../../services/question_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/exam/accessibility_options.dart';
import '../../widgets/exam/calculator_widget.dart';
import '../../widgets/exam/exam_header_official.dart';
import '../../widgets/exam/exam_submit_dialog.dart';
import '../../widgets/exam/exam_timer_official.dart';
import '../../widgets/exam/scratch_sheet_widget.dart';

/// Phases successives (identiques a SimulationScreen pour cohérence).
enum _AuthenticPhase { config, examen, rapport }

/// Variante enrichie du SimulationScreen avec couche d'authenticite.
class AuthenticExamenScreen extends StatefulWidget {
  const AuthenticExamenScreen({super.key, this.examen, this.serie});

  /// Examen pre-selectionne depuis le routing (ex : 'BEPC').
  final String? examen;

  /// Serie pre-selectionnee (ex : 'C') - uniquement pour BAC.
  final String? serie;

  @override
  State<AuthenticExamenScreen> createState() => _AuthenticExamenScreenState();
}

class _AuthenticExamenScreenState extends State<AuthenticExamenScreen> {
  // ─── Phase courante ──────────────────────────────────────────
  _AuthenticPhase _phase = _AuthenticPhase.config;

  // ─── Parametres de configuration (Phase 1) ───────────────────
  late String _examenChoisi;
  String? _serieChoisie;
  int _nombreQuestions = 20;
  int _dureeMinutes = 120;
  bool _modeRapide = false;

  // ─── Etat de l'examen (Phase 2) ──────────────────────────────
  List<Question> _questions = [];
  int _indexCourant = 0;
  final Map<String, String> _reponses = {};
  final Map<String, bool> _marquees = {};
  final Map<String, bool> _correctManuel = {};
  final GlobalKey<ExamTimerOfficialState> _timerKey = GlobalKey();

  // Identifiant d'examen (pour la persistance du brouillon).
  String _examId = 'authentic-exam';

  // ─── Helpers ─────────────────────────────────────────────────

  int _dureeParDefaut(String examen) {
    switch (examen) {
      case 'BAC1':
      case 'BAC2':
        return 240;
      case 'Probatoire':
        return 180;
      case 'BEPC':
      default:
        return 120;
    }
  }

  bool _estBac(String examen) =>
      examen == 'BAC1' || examen == 'BAC2' || examen == 'Probatoire';

  String _formatDuree(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0) return m > 0 ? '${h}h ${m.toString().padLeft(2, '0')}' : '${h}h';
    return '${m}min';
  }

  String _coefficient(String examen, String? serie) {
    if (examen == 'BEPC') return '4';
    if (examen == 'BAC2' && serie == 'C') return '6';
    if (examen == 'BAC2') return '4';
    return '4';
  }

  @override
  void initState() {
    super.initState();
    _examenChoisi = widget.examen ?? 'BEPC';
    _serieChoisie = widget.serie;
    _dureeMinutes = _dureeParDefaut(_examenChoisi);
  }

  // ─── Phase 1 : Configuration ─────────────────────────────────

  Future<void> _demarrerExamen() async {
    final service = Provider.of<QuestionService>(context, listen: false);
    final serie = _estBac(_examenChoisi) ? _serieChoisie : null;
    final questions = service.generateSimulation(
      examen: _examenChoisi,
      serie: serie,
      nombreQuestions: _nombreQuestions,
    );

    if (questions.isEmpty) {
      _showAucuneQuestionDialog();
      return;
    }

    setState(() {
      _questions = questions;
      _indexCourant = 0;
      _reponses.clear();
      _marquees.clear();
      _correctManuel.clear();
      _examId = 'authentic_${_examenChoisi}_${DateTime.now().millisecondsSinceEpoch}';
      _phase = _AuthenticPhase.examen;
    });
  }

  void _showAucuneQuestionDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Aucune question disponible'),
        content: const Text(
          'La banque ne contient pas encore de questions pour cette '
          'configuration. Essaie un autre examen ou serie.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ─── Phase 2 : Actions examen ────────────────────────────────

  void _selectionnerChoix(String choix) {
    setState(() {
      _reponses[_questions[_indexCourant].id] = choix;
    });
  }

  void _enregistrerTexte(String texte) {
    _reponses[_questions[_indexCourant].id] = texte;
  }

  void _basculerMarque() {
    final id = _questions[_indexCourant].id;
    setState(() {
      _marquees[id] = !(_marquees[id] ?? false);
    });
  }

  void _allerA(int index) {
    if (index < 0 || index >= _questions.length) return;
    setState(() => _indexCourant = index);
  }

  void _suivant() {
    if (_indexCourant < _questions.length - 1) {
      _allerA(_indexCourant + 1);
    } else {
      _confirmerTerminaison();
    }
  }

  void _precedent() {
    if (_indexCourant > 0) _allerA(_indexCourant - 1);
  }

  void _onTimerTimeout() {
    if (!mounted) return;
    // Auto-submit quand le temps est ecoule.
    _terminerExamen(autoSubmit: true);
  }

  Future<void> _confirmerTerminaison() async {
    final confirme = await ExamSubmitDialog.show(
      context,
      totalQuestions: _questions.length,
      questionsRepondues: _compterRepondues(),
      tempsRestant: _formatTimer(_timerKey.currentState?.tempsRestant ?? Duration.zero),
      nomExamen: '$_examenChoisi'
          '${_serieChoisie != null ? ' - Serie $_serieChoisie' : ''}',
    );
    if (confirme && mounted) {
      _terminerExamen();
    }
  }

  void _showQuitDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Quitter l\'examen ?'),
        content: const Text(
          'Ta progression sera perdue et l\'examen ne sera pas comptabilise.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Rester'),
          ),
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

  void _terminerExamen({bool autoSubmit = false}) {
    if (!mounted) return;
    setState(() => _phase = _AuthenticPhase.rapport);
  }

  // ─── Outils AppBar ───────────────────────────────────────────

  Future<void> _ouvrirCalculatrice() async {
    final resultat = await CalculatorWidget.show(context);
    if (resultat != null && resultat.isNotEmpty && mounted) {
      // Injecter dans la reponse si la question est ouverte/calcul/redaction.
      final q = _questions[_indexCourant];
      if (q.type == QuestionType.ouvert ||
          q.type == QuestionType.calcul ||
          q.type == QuestionType.redaction) {
        final valeurActuelle = _reponses[q.id] ?? '';
        _reponses[q.id] = '$valeurActuelle$resultat';
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Resultat insere : $resultat'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _ouvrirBrouillon() async {
    await showScratchSheet(
      context,
      examId: _examId,
      questionIndex: _indexCourant,
    );
  }

  Future<void> _ouvrirAccessibilite() async {
    await AccessibilityOptionsDialog.show(context);
    // Le rebuild prendra en compte les nouvelles preferences.
    if (mounted) setState(() {});
  }

  // ─── Correction & scoring (identique a SimulationScreen) ─────

  bool _estCorrecte(Question q) {
    final reponseEleve = _reponses[q.id]?.trim();
    if (reponseEleve == null || reponseEleve.isEmpty) return false;
    switch (q.type) {
      case QuestionType.qcm:
      case QuestionType.vraiFaux:
        return _normaliser(reponseEleve) == _normaliser(q.reponse);
      case QuestionType.ouvert:
      case QuestionType.calcul:
      case QuestionType.redaction:
        return _correctManuel[q.id] ?? false;
    }
  }

  String _normaliser(String s) =>
      s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  double _scoreBrut() {
    double total = 0;
    for (final q in _questions) {
      if (_estCorrecte(q)) total += (q.points ?? 1).toDouble();
    }
    return total;
  }

  double _scoreTotalPossible() {
    double total = 0;
    for (final q in _questions) {
      total += (q.points ?? 1).toDouble();
    }
    return total;
  }

  double _scoreSur20() {
    final possible = _scoreTotalPossible();
    if (possible == 0) return 0;
    return _scoreBrut() / possible * 20;
  }

  int _pourcentageReussite() {
    final possible = _scoreTotalPossible();
    if (possible == 0) return 0;
    return (_scoreBrut() / possible * 100).round();
  }

  void _setCorrectManuel(String questionId, bool valeur) {
    setState(() => _correctManuel[questionId] = valeur);
  }

  int _compterRepondues() {
    return _questions.where((q) {
      final r = _reponses[q.id]?.trim();
      return r != null && r.isNotEmpty;
    }).length;
  }

  int _compterMarquees() =>
      _questions.where((q) => _marquees[q.id] == true).length;

  String _formatTimer(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  Color _scoreColor(int taux) {
    if (taux >= 70) return AppColors.success;
    if (taux >= 40) return AppColors.warning;
    return AppColors.error;
  }

  String _typeLabel(QuestionType t) {
    switch (t) {
      case QuestionType.qcm:
        return 'QCM';
      case QuestionType.vraiFaux:
        return 'Vrai / Faux';
      case QuestionType.calcul:
        return 'Calcul';
      case QuestionType.ouvert:
        return 'Question ouverte';
      case QuestionType.redaction:
        return 'Redaction';
    }
  }

  // ─── Build principal ─────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    switch (_phase) {
      case _AuthenticPhase.config:
        return _buildPhaseConfig();
      case _AuthenticPhase.examen:
        return _buildPhaseExamen();
      case _AuthenticPhase.rapport:
        return _buildPhaseRapport();
    }
  }

  // ─── Phase 1 : Configuration (simplifiee) ────────────────────

  Widget _buildPhaseConfig() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Examen authentique - Configuration'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: 'Accessibilite',
            icon: const Icon(Icons.accessibility),
            onPressed: _ouvrirAccessibilite,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoBandeau(),
              const SizedBox(height: 20),
              Text('Type d\'examen', style: AppTextStyles.h3),
              const SizedBox(height: 8),
              _buildExamensWrap(),
              const SizedBox(height: 20),
              if (_estBac(_examenChoisi)) ...[
                Text('Serie (BAC)', style: AppTextStyles.h3),
                const SizedBox(height: 8),
                _buildSeriesWrap(),
                const SizedBox(height: 20),
              ],
              Text('Nombre de questions', style: AppTextStyles.h3),
              const SizedBox(height: 8),
              _buildNombreWrap(),
              const SizedBox(height: 20),
              Text('Duree', style: AppTextStyles.h3),
              const SizedBox(height: 8),
              _buildDureeWrap(),
              const SizedBox(height: 24),
              _buildResumeCarte(),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _demarrerExamen,
                  icon: const Icon(Icons.play_arrow, size: 22),
                  label: const Text('Demarrer l\'examen authentique'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBandeau() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryLight.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified, color: AppColors.primary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Conditions reelles d\'examen',
                  style: AppTextStyles.h3.copyWith(
                    color: AppColors.primary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Calculatrice, brouillon, en-tete officiel, minuterie avec '
                  'alarmes - simule un vrai sujet BEPC/BAC.',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamensWrap() {
    final examens = [
      {'code': 'BEPC', 'label': 'BEPC'},
      {'code': 'BAC1', 'label': 'BAC 1'},
      {'code': 'BAC2', 'label': 'BAC 2'},
      {'code': 'Probatoire', 'label': 'Probatoire'},
    ];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: examens.map((e) {
        final selected = _examenChoisi == e['code'];
        return ChoiceChip(
          label: Text(e['label']!),
          selected: selected,
          selectedColor: AppColors.primary,
          labelStyle: TextStyle(
            color: selected ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: selected ? AppColors.primary : AppColors.divider,
            ),
          ),
          onSelected: (_) => setState(() {
            _examenChoisi = e['code']!;
            _dureeMinutes = _dureeParDefaut(_examenChoisi);
            _modeRapide = false;
            if (!_estBac(_examenChoisi)) _serieChoisie = null;
          }),
        );
      }).toList(),
    );
  }

  Widget _buildSeriesWrap() {
    final series = ['A', 'B', 'C', 'D', 'F'];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: series.map((s) {
        final selected = _serieChoisie == s;
        return ChoiceChip(
          label: Text('Serie $s'),
          selected: selected,
          selectedColor: AppColors.primary,
          labelStyle: TextStyle(
            color: selected ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: selected ? AppColors.primary : AppColors.divider,
            ),
          ),
          onSelected: (_) =>
              setState(() => _serieChoisie = selected ? null : s),
        );
      }).toList(),
    );
  }

  Widget _buildNombreWrap() {
    final options = [10, 20, 40];
    return Wrap(
      spacing: 10,
      children: options.map((n) {
        final selected = _nombreQuestions == n;
        return ChoiceChip(
          label: Text('$n questions'),
          selected: selected,
          selectedColor: AppColors.accent,
          labelStyle: TextStyle(
            color: selected ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: selected ? AppColors.accent : AppColors.divider,
            ),
          ),
          onSelected: (_) => setState(() => _nombreQuestions = n),
        );
      }).toList(),
    );
  }

  Widget _buildDureeWrap() {
    final defaut = _dureeParDefaut(_examenChoisi);
    return Wrap(
      spacing: 10,
      children: [
        ChoiceChip(
          label: Text('Standard (${_formatDuree(Duration(minutes: defaut))})'),
          selected: !_modeRapide,
          selectedColor: AppColors.primary,
          labelStyle: TextStyle(
            color: !_modeRapide ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: !_modeRapide ? AppColors.primary : AppColors.divider,
            ),
          ),
          onSelected: (_) => setState(() {
            _modeRapide = false;
            _dureeMinutes = defaut;
          }),
        ),
        ChoiceChip(
          label: const Text('Mode rapide 30 min'),
          selected: _modeRapide,
          selectedColor: AppColors.accent,
          labelStyle: TextStyle(
            color: _modeRapide ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: _modeRapide ? AppColors.accent : AppColors.divider,
            ),
          ),
          onSelected: (_) => setState(() {
            _modeRapide = true;
            _dureeMinutes = 30;
          }),
        ),
      ],
    );
  }

  Widget _buildResumeCarte() {
    final dureeAffichee = _modeRapide ? 30 : _dureeParDefaut(_examenChoisi);
    final serieTexte = _estBac(_examenChoisi) && _serieChoisie != null
        ? ' (Serie $_serieChoisie)'
        : '';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primarySurface, AppColors.accentSurface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryLight.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.assignment, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Resume',
                  style: AppTextStyles.h3.copyWith(color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              style: AppTextStyles.body.copyWith(fontSize: 16),
              children: [
                const TextSpan(text: 'Tu vas repondre a '),
                TextSpan(
                  text: '$_nombreQuestions questions',
                  style: AppTextStyles.body.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const TextSpan(text: ' en '),
                TextSpan(
                  text: '$dureeAffichee minutes',
                  style: AppTextStyles.body.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                  ),
                ),
                const TextSpan(text: '.'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Examen : $_examenChoisi$serieTexte',
            style: AppTextStyles.bodySmall,
          ),
          if (AccessibilityService.settings.extraTime25) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Temps additionnel +25% actif',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Phase 2 : Examen en cours ───────────────────────────────

  Widget _buildPhaseExamen() {
    final q = _questions[_indexCourant];
    final isLast = _indexCourant == _questions.length - 1;
    final dureeInitiale = Duration(
      minutes: _modeRapide ? 30 : _dureeMinutes,
    );

    return Scaffold(
      backgroundColor: AccessibilityService.backgroundColor(AppColors.background),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.grid_view_rounded),
          tooltip: 'Plan de l\'examen',
          onPressed: _ouvrirPlanExamen,
        ),
        title: ExamTimerOfficial(
          key: _timerKey,
          duration: dureeInitiale,
          onTimeout: _onTimerTimeout,
          canPause: AccessibilityService.pausesAllowed && _modeRapide,
          compact: true,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Calculatrice',
            icon: const Icon(Icons.calculate),
            onPressed: _ouvrirCalculatrice,
          ),
          IconButton(
            tooltip: 'Brouillon',
            icon: const Icon(Icons.edit_note),
            onPressed: _ouvrirBrouillon,
          ),
          IconButton(
            tooltip: 'Accessibilite',
            icon: const Icon(Icons.accessibility),
            onPressed: _ouvrirAccessibilite,
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _showQuitDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildProgressionHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExamHeaderOfficial(
                    examen: _examenChoisi,
                    serie: _serieChoisie,
                    session: DateTime.now().year,
                    epreuve: q.matiere,
                    duree: _formatDuree(dureeInitiale),
                    coefficient: _coefficient(_examenChoisi, _serieChoisie),
                  ),
                  const SizedBox(height: 16),
                  _buildQuestionDocument(q),
                  const SizedBox(height: 20),
                  _buildZoneReponse(q),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          _buildNavigationBar(isLast),
        ],
      ),
    );
  }

  Widget _buildProgressionHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${_indexCourant + 1} / ${_questions.length}',
                style: AppTextStyles.h3.copyWith(fontSize: 15),
              ),
              Row(
                children: [
                  _compteurBadge('Repondues', _compterRepondues(), AppColors.success),
                  const SizedBox(width: 8),
                  _compteurBadge('Marquees', _compterMarquees(), AppColors.accent),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _questions.isEmpty
                  ? 0
                  : (_indexCourant + 1) / _questions.length,
              minHeight: 4,
              backgroundColor: AppColors.primarySurface,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _compteurBadge(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: AppTextStyles.label.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.label.copyWith(color: color, fontSize: 10),
          ),
        ],
      ),
    );
  }

  /// Affiche la question comme un document d'examen officiel : police serif,
  /// mise en page sobre, encadre noir.
  Widget _buildQuestionDocument(Question q) {
    final styleEnonce = AccessibilityService.adjustTextStyle(
      TextStyle(
        fontFamily: 'serif',
        fontSize: 17,
        height: 1.6,
        color: AccessibilityService.textColor(Colors.black),
      ),
    );
    final styleChapitre = AccessibilityService.adjustTextStyle(
      TextStyle(
        fontFamily: 'serif',
        fontSize: 12,
        fontStyle: FontStyle.italic,
        color: Colors.black54,
      ),
    );
    final styleMeta = AccessibilityService.adjustTextStyle(
      TextStyle(
        fontFamily: 'serif',
        fontSize: 11,
        color: Colors.black87,
        fontWeight: FontWeight.bold,
      ),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AccessibilityService.backgroundColor(Colors.white),
        border: Border.all(color: Colors.black54, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tete de la question : numero + meta
          Row(
            children: [
              Text(
                'Question ${_indexCourant + 1}',
                style: styleMeta.copyWith(fontSize: 13),
              ),
              const SizedBox(width: 8),
              if (q.points != null)
                Text('(${q.points} points)', style: styleMeta),
              const SizedBox(width: 8),
              if (q.annee != null)
                Text('- Session ${q.annee}', style: styleMeta),
            ],
          ),
          const Divider(height: 12),
          if (q.chapitre.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('Chapitre : ${q.chapitre}', style: styleChapitre),
            ),
          const SizedBox(height: 6),
          // Enonce principal en serif
          Text(q.enonce, style: styleEnonce),
          const SizedBox(height: 8),
          // Bouton lecture audio si TTS active
          if (AccessibilityService.textToSpeechEnabled)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Lecture audio non disponible (TTS a brancher via '
                          'flutter_tts - voir README).'),
                      duration: Duration(seconds: 3),
                    ),
                  );
                },
                icon: const Icon(Icons.volume_up, size: 18),
                label: const Text('Lire l\'enonce'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildZoneReponse(Question q) {
    switch (q.type) {
      case QuestionType.qcm:
        return _buildQcmReponse(q);
      case QuestionType.vraiFaux:
        return _buildVraiFauxReponse(q);
      case QuestionType.calcul:
      case QuestionType.ouvert:
      case QuestionType.redaction:
        return _buildTexteReponse(q);
    }
  }

  Widget _buildQcmReponse(Question q) {
    final choix = q.choix ?? [];
    final selected = _reponses[q.id];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Choisis la bonne reponse :',
            style: AccessibilityService.adjustTextStyle(AppTextStyles.bodySmall)),
        const SizedBox(height: 10),
        ...choix.map((c) {
          final isSelected = selected == c;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () => _selectionnerChoix(c),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primarySurface
                      : AccessibilityService.backgroundColor(AppColors.surface),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.divider,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        c,
                        style: AccessibilityService.adjustTextStyle(
                          AppTextStyles.body.copyWith(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textPrimary,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildVraiFauxReponse(Question q) {
    final selected = _reponses[q.id];
    return Row(
      children: [
        Expanded(
          child: _buildVraiFauxButton(
            label: 'Vrai',
            icon: Icons.check_circle_outline,
            color: AppColors.success,
            selected: selected == 'Vrai',
            onTap: () => _selectionnerChoix('Vrai'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildVraiFauxButton(
            label: 'Faux',
            icon: Icons.cancel_outlined,
            color: AppColors.error,
            selected: selected == 'Faux',
            onTap: () => _selectionnerChoix('Faux'),
          ),
        ),
      ],
    );
  }

  Widget _buildVraiFauxButton({
    required String label,
    required IconData icon,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: selected
              ? color
              : AccessibilityService.backgroundColor(AppColors.surface),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : AppColors.divider,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: selected ? Colors.white : color),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTextStyles.h3
                  .copyWith(color: selected ? Colors.white : color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTexteReponse(Question q) {
    final controller = TextEditingController(text: _reponses[q.id] ?? '');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          q.type == QuestionType.calcul
              ? 'Saisis ta reponse (detaille le calcul) :'
              : 'Saisis ta reponse :',
          style: AccessibilityService.adjustTextStyle(AppTextStyles.bodySmall),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          onChanged: _enregistrerTexte,
          maxLines: 6,
          minLines: 4,
          textInputAction: TextInputAction.newline,
          decoration: const InputDecoration(
            hintText: 'Ecris ta reponse ici...',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Cette question sera corrigee lors du rapport final.',
          style: AppTextStyles.bodySmall.copyWith(fontStyle: FontStyle.italic),
        ),
      ],
    );
  }

  Widget _buildNavigationBar(bool isLast) {
    final q = _questions[_indexCourant];
    final isMarquee = _marquees[q.id] == true;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _indexCourant == 0 ? null : _precedent,
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Precedent'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  foregroundColor: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              onPressed: _basculerMarque,
              tooltip: 'Marquer pour revoir',
              icon: Icon(
                isMarquee ? Icons.flag : Icons.flag_outlined,
                color: isMarquee ? AppColors.accent : AppColors.textSecondary,
                size: 28,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _suivant,
                icon: Icon(isLast ? Icons.check : Icons.arrow_forward, size: 18),
                label: Text(isLast ? 'Terminer' : 'Suivant'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor:
                      isLast ? AppColors.success : AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Plan d'examen ───────────────────────────────────────────

  void _ouvrirPlanExamen() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Plan de l\'examen', style: AppTextStyles.h2),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1,
                ),
                itemCount: _questions.length,
                itemBuilder: (context, i) {
                  final q = _questions[i];
                  final repondue =
                      (_reponses[q.id]?.trim() ?? '').isNotEmpty;
                  final marquee = _marquees[q.id] == true;
                  final courante = i == _indexCourant;
                  Color couleur;
                  if (marquee) {
                    couleur = AppColors.accent;
                  } else if (repondue) {
                    couleur = AppColors.success;
                  } else {
                    couleur = AppColors.surfaceVariant;
                  }
                  return InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      _allerA(i);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: couleur,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color:
                              courante ? AppColors.primary : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: AppTextStyles.h3.copyWith(
                            color: repondue || marquee
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _confirmerTerminaison();
                  },
                  icon: const Icon(Icons.check_circle_outline, size: 20),
                  label: const Text('Terminer l\'examen'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Phase 3 : Rapport (simplifie) ───────────────────────────

  Widget _buildPhaseRapport() {
    final score = _scoreSur20();
    final pct = _pourcentageReussite();
    final color = _scoreColor(pct);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Rapport d\'examen'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildScoreCard(score, pct, color),
              const SizedBox(height: 20),
              _buildStatsRow(),
              const SizedBox(height: 20),
              _buildAutoEvalSection(),
              const SizedBox(height: 20),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreCard(double score, int pct, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.15), AppColors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Text('Examen authentique termine !', style: AppTextStyles.h2),
          const SizedBox(height: 24),
          Text(
            '${score.toStringAsFixed(1)} / 20',
            style: TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$pct% de reussite',
            style: AppTextStyles.h3.copyWith(color: color),
          ),
          const SizedBox(height: 6),
          Text(
            '${_compterRepondues()} / ${_questions.length} questions repondues',
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            'Repondues',
            _compterRepondues().toString(),
            AppColors.success,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            'Marquees',
            _compterMarquees().toString(),
            AppColors.accent,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            'Total',
            _questions.length.toString(),
            AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _statCard(String label, String valeur, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            valeur,
            style: AppTextStyles.h2.copyWith(color: color),
          ),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }

  /// Section d'auto-evaluation pour les questions ouvertes/calcul/redaction
  /// (l'eleve coche "correct" ou "incorrect" pour chaque question ouverte).
  Widget _buildAutoEvalSection() {
    final ouvertes = _questions.where((q) =>
        q.type == QuestionType.ouvert ||
        q.type == QuestionType.calcul ||
        q.type == QuestionType.redaction);
    if (ouvertes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Auto-evaluation (questions ouvertes)',
            style: AppTextStyles.h3),
        const SizedBox(height: 4),
        Text(
          'Pour chaque question ouverte, compare ta reponse au corrige et '
          'coche "correct" si elle est juste.',
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(height: 12),
        ...ouvertes.map((q) {
          final index = _questions.indexOf(q);
          final estCorrect = _correctManuel[q.id] ?? false;
          final reponseEleve = _reponses[q.id] ?? '(sans reponse)';
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Q${index + 1} - ${q.chapitre}',
                      style: AppTextStyles.label
                          .copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text('Ta reponse : $reponseEleve',
                      style: AppTextStyles.bodySmall),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('Corrige : ${q.reponse}',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.primary)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      FilterChip(
                        label: const Text('Correct'),
                        selected: estCorrect,
                        selectedColor: AppColors.success,
                        labelStyle: TextStyle(
                          color: estCorrect ? Colors.white : AppColors.success,
                        ),
                        onSelected: (_) => _setCorrectManuel(q.id, true),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Incorrect'),
                        selected: !estCorrect,
                        selectedColor: AppColors.error,
                        labelStyle: TextStyle(
                          color: !estCorrect ? Colors.white : AppColors.error,
                        ),
                        onSelected: (_) => _setCorrectManuel(q.id, false),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _phase = _AuthenticPhase.config;
                _questions.clear();
                _reponses.clear();
                _marquees.clear();
                _correctManuel.clear();
              });
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Nouvel examen'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.home),
            label: const Text('Retour a l\'accueil'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              foregroundColor: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}
