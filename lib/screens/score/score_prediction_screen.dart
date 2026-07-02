// lib/screens/score/score_prediction_screen.dart
// Page principale de prédiction du score officiel BEPC/BAC.
//
// C'est le differenciateur #1 d'ExamBoost vs Khan Academy / Afrilearn :
//   - Score predit sur 20 (echelle officielle togolaise)
//   - Pondere par les coefficients officiels MEPST
//   - Aligne sur le programme du Togo, pas generique
//
// Sections affichees (SingleChildScrollView) :
//   1. Header : titre "Prediction score [BEPC/BAC serie X]"
//   2. Jauge circulaire geante (ScoreGauge) + confiance + couverture
//   3. Carte recommandation pedagogique contextuelle
//   4. Subject breakdown (liste cartes par matiere, ordonne par coef desc)
//   5. Tableau coefficients officiels MEPST
//   6. Chart evolution score predit sur 3 mois
//   7. Actions : Refaire simulation / Voir chapitres faibles / Partager
//
// Donnees :
//   - AppUser courant via UserProvider
//   - ScorePrediction via ScorePredictor.instance.predictForUser()
//   - Historique via ScorePredictor.instance.getHistory()

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/score_prediction.dart';
import '../../models/user.dart';
import '../../providers/user_provider.dart';
import '../../services/score_predictor.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_router.dart';
import 'widgets/coefficient_table.dart';
import 'widgets/score_gauge.dart';
import 'widgets/score_history_chart.dart';
import 'widgets/subject_breakdown_card.dart';

class ScorePredictionScreen extends StatefulWidget {
  /// Si fournie, evite le recalcul au demarrage (depuis Dashboard).
  final ScorePrediction? initialPrediction;

  const ScorePredictionScreen({super.key, this.initialPrediction});

  @override
  State<ScorePredictionScreen> createState() =>
      _ScorePredictionScreenState();
}

