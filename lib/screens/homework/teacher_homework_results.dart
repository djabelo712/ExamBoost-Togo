// lib/screens/homework/teacher_homework_results.dart
// Écran enseignant : résultats classe détaillés pour un devoir.
//
// Affiche :
//   - Header dévoir (titre, matière, classes, deadline),
//   - 3 KPI cards : rendus / en cours / manqués (via HomeworkClassProgressRow),
//   - Stats globales : moyenne classe /20, temps moyen, taux rendu,
//   - Onglets : "Élèves" (tableau triable) / "Questions" (analyse par item),
//   - Bouton export CSV (Snackbar qui affiche le contenu exporté),
//   - Filtre classe (si devoir multi-classes).
//
// L'onglet "Élèves" liste tous les élèves ciblés via StudentResultRow :
// tap sur une ligne ouvre le détail des réponses de l'élève (dialog).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../theme/adaptive_colors.dart';
import '../../theme/app_theme.dart';
import '../models/homework.dart';
import '../models/homework_submission.dart';
import '../services/homework_service.dart';
import 'widgets/homework_progress.dart';
import 'widgets/student_result_row.dart';

class TeacherHomeworkResults extends StatelessWidget {
  final String homeworkId;

  const TeacherHomeworkResults({super.key, required this.homeworkId});

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeworkService>(
      builder: (context, service, _) {
        final homework = service.homeworks.firstWhere(
          (h) => h.id == homeworkId,
          orElse: () => service.homeworks.first,
        );
        final stats = service.getStatsForHomework(homeworkId);

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: Text(homework.titre, maxLines: 1, overflow: TextOverflow.ellipsis),
              actions: [
                IconButton(
                  tooltip: 'Exporter CSV',
                  icon: const Icon(Icons.download_outlined),
                  onPressed: () => _exportCsv(context, service, homework),
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: _buildTabBar(context),
              ),
            ),
            body: Column(
              children: [
                _buildHeader(context, homework, stats),
                Expanded(
                  child: TabBarView(
                    children: [
                      _ElevesTab(homework: homework, service: service),
                      _QuestionsTab(homework: homework, stats: stats),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── TabBar ──────────────────────────────────────────────────
  Widget _buildTabBar(BuildContext context) {
    return Container(
      color: AdaptiveColors.surface(context),
      child: TabBar(
        labelColor: AppColors.primary,
        unselectedLabelColor: AdaptiveColors.textSecondary(context),
        indicatorColor: AppColors.primary,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        tabs: const [
          Tab(text: 'Élèves'),
          Tab(text: 'Questions'),
        ],
      ),
    );
  }

  // ─── Header (résumé global) ─────────────────────────────────
  Widget _buildHeader(
    BuildContext context,
    Homework homework,
    HomeworkClassStats stats,
  ) {
    return Container(
      color: AdaptiveColors.surface(context),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Méta-info
          Row(
            children: [
              Icon(homework.matiereIcon,
                  color: homework.matiereColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${homework.matiere} • ${homework.classes.join(", ")}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AdaptiveColors.textSecondary(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 3 KPI cards
          HomeworkClassProgressRow(
            nbRendus: stats.nbRendus,
            nbEnCours: stats.nbEnCours,
            nbManques: stats.nbManques,
            effectif: stats.effectifClasse,
          ),
          const SizedBox(height: 12),

          // Stats globales (moyenne + temps moyen + taux rendu)
          Row(
            children: [
              Expanded(
                child: _globalStatCard(
                  context,
                  icon: Icons.trending_up_outlined,
                  label: 'Moyenne classe',
                  value: '${stats.moyenne20.toStringAsFixed(1)}/20',
                  color: _noteColor(stats.moyenne20),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _globalStatCard(
                  context,
                  icon: Icons.timer_outlined,
                  label: 'Temps moyen',
                  value: _formatTime(stats.tempsMoyenSecondes),
                  color: AppColors.info,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _globalStatCard(
                  context,
                  icon: Icons.assignment_turned_in_outlined,
                  label: 'Taux rendu',
                  value: '${stats.tauxRendu.round()}%',
                  color: _tauxColor(stats.tauxRendu),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _globalStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.h3.copyWith(
              color: color,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AdaptiveColors.textSecondary(context),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Export CSV ──────────────────────────────────────────────
  void _exportCsv(
    BuildContext context,
    HomeworkService service,
    Homework homework,
  ) {
    final csv = service.exportCsv(homework.id);

    // Copie dans le presse-papier (démo mobile-friendly)
    Clipboard.setData(ClipboardData(text: csv));

    // Affiche un extrait dans un dialog
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Export CSV'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Contenu copié dans le presse-papier. Voici un aperçu :',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AdaptiveColors.surfaceVariant(context),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  csv.length > 400 ? '${csv.substring(0, 400)}...' : csv,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ─── Helpers couleurs ────────────────────────────────────────
  Color _noteColor(double note) {
    if (note >= 14) return AppColors.success;
    if (note >= 10) return AppColors.warning;
    return AppColors.error;
  }

  Color _tauxColor(double taux) {
    if (taux >= 75) return AppColors.success;
    if (taux >= 50) return AppColors.warning;
    return AppColors.error;
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m >= 60) {
      final h = m ~/ 60;
      final mm = m % 60;
      return '$h h ${mm.toString().padLeft(2, "0")} min';
    }
    return '$m min ${s.toString().padLeft(2, "0")} s';
  }
}

// ════════════════════════════════════════════════════════════════
// ONGLET ÉLÈVES — tableau triable des résultats
// ════════════════════════════════════════════════════════════════

class _ElevesTab extends StatefulWidget {
  final Homework homework;
  final HomeworkService service;

  const _ElevesTab({required this.homework, required this.service});

  @override
  State<_ElevesTab> createState() => _ElevesTabState();
}

class _ElevesTabState extends State<_ElevesTab> {
  String? _filterClasse;
  _SortColumn _sortColumn = _SortColumn.note;
  bool _sortAscending = false;

  @override
  Widget build(BuildContext context) {
    // Élèves ciblés par le devoir
    final elevesCibles = widget.service.eleves
        .where((e) => widget.homework.classes.contains(e.classe))
        .where((e) => _filterClasse == null || e.classe == _filterClasse)
        .toList();

    // Pour chaque élève, trouve sa soumission
    var rows = elevesCidesWithSoumission(elevesCibles);

    // Tri
    rows.sort((a, b) {
      int cmp;
      switch (_sortColumn) {
        case _SortColumn.nom:
          cmp = a.eleve.nomComplet.compareTo(b.eleve.nomComplet);
          break;
        case _SortColumn.classe:
          cmp = a.eleve.classe.compareTo(b.eleve.classe);
          break;
        case _SortColumn.note:
          final aNote = _note(a.soumission);
          final bNote = _note(b.soumission);
          cmp = aNote.compareTo(bNote);
          break;
        case _SortColumn.temps:
          final aT = a.soumission?.tempsPasseSecondes ?? 0;
          final bT = b.soumission?.tempsPasseSecondes ?? 0;
          cmp = aT.compareTo(bT);
          break;
      }
      return _sortAscending ? cmp : -cmp;
    });

    return Column(
      children: [
        // Filtre classe + entête tri
        _buildFiltersHeader(context, elevesCibles),
        // Liste
        Expanded(
          child: rows.isEmpty
              ? _buildEmptyState(context)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: rows.length,
                  itemBuilder: (context, index) {
                    final row = rows[index];
                    return StudentResultRow(
                      homework: widget.homework,
                      soumission: row.soumission,
                      avatarColor: widget.homework.matiereColor,
                      onTap: row.soumission?.termine == true
                          ? () => _showEleveDetail(context, row)
                          : null,
                    );
                  },
                ),
        ),
      ],
    );
  }

  List<_EleveRow> elevesCidesWithSoumission(List<MockEleve> eleves) {
    final subs = widget.service.getSubmissionsForHomework(widget.homework.id);
    return eleves.map((e) {
      HomeworkSubmission? sub;
      for (final s in subs) {
        if (s.eleveId == e.id) {
          sub = s;
          break;
        }
      }
      return _EleveRow(eleve: e, soumission: sub);
    }).toList();
  }

  double _note(HomeworkSubmission? sub) {
    if (sub == null || !sub.termine) return -1; // non rendus en dernier
    return (sub.score / widget.homework.pointsTotal) * 20;
  }

  // ─── Header filtres + tri ───────────────────────────────────
  Widget _buildFiltersHeader(BuildContext context, List<MockEleve> eleves) {
    final classesDispos = widget.homework.classes.toList();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      color: AdaptiveColors.surface(context),
      child: Row(
        children: [
          // Filtre classe
          if (classesDispos.length > 1) ...[
            const Text('Classe : ',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            DropdownButton<String?>(
              value: _filterClasse,
              underline: const SizedBox(),
              isDense: true,
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Toutes'),
                ),
                ...classesDispos.map((c) => DropdownMenuItem<String?>(
                      value: c,
                      child: Text(c),
                    )),
              ],
              onChanged: (v) => setState(() => _filterClasse = v),
            ),
          ] else
            Expanded(
              child: Text(
                '${eleves.length} élève(s)',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AdaptiveColors.textSecondary(context),
                ),
              ),
            ),
          const Spacer(),
          // Tri
          _SortButton(
            label: 'Trier',
            column: _sortColumn,
            ascending: _sortAscending,
            onColumnChanged: (c) => setState(() {
              if (_sortColumn == c) {
                _sortAscending = !_sortAscending;
              } else {
                _sortColumn = c;
                _sortAscending = c == _SortColumn.nom; // nom ASC par défaut
              }
            }),
          ),
        ],
      ),
    );
  }

  // ─── Détail d'un élève (dialog) ─────────────────────────────
  void _showEleveDetail(BuildContext context, _EleveRow row) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 600, maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor:
                          widget.homework.matiereColor.withOpacity(0.15),
                      child: Text(
                        row.eleve.initiales,
                        style: TextStyle(
                          color: widget.homework.matiereColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            row.eleve.nomComplet,
                            style: AppTextStyles.h3,
                          ),
                          Text(
                            row.eleve.classe,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AdaptiveColors.textSecondary(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const Divider(height: 24),
                _detailLine('Note',
                    '${_note(row.soumission).toStringAsFixed(1)} / 20'),
                _detailLine('Points',
                    '${row.soumission!.score} / ${widget.homework.pointsTotal}'),
                _detailLine('Temps passé', row.soumission!.tempsLabel),
                _detailLine('Soumis le',
                    _formatDate(row.soumission!.dateSoumission!)),
                if (row.soumission!.isEnRetard(widget.homework))
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              color: AppColors.warning, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Rendu en retard',
                            style: TextStyle(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                // Réponses par question (résumé)
                const Text('Réponses :',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ...widget.homework.questions.asMap().entries.map((entry) {
                  final i = entry.key;
                  final q = entry.value;
                  final ans = row.soumission!.reponses[q.id];
                  final isCorrect = ans?.isCorrect ?? false;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          isCorrect ? Icons.check_circle : Icons.cancel,
                          color: isCorrect
                              ? AppColors.success
                              : AppColors.error,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Q${i + 1}. ${q.enonce}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySmall),
          Text(
            value,
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, "0")}/'
        '${d.month.toString().padLeft(2, "0")}/'
        '${d.year} à ${d.hour.toString().padLeft(2, "0")}:'
        '${d.minute.toString().padLeft(2, "0")}';
  }

  // ─── Empty state ────────────────────────────────────────────
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_off,
                size: 56, color: AdaptiveColors.textSecondary(context)),
            const SizedBox(height: 12),
            Text(
              'Aucun élève dans cette classe.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AdaptiveColors.textSecondary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _SortColumn { nom, classe, note, temps }

class _SortButton extends StatelessWidget {
  final String label;
  final _SortColumn column;
  final bool ascending;
  final ValueChanged<_SortColumn> onColumnChanged;

  const _SortButton({
    required this.label,
    required this.column,
    required this.ascending,
    required this.onColumnChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_SortColumn>(
      onSelected: onColumnChanged,
      itemBuilder: (ctx) => [
        _menuItem(_SortColumn.nom, 'Nom (A-Z)'),
        _menuItem(_SortColumn.classe, 'Classe'),
        _menuItem(_SortColumn.note, 'Note'),
        _menuItem(_SortColumn.temps, 'Temps'),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Icon(
            ascending ? Icons.arrow_upward : Icons.arrow_downward,
            size: 14,
          ),
          const Icon(Icons.arrow_drop_down, size: 16),
        ],
      ),
    );
  }

  PopupMenuItem<_SortColumn> _menuItem(_SortColumn c, String label) {
    return PopupMenuItem<_SortColumn>(
      value: c,
      child: Row(
        children: [
          if (column == c)
            const Icon(Icons.check, size: 16, color: AppColors.primary),
          if (column == c) const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}

class _EleveRow {
  final MockEleve eleve;
  final HomeworkSubmission? soumission;
  const _EleveRow({required this.eleve, this.soumission});
}

// ════════════════════════════════════════════════════════════════
// ONGLET QUESTIONS — analyse par item (% réussite)
// ════════════════════════════════════════════════════════════════

class _QuestionsTab extends StatelessWidget {
  final Homework homework;
  final HomeworkClassStats stats;

  const _QuestionsTab({required this.homework, required this.stats});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: homework.questions.length,
      itemBuilder: (context, index) {
        final q = homework.questions[index];
        final taux = stats.reussiteParQuestion[q.id] ?? 0;
        return _buildQuestionCard(context, index + 1, q, taux);
      },
    );
  }

  Widget _buildQuestionCard(
    BuildContext context,
    int numero,
    HomeworkQuestion q,
    double taux,
  ) {
    final color = _tauxColor(taux);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$numero',
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Question $numero • ${q.points} pt${q.points > 1 ? "s" : ""}',
                    style: AppTextStyles.label.copyWith(
                      color: AdaptiveColors.textSecondary(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${taux.round()}%',
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              q.enonce,
              style: AppTextStyles.body.copyWith(
                color: AdaptiveColors.textPrimary(context),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 10),
            // Barre de réussite
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: taux / 100,
                minHeight: 8,
                backgroundColor: AdaptiveColors.surfaceVariant(context),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _tauxLabel(taux),
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${stats.nbRendus} élève(s) ont répondu',
                  style: TextStyle(
                    color: AdaptiveColors.textSecondary(context),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            if (q.explication != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AdaptiveColors.primarySurface(context),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb_outline,
                        size: 14, color: AdaptiveColors.primary(context)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Correction : ${q.explication}',
                        style: TextStyle(
                          color: AdaptiveColors.primary(context),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _tauxColor(double t) {
    if (t >= 70) return AppColors.success;
    if (t >= 40) return AppColors.warning;
    return AppColors.error;
  }

  String _tauxLabel(double t) {
    if (t >= 70) return 'Bien maîtrisée';
    if (t >= 40) return 'Fragile';
    return 'À retravailler';
  }
}
