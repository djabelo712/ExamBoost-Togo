// lib/screens/community/challenges_tab.dart
// Onglet "Défis hebdomadaires" du module Communauté.
//
// 3 sections :
//   1. Défi de la semaine (carte prominent) :
//      - Titre, description, récompense, barre de progression X/N
//      - Graphique fl_chart (LineChart) montrant les points/jour
//      - Bouton "Participer" / "Continuer"
//   2. Défis en cours (3 cartes) :
//      - Streak 7 jours, Simulation BAC, Aidant (5 questions forum)
//      - Progression visuelle (barre + % + reste à faire)
//   3. Défis terminés (historique — 5 derniers avec badges)
//
// Données : mock local. Pas d'appel réseau.
// Pour la production : remplacer _mockDefis... par un service backend
// qui synchronise les défis depuis le serveur chaque lundi.

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

// ─── Modèles locaux ─────────────────────────────────────────────────

enum _DefiType { streak, simulation, aidant, matiere }

class _Defi {
  final String id;
  final String titre;
  final String description;
  final String recompense;
  final _DefiType type;
  final int objectif;
  final int progression;
  final int pointsGagnes;
  final String? badge;
  final DateTime? dateFin;

  const _Defi({
    required this.id,
    required this.titre,
    required this.description,
    required this.recompense,
    required this.type,
    required this.objectif,
    required this.progression,
    this.pointsGagnes = 0,
    this.badge,
    this.dateFin,
  });

  double get ratio =>
      objectif == 0 ? 0 : (progression / objectif).clamp(0.0, 1.0);

  bool get estTermine => progression >= objectif;
}

// ─── Onglet Défis ───────────────────────────────────────────────────

class ChallengesTab extends StatefulWidget {
  const ChallengesTab({super.key});

  @override
  State<ChallengesTab> createState() => _ChallengesTabState();
}

class _ChallengesTabState extends State<ChallengesTab> {
  // État interactif : le défi de la semaine est "participé" si l'élève
  // clique sur le bouton. Mock — sera remplacé par l'état backend.
  late _Defi _defiSemaine;
  late List<_Defi> _defisEnCours;
  final List<_Defi> _defisTermines = _mockDefisTermines();

  // Activité hebdomadaire pour le LineChart (points gagnés par jour Lun→Dim).
  final List<int> _activiteSemaine = [60, 120, 0, 90, 180, 0, 0];

  @override
  void initState() {
    super.initState();
    _defiSemaine = _mockDefiSemaine();
    _defisEnCours = _mockDefisEnCours();
  }

