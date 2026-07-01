// lib/screens/admin/students_tab.dart
// Onglet "Élèves" du dashboard directeur
//
// Fonctionnalités :
//   - Tableau dense (DataTable) des élèves de l'établissement
//   - Recherche texte + filtre par classe
//   - Tri par score / nom / activité
//   - Pagination 20 lignes par page
//   - Tap sur une ligne -> dialog détails (compétences fortes/faibles,
//     simulations)
//   - Bouton export CSV (UI seulement)

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'admin_dashboard_screen.dart';

class StudentsTab extends StatefulWidget {
  const StudentsTab({super.key});

  @override
  State<StudentsTab> createState() => _StudentsTabState();
}

class _StudentsTabState extends State<StudentsTab> {
  // ─── Filtres / tri ─────────────────────────────────────────────
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String? _classFilter; // null = toutes les classes
  _SortField _sortField = _SortField.score;
  bool _sortAscending = false; // par défaut : décroissant (meilleur 1er)

  // ─── Pagination ────────────────────────────────────────────────
  static const int _rowsPerPage = 20;
  int _firstRow = 0;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ─── Liste filtrée + triée ─────────────────────────────────────
  List<AdminStudent> get _filtered {
    var list = AdminMockData.students.where((s) {
      // Filtre classe
      if (_classFilter != null && s.classe != _classFilter) return false;
      // Recherche texte (nom, prénom, classe)
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final hay = '${s.prenom} ${s.nom} ${s.classe}'.toLowerCase();
        if (!hay.contains(q)) return false;
      }
      return true;
    }).toList();

    // Tri
    int cmp(AdminStudent a, AdminStudent b) {
      switch (_sortField) {
        case _SortField.score:
          return a.scoreGlobal.compareTo(b.scoreGlobal);
        case _SortField.nom:
          return a.nomComplet.toLowerCase().compareTo(b.nomComplet.toLowerCase());
        case _SortField.activite:
          return a.daysSinceLastActive.compareTo(b.daysSinceLastActive);
      }
    }

