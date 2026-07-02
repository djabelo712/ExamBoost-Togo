// lib/screens/stats/competence_detail_screen.dart
// Page de détail d'une compétence — s'ouvre quand on tape une CompetenceCard.
//
// Route : /stats/competence/:competenceId
//
// Sections :
//   1. Header : nom du chapitre + competence ID + P(L) gauge circulaire + statut
//   2. 4 cards en row : questions répondues / taux réussite / temps moyen /
//      dernière révision
//   3. Historique des réponses (chronologique, X dernières entrées)
//   4. Questions disponibles pour cette compétence (liste)
//   5. Recommandation : "Pour maîtriser cette compétence, vise 10 questions
//      correctes consécutives. Tu en es à N."

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';

import '../../models/question.dart';
import '../../models/review_card.dart';
import '../../models/user.dart';
import '../../providers/user_provider.dart';
import '../../services/question_service.dart';
import '../../theme/app_theme.dart';
import 'services/subject_stats_service.dart';

class CompetenceDetailScreen extends StatefulWidget {
  final String competenceId;

  const CompetenceDetailScreen({
    super.key,
    required this.competenceId,
  });

  @override
  State<CompetenceDetailScreen> createState() =>
      _CompetenceDetailScreenState();
}

class _CompetenceDetailScreenState extends State<CompetenceDetailScreen> {
  final _service = SubjectStatsService();

  AppUser? _user;
  List<ReviewCard> _cards = const [];
  CompetenceStats? _stats;
  List<CompetenceHistoryEntry> _history = const [];
  List<Question> _questions = const [];
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

      List<ReviewCard> cards = [];
      try {
        final cardBox = Hive.isBoxOpen('review_cards')
            ? Hive.box<ReviewCard>('review_cards')
            : await Hive.openBox<ReviewCard>('review_cards');
        cards = cardBox.values
            .where((c) => c.userId == user!.id)
            .toList();
      } catch (_) {
        // Box non disponible — on continue
      }

      final qs = Provider.of<QuestionService>(context, listen: false);
      final stats = _service.computeCompetenceStats(
        competenceId: widget.competenceId,
        user: user!,
        questionService: qs,
        userCards: cards,
      );
      final history = _service.getCompetenceHistory(
        competenceId: widget.competenceId,
        questionService: qs,
        userCards: cards,
      );
      final questions = qs.getByCompetence(widget.competenceId);

      if (mounted) {
        setState(() {
          _user = user;
          _cards = cards;
          _stats = stats;
          _history = history;
          _questions = questions;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Impossible de charger la compétence : $e';
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
          _stats?.chapitre ?? 'Compétence',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          // Pas de route parente /stats :matiere connue, on revient au dashboard
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _stats == null
                  ? _buildNotFound()
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
                            _buildStatsRow(),
                            const SizedBox(height: 20),
                            _buildSectionRecommandation(),
                            const SizedBox(height: 20),
                            _buildSectionHistory(),
                            const SizedBox(height: 20),
                            _buildSectionQuestions(),
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
    final scoreColor = _couleurStatut(stats.statut);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Text(
            stats.chapitre,
            style: AppTextStyles.h1.copyWith(fontSize: 22),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            stats.competenceId,
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 11,
              color: AppColors.textDisabled,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 16),
          CircularPercentIndicator(
            radius: 70,
            lineWidth: 12,
            percent: stats.pL.clamp(0.0, 1.0),
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${stats.pLPourcent}%',
                  style: AppTextStyles.h1.copyWith(
                    color: scoreColor,
                    fontSize: 26,
                  ),
                ),
                Text(
                  'P(L)',
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
          _buildStatutBadge(stats.statut, scoreColor),
        ],
      ),
    );
  }

