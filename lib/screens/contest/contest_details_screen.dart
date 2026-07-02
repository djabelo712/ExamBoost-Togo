// lib/screens/contest/contest_details_screen.dart
// Ecran : detail d'un concours (en cours ou passe).
//
// Affiche :
//   - Header thematique (titre, matiere, dates, statut).
//   - Progression collective (ContestProgressWidget) si enCours.
//   - Regles de points (4 lignes : question / simulation / badge / streak).
//   - Recompenses possibles (liste a puces).
//   - Top 10 ecoles actuelles (si enCours) ou podium final (si termine).
//   - Liste des contributions recentes de l'eleve (si enCours).
//
// Si le concours est termine, on affiche en plus l'ecole gagnante et les
// trophees distribues (or / argent / bronze).
//
// Le service et l'id du concours sont passes en parametre depuis
// ContestHomeScreen (concours en cours) ou ContestHistoryScreen
// (concours passe).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_theme.dart';
import 'models/contest.dart';
import 'models/contest_contribution.dart';
import 'models/school_ranking.dart';
import 'services/contest_service.dart';
import 'widgets/contest_progress_widget.dart';
import 'widgets/school_ranking_card.dart';

class ContestDetailsScreen extends StatelessWidget {
  final ContestService service;
  final String contestId;

  const ContestDetailsScreen({
    super.key,
    required this.service,
    required this.contestId,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: service,
      child: _DetailsView(contestId: contestId),
    );
  }
}

class _DetailsView extends StatelessWidget {
  final String contestId;
  const _DetailsView({required this.contestId});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<ContestService>();

    // Recupere le concours : soit le courant, soit un passe par id.
    final current = service.currentContest;
    Contest? contest = current;
    if (current == null || current.id != contestId) {
      contest = service.getPastContestById(contestId);
    }

    if (contest == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Concours introuvable')),
        body: Center(
          child: Text(
            'Ce concours est introuvable.',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final isEnCours = contest.status == ContestStatus.enCours;
    final top10 = isEnCours ? service.getRanking(limit: 10) : <SchoolRanking>[];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ─── AppBar sliver avec header thematique ──────────────
          _buildSliverHeader(contest),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Description ────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Text(
                    contest.description,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),

                // ─── Progression collective (si enCours) ────────
                if (isEnCours) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ContestProgressWidget(contest: contest),
                  ),
                ],

                // ─── Ecole gagnante (si termine) ────────────────
                if (!isEnCours && contest.ecoleGagnanteNom != null) ...[
                  const SizedBox(height: 12),
                  _buildWinnerCard(contest),
                ],

                // ─── Regles de points ───────────────────────────
                const SizedBox(height: 16),
                _buildSectionTitle('Regles des points'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildPointsRules(),
                ),

                // ─── Recompenses ────────────────────────────────
                const SizedBox(height: 16),
                _buildSectionTitle('Recompenses'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildRewardsList(contest.recompenses),
                ),

                // ─── Top 10 ecoles (si enCours) ─────────────────
                if (isEnCours) ...[
                  const SizedBox(height: 16),
                  _buildSectionTitle('Top 10 ecoles actuelles'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: top10.map((s) => SchoolRankingCard(ecole: s)).toList(),
                    ),
                  ),
                ],

                // ─── Trophees distribues (si termine) ───────────
                if (!isEnCours && contest.trophees.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildSectionTitle('Trophees distribues'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildTrophiesList(contest),
                  ),
                ],

                // ─── Contributions recentes (si enCours) ────────
                if (isEnCours && service.myContribution != null) ...[
                  const SizedBox(height: 16),
                  _buildSectionTitle('Mes contributions recentes'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildRecentContributions(
                      service.myContribution!.recentes,
                    ),
                  ),
                ],

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Sliver header avec degrade ──────────────────────────────────

  Widget _buildSliverHeader(Contest contest) {
    final statusColor =
        contest.status == ContestStatus.enCours
            ? AppColors.accent
            : contest.status == ContestStatus.termine
            ? AppColors.textSecondary
            : AppColors.info;
    final statusLabel =
        contest.status == ContestStatus.enCours
            ? 'EN COURS'
            : contest.status == ContestStatus.termine
            ? 'TERMINE'
            : 'A VENIR';

    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor, width: 1),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                contest.titre,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.menu_book_outlined,
                    size: 14,
                    color: Colors.white.withOpacity(0.85),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    contest.matiere,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 12,
                    color: Colors.white.withOpacity(0.85),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatPeriode(contest.dateDebut, contest.dateFin),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Carte ecole gagnante (concours termine) ─────────────────────

