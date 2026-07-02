// lib/screens/contest/contest_home_screen.dart
// Ecran d'accueil du module Concours inter-ecoles.
//
// Composition :
//   1. AppBar thematique (titre "Concours inter-ecoles" + bouton refresh).
//   2. Hero card : concours mensuel en cours (titre, matiere, dates,
//      progression collective).
//   3. Podium national (top 3 ecoles) avec mise en avant visuelle.
//   4. Carte "Mon ecole" avec rang + vitrine trophees (TrophyShowcase).
//   5. Carte "Ma contribution" (ContributionCard) -- points apportes.
//   6. Boutons d'action : classement complet / detail concours / historique.
//
// Architecture Provider :
//   - ContestHomeScreen (StatelessWidget) encapsule un ChangeNotifierProvider
//     qui cree une instance unique de ContestService et declenche load().
//   - _HomeView consomme le service via context.watch<ContestService>() et
//     se rebuild a chaque notifyListeners().
//   - Les sous-ecrans (leaderboard / details / history) sont pousses via
//     Navigator.push et recoivent le service en parametre pour conserver
//     l'etat sans re-instancier les donnees mock.
//
// Note : le ChangeNotifierProvider est declare ici (et non dans main.dart)
// car la consigne est de ne PAS toucher au router/main.dart. Le service
// est donc isole au module concours et instancie a l'entree de l'ecran.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_theme.dart';
import 'models/contest.dart';
import 'models/school_ranking.dart';
import 'services/contest_service.dart';
import 'widgets/contribution_card.dart';
import 'widgets/contest_progress_widget.dart';
import 'widgets/school_ranking_card.dart';
import 'widgets/trophy_showcase.dart';
import 'contest_details_screen.dart';
import 'contest_history_screen.dart';
import 'contest_leaderboard_screen.dart';

class ContestHomeScreen extends StatelessWidget {
  const ContestHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Le ChangeNotifierProvider cree le service et le dispose
    // automatiquement quand l'ecran est detruit.
    return ChangeNotifierProvider(
      create: (_) => ContestService()..load(),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    final service = context.watch<ContestService>();
    final contest = service.currentContest;
    final mySchool = service.mySchool;
    final myContribution = service.myContribution;
    final podium = service.getPodiumNational();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Concours inter-ecoles',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Clique pour ton etablissement',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w400,
                height: 1.2,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            tooltip: 'Historique',
            onPressed:
                () => _pushHistory(context, service),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Rafraichir',
            onPressed: () => service.refresh(),
          ),
        ],
      ),
      body:
          service.isLoading && contest == null
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: () => service.refresh(),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  children: [
                    // ─── Hero card : concours en cours ────────────────
                    if (contest != null)
                      _HeroContestCard(
                        contest: contest,
                        onTap: () => _pushDetails(context, service, contest.id),
                      ),
                    const SizedBox(height: 16),

                    // ─── Progression collective ───────────────────────
                    if (contest != null) ...[
                      _SectionHeader(
                        titre: 'Progression nationale',
                        action: 'Detail',
                        onAction: () => _pushDetails(context, service, contest.id),
                      ),
                      ContestProgressWidget(contest: contest),
                      const SizedBox(height: 16),
                    ],

                    // ─── Podium top 3 ─────────────────────────────────
                    _SectionHeader(
                      titre: 'Podium national',
                      action: 'Classement complet',
                      onAction: () => _pushLeaderboard(context, service),
                    ),
                    _PodiumWidget(podium: podium, mySchoolId: mySchool?.id),
                    const SizedBox(height: 16),

                    // ─── Mon ecole ────────────────────────────────────
                    if (mySchool != null) ...[
                      _SectionHeader(
                        titre: 'Mon ecole',
                        action: 'Voir classement',
                        onAction: () => _pushLeaderboard(context, service),
                      ),
                      _MySchoolCard(
                        school: mySchool,
                        onTap: () => _pushLeaderboard(context, service),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ─── Ma contribution ──────────────────────────────
                    if (myContribution != null) ...[
                      _SectionHeader(
                        titre: 'Ma contribution',
                        action: null,
                        onAction: null,
                      ),
                      ContributionCard(contribution: myContribution),
                      const SizedBox(height: 16),
                    ],

                    // ─── Vitrine trophees ─────────────────────────────
                    if (mySchool != null && mySchool.trophees.isNotEmpty) ...[
                      _SectionHeader(
                        titre: 'Trophees de mon ecole',
                        action: null,
                        onAction: null,
                      ),
                      TrophyShowcase(
                        trophees: mySchool.trophees,
                        title: '${mySchool.nbTrophees} trophee(s) gagne(s)',
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ─── Boutons d'action ─────────────────────────────
                    _ActionButtons(
                      onLeaderboard: () => _pushLeaderboard(context, service),
                      onDetails:
                          contest != null
                              ? () => _pushDetails(context, service, contest.id)
                              : null,
                      onHistory: () => _pushHistory(context, service),
                    ),
                  ],
                ),
              ),
    );
  }

  // ─── Navigation vers les sous-ecrans ──────────────────────────────

  void _pushLeaderboard(BuildContext context, ContestService service) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ContestLeaderboardScreen(service: service),
      ),
    );
  }

  void _pushDetails(
    BuildContext context,
    ContestService service,
    String contestId,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) =>
                ContestDetailsScreen(service: service, contestId: contestId),
      ),
    );
  }

  void _pushHistory(BuildContext context, ContestService service) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ContestHistoryScreen(service: service),
      ),
    );
  }
}