class _ScorePredictionScreenState extends State<ScorePredictionScreen> {
  ScorePrediction? _prediction;
  List<ScorePrediction> _history = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Si on recoit une prediction initiale, on l'affiche immediatement
    // et on charge l'historique en arriere-plan.
    if (widget.initialPrediction != null) {
      _prediction = widget.initialPrediction;
      _loading = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadHistory());
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
    }
  }

  // ─── Chargement prediction + historique ──────────────────────────
  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final userProvider = Provider.of<UserProvider>(
        context,
        listen: false,
      );
      final user = userProvider.currentUser ?? _fallbackUser();
      final predictor = ScorePredictor.instance;
      final prediction = await predictor.predictForUser(user, force: true);
      final history = await predictor.getHistory(user.id);
      if (mounted) {
        setState(() {
          _prediction = prediction;
          _history = history;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Impossible de calculer la prediction : $e';
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadHistory() async {
    try {
      final userProvider = Provider.of<UserProvider>(
        context,
        listen: false,
      );
      final user = userProvider.currentUser ?? _fallbackUser();
      final history = await ScorePredictor.instance.getHistory(user.id);
      if (mounted) {
        setState(() => _history = history);
      }
    } catch (_) {
      // silently ignore — l'historique est optionnel
    }
  }

  AppUser _fallbackUser() {
    return AppUser(
      id: 'user_demo',
      nom: 'Eleve',
      prenom: 'Eleve',
      niveauScolaire: '3eme',
      dateInscription: DateTime.now(),
    );
  }

  // ─── Build ───────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Score officiel'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recalculer',
            onPressed: _loading ? null : _loadAll,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _buildErrorState();
    }
    if (_prediction == null) {
      return _buildEmptyState();
    }
    return RefreshIndicator(
      onRefresh: _loadAll,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildGaugeSection(),
            const SizedBox(height: 20),
            _buildRecommendationCard(),
            const SizedBox(height: 20),
            _buildSectionTitle(
              'Detail par matiere',
              Icons.list_alt,
            ),
            const SizedBox(height: 8),
            ..._buildSubjectBreakdown(),
            const SizedBox(height: 20),
            _buildSectionTitle(
              'Coefficients officiels',
              Icons.table_chart,
            ),
            const SizedBox(height: 8),
            CoefficientTable(prediction: _prediction!),
            const SizedBox(height: 20),
            _buildSectionTitle(
              'Evolution du score',
              Icons.insights,
            ),
            const SizedBox(height: 8),
            ScoreHistoryChart(history: _history),
            const SizedBox(height: 24),
            _buildActions(),
            const SizedBox(height: 16),
            _buildSourceNote(),
          ],
        ),
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────────────
  Widget _buildHeader() {
    final label = _prediction!.examen == 'BEPC'
        ? 'BEPC'
        : _prediction!.serie != null
            ? 'BAC serie ${_prediction!.serie}'
            : _prediction!.examen;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Prediction score $label',
          style: AppTextStyles.h2.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Base sur ton BKT et les coefficients MEPST officiels',
          style: AppTextStyles.bodySmall,
        ),
      ],
    );
  }

  // ─── Section Jauge + confiance + couverture ──────────────────────
  Widget _buildGaugeSection() {
    final pred = _prediction!;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Center(child: ScoreGauge(prediction: pred)),
            const SizedBox(height: 20),
            // Confiance + couverture
            Row(
              children: [
                Expanded(child: _buildConfidenceChip(pred)),
                const SizedBox(width: 10),
                Expanded(child: _buildCoverageChip(pred)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfidenceChip(ScorePrediction pred) {
    final color = pred.confidence < 0.3
        ? AppColors.error
        : pred.confidence < 0.7
            ? AppColors.warning
            : AppColors.success;
    final icon = pred.confidence < 0.3
        ? Icons.shield
        : pred.confidence < 0.7
            ? Icons.shield
            : Icons.verified_user;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Confiance',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  pred.confidenceLabel,
                  style: AppTextStyles.label.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverageChip(ScorePrediction pred) {
    final coveragePercent = (pred.coverageRate * 100).round();
    final color = pred.coverageRate < 0.3
        ? AppColors.error
        : pred.coverageRate < 0.7
            ? AppColors.warning
            : AppColors.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.school, color: color, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Couverture',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '$coveragePercent % du programme',
                  style: AppTextStyles.label.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Carte recommandation ────────────────────────────────────────
  Widget _buildRecommendationCard() {
    final pred = _prediction!;
    final color = _recommendationColor(pred.scoreGlobal, pred.coverageRate);
    final icon = _recommendationIcon(pred.scoreGlobal, pred.coverageRate);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25), width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recommandation',
                  style: AppTextStyles.label.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  pred.recommendation,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _recommendationColor(double score, double coverage) {
    if (coverage < 0.3) return AppColors.info;
    if (score < 8) return AppColors.error;
    if (score < 10) return AppColors.warning;
    if (score < 12) return AppColors.accent;
    if (score < 14) return AppColors.primaryLight;
    return AppColors.success;
  }

  IconData _recommendationIcon(double score, double coverage) {
    if (coverage < 0.3) return Icons.info_outline;
    if (score < 10) return Icons.warning_amber_rounded;
    if (score < 12) return Icons.trending_up;
    return Icons.emoji_events;
  }

  // ─── Section title ───────────────────────────────────────────────
  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTextStyles.h3.copyWith(fontSize: 16),
        ),
      ],
    );
  }

  // ─── Subject breakdown ───────────────────────────────────────────
  List<Widget> _buildSubjectBreakdown() {
    final subjects = _prediction!.subjectsSortedByCoefDesc;
    return subjects.map((s) {
      return SubjectBreakdownCard(
        subject: s,
        onTap: () => _navigateToRevision(s.matiere),
      );
    }).toList();
  }

  void _navigateToRevision(String matiere) {
    // Navigation vers la page de revision de la matiere
    // (route existante : /revision/:matiere)
    context.go(
      '${AppRoutes.revision}/${Uri.encodeComponent(matiere)}',
    );
  }

  // ─── Actions ─────────────────────────────────────────────────────
  Widget _buildActions() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.go(AppRoutes.simulation),
                icon: const Icon(Icons.timer, size: 18),
                label: const Text('Refaire une simulation'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.go(AppRoutes.dashboard),
                icon: const Icon(Icons.dashboard_outlined, size: 18),
                label: const Text('Voir mes chapitres faibles'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _sharePrediction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.share_outlined, size: 18),
                label: const Text('Partager ma prediction'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _sharePrediction() {
    // UI only — pas de partage reel dans cette version
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Partage bientot disponible !'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ─── Note de source ──────────────────────────────────────────────
  Widget _buildSourceNote() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline,
              size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Coefficients bases sur la pratique commune BEPC/BAC '
              'Afrique francophone. A valider avec le MEPST officiellement.',
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Etats speciaux ──────────────────────────────────────────────
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAll,
              child: const Text('Reessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.school_outlined,
                size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              'Aucune prediction disponible',
              style: AppTextStyles.h3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Commence a reviser pour generer ton score predit.',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Aller a l\'accueil'),
            ),
          ],
        ),
      ),
    );
  }
}
