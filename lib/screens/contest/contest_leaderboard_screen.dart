// lib/screens/contest/contest_leaderboard_screen.dart
// Ecran : classement complet des ecoles dans le concours en cours.
//
// 2 scopes via SegmentedButton (Material 3) :
//   - National : top 50 ecoles du Togo, toutes regions confondues.
//   - Regional : top 50 ecoles filtrees par region (ChoiceChips).
//
// Une carte "Mon ecole" reste sticky en haut de la liste pour identifier
// rapidement la position de son etablissement, meme si on scrolle.
//
// Pour chaque ecole, on affiche SchoolRankingCard (rang / medaille / nom
// / region / points / variation / trophees).
//
// Le service est passe en parametre depuis ContestHomeScreen (le service
// est instancie dans un ChangeNotifierProvider au niveau de l'ecran
// d'accueil).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_theme.dart';
import 'models/school_ranking.dart';
import 'services/contest_service.dart';
import 'widgets/school_ranking_card.dart';

class ContestLeaderboardScreen extends StatelessWidget {
  /// Service partage depuis ContestHomeScreen (permet de conserver
  /// l'etat entre les ecrans sans re-instancier les donnees mock).
  final ContestService service;

  const ContestLeaderboardScreen({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: service,
      child: const _LeaderboardView(),
    );
  }
}

class _LeaderboardView extends StatefulWidget {
  const _LeaderboardView();

  @override
  State<_LeaderboardView> createState() => _LeaderboardViewState();
}

class _LeaderboardViewState extends State<_LeaderboardView> {
  RankingScope _scope = RankingScope.national;
  String _regionSelectionnee = 'Lome';

  @override
  Widget build(BuildContext context) {
    final service = context.watch<ContestService>();
    final mySchool = service.mySchool;

    final liste = service.getRanking(
      scope: _scope,
      region: _regionSelectionnee,
      limit: 50,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Classement des ecoles',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Rafraichir',
            onPressed: () => service.refresh(),
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── SegmentedButton National / Regional ─────────────
          _buildSegmentedControl(),
          if (_scope == RankingScope.regional) _buildRegionFilter(),

          // ─── Carte "Mon ecole" sticky ────────────────────────
          if (mySchool != null) _buildMonEcoleCard(mySchool),

          // ─── Liste des ecoles ────────────────────────────────
          Expanded(
            child:
                service.isLoading && liste.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                      onRefresh: () => service.refresh(),
                      child:
                          liste.isEmpty
                              ? _buildEmptyState()
                              : ListView.builder(
                                physics:
                                    const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  4,
                                  16,
                                  24,
                                ),
                                itemCount: liste.length,
                                itemBuilder: (context, i) {
                                  final e = liste[i];
                                  final isMine =
                                      mySchool != null && e.id == mySchool.id;
                                  return SchoolRankingCard(
                                    ecole: e,
                                    isMySchool: isMine,
                                    rangForce:
                                        _scope == RankingScope.regional
                                            ? e.rangRegional
                                            : null,
                                  );
                                },
                              ),
                    ),
          ),
        ],
      ),
    );
  }

  // ─── SegmentedButton (2 scopes) ─────────────────────────────────

  Widget _buildSegmentedControl() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: SegmentedButton<RankingScope>(
        segments: const [
          ButtonSegment(
            value: RankingScope.national,
            icon: Icon(Icons.public, size: 16),
            label: Text('National'),
          ),
          ButtonSegment(
            value: RankingScope.regional,
            icon: Icon(Icons.map_outlined, size: 16),
            label: Text('Regional'),
          ),
        ],
        selected: {_scope},
        onSelectionChanged: (s) => setState(() => _scope = s.first),
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.primary.withOpacity(0.12);
            }
            return null;
          }),
          foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.primary;
            }
            return AppColors.textSecondary;
          }),
          side: WidgetStateProperty.all(
            BorderSide(color: AppColors.divider, width: 1),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          visualDensity: VisualDensity.compact,
          textStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  // ─── Filtre regional (chips horizontaux) ────────────────────────

  Widget _buildRegionFilter() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: kTogoRegions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final r = kTogoRegions[i];
          final selected = r == _regionSelectionnee;
          return ChoiceChip(
            label: Text(r),
            selected: selected,
            onSelected: (_) => setState(() => _regionSelectionnee = r),
            selectedColor: AppColors.primary,
            labelStyle: TextStyle(
              color: selected ? Colors.white : AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            backgroundColor: AppColors.surface,
            side: BorderSide(
              color: selected ? AppColors.primary : AppColors.divider,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 8),
          );
        },
      ),
    );
  }

  // ─── Carte "Mon ecole" sticky en haut ───────────────────────────

  Widget _buildMonEcoleCard(SchoolRanking school) {
    final rang =
        _scope == RankingScope.regional
            ? school.rangRegional
            : school.rangNational;
    final label =
        _scope == RankingScope.regional
            ? 'dans la region ${school.region}'
            : 'au niveau national';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '#$rang',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  school.nom,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Classe $rangᵉ $label',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            '${school.points} pts',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Etat vide ──────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        Icon(
          Icons.school_outlined,
          size: 64,
          color: AppColors.textDisabled,
        ),
        const SizedBox(height: 12),
        Text(
          'Aucune ecole dans cette region pour le moment.',
          textAlign: TextAlign.center,
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
