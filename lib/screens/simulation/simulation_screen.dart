// lib/screens/simulation/simulation_screen.dart
// Écran Simulation d'Examen — conditions réelles BEPC / BAC togolais
// Architecture en 3 phases : Configuration > Examen chronométré > Rapport

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/question.dart';
import '../../services/question_service.dart';
import '../../theme/adaptive_colors.dart';
import '../../theme/app_theme.dart';

/// Phases successives de l'écran simulation.
enum SimulationPhase { config, examen, rapport }

class SimulationScreen extends StatefulWidget {
  const SimulationScreen({super.key, this.examen, this.serie});

  /// Examen pré-sélectionné depuis le routing (ex : 'BEPC').
  final String? examen;

  /// Série pré-sélectionnée (ex : 'C') — uniquement pour BAC.
  final String? serie;

  @override
  State<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends State<SimulationScreen>
    with TickerProviderStateMixin {
  // ─── Phase courante ────────────────────────────────────────────
  SimulationPhase _phase = SimulationPhase.config;

  // ─── Paramètres de configuration (Phase 1) ─────────────────────
  late String _examenChoisi; // 'BEPC' | 'BAC1' | 'BAC2' | 'Probatoire'
  String? _serieChoisie; // 'A' | 'B' | 'C' | 'D' | 'F' | null
  int _nombreQuestions = 20;
  int _dureeMinutes = 120;
  bool _modeRapide = false;

  // ─── État de l'examen (Phase 2) ────────────────────────────────
  List<Question> _questions = [];
  int _indexCourant = 0;
  final Map<String, String> _reponses = {}; // questionId -> réponse saisie
  final Map<String, bool> _marquees = {}; // questionId -> drapeau levé ?
  final Map<String, bool> _correctManuel =
      {}; // questionId -> auto-éval élève (ouvert/calcul)

  // Minuterie descendante
  Timer? _timer;
  DateTime? _finExamen; // heure de fin prévue ( recalculée à chaque tick )
  Duration _tempsRestant = Duration.zero;
  Duration _tempsTotalUtilise = Duration.zero;

  // Contrôleur de saisie texte (réutilisé entre les questions)
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _examenChoisi = widget.examen ?? 'BEPC';
    _serieChoisie = widget.serie;
    _dureeMinutes = _dureeParDefaut(_examenChoisi);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _textController.dispose();
    super.dispose();
  }

  // ─── Helpers durée ─────────────────────────────────────────────

  int _dureeParDefaut(String examen) {
    switch (examen) {
      case 'BAC1':
      case 'BAC2':
        return 240; // 4h
      case 'Probatoire':
        return 180; // 3h
      case 'BEPC':
      default:
        return 120; // 2h
    }
  }

  bool _estBac(String examen) =>
      examen == 'BAC1' || examen == 'BAC2' || examen == 'Probatoire';

  // ─── Actions Phase 1 : démarrage de l'examen ───────────────────