  Widget _buildWinnerCard(Contest contest) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFFFFB300), const Color(0xFFFF8F00)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFB300).withOpacity(0.30),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.emoji_events,
            color: Colors.white,
            size: 36,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Ecole gagnante',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  contest.ecoleGagnanteNom ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Points',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${contest.pointsActuels}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Titre de section ────────────────────────────────────────────

  Widget _buildSectionTitle(String titre) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Text(
        titre,
        style: AppTextStyles.body.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  // ─── Regles des points ───────────────────────────────────────────

  Widget _buildPointsRules() {
    const rules = <_PointRule>[
      _PointRule(
        icon: Icons.check_circle_outline,
        label: 'Question correcte',
        detail: 'Reponse validee en revision',
        points: 10,
        color: AppColors.info,
      ),
      _PointRule(
        icon: Icons.assignment_turned_in_outlined,
        label: 'Simulation reussie',
        detail: 'Note > 10/20 a une simulation d\'examen',
        points: 50,
        color: AppColors.success,
      ),
      _PointRule(
        icon: Icons.verified_outlined,
        label: 'Badge debloque',
        detail: 'Nouveau badge decroche',
        points: 100,
        color: AppColors.accent,
      ),
      _PointRule(
        icon: Icons.local_fire_department_outlined,
        label: 'Streak 7 jours',
        detail: '7 jours consecutifs de revision',
        points: 200,
        color: AppColors.error,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Column(
        children: rules.map((r) => _PointRuleTile(rule: r)).toList(),
      ),
    );
  }

  // ─── Liste des recompenses ───────────────────────────────────────

  Widget _buildRewardsList(List<String> recompenses) {
    if (recompenses.isEmpty) {
      return Text(
        'Aucune recompense definie.',
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textSecondary,
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.accentSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.accent.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children:
            recompenses
                .map(
                  (r) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.card_giftcard,
                          size: 14,
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            r,
                            style: AppTextStyles.body.copyWith(
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
      ),
    );
  }

  // ─── Trophees distribues (concours termine) ──────────────────────

  Widget _buildTrophiesList(Contest contest) {
    return Row(
      children: contest.trophees.map((t) {
        final color = _tierColor(t.tier);
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.4), width: 1),
            ),
            child: Column(
              children: [
                Icon(Icons.emoji_events, size: 24, color: color),
                const SizedBox(height: 4),
                Text(
                  _tierLabel(t.tier),
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${t.pointsEcole} pts',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── Contributions recentes ──────────────────────────────────────

  Widget _buildRecentContributions(List<ContestContribution> recentes) {
    if (recentes.isEmpty) {
      return Text(
        'Aucune contribution pour le moment.',
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textSecondary,
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Column(
        children: [
          for (int i = 0; i < recentes.length; i++) ...[
            _ContributionTile(contribution: recentes[i]),
            if (i < recentes.length - 1)
              const Divider(height: 1, indent: 12, endIndent: 12),
          ],
        ],
      ),
    );
  }

  // ─── Utilitaires ─────────────────────────────────────────────────

  static Color _tierColor(TrophyTier tier) {
    switch (tier) {
      case TrophyTier.or:
        return const Color(0xFFFFB300);
      case TrophyTier.argent:
        return const Color(0xFF78909C);
      case TrophyTier.bronze:
        return const Color(0xFFB8693B);
    }
  }

  static String _tierLabel(TrophyTier tier) {
    switch (tier) {
      case TrophyTier.or:
        return 'Or';
      case TrophyTier.argent:
        return 'Argent';
      case TrophyTier.bronze:
        return 'Bronze';
    }
  }

  static String _formatPeriode(DateTime debut, DateTime fin) {
    const mois = [
      '', 'jan', 'fev', 'mar', 'avr', 'mai', 'jun',
      'jul', 'aou', 'sep', 'oct', 'nov', 'dec',
    ];
    if (debut.month == fin.month) {
      return '${debut.day}-${fin.day} ${mois[debut.month]} ${debut.year}';
    }
    return '${debut.day} ${mois[debut.month]} - '
        '${fin.day} ${mois[fin.month]} ${fin.year}';
  }
}

// ─── Modeles internes pour les regles de points ──────────────────────

class _PointRule {
  final IconData icon;
  final String label;
  final String detail;
  final int points;
  final Color color;
  const _PointRule({
    required this.icon,
    required this.label,
    required this.detail,
    required this.points,
    required this.color,
  });
}

class _PointRuleTile extends StatelessWidget {
  final _PointRule rule;
  const _PointRuleTile({required this.rule});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: rule.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(rule.icon, size: 18, color: rule.color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  rule.label,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  rule.detail,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: rule.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '+${rule.points}',
              style: TextStyle(
                color: rule.color,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContributionTile extends StatelessWidget {
  final ContestContribution contribution;
  const _ContributionTile({required this.contribution});

  @override
  Widget build(BuildContext context) {
    final type = contribution.type;
    final color = _colorFor(type);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Icon(_iconFor(type), size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  contribution.description,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _formatDate(contribution.date),
                  style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
          Text(
            '+${contribution.points} pts',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  static IconData _iconFor(ContributionType t) {
    switch (t) {
      case ContributionType.question:
        return Icons.check_circle_outline;
      case ContributionType.simulation:
        return Icons.assignment_turned_in_outlined;
      case ContributionType.badge:
        return Icons.verified_outlined;
      case ContributionType.streakBonus:
        return Icons.local_fire_department_outlined;
    }
  }

  static Color _colorFor(ContributionType t) {
    switch (t) {
      case ContributionType.question:
        return AppColors.info;
      case ContributionType.simulation:
        return AppColors.success;
      case ContributionType.badge:
        return AppColors.accent;
      case ContributionType.streakBonus:
        return AppColors.error;
    }
  }

  static String _formatDate(DateTime d) {
    const mois = [
      '', 'jan', 'fev', 'mar', 'avr', 'mai', 'jun',
      'jul', 'aou', 'sep', 'oct', 'nov', 'dec',
    ];
    return '${d.day} ${mois[d.month]} ${d.hour}h${d.minute.toString().padLeft(2, '0')}';
  }
}