  Widget _buildStatutBadge(String statut, Color couleur) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: couleur.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: couleur.withOpacity(0.3), width: 1),
      ),
      child: Text(
        statut,
        style: AppTextStyles.label.copyWith(
          color: couleur,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ─── 2. 4 Stats cards en row ─────────────────────────────────
  Widget _buildStatsRow() {
    final stats = _stats!;
    return Row(
      children: [
        Expanded(
          child: _buildMiniStat(
            icon: Icons.question_answer_outlined,
            value: stats.questionsRepondues.toString(),
            label: 'Questions\nrépondues',
            color: AppColors.info,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMiniStat(
            icon: Icons.check_circle_outline,
            value: '${stats.tauxReussitePourcent}%',
            label: 'Taux\nréussite',
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMiniStat(
            icon: Icons.timer_outlined,
            value: '${stats.tempsMoyenSecondes}s',
            label: 'Temps\nmoyen',
            color: AppColors.accent,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMiniStat(
            icon: Icons.history,
            value: _formatDerniereRevisionCourt(stats.derniereRevision),
            label: 'Dernière\nrévision',
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStat({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: AppTextStyles.h3.copyWith(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 9,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  // ─── 3. Section Recommandation ───────────────────────────────
  Widget _buildSectionRecommandation() {
    final stats = _stats!;
    final consecutive = stats.reponsesCorrectesConsecutives;
    final objectif = 10;
    final reste = (objectif - consecutive).clamp(1, objectif);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accentSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.accent.withOpacity(0.3),
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.flag,
              color: AppColors.accent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Objectif maîtrise',
                  style: AppTextStyles.h3.copyWith(
                    fontSize: 14,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pour maîtriser cette compétence, vise $objectif questions '
                  'correctes consécutives. Tu en es à $consecutive.',
                  style: AppTextStyles.bodySmall.copyWith(
                    height: 1.4,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: (consecutive / objectif).clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: AppColors.accent.withOpacity(0.15),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.accent),
                ),
                const SizedBox(height: 6),
                Text(
                  'Encore $reste question${reste > 1 ? "s" : ""} pour atteindre l\'objectif.',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── 4. Section Historique ───────────────────────────────────
  Widget _buildSectionHistory() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history, color: AppColors.primary, size: 20),
              const SizedBox(width: 6),
              Text('Historique des réponses', style: AppTextStyles.h3),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Tes dernières interactions avec les questions de cette compétence.',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 14),
          if (_history.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Aucune réponse enregistrée pour cette compétence.',
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
              itemCount: _history.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final entry = _history[i];
                return _buildHistoryEntry(entry);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildHistoryEntry(CompetenceHistoryEntry entry) {
    final qualite = entry.qualiteSm2;
    final qualiteCouleur = _couleurQualite(qualite);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Icône correct / incorrect ──────────────────────
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: (entry.correct ? AppColors.success : AppColors.error)
                  .withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              entry.correct ? Icons.check : Icons.close,
              color: entry.correct ? AppColors.success : AppColors.error,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          // ─── Date + extrait énoncé ──────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDateTime(entry.date),
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  entry.extraitEnonce,
                  style: AppTextStyles.body.copyWith(fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // ─── Qualité SM-2 ───────────────────────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: qualiteCouleur.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'q=$qualite',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: qualiteCouleur,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${entry.tempsPasseSecondes}s',
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── 5. Section Questions disponibles ────────────────────────
  Widget _buildSectionQuestions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.quiz, color: AppColors.primary, size: 20),
              const SizedBox(width: 6),
              Text('Questions de cette compétence',
                  style: AppTextStyles.h3),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Toutes les questions disponibles pour "${_stats!.chapitre}".',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 14),
          if (_questions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Aucune question disponible pour cette compétence.',
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
              itemCount: _questions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                return _buildQuestionItem(_questions[i]);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildQuestionItem(Question q) {
    final diff = q.difficulte;
    final diffLabel = diff == DifficulteNiveau.facile
        ? 'Facile'
        : (diff == DifficulteNiveau.moyen ? 'Moyen' : 'Difficile');
    final diffCouleur = diff == DifficulteNiveau.facile
        ? AppColors.facile
        : (diff == DifficulteNiveau.moyen
            ? AppColors.moyen
            : AppColors.difficile);

    // Statut élève : répondu X fois / réussi Y%
    final card = _cards.firstWhere(
      (c) => c.questionId == q.id,
      orElse: () => ReviewCard(userId: '', questionId: q.id),
    );
    final aEteRepondu = card.totalAttempts > 0;
    final tentativeTexte = aEteRepondu
        ? 'Répondu ${card.totalAttempts} fois — '
            '${(card.successRate * 100).round()}% de réussite'
        : 'Pas encore répondue';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // ─── Difficulté ─────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: diffCouleur.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  diffLabel,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: diffCouleur,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // ─── Année + examen ─────────────────────────────
              if (q.annee != null) ...[
                Text(
                  '${q.annee}',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                q.examen,
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              // ─── Bouton réviser ─────────────────────────────
              IconButton(
                onPressed: () => context.go(
                  '/revision/${Uri.encodeComponent(q.matiere)}',
                ),
                icon: const Icon(Icons.play_arrow,
                    color: AppColors.primary, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
                tooltip: 'Réviser cette question',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            q.enonce,
            style: AppTextStyles.body.copyWith(fontSize: 13),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            tentativeTexte,
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: aEteRepondu
                  ? AppColors.textSecondary
                  : AppColors.textDisabled,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Not found ───────────────────────────────────────────────
  Widget _buildNotFound() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off,
                size: 64, color: AppColors.textDisabled),
            const SizedBox(height: 16),
            Text(
              'Compétence introuvable',
              style: AppTextStyles.h2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Aucune question n\'existe pour l\'identifiant '
              '${widget.competenceId}.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => context.go('/dashboard'),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Retour au tableau de bord'),
            ),
          ],
        ),
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

  // ─── Helpers couleur / formatage ─────────────────────────────
  Color _couleurStatut(String statut) {
    switch (statut) {
      case 'Maîtrisée':
        return AppColors.success;
      case 'En cours':
        return AppColors.warning;
      case 'Fragile':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _couleurQualite(int q) {
    if (q >= 5) return AppColors.success;
    if (q >= 3) return AppColors.primary;
    if (q >= 1) return AppColors.warning;
    return AppColors.error;
  }

  String _formatDateTime(DateTime d) {
    const months = [
      'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
      'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
    ];
    final m = months[d.month - 1];
    final h = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '${d.day} $m ${d.year} à ${h}h${min}';
  }

  String _formatDerniereRevisionCourt(DateTime? date) {
    if (date == null) return 'N/A';
    final maintenant = DateTime.now();
    final diff = maintenant.difference(date);
    if (diff.inHours < 1) return '<1h';
    if (diff.inHours < 24) return '${diff.inHours}h';
    final jours = diff.inDays;
    if (jours == 0) return 'Auj.';
    if (jours == 1) return 'Hier';
    if (jours < 30) return '${jours}j';
    if (jours < 365) return '${(jours / 30).floor()}mo';
    return '>1an';
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
