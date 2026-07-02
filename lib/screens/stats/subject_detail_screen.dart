// lib/screens/stats/subject_detail_screen.dart
// Page de détail d'une matière — s'ouvre quand on tape sur une matière dans le dashboard.
//
// Route : /stats/:matiere (path param URL-encoded, ex : /stats/Math%C3%A9matiques)
//
// 6 sections :
//   1. Header : nom matière + P(L) global (cercle) + stats rapides + actions
//   2. Vue d'ensemble (Radar Chart) — MasteryRadarChart
//   3. Liste des compétences (CompetenceCard × N, triée par P(L) ascendant)
//   4. Recommandations automatiques (3 RecommendationCard)
//   5. Comparaison vs classe (anonymisée) — ComparisonChart
//   6. Timeline activité (30 derniers jours) — SubjectTimeline
//   7. Actions : Réviser points faibles / Simulation / Exporter JSON
//
// Données : AppUser via UserProvider + ReviewCards (Hive box "review_cards")
// Service : SubjectStatsService (computeSubjectStats / getTimeline30Jours /
//          getClassroomComparison).

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';

import '../../models/review_card.dart';
import '../../models/user.dart';
import '../../providers/user_provider.dart';
import '../../services/question_service.dart';
import '../../theme/app_theme.dart';
import 'services/subject_stats_service.dart';
import 'widgets/competence_card.dart';
import 'widgets/comparison_chart.dart';
import 'widgets/mastery_radar_chart.dart';
import 'widgets/recommendation_card.dart';
import 'widgets/subject_timeline.dart';

class SubjectDetailScreen extends StatefulWidget {
  final String matiere;

  const SubjectDetailScreen({super.key, required this.matiere});

  @override
  State<SubjectDetailScreen> createState() => _SubjectDetailScreenState();
}

class _SubjectDetailScreenState extends State<SubjectDetailScreen> {
  final _service = SubjectStatsService();

  AppUser? _user;
  List<ReviewCard> _cards = const [];
  SubjectStats? _stats;
  List<DayActivity> _timeline = const [];
  ClassroomComparison? _comparison;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  // ─── Chargement ──────────────────────────────────────────────
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
      AppUser? user = userProvider.currentUser;
      // Fallback : charger depuis Hive box "users" avec userId démo
      if (user == null) {
        try {
          final userBox = Hive.isBoxOpen('users')
              ? Hive.box<AppUser>('users')
              : await Hive.openBox<AppUser>('users');
          user = userBox.get(userProvider.currentUserId) ??
              AppUser(
                id: userProvider.currentUserId,
                nom: 'Élève',
                prenom: 'Élève',
                niveauScolaire: '3eme',
                dateInscription: DateTime.now(),
              );
        } catch (_) {
          user = AppUser(
            id: userProvider.currentUserId,
            nom: 'Élève',
            prenom: 'Élève',
            niveauScolaire: '3eme',
            dateInscription: DateTime.now(),
          );
        }
      }

      // Charger ReviewCards de l'utilisateur
      List<ReviewCard> cards = [];
      try {
        final cardBox = Hive.isBoxOpen('review_cards')
            ? Hive.box<ReviewCard>('review_cards')
            : await Hive.openBox<ReviewCard>('review_cards');
        cards = cardBox.values
            .where((c) => c.userId == user!.id)
            .toList();
      } catch (_) {
        // Box non ouverte / adaptateur non enregistré — on continue avec cartes vides
      }

      final qs = Provider.of<QuestionService>(context, listen: false);
      final stats = _service.computeSubjectStats(
        matiere: widget.matiere,
        user: user!,
        questionService: qs,
        userCards: cards,
      );
      final timeline = _service.getTimeline30Jours(cards);
      final comparison =
          _service.getClassroomComparison(stats.pLMoyen);

