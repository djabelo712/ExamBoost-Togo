// lib/screens/parent/parent_progress_tab.dart
// Onglet "Progression" du dashboard parent.
//
// Affiche, pour l'enfant sélectionné :
//   1. Sélecteur d'enfant (segmented control en haut)
//   2. ProgressSummaryCard (score global + comparaison classe + 3 mini-stats)
//   3. LineChart fl_chart : activité 7 derniers jours (minutes/jour)
//   4. Liste des matières (barres horizontales double : enfant vs classe)
//   5. Badges récents (wrap horizontal)
//
// Données : ParentMockData.children. A brancher sur
// ParentService.fetchChildDetail(childId) pour la v2.

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../theme/adaptive_colors.dart';
import '../../theme/app_theme.dart';
import 'services/parent_service.dart';
import 'widgets/progress_summary_card.dart';

class ProgressTab extends StatefulWidget {
  final List<Child> children;
  final String? selectedChildId;
  final ValueChanged<String> onChildChanged;

  const ProgressTab({
    super.key,
    required this.children,
    required this.selectedChildId,
    required this.onChildChanged,
  });

  @override
  State<ProgressTab> createState() => _ProgressTabState();
}

class _ProgressTabState extends State<ProgressTab> {
  @override
  Widget build(BuildContext context) {
    if (widget.children.isEmpty) {
      return _buildEmptyState(context);
    }

    final selectedId = widget.selectedChildId ?? widget.children.first.id;
    final child = widget.children.firstWhere(
      (c) => c.id == selectedId,
      orElse: () => widget.children.first,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Sélecteur d'enfant ───────────────────────────────
          if (widget.children.length > 1) ...[
            _buildChildSelector(context, selectedId),
            const SizedBox(height: 14),
          ],

          // ─── Carte résumé ─────────────────────────────────────
          ProgressSummaryCard(child: child),
          const SizedBox(height: 14),

          // ─── Graphique activité 7 j ───────────────────────────
          _buildActivityChart(context, child),
          const SizedBox(height: 14),

          // ─── Progression par matière ──────────────────────────
          _buildSubjectsSection(context, child),
          const SizedBox(height: 14),

          // ─── Badges ───────────────────────────────────────────
          _buildBadgesSection(context, child),
        ],
      ),
    );
  }

  // ─── Sélecteur d'enfant (segmented) ────────────────────────────
  Widget _buildChildSelector(BuildContext context, String selectedId) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AdaptiveColors.surfaceVariant(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: widget.children.map((c) {
          final isSelected = c.id == selectedId;
          return Expanded(
            child: GestureDetector(
              onTap: () => widget.onChildChanged(c.id),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AdaptiveColors.surface(context)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AdaptiveColors.shadowColor(context),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  c.prenom,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.label.copyWith(
                    color: isSelected
                        ? AdaptiveColors.primary(context)
                        : AdaptiveColors.textSecondary(context),
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── LineChart activité 7 j ────────────────────────────────────
  Widget _buildActivityChart(BuildContext context, Child child) {
    final minutes = child.activity7j.map((a) => a.minutes.toDouble()).toList();
    final maxVal = minutes.fold<double>(0, (a, b) => a > b ? a : b);
    final hasActivity = minutes.any((v) => v > 0);
    final yInterval = maxVal <= 30 ? 10.0 : (maxVal / 4).ceilToDouble();
    const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Temps de révision (7 derniers jours)',
              style: AppTextStyles.h3.copyWith(
                  color: AdaptiveColors.textPrimary(context), fontSize: 16)),
          const SizedBox(height: 4),
          Text(
            'Total : ${_formatTotalMinutes(child.tempsRevisionMinutes7j)} '
            'sur la semaine',
            style: AppTextStyles.bodySmall.copyWith(
                color: AdaptiveColors.textSecondary(context)),
          ),
          const SizedBox(height: 16),
          if (!hasActivity)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.show_chart,
                        color: AdaptiveColors.textDisabled(context), size: 36),
                    const SizedBox(height: 8),
                    Text(
                      'Pas encore d\'activité cette semaine.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySmall.copyWith(
                          color: AdaptiveColors.textSecondary(context)),
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: yInterval,
                    getDrawingHorizontalLine: (v) => FlLine(
                      color: AdaptiveColors.divider(context),
                      strokeWidth: 1,
                      dashArray: [4, 4],
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        interval: yInterval,
                        getTitlesWidget: (v, meta) {
                          if (v != v.floorToDouble()) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Text(
                              '${v.toInt()}min',
                              style: AppTextStyles.bodySmall.copyWith(
                                  fontSize: 10,
                                  color: AdaptiveColors.textSecondary(
                                      context)),
                              textAlign: TextAlign.right,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        interval: 1,
                        getTitlesWidget: (v, meta) {
                          final i = v.toInt();
                          if (i < 0 || i >= days.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              days[i],
                              style: AppTextStyles.bodySmall.copyWith(
                                  fontSize: 11,
                                  color: AdaptiveColors.textSecondary(
                                      context)),
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
                          FlSpot(i.toDouble(), minutes[i]),
                      ],
                      isCurved: true,
                      color: AdaptiveColors.primary(context),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, _, __, ___) =>
                            FlDotCirclePainter(
                          radius: 4,
                          color: AdaptiveColors.primary(context),
                          strokeWidth: 2,
                          strokeColor: AdaptiveColors.surface(context),
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color:
                            AdaptiveColors.primary(context).withOpacity(0.12),
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

  // ─── Section matières ──────────────────────────────────────────
  Widget _buildSubjectsSection(BuildContext context, Child child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Progression par matière',
              style: AppTextStyles.h3.copyWith(
                  color: AdaptiveColors.textPrimary(context), fontSize: 16)),
          const SizedBox(height: 4),
          Text(
            'Barre verte : votre enfant · Repère orange : moyenne classe',
            style: AppTextStyles.bodySmall.copyWith(
                color: AdaptiveColors.textSecondary(context), fontSize: 12),
          ),
          const SizedBox(height: 14),
          ...child.subjects.map((s) => _subjectRow(context, s)),
        ],
      ),
    );
  }

  Widget _subjectRow(BuildContext context, SubjectProgress subject) {
    final diff = subject.maitrise - subject.maitriseClasse;
    final diffColor = diff >= 0 ? AppColors.success : AppColors.error;
    final icon = _iconForSubject(subject.iconData);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AdaptiveColors.primarySurface(context),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AdaptiveColors.primary(context), size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        subject.matiere,
                        style: AppTextStyles.h3.copyWith(
                            color: AdaptiveColors.textPrimary(context),
                            fontSize: 14),
                      ),
                    ),
                    Text(
                      '${subject.maitrise}%',
                      style: AppTextStyles.h3.copyWith(
                          color: AdaptiveColors.textPrimary(context),
                          fontSize: 14,
                          fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: diffColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${diff >= 0 ? '+' : ''}$diff',
                        style: TextStyle(
                          color: diffColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Barre enfant (verte) — seule barre affichée pour la
                // lisibilité. La moyenne classe est indiquée par une
                // petite étiquette à droite.
                Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    // Barre enfant (verte) au premier plan.
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: subject.maitrise / 100,
                        minHeight: 8,
                        backgroundColor:
                            AdaptiveColors.surfaceVariant(context),
                        color: AdaptiveColors.primary(context),
                      ),
                    ),
                    // Repère vertical : moyenne classe (ligne rouge/orange).
                    Positioned(
                      left: (subject.maitriseClasse / 100) *
                          (MediaQuery.of(context).size.width - 100),
                      child: Container(
                        width: 2,
                        height: 12,
                        color: AdaptiveColors.adaptiveAccent(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Classe : ${subject.maitriseClasse}% · '
                  '${subject.questionsRepondues} questions · '
                  '${_formatTotalMinutes(subject.tempsMinutes)}',
                  style: AppTextStyles.bodySmall.copyWith(
                      color: AdaptiveColors.textSecondary(context),
                      fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Section badges ────────────────────────────────────────────
  Widget _buildBadgesSection(BuildContext context, Child child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events_outlined, color: AppColors.accent),
              const SizedBox(width: 8),
              Text('Badges récents',
                  style: AppTextStyles.h3.copyWith(
                      color: AdaptiveColors.textPrimary(context),
                      fontSize: 16)),
              const Spacer(),
              Text(
                '${child.badges.length} au total',
                style: AppTextStyles.bodySmall.copyWith(
                    color: AdaptiveColors.textSecondary(context)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (child.badges.isEmpty)
            Text(
              'Aucun badge gagné pour le moment. Encouragez votre enfant à '
              'réviser régulièrement pour débloquer ses premiers badges !',
              style: AppTextStyles.bodySmall.copyWith(
                  color: AdaptiveColors.textSecondary(context)),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children:
                  child.badges.map((b) => _badgeChip(context, b)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _badgeChip(BuildContext context, BadgeEarned badge) {
    final color = _badgeColor(badge.niveau);
    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.emoji_events,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  badge.titre,
                  style: AppTextStyles.h3.copyWith(
                      color: AdaptiveColors.textPrimary(context),
                      fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${DateFormat('dd/MM').format(badge.gagneLe)} · '
                      '${_badgeNiveauLabel(badge.niveau)}',
                  style: AppTextStyles.bodySmall.copyWith(
                      color: AdaptiveColors.textSecondary(context),
                      fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── État vide ─────────────────────────────────────────────────
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.trending_up,
              size: 56, color: AdaptiveColors.textDisabled(context)),
          const SizedBox(height: 12),
          Text('Aucun enfant à afficher',
              style: AppTextStyles.h3
                  .copyWith(color: AdaptiveColors.textPrimary(context))),
          const SizedBox(height: 6),
          Text(
            'Liez un enfant dans l\'onglet « Enfants » pour voir sa '
            'progression détaillée ici.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall
                .copyWith(color: AdaptiveColors.textSecondary(context)),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────
  BoxDecoration _cardDecoration(BuildContext context) => BoxDecoration(
        color: AdaptiveColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AdaptiveColors.shadowColor(context),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      );

  IconData _iconForSubject(IconDataRef ref) => switch (ref) {
        IconDataRef.calcul => Icons.calculate_outlined,
        IconDataRef.science => Icons.science_outlined,
        IconDataRef.livre => Icons.menu_book_outlined,
        IconDataRef.globe => Icons.public,
        IconDataRef.histoire => Icons.history_edu_outlined,
        IconDataRef.physique => Icons.bolt_outlined,
      };

  Color _badgeColor(BadgeNiveau n) => switch (n) {
        BadgeNiveau.bronze => const Color(0xFFCD7F32),
        BadgeNiveau.argent => const Color(0xFF9E9E9E),
        BadgeNiveau.or => const Color(0xFFFFD700),
        BadgeNiveau.platine => const Color(0xFF6A1B9A),
      };

  String _badgeNiveauLabel(BadgeNiveau n) => switch (n) {
        BadgeNiveau.bronze => 'Bronze',
        BadgeNiveau.argent => 'Argent',
        BadgeNiveau.or => 'Or',
        BadgeNiveau.platine => 'Platine',
      };

  String _formatTotalMinutes(int total) {
    if (total < 60) return '${total}min';
    final h = total ~/ 60;
    final m = total % 60;
    return m == 0 ? '${h}h' : '${h}h${m}min';
  }
}