  /// Simule le clic sur "Continuer" : incrémente la progression du défi.
  /// (Mock — sera remplacé par un appel backend qui persiste la progression.)
  void _continuerDefiSemaine() {
    final avant = _defiSemaine;
    final nouvelle = (avant.progression + 1).clamp(0, avant.objectif);
    setState(() {
      _defiSemaine = _Defi(
        id: avant.id,
        titre: avant.titre,
        description: avant.description,
        recompense: avant.recompense,
        type: avant.type,
        objectif: avant.objectif,
        progression: nouvelle,
        pointsGagnes: avant.pointsGagnes,
        badge: avant.badge,
        dateFin: avant.dateFin,
      );

      // Si le défi de la semaine est aussi listé dans "défis en cours"
      // (par ex. défi "Aidant"), on synchronise sa progression.
      final idx = _defisEnCours.indexWhere((d) => d.id == avant.id);
      if (idx >= 0) {
        final d = _defisEnCours[idx];
        _defisEnCours[idx] = _Defi(
          id: d.id,
          titre: d.titre,
          description: d.description,
          recompense: d.recompense,
          type: d.type,
          objectif: d.objectif,
          progression: nouvelle.clamp(0, d.objectif),
          pointsGagnes: d.pointsGagnes,
          badge: d.badge,
          dateFin: d.dateFin,
        );
      }
    });

    if (_defiSemaine.estTermine && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Défi terminé ! ${_defiSemaine.recompense}',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        // Mock : simule un rechargement.
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) setState(() {});
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Section 1 : Défi de la semaine ───────────────────
            _buildSectionTitle('Défi de la semaine', Icons.star),
            const SizedBox(height: 8),
            _buildDefiSemaineCard(),
            const SizedBox(height: 24),

            // ─── Section 2 : Défis en cours ───────────────────────
            _buildSectionTitle('Mes défis en cours', Icons.play_circle_outline),
            const SizedBox(height: 8),
            if (_defisEnCours.isEmpty)
              _buildEmptyState(
                'Aucun défi en cours. Reviens lundi prochain !',
                icon: Icons.hourglass_empty,
              )
            else
              ..._defisEnCours.map(_buildDefiEnCoursCard),
            const SizedBox(height: 24),

            // ─── Section 3 : Défis terminés (historique) ─────────
            _buildSectionTitle('Défis terminés', Icons.verified_outlined),
            const SizedBox(height: 8),
            if (_defisTermines.isEmpty)
              _buildEmptyState(
                'Aucun défi terminé pour le moment. Lance-toi !',
                icon: Icons.flag_outlined,
              )
            else
              ..._defisTermines.map(_buildDefiTermineCard),
          ],
        ),
      ),
    );
  }

  // ─── Titre de section ──────────────────────────────────────────

  Widget _buildSectionTitle(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.h3.copyWith(fontSize: 16),
        ),
      ],
    );
  }

  // ─── Section 1 : Carte "Défi de la semaine" ────────────────────

  Widget _buildDefiSemaineCard() {
    final d = _defiSemaine;
    final ratio = d.ratio;
    final reste = (d.objectif - d.progression).clamp(0, d.objectif);
    final boutonLabel = d.progression == 0 ? 'Participer' : 'Continuer';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tag "Semaine en cours"
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'SEMAINE EN COURS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Titre + description
          Text(
            d.titre,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            d.description,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),

          // Récompense
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accentLight, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.card_giftcard,
                    color: AppColors.accentLight, size: 16),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    d.recompense,
                    style: const TextStyle(
                      color: AppColors.accentLight,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Barre de progression + compteur
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progression',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${d.progression}/${d.objectif}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 10,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentLight),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            reste == 0
                ? 'Bravo, tu as terminé ce défi !'
                : 'Plus que $reste question${reste > 1 ? "s" : ""} pour valider.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 11,
            ),
          ),

          const SizedBox(height: 16),

          // Graphique d'activité de la semaine (LineChart fl_chart)
          _buildWeeklyProgressChart(),

          const SizedBox(height: 16),

          // Bouton Participer / Continuer
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: d.estTermine ? null : _continuerDefiSemaine,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    d.estTermine ? AppColors.surfaceVariant : Colors.white,
                foregroundColor:
                    d.estTermine ? AppColors.textSecondary : AppColors.primary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                d.estTermine ? 'Défi terminé' : boutonLabel,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── LineChart fl_chart : points gagnés par jour cette semaine ─

  Widget _buildWeeklyProgressChart() {
    const days = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    final maxVal =
        _activiteSemaine.fold<int>(0, (a, b) => a > b ? a : b).clamp(1, 999);
    final yInterval = maxVal <= 60 ? 30.0 : (maxVal / 3).ceilToDouble();

    return SizedBox(
      height: 120,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: yInterval,
            getDrawingHorizontalLine: (v) => FlLine(
              color: Colors.white.withOpacity(0.15),
              strokeWidth: 1,
              dashArray: [4, 4],
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: yInterval,
                getTitlesWidget: (v, _) {
                  if (v != v.floorToDouble()) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text(
                      v.toInt().toString(),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 18,
                interval: 1,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= days.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      days[i],
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 11,
                      ),
                    ),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minY: 0,
          maxY: (maxVal + yInterval).toDouble(),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (int i = 0; i < 7; i++)
                  FlSpot(i.toDouble(), _activiteSemaine[i].toDouble()),
              ],
              isCurved: true,
              color: AppColors.accentLight,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                  radius: 3.5,
                  color: AppColors.accentLight,
                  strokeWidth: 1.5,
                  strokeColor: Colors.white,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.accentLight.withOpacity(0.18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Section 2 : Carte "Défi en cours" ────────────────────────

  Widget _buildDefiEnCoursCard(_Defi d) {
    final ratio = d.ratio;
    final reste = (d.objectif - d.progression).clamp(0, d.objectif);
    final (icon, color) = _iconAndColorForType(d.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icône
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),

          // Titre + reste
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  d.titre,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  reste == 0
                      ? 'Terminé !'
                      : 'Plus que $reste pour réussir',
                  style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 6,
                    backgroundColor: color.withOpacity(0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // % arrondi
          Text(
            '${(ratio * 100).round()}%',
            style: AppTextStyles.h3.copyWith(
              fontSize: 16,
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Section 3 : Carte "Défi terminé" (historique) ────────────

  Widget _buildDefiTermineCard(_Defi d) {
    final (icon, color) = _iconAndColorForType(d.type);
    final dateLabel = d.dateFin != null
        ? '${d.dateFin!.day.toString().padLeft(2, '0')}/'
            '${d.dateFin!.month.toString().padLeft(2, '0')}/'
            '${d.dateFin!.year}'
        : '—';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Row(
        children: [
          // Badge obtenu (icône cerclée)
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 1.5),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  d.titre,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Terminé le $dateLabel',
                  style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),

          // Badge + points
          if (d.badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accentSurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                d.badge!,
                style: AppTextStyles.label.copyWith(
                  color: AppColors.accent,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          const SizedBox(width: 6),
          Text(
            '+${d.pointsGagnes} pts',
            style: AppTextStyles.body.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────

  (IconData, Color) _iconAndColorForType(_DefiType type) {
    return switch (type) {
      _DefiType.streak => (Icons.local_fire_department, AppColors.accent),
      _DefiType.simulation => (Icons.timer, AppColors.info),
      _DefiType.aidant => (Icons.handshake_outlined, AppColors.primary),
      _DefiType.matiere => (Icons.menu_book, AppColors.success),
    };
  }

  Widget _buildEmptyState(String message, {IconData icon = Icons.inbox}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: AppColors.textDisabled),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Mock data ──────────────────────────────────────────────────────

_Defi _mockDefiSemaine() {
  final maintenant = DateTime.now();
  final lundi = maintenant.subtract(Duration(days: maintenant.weekday - 1));
  final dimanche = lundi.add(const Duration(days: 6));

  return _Defi(
    id: 'semaine_maths_eq1',
    titre: 'Défi Maths - Équations 1er degré',
    description: 'Réponds à 20 questions en 7 jours (du ${_formatDate(lundi)} '
        'au ${_formatDate(dimanche)}).',
    recompense: '+500 points + badge Maths Master',
    type: _DefiType.matiere,
    objectif: 20,
    progression: 7,
    badge: 'Maths Master',
  );
}

List<_Defi> _mockDefisEnCours() {
  return [
    _Defi(
      id: 'streak_7j',
      titre: 'Streak 7 jours',
      description: 'Réviser 7 jours de suite',
      recompense: '+200 points + badge Assidu',
      type: _DefiType.streak,
      objectif: 7,
      progression: 5,
    ),
    _Defi(
      id: 'simu_bac',
      titre: 'Simulation BAC',
      description: 'Compléter 1 simulation complète',
      recompense: '+300 points + badge Simulateur',
      type: _DefiType.simulation,
      objectif: 1,
      progression: 0,
    ),
    _Defi(
      id: 'aidant_forum',
      titre: 'Aidant du forum',
      description: 'Répondre à 5 questions du forum',
      recompense: '+150 points + badge Aidant',
      type: _DefiType.aidant,
      objectif: 5,
      progression: 2,
    ),
  ];
}

List<_Defi> _mockDefisTermines() {
  return [
    _Defi(
      id: 'termine_1',
      titre: 'Défi SVT - Cellule animale',
      description: 'Terminé la semaine dernière',
      recompense: '+400 points + badge Bio Master',
      type: _DefiType.matiere,
      objectif: 15,
      progression: 15,
      pointsGagnes: 400,
      badge: 'Bio Master',
      dateFin: DateTime.now().subtract(const Duration(days: 7)),
    ),
    _Defi(
      id: 'termine_2',
      titre: 'Streak 14 jours',
      description: 'Terminé il y a 2 semaines',
      recompense: '+500 points + badge Régulier',
      type: _DefiType.streak,
      objectif: 14,
      progression: 14,
      pointsGagnes: 500,
      badge: 'Régulier',
      dateFin: DateTime.now().subtract(const Duration(days: 14)),
    ),
    _Defi(
      id: 'termine_3',
      titre: 'Défi Français - Conjugaison',
      description: 'Terminé il y a 3 semaines',
      recompense: '+350 points + badge Littéraire',
      type: _DefiType.matiere,
      objectif: 18,
      progression: 18,
      pointsGagnes: 350,
      badge: 'Littéraire',
      dateFin: DateTime.now().subtract(const Duration(days: 21)),
    ),
    _Defi(
      id: 'termine_4',
      titre: 'Défi Sciences Physiques - Électricité',
      description: 'Terminé il y a 1 mois',
      recompense: '+450 points + badge Électricien',
      type: _DefiType.matiere,
      objectif: 20,
      progression: 20,
      pointsGagnes: 450,
      badge: 'Électricien',
      dateFin: DateTime.now().subtract(const Duration(days: 30)),
    ),
    _Defi(
      id: 'termine_5',
      titre: 'Aidant du forum (mai)',
      description: 'Terminé il y a 6 semaines',
      recompense: '+150 points + badge Aidant',
      type: _DefiType.aidant,
      objectif: 5,
      progression: 5,
      pointsGagnes: 150,
      badge: 'Aidant',
      dateFin: DateTime.now().subtract(const Duration(days: 42)),
    ),
  ];
}

String _formatDate(DateTime d) {
  return '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}';
}