      if (mounted) {
        setState(() {
          _user = user;
          _cards = cards;
          _stats = stats;
          _timeline = timeline;
          _comparison = comparison;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Impossible de charger les statistiques : $e';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.matiere,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _loadAll,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 20),
                        _buildSectionRadar(),
                        const SizedBox(height: 20),
                        _buildSectionCompetences(),
                        const SizedBox(height: 20),
                        _buildSectionRecommandations(),
                        const SizedBox(height: 20),
                        _buildSectionComparison(),
                        const SizedBox(height: 20),
                        _buildSectionTimeline(),
                        const SizedBox(height: 20),
                        _buildSectionActions(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
    );
  }

  // ─── 1. Header ───────────────────────────────────────────────
  Widget _buildHeader() {
    final stats = _stats!;
    final scoreColor = _scoreColor(stats.pLMoyen * 100);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Text(
            widget.matiere,
            style: AppTextStyles.h1.copyWith(fontSize: 24),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          CircularPercentIndicator(
            radius: 64,
            lineWidth: 11,
            percent: stats.pLMoyen.clamp(0.0, 1.0),
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${stats.pLMoyenPourcent}%',
                  style: AppTextStyles.h1.copyWith(
                    color: scoreColor,
                    fontSize: 24,
                  ),
                ),
                Text(
                  'maîtrise',
                  style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
                ),
              ],
            ),
            progressColor: scoreColor,
            backgroundColor: scoreColor.withOpacity(0.12),
            circularStrokeCap: CircularStrokeCap.round,
            animation: true,
            animationDuration: 800,
          ),
          const SizedBox(height: 14),
          // Stats rapides : X suivies / Y maîtrisées / Z en apprentissage
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(
                value: stats.competencesSuivies.toString(),
                label: 'Compétences\nsuivies',
                color: AppColors.info,
              ),
              _buildStatItem(
                value: stats.competencesMaitrisees.toString(),
                label: 'Compétences\nmaîtrisées',
                color: AppColors.success,
              ),
              _buildStatItem(
                value: stats.competencesEnApprentissage.toString(),
                label: 'En\napprentissage',
                color: AppColors.warning,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Boutons d'action principaux
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.go(
                    '/revision/${Uri.encodeComponent(widget.matiere)}',
                  ),
                  icon: const Icon(Icons.menu_book, size: 18),
                  label: const Text('Réviser'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.go(
                    '/simulation',
                    extra: {'examen': 'BEPC', 'serie': null},
                  ),
                  icon: const Icon(Icons.timer, size: 18),
                  label: const Text('Simulation'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: AppColors.accent, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.h2.copyWith(
            color: color,
            fontSize: 22,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall.copyWith(
            fontSize: 10,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  // ─── 2. Section Radar ────────────────────────────────────────
  Widget _buildSectionRadar() {
    final stats = _stats!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.radar, color: AppColors.primary, size: 20),
              const SizedBox(width: 6),
              Text('Vue d\'ensemble', style: AppTextStyles.h3),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Maîtrise par chapitre (P(L) en %) — plus la surface est grande, plus tu maîtrises la matière.',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 12),
          MasteryRadarChart(competences: stats.competences),
        ],
      ),
    );
  }

  // ─── 3. Section Compétences ──────────────────────────────────
  Widget _buildSectionCompetences() {
    final stats = _stats!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.list_alt, color: AppColors.primary, size: 20),
              const SizedBox(width: 6),
              Text('Compétences', style: AppTextStyles.h3),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Triées par P(L) ascendant (les plus fragiles en premier). '
            'Tape une carte pour voir le détail.',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 14),
          if (stats.competences.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Aucune compétence disponible pour ${widget.matiere}.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: stats.competences.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final c = stats.competences[i];
                return CompetenceCard(
                  stats: c,
                  userId: _user?.id ?? 'user_demo',
                );
              },
            ),
        ],
      ),
    );
  }

  // ─── 4. Section Recommandations ──────────────────────────────
  Widget _buildSectionRecommandations() {
    final stats = _stats!;
    final recos = stats.recommandations;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome,
                  color: AppColors.accent, size: 20),
              const SizedBox(width: 6),
              Text('Recommandations', style: AppTextStyles.h3),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Suggestions personnalisées basées sur tes performances.',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 14),
          if (recos.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'Commence à réviser pour recevoir des recommandations.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recos.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                return RecommendationCard(
                  recommendation: recos[i],
                  userId: _user?.id ?? 'user_demo',
                );
              },
            ),
        ],
      ),
    );
  }

  // ─── 5. Section Comparaison vs classe ────────────────────────
  Widget _buildSectionComparison() {
    final comparison = _comparison!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.leaderboard,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 6),
              Text('Comparaison vs classe', style: AppTextStyles.h3),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Ta position par rapport aux autres élèves (données anonymes).',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 16),
          ComparisonChart(comparison: comparison),
        ],
      ),
    );
  }

  // ─── 6. Section Timeline 30 jours ────────────────────────────
  Widget _buildSectionTimeline() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_view_month,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 6),
              Text('Activité (30 derniers jours)', style: AppTextStyles.h3),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Questions répondues dans cette matière, jour par jour.',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 16),
          SubjectTimeline(activities: _timeline),
        ],
      ),
    );
  }

  // ─── 7. Section Actions ──────────────────────────────────────
  Widget _buildSectionActions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt, color: AppColors.accent, size: 20),
              const SizedBox(width: 6),
              Text('Actions', style: AppTextStyles.h3),
            ],
          ),
          const SizedBox(height: 14),
          // ─── Réviser points faibles ─────────────────────────
          _buildActionTile(
            icon: Icons.priority_high,
            color: AppColors.error,
            titre: 'Réviser mes points faibles',
            description:
                'Génère une session SRS ciblée sur les compétences '
                'avec P(L) < 0.5 dans cette matière.',
            onTap: () => context.go(
              '/revision/${Uri.encodeComponent(widget.matiere)}',
            ),
          ),
          const SizedBox(height: 10),
          // ─── Simulation matière ─────────────────────────────
          _buildActionTile(
            icon: Icons.timer,
            color: AppColors.accent,
            titre: 'Simulation sur cette matière',
            description:
                'Lance un examen blanc chronométré uniquement sur '
                '${widget.matiere}.',
            onTap: () => context.go(
              '/simulation',
              extra: {'examen': 'BEPC', 'serie': null},
            ),
          ),
          const SizedBox(height: 10),
          // ─── Exporter JSON ──────────────────────────────────
          _buildActionTile(
            icon: Icons.download,
            color: AppColors.info,
            titre: 'Exporter mes progrès',
            description:
                'Télécharge un récapitulatif JSON de tes statistiques '
                'pour cette matière.',
            onTap: _exporterJson,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color color,
    required String titre,
    required String description,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titre,
                      style: AppTextStyles.h3.copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: color, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Export JSON (dialog avec contenu sélectionnable) ────────
  void _exporterJson() {
    final stats = _stats!;
    final user = _user;
    final data = {
      'matiere': widget.matiere,
      'eleve': {
        'id': user?.id,
        'nom': user?.nomComplet,
      },
      'exporteLe': DateTime.now().toIso8601String(),
      'resume': {
        'pL_moyen': stats.pLMoyen,
        'pL_moyen_pourcent': stats.pLMoyenPourcent,
        'competences_suivies': stats.competencesSuivies,
        'competences_maitrisees': stats.competencesMaitrisees,
        'competences_en_apprentissage': stats.competencesEnApprentissage,
      },
      'competences': stats.competences
          .map((c) => {
                'competence_id': c.competenceId,
                'chapitre': c.chapitre,
                'pL': c.pL,
                'pL_pourcent': c.pLPourcent,
                'statut': c.statut,
                'questions_total': c.questionsTotal,
                'questions_repondues': c.questionsRepondues,
                'taux_reussite': c.tauxReussite,
                'taux_reussite_pourcent': c.tauxReussitePourcent,
                'temps_moyen_secondes': c.tempsMoyenSecondes,
                'derniere_revision':
                    c.derniereRevision?.toIso8601String(),
              })
          .toList(),
      'activite_30_jours': _timeline
          .map((d) => {
                'date':
                    '${d.date.year}-${d.date.month.toString().padLeft(2, '0')}-${d.date.day.toString().padLeft(2, '0')}',
                'questions_repondues': d.questionsRepondues,
              })
          .toList(),
    };

    final jsonStr = const JsonEncoder.withIndent('  ').convert(data);

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.download, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Export JSON — ${widget.matiere}',
                style: AppTextStyles.h3,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(
              jsonStr,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  // ─── Erreur ──────────────────────────────────────────────────
  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadAll,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────
  Color _scoreColor(double score) {
    if (score < 40) return AppColors.error;
    if (score <= 70) return AppColors.warning;
    return AppColors.success;
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      );
}