    list.sort(cmp);
    if (!_sortAscending) list = list.reversed.toList();
    return list;
  }

  // ─── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final total = filtered.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Barre d'outils (recherche + filtre + export) ──────
          _buildToolbar(total),
          const SizedBox(height: 12),

          // ─── Tableau ───────────────────────────────────────────
          Expanded(
            child: total == 0
                ? _buildEmptyState()
                : _buildTable(filtered),
          ),
          const SizedBox(height: 8),

          // ─── Pagination ────────────────────────────────────────
          if (total > 0) _buildPagination(total),
        ],
      ),
    );
  }

  // ─── Toolbar ───────────────────────────────────────────────────
  Widget _buildToolbar(int total) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Recherche
        SizedBox(
          width: 260,
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Rechercher un élève...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() {
                          _searchQuery = '';
                          _firstRow = 0;
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onChanged: (v) => setState(() {
              _searchQuery = v.trim();
              _firstRow = 0;
            }),
          ),
        ),

        // Filtre par classe
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.divider),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: _classFilter,
              hint: const Text('Toutes les classes'),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Toutes les classes'),
                ),
                ...AdminMockData.classes
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c),
                        ))
                    .toList(),
              ],
              onChanged: (v) => setState(() {
                _classFilter = v;
                _firstRow = 0;
              }),
            ),
          ),
        ),

        // Compteur
        Text(
          '$total élève(s)',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),

        // Export CSV (spacer + bouton à droite)
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: _exportCsv,
          icon: const Icon(Icons.download_outlined, size: 18),
          label: const Text('Export CSV'),
        ),
      ],
    );
  }

  // ─── Tableau ───────────────────────────────────────────────────
  Widget _buildTable(List<AdminStudent> students) {
    final visible = students.skip(_firstRow).take(_rowsPerPage).toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            columnSpacing: 18,
            horizontalMargin: 14,
            dataRowHeight: 56,
            headingRowHeight: 48,
            headingRowColor: WidgetStateProperty.all(AppColors.surfaceVariant),
            columns: [
              _buildColumn('Élève', _SortField.nom),
              _buildColumn('Classe', null),
              _buildColumn('Score', _SortField.score),
              _buildColumn('Streak', null),
              _buildColumn('Dernière activité', _SortField.activite),
              const DataColumn(
                label: Text('Statut',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
            rows: visible.map((s) => _buildRow(s)).toList(),
          ),
        ),
      ),
    );
  }

  DataColumn _buildColumn(String label, _SortField? sortField) {
    final isSorted = sortField != null && _sortField == sortField;
    return DataColumn(
      label: GestureDetector(
        onTap: sortField == null
            ? null
            : () => setState(() {
                  if (_sortField == sortField) {
                    _sortAscending = !_sortAscending;
                  } else {
                    _sortField = sortField;
                    _sortAscending = sortField == _SortField.nom;
                  }
                }),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isSorted
                      ? AppColors.primary
                      : AppColors.textPrimary,
                )),
            if (sortField != null) ...[
              const SizedBox(width: 4),
              Icon(
                isSorted
                    ? (_sortAscending
                        ? Icons.arrow_upward
                        : Icons.arrow_downward)
                    : Icons.unfold_more,
                size: 14,
                color: isSorted
                    ? AppColors.primary
                    : AppColors.textDisabled,
              ),
            ],
          ],
        ),
      ),
    );
  }

  DataRow _buildRow(AdminStudent s) {
    return DataRow(
      onSelectChanged: (_) => _showStudentDetail(s),
      cells: [
        // Élève (avatar + nom)
        DataCell(Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: _statusColor(s.status).withOpacity(0.15),
              child: Text(
                s.initiales,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _statusColor(s.status),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(s.nomComplet,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        )),
        DataCell(Text(s.classe)),
        DataCell(
          Row(
            children: [
              Text('${s.scoreGlobal}%',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(width: 6),
              _scoreBadge(s.scoreGlobal),
            ],
          ),
        ),
        DataCell(Row(
          children: [
            const Icon(Icons.local_fire_department_outlined,
                size: 14, color: AppColors.accent),
            const SizedBox(width: 4),
            Text('${s.streakDays} j'),
          ],
        )),
        DataCell(Text(s.derniereActiviteLabel)),
        DataCell(_statusChip(s.status)),
      ],
    );
  }

  Widget _scoreBadge(int score) {
    Color c;
    if (score >= 70) {
      c = AppColors.success;
    } else if (score >= 50) {
      c = AppColors.warning;
    } else {
      c = AppColors.error;
    }
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: c, shape: BoxShape.circle),
    );
  }

  Widget _statusChip(StudentStatus status) {
    final (label, color) = switch (status) {
      StudentStatus.actif => ('Actif', AppColors.success),
      StudentStatus.modere => ('Modéré', AppColors.warning),
      StudentStatus.inactif => ('Inactif', AppColors.error),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _statusColor(StudentStatus status) => switch (status) {
        StudentStatus.actif => AppColors.success,
        StudentStatus.modere => AppColors.warning,
        StudentStatus.inactif => AppColors.error,
      };

  // ─── Pagination ────────────────────────────────────────────────
  Widget _buildPagination(int total) {
    final last = ((_firstRow + _rowsPerPage) / _rowsPerPage).ceil();
    final pageCount = (total / _rowsPerPage).ceil();
    final currentPage = (_firstRow ~/ _rowsPerPage) + 1;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          'Page $currentPage / $pageCount '
          '(${_firstRow + 1}-${(_firstRow + _rowsPerPage).clamp(0, total)} '
          'sur $total)',
          style: const TextStyle(
              color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(width: 12),
        IconButton(
          tooltip: 'Page précédente',
          icon: const Icon(Icons.chevron_left),
          onPressed: _firstRow == 0
              ? null
              : () => setState(() => _firstRow =
                  (_firstRow - _rowsPerPage).clamp(0, total)),
        ),
        IconButton(
          tooltip: 'Page suivante',
          icon: const Icon(Icons.chevron_right),
          onPressed: _firstRow + _rowsPerPage >= total
              ? null
              : () => setState(() => _firstRow += _rowsPerPage),
        ),
      ],
    );
  }

  // ─── État vide ─────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off, size: 56, color: AppColors.textDisabled),
          const SizedBox(height: 12),
          const Text(
            'Aucun élève ne correspond à votre recherche.',
            style: AppTextStyles.body,
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => setState(() {
              _searchCtrl.clear();
              _searchQuery = '';
              _classFilter = null;
              _firstRow = 0;
            }),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Réinitialiser les filtres'),
          ),
        ],
      ),
    );
  }

  // ─── Dialog détails élève ──────────────────────────────────────
  void _showStudentDetail(AdminStudent s) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor:
                          _statusColor(s.status).withOpacity(0.15),
                      child: Text(
                        s.initiales,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _statusColor(s.status),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.nomComplet, style: AppTextStyles.h3),
                          Text(
                            '${s.classe} · ${s.derniereActiviteLabel}',
                            style: AppTextStyles.bodySmall,
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
                const SizedBox(height: 16),
                _buildDetailStat('Score global', '${s.scoreGlobal}%'),
                _buildDetailStat('Série de jours (streak)', '${s.streakDays} j'),
                _buildDetailStat(
                    'Statut', _statusLabel(s.status)),
                const Divider(height: 28),

                // Compétences fortes
                const Text('Compétences maîtrisées',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                if (s.competencesFortes.isEmpty)
                  const Text('Aucune pour le moment.',
                      style: AppTextStyles.bodySmall)
                else
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: s.competencesFortes
                        .map((c) => _tag(c, AppColors.success))
                        .toList(),
                  ),
                const SizedBox(height: 16),

                // Compétences faibles
                const Text('Compétences à renforcer',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                if (s.competencesFaibles.isEmpty)
                  const Text('Aucune compétence faible identifiée.',
                      style: AppTextStyles.bodySmall)
                else
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: s.competencesFaibles
                        .map((c) => _tag(c, AppColors.error))
                        .toList(),
                  ),
                const SizedBox(height: 16),

                // Simulations
                const Text('Simulations d\'examen',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(
                  '${s.simulationsDone} simulation(s) réalisée(s) · '
                  'Moyenne : ${s.simulationsAvgScore}%',
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: 20),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Email de relance préparé pour ${s.nomComplet}.',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.mail_outline, size: 18),
                      label: const Text('Contacter'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Fermer'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailStat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySmall),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _tag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _statusLabel(StudentStatus s) => switch (s) {
        StudentStatus.actif => 'Actif',
        StudentStatus.modere => 'Modéré',
        StudentStatus.inactif => 'Inactif',
      };

  // ─── Export CSV (UI seulement) ─────────────────────────────────
  void _exportCsv() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Export CSV préparé : ${_filtered.length} élève(s). '
          '(UI seulement — brancher sur GET /admin/export/students.csv)',
        ),
        backgroundColor: AppColors.info,
      ),
    );
  }
}

// ─── Enum interne pour le tri ────────────────────────────────────
enum _SortField { score, nom, activite }