// ─── Hero card : concours en cours ───────────────────────────────────

class _HeroContestCard extends StatelessWidget {
  final Contest contest;
  final VoidCallback onTap;

  const _HeroContestCard({required this.contest, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.accentLight, width: 1),
                    ),
                    child: const Text(
                      'CONCOURS DU MOIS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.white.withOpacity(0.7),
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                contest.titre,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.menu_book_outlined,
                    size: 13,
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
                  const SizedBox(width: 10),
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 11,
                    color: Colors.white.withOpacity(0.85),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    _formatPeriode(contest.dateDebut, contest.dateFin),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Mini barre de progression
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  height: 8,
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: contest.ratioCollectif.clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.accentLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(contest.ratioCollectif * 100).round()}% de l\'objectif',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${contest.joursRestants} j restants',
                    style: const TextStyle(
                      color: AppColors.accentLight,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
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

  static String _formatPeriode(DateTime debut, DateTime fin) {
    const mois = [
      '', 'jan', 'fev', 'mar', 'avr', 'mai', 'jun',
      'jul', 'aou', 'sep', 'oct', 'nov', 'dec',
    ];
    if (debut.month == fin.month) {
      return '${debut.day}-${fin.day} ${mois[debut.month]}';
    }
    return '${debut.day} ${mois[debut.month]} - ${fin.day} ${mois[fin.month]}';
  }
}

// ─── Header de section ───────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String titre;
  final String? action;
  final VoidCallback? onAction;

  const _SectionHeader({
    required this.titre,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            titre,
            style: AppTextStyles.body.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          if (action != null && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    action!,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Podium top 3 ────────────────────────────────────────────────────

class _PodiumWidget extends StatelessWidget {
  final List<SchoolRanking> podium;
  final String? mySchoolId;

  const _PodiumWidget({required this.podium, this.mySchoolId});

  @override
  Widget build(BuildContext context) {
    if (podium.length < 3) {
      // Fallback : on affiche ce qu'on a via SchoolRankingCard.
      return Column(
        children:
            podium
                .map(
                  (s) => SchoolRankingCard(
                    ecole: s,
                    isMySchool: s.id == mySchoolId,
                  ),
                )
                .toList(),
      );
    }

    // Podium : 2e | 1er | 3e (style olympique).
    // IntrinsicHeight pour que les colonnes (de hauteurs differentes)
    // s'alignent par le bas sans debordement.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: _PodiumColumn(
              school: podium[1],
              tier: 2,
              height: 90,
              isMine: podium[1].id == mySchoolId,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _PodiumColumn(
              school: podium[0],
              tier: 1,
              height: 120,
              isMine: podium[0].id == mySchoolId,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _PodiumColumn(
              school: podium[2],
              tier: 3,
              height: 70,
              isMine: podium[2].id == mySchoolId,
            ),
          ),
        ],
      ),
    );
  }
}

class _PodiumColumn extends StatelessWidget {
  final SchoolRanking school;
  final int tier; // 1, 2 ou 3
  final double height;
  final bool isMine;