  Future<void> _demarrerExamen() async {
    final service = Provider.of<QuestionService>(context, listen: false);
    final serie = _estBac(_examenChoisi) ? _serieChoisie : null;
    final questions = service.generateSimulation(
      examen: _examenChoisi,
      serie: serie,
      nombreQuestions: _nombreQuestions,
    );

    // Sécurité : si la banque ne contient aucune question correspondante,
    // on bloque le démarrage avec un message.
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
      _tempsRestant = Duration(minutes: _modeRapide ? 30 : _dureeMinutes);
      _finExamen = DateTime.now().add(_tempsRestant);
      _tempsTotalUtilise = Duration.zero;
      _phase = SimulationPhase.examen;
    });

    _demarrerTimer();
    _syncTextController();
  }

  void _showAucuneQuestionDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Aucune question disponible'),
        content: const Text(
          'La banque ne contient pas encore de questions pour cette '
          'configuration. Essaie un autre examen ou série.',
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

  // ─── Minuterie descendante ────────────────────────────────────
  // Le calcul se base sur DateTime.now() plutôt qu'un simple compteur,
  // pour rester correct même si l'app passe en arrière-plan.

  void _demarrerTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final maintenant = DateTime.now();
      final restant = _finExamen!.difference(maintenant);
      setState(() {
        _tempsRestant = restant.isNegative ? Duration.zero : restant;
        _tempsTotalUtilise =
            Duration(minutes: _modeRapide ? 30 : _dureeMinutes) - _tempsRestant;
      });
      if (_tempsRestant == Duration.zero) {
        _timer?.cancel();
        _terminerExamen(autoSubmit: true);
      }
    });
  }

  // ─── Actions Phase 2 : navigation & réponses ───────────────────

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
    _syncTextController();
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

  /// Synchronise le TextController avec la réponse enregistrée
  /// quand on navigue entre les questions ouvertes/calcul.
  void _syncTextController() {
    if (_questions.isEmpty) return;
    final q = _questions[_indexCourant];
    final t = q.type;
    if (t == QuestionType.ouvert ||
        t == QuestionType.calcul ||
        t == QuestionType.redaction) {
      final valeur = _reponses[q.id] ?? '';
      if (_textController.text != valeur) {
        _textController.text = valeur;
        _textController.selection =
            TextSelection.collapsed(offset: valeur.length);
      }
    }
  }

  void _confirmerTerminaison() {
    final sansReponse = _questions.where((q) {
      final r = _reponses[q.id]?.trim();
      return r == null || r.isEmpty;
    }).length;

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Terminer l\'examen ?'),
        content: Text(
          sansReponse > 0
              ? 'Il te reste $sansReponse question(s) sans réponse. '
                  'Terminer quand même ?'
              : 'Tu as répondu à toutes les questions. Souhaites-tu terminer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Continuer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _terminerExamen();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Terminer'),
          ),
        ],
      ),
    );
  }

  void _showQuitDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Quitter l\'examen ?'),
        content: const Text(
          'Ta progression sera perdue et l\'examen ne sera pas comptabilisé.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Rester'),
          ),
          ElevatedButton(
            onPressed: () {
              _timer?.cancel();
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
    _timer?.cancel();
    if (!mounted) return;

    // En cas d'auto-submit (timer à 0), on fige le temps utilisé.
    if (autoSubmit) {
      _tempsTotalUtilise = Duration(minutes: _modeRapide ? 30 : _dureeMinutes);
    }

    setState(() => _phase = SimulationPhase.rapport);
  }

  // ─── Correction & scoring ──────────────────────────────────────

  /// Correction automatique pour QCM/vraiFaux. Pour ouvert/calcul/redaction,
  /// on se base sur l'auto-évaluation de l'élève (map _correctManuel).
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

  /// Somme des points des questions correctes.
  double _scoreBrut() {
    double total = 0;
    for (final q in _questions) {
      if (_estCorrecte(q)) {
        total += (q.points ?? 1).toDouble();
      }
    }
    return total;
  }

  /// Somme des points de toutes les questions (plafond).
  double _scoreTotalPossible() {
    double total = 0;
    for (final q in _questions) {
      total += (q.points ?? 1).toDouble();
    }
    return total;
  }

  /// Score ramené sur 20.
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

  /// Auto-évaluation de l'élève pour une question ouverte/calcul.
  void _setCorrectManuel(String questionId, bool valeur) {
    setState(() => _correctManuel[questionId] = valeur);
  }

  // ─── Helpers UI ────────────────────────────────────────────────

  Color _scoreColor(int taux) {
    if (taux >= 70) return AppColors.success;
    if (taux >= 40) return AppColors.warning;
    return AppColors.error;
  }

  String _formatTimer(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String _formatDuree(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0) {
      return m > 0 ? '${h}h ${m.toString().padLeft(2, '0')}min' : '${h}h';
    }
    return '${m}min';
  }

  int _compterRepondues() {
    return _questions.where((q) {
      final r = _reponses[q.id]?.trim();
      return r != null && r.isNotEmpty;
    }).length;
  }

  int _compterMarquees() =>
      _questions.where((q) => _marquees[q.id] == true).length;

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
        return 'Rédaction';
    }
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

  // ─── Build principal ───────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    switch (_phase) {
      case SimulationPhase.config:
        return _buildPhaseConfig();
      case SimulationPhase.examen:
        return _buildPhaseExamen();
      case SimulationPhase.rapport:
        return _buildPhaseRapport();
    }
  }

  // ─── Phase 1 : Configuration ───────────────────────────────────

  Widget _buildPhaseConfig() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuration de l\'examen'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Choisis ton examen',
                  style: AppTextStyles.h2
                      .copyWith(color: AdaptiveColors.textPrimary(context))),
              const SizedBox(height: 6),
              Text(
                'Sélectionne l\'examen que tu veux simuler, '
                'puis ajuste les paramètres.',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AdaptiveColors.textSecondary(context)),
              ),
              const SizedBox(height: 16),
              _buildExamensGrid(),
              const SizedBox(height: 24),
              if (_estBac(_examenChoisi)) ...[
                Text('Série (BAC)',
                    style: AppTextStyles.h3
                        .copyWith(color: AdaptiveColors.textPrimary(context))),
                const SizedBox(height: 8),
                _buildSeriesChips(),
                const SizedBox(height: 24),
              ],
              Text('Nombre de questions',
                  style: AppTextStyles.h3
                      .copyWith(color: AdaptiveColors.textPrimary(context))),
              const SizedBox(height: 8),
              _buildNombreChips(),
              const SizedBox(height: 24),
              Text('Durée',
                  style: AppTextStyles.h3
                      .copyWith(color: AdaptiveColors.textPrimary(context))),
              const SizedBox(height: 8),
              _buildDureeChips(),
              const SizedBox(height: 32),
              _buildResumeCarte(),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _demarrerExamen,
                  icon: const Icon(Icons.play_arrow, size: 22),
                  label: const Text('Démarrer l\'examen'),
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

  Widget _buildExamensGrid() {
    final examens = [
      {'code': 'BEPC', 'label': 'BEPC', 'desc': 'Brevet d\'études'},
      {'code': 'BAC1', 'label': 'BAC 1', 'desc': 'Première partie'},
      {'code': 'BAC2', 'label': 'BAC 2', 'desc': 'Baccalauréat'},
      {'code': 'Probatoire', 'label': 'Probatoire', 'desc': 'Admission en Tle'},
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.4,
      ),
      itemCount: examens.length,
      itemBuilder: (context, i) {
        final e = examens[i];
        final selected = _examenChoisi == e['code'];
        return _buildExamenCard(
          e['code']!,
          e['label']!,
          e['desc']!,
          selected,
          () => setState(() {
            _examenChoisi = e['code']!;
            _dureeMinutes = _dureeParDefaut(_examenChoisi);
            _modeRapide = false;
            if (!_estBac(_examenChoisi)) _serieChoisie = null;
          }),
        );
      },
    );
  }

  Widget _buildExamenCard(
    String code,
    String label,
    String desc,
    bool selected,
    VoidCallback onTap,
  ) {
    return Material(
      color: selected ? AppColors.primary : AdaptiveColors.surface(context),
      borderRadius: BorderRadius.circular(14),
      elevation: selected ? 4 : 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : AdaptiveColors.divider(context),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: selected
                        ? Colors.white
                        : AdaptiveColors.textSecondary(context),
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: AppTextStyles.h3.copyWith(
                      color: selected
                          ? Colors.white
                          : AdaptiveColors.textPrimary(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: AppTextStyles.bodySmall.copyWith(
                  color: selected
                      ? Colors.white.withOpacity(0.85)
                      : AdaptiveColors.textSecondary(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeriesChips() {
    final series = ['A', 'B', 'C', 'D', 'F'];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: series.map((s) {
        final selected = _serieChoisie == s;
        return ChoiceChip(
          label: Text('Série $s'),
          selected: selected,
          selectedColor: AppColors.primary,
          labelStyle: TextStyle(
            color: selected
                ? Colors.white
                : AdaptiveColors.textPrimary(context),
            fontWeight: FontWeight.w600,
          ),
          backgroundColor: AdaptiveColors.surface(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: selected
                  ? AppColors.primary
                  : AdaptiveColors.divider(context),
            ),
          ),
          onSelected: (_) => setState(() => _serieChoisie = selected ? null : s),
        );
      }).toList(),
    );
  }

  Widget _buildNombreChips() {
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
            color: selected
                ? Colors.white
                : AdaptiveColors.textPrimary(context),
            fontWeight: FontWeight.w600,
          ),
          backgroundColor: AdaptiveColors.surface(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: selected
                  ? AppColors.accent
                  : AdaptiveColors.divider(context),
            ),
          ),
          onSelected: (_) => setState(() => _nombreQuestions = n),
        );
      }).toList(),
    );
  }

  Widget _buildDureeChips() {
    final defaut = _dureeParDefaut(_examenChoisi);
    return Wrap(
      spacing: 10,
      children: [
        ChoiceChip(
          label: Text('Standard (${_formatDuree(Duration(minutes: defaut))})'),
          selected: !_modeRapide,
          selectedColor: AppColors.primary,
          labelStyle: TextStyle(
            color: !_modeRapide
                ? Colors.white
                : AdaptiveColors.textPrimary(context),
            fontWeight: FontWeight.w600,
          ),
          backgroundColor: AdaptiveColors.surface(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: !_modeRapide
                  ? AppColors.primary
                  : AdaptiveColors.divider(context),
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
            color: _modeRapide
                ? Colors.white
                : AdaptiveColors.textPrimary(context),
            fontWeight: FontWeight.w600,
          ),
          backgroundColor: AdaptiveColors.surface(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: _modeRapide
                  ? AppColors.accent
                  : AdaptiveColors.divider(context),
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
        ? ' (Série ${_serieChoisie})'
        : '';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AdaptiveColors.primarySurface(context),
            AdaptiveColors.accentSurface(context),
          ],
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
              Text('Résumé',
                  style: AppTextStyles.h3.copyWith(color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              style: AppTextStyles.body.copyWith(fontSize: 16),
              children: [
                const TextSpan(text: 'Tu vas répondre à '),
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
            style: AppTextStyles.bodySmall
                .copyWith(color: AdaptiveColors.textSecondary(context)),
          ),
          const SizedBox(height: 6),
          Text(
            'Prêt ?',
            style: AppTextStyles.h3.copyWith(color: AppColors.accent),
          ),
        ],
      ),
    );
  }

  // ─── Phase 2 : Examen en cours ─────────────────────────────────

  Widget _buildPhaseExamen() {
    final q = _questions[_indexCourant];
    final isLast = _indexCourant == _questions.length - 1;
    final urgent = _tempsRestant.inMinutes < 10;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.grid_view_rounded),
          tooltip: 'Plan de l\'examen',
          onPressed: _ouvrirPlanExamen,
        ),
        title: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: urgent
                  ? AppColors.error.withOpacity(context.isDark ? 0.20 : 0.12)
                  : AdaptiveColors.primarySurface(context),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 18,
                  color: urgent ? AppColors.error : AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  _formatTimer(_tempsRestant),
                  style: AppTextStyles.button.copyWith(
                    color: urgent ? AppColors.error : AppColors.primary,
                    fontSize: 16,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
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
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildQuestionMeta(q),
                  const SizedBox(height: 16),
                  _buildEnonce(q),
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
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${_indexCourant + 1} / ${_questions.length}',
                style: AppTextStyles.h3.copyWith(fontSize: 16),
              ),
              Row(
                children: [
                  _compteurBadge('Répondues', _compterRepondues(), AppColors.success),
                  const SizedBox(width: 8),
                  _compteurBadge('Marquées', _compterMarquees(), AppColors.accent),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _questions.isEmpty
                  ? 0
                  : (_indexCourant + 1) / _questions.length,
              minHeight: 6,
              backgroundColor: AdaptiveColors.primarySurface(context),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(context.isDark ? 0.20 : 0.12),
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
            style: AppTextStyles.label.copyWith(color: color, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionMeta(Question q) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildChip(label: q.matiere, color: AppColors.primary),
        _buildChip(label: _typeLabel(q.type), color: AppColors.info),
        if (q.annee != null)
          _buildChip(
              label: q.annee.toString(),
              color: AdaptiveColors.textSecondary(context)),
        _buildChip(label: '${q.points ?? 1} pts', color: AppColors.accent),
      ],
    );
  }

  Widget _buildEnonce(Question q) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AdaptiveColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AdaptiveColors.shadow(context),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (q.chapitre.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                q.chapitre,
                style: AppTextStyles.bodySmall.copyWith(
                    fontStyle: FontStyle.italic,
                    color: AdaptiveColors.textSecondary(context)),
              ),
            ),
          Text(
            q.enonce,
            style: AppTextStyles.questionText.copyWith(
                fontSize: 18,
                color: AdaptiveColors.textPrimary(context)),
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
        Text('Choisis la bonne réponse :',
            style: AppTextStyles.bodySmall
                .copyWith(color: AdaptiveColors.textSecondary(context))),
        const SizedBox(height: 12),
        ...choix.map((c) {
          final isSelected = selected == c;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: () => _selectionnerChoix(c),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AdaptiveColors.primarySurface(context)
                      : AdaptiveColors.surface(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : AdaptiveColors.divider(context),
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
                          : AdaptiveColors.textSecondary(context),
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        c,
                        style: AppTextStyles.body.copyWith(
                          color: isSelected
                              ? AppColors.primary
                              : AdaptiveColors.textPrimary(context),
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
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
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          color: selected ? color : AdaptiveColors.surface(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : AdaptiveColors.divider(context),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 36, color: selected ? Colors.white : color),
            const SizedBox(height: 8),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          q.type == QuestionType.calcul
              ? 'Saisis ta réponse (détaille le calcul) :'
              : 'Saisis ta réponse :',
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _textController,
          onChanged: _enregistrerTexte,
          maxLines: 6,
          minLines: 4,
          textInputAction: TextInputAction.newline,
          decoration: const InputDecoration(
            hintText: 'Écris ta réponse ici...',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Cette question sera corrigée lors du rapport final.',
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
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: AdaptiveColors.surface(context),
          boxShadow: [
            BoxShadow(
              color: AdaptiveColors.shadow(context),
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
                label: const Text('Précédent'),
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
                color: isMarquee
                    ? AppColors.accent
                    : AdaptiveColors.textSecondary(context),
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

  // ─── Plan d'examen (sidebar grille) ────────────────────────────

  void _ouvrirPlanExamen() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AdaptiveColors.surface(context),
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
                  Text('Plan de l\'examen',
                      style: AppTextStyles.h2
                          .copyWith(color: AdaptiveColors.textPrimary(context))),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  _legendeCircle(
                      AdaptiveColors.surfaceVariant(context), 'Non répondue'),
                  _legendeCircle(AppColors.success, 'Répondue'),
                  _legendeCircle(AppColors.accent, 'Marquée'),
                ],
              ),
              const SizedBox(height: 20),
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
                    couleur = AdaptiveColors.surfaceVariant(context);
                  }
                  return InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      _allerA(i);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: couleur,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: courante
                              ? AppColors.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: AppTextStyles.h3.copyWith(
                            color: repondue || marquee
                                ? Colors.white
                                : AdaptiveColors.textSecondary(context),
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

  Widget _legendeCircle(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border:
                Border.all(color: AdaptiveColors.divider(context), width: 1),
          ),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: AppTextStyles.bodySmall
                .copyWith(color: AdaptiveColors.textSecondary(context))),
      ],
    );
  }

  // ─── Phase 3 : Rapport de fin d'examen ─────────────────────────

  Widget _buildPhaseRapport() {
    final score = _scoreSur20();
    final pct = _pourcentageReussite();
    final color = _scoreColor(pct);

    return Scaffold(
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
              _buildAnalyseMatieres(),
              const SizedBox(height: 20),
              _buildRecommandations(),
              const SizedBox(height: 20),
              _buildCorrectionsButton(),
              const SizedBox(height: 20),
              _buildActionButtons(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreCard(double score, int pct, Color color) {
    final serieLabel = _serieChoisie != null && _estBac(_examenChoisi)
        ? ' - Série ${_serieChoisie}'
        : '';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.15), AdaptiveColors.surface(context)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Text('Examen terminé !',
              style: AppTextStyles.h2
                  .copyWith(color: AdaptiveColors.textPrimary(context))),
          const SizedBox(height: 6),
          Text(
            '$_examenChoisi$serieLabel',
            style: AppTextStyles.bodySmall
                .copyWith(color: AdaptiveColors.textSecondary(context)),
          ),
          const SizedBox(height: 24),
          // Pourcentage circulaire
          SizedBox(
            width: 160,
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 160,
                  height: 160,
                  child: CircularProgressIndicator(
                    value: pct / 100,
                    strokeWidth: 12,
                    backgroundColor: color.withOpacity(0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$pct%',
                      style: AppTextStyles.h1
                          .copyWith(color: color, fontSize: 32),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${score.toStringAsFixed(1)} / 20',
                      style: AppTextStyles.h3.copyWith(
                          color: AdaptiveColors.textSecondary(context)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _messageScore(pct),
            style: AppTextStyles.body.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _messageScore(int pct) {
    if (pct >= 70) return 'Excellent travail ! Tu es prêt pour l\'examen.';
    if (pct >= 50) return 'Bon début, mais il reste des progrès à faire.';
    if (pct >= 30) return 'Tu dois réviser davantage certains chapitres.';
    return 'Courage ! Reprends les bases et réessaie.';
  }

  Widget _buildStatsRow() {
    final tempsMoyen = _questions.isEmpty
        ? Duration.zero
        : _tempsTotalUtilise ~/ _questions.length;
    final tauxAchevement = _questions.isEmpty
        ? 0
        : (_compterRepondues() / _questions.length * 100).round();

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.timer_outlined,
            label: 'Temps utilisé',
            value: _formatDuree(_tempsTotalUtilise),
            color: AppColors.info,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            icon: Icons.speed,
            label: 'Temps moyen/q',
            value: '${tempsMoyen.inSeconds}s',
            color: AppColors.accent,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            icon: Icons.check_circle_outline,
            label: 'Achèvement',
            value: '$tauxAchevement%',
            color: AppColors.success,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AdaptiveColors.surface(context),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AdaptiveColors.shadow(context),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: AppTextStyles.h3.copyWith(color: color, fontSize: 16),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
                fontSize: 11, color: AdaptiveColors.textSecondary(context)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyseMatieres() {
    // Calcul du pourcentage par matière.
    final parMatiere = <String, _MatiereStat>{};
    for (final q in _questions) {
      final stat = parMatiere.putIfAbsent(q.matiere, () => _MatiereStat());
      stat.total++;
      if (_estCorrecte(q)) stat.correctes++;
    }
    final entries = parMatiere.entries.toList()
      ..sort((a, b) => b.value.pct().compareTo(a.value.pct()));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AdaptiveColors.surface(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Analyse par matière',
                  style: AppTextStyles.h3
                      .copyWith(color: AdaptiveColors.textPrimary(context))),
            ],
          ),
          const SizedBox(height: 16),
          if (entries.isEmpty)
            Text(
              'Pas de matière à analyser.',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AdaptiveColors.textSecondary(context)),
            )
          else
            ...entries.map((e) {
              final pct = e.value.pct();
              final color = _scoreColor(pct);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            e.key,
                            style: AppTextStyles.body
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text(
                          '${e.value.correctes}/${e.value.total} ($pct%)',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: pct / 100,
                        minHeight: 10,
                        backgroundColor:
                            AdaptiveColors.surfaceVariant(context),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildRecommandations() {
    // Liste des chapitres des questions ratées.
    final chapitresRates = <String>{};
    for (final q in _questions) {
      if (!_estCorrecte(q)) {
        chapitresRates.add(q.chapitre);
      }
    }
    final liste = chapitresRates.toList()..sort();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AdaptiveColors.accentSurface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accentLight.withOpacity(0.4), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline, color: AppColors.accent),
              const SizedBox(width: 8),
              Text('Recommandations',
                  style: AppTextStyles.h3.copyWith(color: AppColors.accent)),
            ],
          ),
          const SizedBox(height: 12),
          if (liste.isEmpty)
            Text(
              'Félicitations, aucune matière à revoir !',
              style: AppTextStyles.body.copyWith(color: AppColors.success),
            )
          else ...[
            Text(
              'Tu as besoin de réviser :',
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: liste.map((c) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AdaptiveColors.surfaceVariant(context),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.accentLight.withOpacity(0.6),
                    ),
                  ),
                  child: Text(
                    c,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.accent),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCorrectionsButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _ouvrirCorrections,
        icon: const Icon(Icons.menu_book_outlined, size: 20),
        label: const Text('Voir les corrections détaillées'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  void _ouvrirCorrections() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AdaptiveColors.background(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                children: [
                  // Poignée de drag
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AdaptiveColors.divider(context),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Corrections détaillées',
                          style: AppTextStyles.h2
                              .copyWith(color: AdaptiveColors.textPrimary(context))),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      itemCount: _questions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final q = _questions[i];
                        return _buildCorrectionCard(q, i);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCorrectionCard(Question q, int index) {
    final reponseEleve = _reponses[q.id]?.trim() ?? '';
    final correcte = _estCorrecte(q);
    final estAuto =
        q.type == QuestionType.qcm || q.type == QuestionType.vraiFaux;
    final color = correcte ? AppColors.success : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdaptiveColors.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  children: [
                    _buildChip(label: 'Q${index + 1}', color: AppColors.primary),
                    _buildChip(label: q.matiere, color: AppColors.info),
                    _buildChip(
                        label: _typeLabel(q.type),
                        color: AdaptiveColors.textSecondary(context)),
                  ],
                ),
              ),
              Icon(
                correcte ? Icons.check_circle : Icons.cancel,
                color: color,
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            q.enonce,
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          _buildLigneReponse(
            label: 'Ta réponse',
            value: reponseEleve.isEmpty ? '(sans réponse)' : reponseEleve,
            color: reponseEleve.isEmpty
                ? AdaptiveColors.textDisabled(context)
                : color,
          ),
          const SizedBox(height: 6),
          _buildLigneReponse(
            label: 'Bonne réponse',
            value: q.reponse,
            color: AppColors.success,
          ),
          if (q.explication != null && q.explication!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AdaptiveColors.primarySurface(context),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Explication',
                        style: AppTextStyles.label
                            .copyWith(color: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    q.explication!,
                    style: AppTextStyles.body.copyWith(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
          // Auto-évaluation pour les questions ouvertes/calcul/redaction.
          if (!estAuto) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AdaptiveColors.accentSurface(context),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Auto-évaluation',
                    style: AppTextStyles.label.copyWith(color: AppColors.accent),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Compare ta réponse à la bonne réponse puis évalue-toi.',
                    style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _setCorrectManuel(q.id, true),
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('J\'ai eu juste'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: correcte
                                ? AppColors.success
                                : AdaptiveColors.surface(context),
                            foregroundColor:
                                correcte ? Colors.white : AppColors.success,
                            elevation: correcte ? 2 : 0,
                            side: BorderSide(
                              color: correcte
                                  ? AppColors.success
                                  : AdaptiveColors.divider(context),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _setCorrectManuel(q.id, false),
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text('J\'ai eu faux'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: !correcte
                                ? AppColors.error
                                : AdaptiveColors.surface(context),
                            foregroundColor:
                                !correcte ? Colors.white : AppColors.error,
                            elevation: !correcte ? 2 : 0,
                            side: BorderSide(
                              color: !correcte
                                  ? AppColors.error
                                  : AdaptiveColors.divider(context),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLigneReponse({
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            '$label :',
            style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.body.copyWith(color: color),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _refaireExamen,
            icon: const Icon(Icons.refresh, size: 20),
            label: const Text('Refaire un examen'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.home_outlined, size: 20),
            label: const Text('Retour à l\'accueil'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              foregroundColor: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  void _refaireExamen() {
    setState(() {
      _phase = SimulationPhase.config;
      _questions = [];
      _indexCourant = 0;
      _reponses.clear();
      _marquees.clear();
      _correctManuel.clear();
      _tempsRestant = Duration.zero;
      _tempsTotalUtilise = Duration.zero;
    });
    _textController.clear();
  }
}

/// Statistiques par matière (helper interne au rapport).
class _MatiereStat {
  int total = 0;
  int correctes = 0;
  int pct() => total == 0 ? 0 : (correctes / total * 100).round();
}
