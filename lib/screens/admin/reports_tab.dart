// lib/screens/admin/reports_tab.dart
// Onglet "Rapports" du dashboard directeur
//
// Rapport trimestriel agrégé :
//   - Sélecteur T1 / T2 / T3
//   - Carte résumé : moyenne classe, évolution vs trimestre précédent,
//     top 5 élèves, élèves en progression
//   - Graphique barres : % de maîtrise par matière (fl_chart)
//   - Graphique ligne : évolution du score moyen sur 3 mois (fl_chart)
//   - Bouton "Télécharger PDF" (UI seulement)
//   - Recommandations automatiques (3 cartes)

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'admin_dashboard_screen.dart';

class ReportsTab extends StatefulWidget {
  const ReportsTab({super.key});

  @override
  State<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<ReportsTab> {
  // ─── Trimestre sélectionné ─────────────────────────────────────
  // 0 = T1, 1 = T2, 2 = T3
  int _selectedTrimestre = 1;

  // ─── Données par trimestre (mock) ──────────────────────────────
  static const _trimestreLabels = ['Trimestre 1', 'Trimestre 2', 'Trimestre 3'];

  static const _moyennes = [52.3, 56.4, 60.1];
  static const _evolutions = [3.8, 4.1, 3.7]; // vs trim précédent
  static const _elevesEnProgression = [11, 14, 17];

  // Top 5 (identique mock pour la démo)
  static const _top5 = [
    ('Kossi Agbodjan', 'Terminale C', 84),
    ('Adjo Aziabou', '3e A', 81),
    ('Delali Sewa', '3e B', 80),
    ('Edem Akolly', 'Terminale D', 79),
    ('Kossi Mensah', '3e A', 78),
  ];

  // ─── Maîtrise par matière (mock, varie légèrement par trim.) ──
  static const _matieres = [
    'Mathématiques',
    'Physique-Chimie',
    'SVT',
    'Histoire-Géo',
    'Français',
    'Anglais',
    'EPS',
  ];

  // 3 colonnes : T1, T2, T3 (mock)
  static const _maitriseParMatiere = [
    [42, 46, 50], // Maths
    [46, 50, 54], // PC
    [55, 59, 64], // SVT
    [62, 65, 70], // HG
    [52, 56, 60], // Français
    [66, 70, 74], // Anglais
    [82, 85, 88], // EPS
  ];

  // ─── Évolution mensuelle du score moyen (3 mois du trimestre) ─
  static const _moisLabels = [
    ['Sept', 'Oct', 'Nov'],
    ['Déc', 'Jan', 'Fév'],
    ['Mars', 'Avr', 'Mai'],
  ];

  static const _evolutionMensuelle = [
    [46.0, 49.5, 52.3], // T1
    [53.0, 55.0, 56.4], // T2
    [56.5, 58.5, 60.1], // T3
  ];

  // ─── Recommandations automatiques ──────────────────────────────
  static const _recommendations = [
    (
      title: 'Renforcer le chapitre « Équations 1er degré » en 3e B',
      detail: '18 élèves en difficulté sur cette compétence. '
          'Séance de soutien recommandée sous 2 semaines.',
      icon: Icons.warning_amber_rounded,
      color: AppColors.error,
    ),
    (
      title: 'Prévoir une révision sur le « Théorème de Thalès » en 3e A',
      detail: '12 élèves ont un score < 40% sur ce chapitre. '
          'Exercices ciblés à distribuer.',
      icon: Icons.priority_high,
      color: AppColors.warning,
    ),
    (
      title: 'Simuler un examen blanc en Terminale C',
      detail: '6 élèves sous la moyenne globale. Simulation complète '
          'BAC recommandée avant la fin du mois.',
      icon: Icons.assignment_outlined,
      color: AppColors.info,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Sélecteur trimestre + bouton PDF ─────────────────
          _buildTrimestreHeader(),
          const SizedBox(height: 16),

          // ─── Carte résumé ─────────────────────────────────────
          _buildSummaryCard(),
          const SizedBox(height: 16),

          // ─── Graphique barres : maîtrise par matière ──────────
          _buildSectionTitle('Maîtrise par matière (%)'),
          const SizedBox(height: 8),
          _buildBarChart(),
          const SizedBox(height: 24),

          // ─── Graphique ligne : évolution sur 3 mois ───────────
          _buildSectionTitle('Évolution du score moyen (3 mois)'),
          const SizedBox(height: 8),
          _buildLineChart(),
          const SizedBox(height: 24),

          // ─── Recommandations automatiques ─────────────────────
          _buildSectionTitle('Recommandations automatiques'),
          const SizedBox(height: 8),
          _buildRecommendations(),
        ],
      ),
    );
  }

  // ─── Header (sélecteur + PDF) ──────────────────────────────────
  Widget _buildTrimestreHeader() {
    return Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: 6,
            children: List.generate(3, (i) {
              final selected = _selectedTrimestre == i;
              return ChoiceChip(
                label: Text('T${i + 1}'),
                selected: selected,
                selectedColor: AppColors.primarySurface,
                backgroundColor: AppColors.surface,
                side: BorderSide(
                  color: selected ? AppColors.primary : AppColors.divider,
                  width: 1,
                ),
                labelStyle: TextStyle(
                  color: selected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
                onSelected: (_) => setState(() => _selectedTrimestre = i),
              );
            }),
          ),
        ),
        OutlinedButton.icon(
          onPressed: _downloadPdf,
          icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
          label: const Text('Télécharger PDF'),
        ),
      ],
    );
  }

  // ─── Carte résumé ──────────────────────────────────────────────
  Widget _buildSummaryCard() {
    final moyenne = _moyennes[_selectedTrimestre];
    final evolution = _evolutions[_selectedTrimestre];
    final progression = _elevesEnProgression[_selectedTrimestre];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.summarize_outlined,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Résumé — ${_trimestreLabels[_selectedTrimestre]}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 3 KPI inline
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              _buildMiniStat(
                'Moyenne classe',
                '${moyenne.toStringAsFixed(1)}%',
                evolution >= 0 ? '+$evolution pts' : '$evolution pts',
                evolution >= 0 ? AppColors.success : AppColors.error,
              ),
              _buildMiniStat(
                'Élèves en progression',
                '+$progression',
                'vs trimestre précédent',
                AppColors.success,
              ),
              _buildMiniStat(
                'Effectif suivi',
                '${AdminMockData.students.length}',
                'sur ${AdminMockData.effectifTotal}',
                AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),

          // Top 5
          const Text('Top 5 élèves',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...List.generate(5, (i) {
            final (nom, classe, score) = _top5[i];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 22,
                    child: Text(
                      '${i + 1}.',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary),
                    ),
                  ),
                  Expanded(
                    child: Text(nom,
                        style:
                            const TextStyle(fontWeight: FontWeight.w500)),
                  ),
                  Text(classe,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 50,
                    child: Text('$score%',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.success)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMiniStat(
      String label, String value, String delta, Color deltaColor) {
    return SizedBox(
      width: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                height: 1.1,
              )),
          const SizedBox(height: 2),
          Text(delta,
              style: TextStyle(
                  color: deltaColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ─── Titre de section ──────────────────────────────────────────
  Widget _buildSectionTitle(String text) {
    return Text(text,
        style: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.w700));
  }

  // ─── Bar chart : maîtrise par matière ──────────────────────────
  Widget _buildBarChart() {
    final valeurs = _maitriseParMatiere
        .map((l) => l[_selectedTrimestre].toDouble())
        .toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.textPrimary,
                    getTooltipItem: (group, gIdx, rod, rIdx) {
                      return BarTooltipItem(
                        '${_matieres[gIdx]}\n${rod.toY.toStringAsFixed(0)}%',
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: 25,
                      getTitlesWidget: (v, _) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Text('${v.toInt()}%',
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 10)),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 38,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= _matieres.length) {
                          return const SizedBox.shrink();
                        }
                        // Libellé court (1ère lettre / sigle)
                        final short = _matieresShort[i];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(short,
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500)),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: AppColors.divider.withOpacity(0.6),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(_matieres.length, (i) {
                  final v = valeurs[i];
                  final color = _colorForScore(v);
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: v,
                        gradient: LinearGradient(
                          colors: [color, color.withOpacity(0.75)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        width: 18,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Légende
          Wrap(
            spacing: 14,
            runSpacing: 4,
            children: [
              _legendDot('Maîtrisé (≥70%)', AppColors.success),
              _legendDot('Moyen (50-69%)', AppColors.warning),
              _legendDot('Faible (<50%)', AppColors.error),
            ],
          ),
          const SizedBox(height: 8),
          // Libellés complets
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: List.generate(_matieres.length, (i) {
              return Text('${_matieresShort[i]} = ${_matieres[i]}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary));
            }),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }

  Color _colorForScore(double v) {
    if (v >= 70) return AppColors.success;
    if (v >= 50) return AppColors.warning;
    return AppColors.error;
  }

  // ─── Line chart : évolution mensuelle ──────────────────────────
  Widget _buildLineChart() {
    final values = _evolutionMensuelle[_selectedTrimestre];
    final mois = _moisLabels[_selectedTrimestre];
    final spots = List.generate(
        3, (i) => FlSpot(i.toDouble(), values[i]));

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minY: 40,
                maxY: 70,
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppColors.textPrimary,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((s) {
                        return LineTooltipItem(
                          '${mois[s.spotIndex]}\n${s.y.toStringAsFixed(1)}%',
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: 5,
                      getTitlesWidget: (v, _) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Text('${v.toInt()}%',
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 10)),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= mois.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(mois[i],
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500)),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 5,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: AppColors.divider.withOpacity(0.6),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withOpacity(0.12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Recommandations automatiques ──────────────────────────────
  Widget _buildRecommendations() {
    return Column(
      children: _recommendations.map((r) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border(
                left: BorderSide(color: r.color, width: 4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(r.icon, color: r.color, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.title,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(r.detail,
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.4)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── Sigles matières pour axe X du bar chart ───────────────────
  static const _matieresShort = [
    'Maths',
    'PC',
    'SVT',
    'HG',
    'Fr',
    'Ang',
    'EPS',
  ];

  // ─── Téléchargement PDF (UI seulement) ─────────────────────────
  void _downloadPdf() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Rapport ${_trimestreLabels[_selectedTrimestre]} : '
          'génération PDF simulée (à brancher sur GET /admin/reports/T'
          '${_selectedTrimestre + 1}.pdf).',
        ),
        backgroundColor: AppColors.info,
      ),
    );
  }
}