  const _PodiumColumn({
    required this.school,
    required this.tier,
    required this.height,
    required this.isMine,
  });

  @override
  Widget build(BuildContext context) {
    final color = _tierColor(tier);
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Medaille
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '$tier',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        // Nom ecole (2 lignes max)
        Text(
          _shortName(school.nom),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isMine ? AppColors.primary : AppColors.textPrimary,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        // Bloc podium
        Container(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(8),
            ),
            border: Border(
              top: BorderSide(color: color, width: 2),
              left: BorderSide(color: color.withOpacity(0.3), width: 1),
              right: BorderSide(color: color.withOpacity(0.3), width: 1),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${school.points}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: color,
                  height: 1.1,
                ),
              ),
              Text(
                'pts',
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Color _tierColor(int tier) {
    switch (tier) {
      case 1:
        return const Color(0xFFFFB300);
      case 2:
        return const Color(0xFF78909C);
      case 3:
        return const Color(0xFFB8693B);
      default:
        return AppColors.textSecondary;
    }
  }

  /// Nom raccourci pour le podium (retire "Lycee" / "Lycee de" / "Lycee d'").
  static String _shortName(String nom) {
    return nom
        .replaceAll('Lycée ', '')
        .replaceAll('Collège ', '')
        .trim();
  }
}

// ─── Carte "Mon ecole" ───────────────────────────────────────────────

class _MySchoolCard extends StatelessWidget {
  final SchoolRanking school;
  final VoidCallback onTap;

  const _MySchoolCard({required this.school, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              // Rang national
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${school.rangNational}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          height: 1.0,
                        ),
                      ),
                      const Text(
                        'e',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                          height: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Nom + region + rang regional
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      school.nom,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.place_outlined,
                          size: 11,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${school.region} - ${school.rangRegional}e regional',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    if (school.nbTrophees > 0) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.emoji_events_outlined,
                            size: 11,
                            color: const Color(0xFFFFB300),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${school.nbTrophees} trophee(s) (${school.nbOr} or)',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontSize: 11,
                              color: const Color(0xFFB8693B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Points
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${school.points}',
                    style: AppTextStyles.body.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  const Text(
                    'pts',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
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
}

// ─── Boutons d'action ────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  final VoidCallback onLeaderboard;
  final VoidCallback? onDetails;
  final VoidCallback onHistory;

  const _ActionButtons({
    required this.onLeaderboard,
    required this.onDetails,
    required this.onHistory,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ActionTile(
          icon: Icons.leaderboard_outlined,
          label: 'Classement complet des ecoles',
          subtitle: 'Top 50 national et regional',
          onTap: onLeaderboard,
        ),
        const SizedBox(height: 8),
        _ActionTile(
          icon: Icons.info_outline,
          label: 'Detail du concours en cours',
          subtitle: 'Regles, recompenses, top 10',
          onTap: onDetails,
          enabled: onDetails != null,
        ),
        const SizedBox(height: 8),
        _ActionTile(
          icon: Icons.history,
          label: 'Historique des concours',
          subtitle: '6 derniers concours mensuels',
          onTap: onHistory,
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback? onTap;
  final bool enabled;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider, width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
