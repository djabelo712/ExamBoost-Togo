// lib/screens/admin/alerts_tab.dart
// Onglet "Alertes" du dashboard directeur
//
// Liste les élèves en difficulté, classés en 3 catégories :
//   - Décrochage (rouge) : non connecté depuis 7+ jours
//   - Chute de score (orange) : -10 points ou plus sur 30 jours
//   - Compétence bloquée (jaune) : compétence < 30% depuis 2+ semaines
//
// Chaque alerte propose 2 actions : Contacter (email/SMS simulé) et
// Voir profil (renvoie vers l'onglet Élèves avec dialog détails).
//
// État vide : "Aucune alerte. Tout va bien dans votre établissement !"

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'admin_dashboard_screen.dart';

class AlertsTab extends StatefulWidget {
  const AlertsTab({super.key});

  @override
  State<AlertsTab> createState() => _AlertsTabState();
}

class _AlertsTabState extends State<AlertsTab> {
  AlertType? _filter; // null = toutes

  @override
  Widget build(BuildContext context) {
    final all = AdminMockData.alerts;
    final filtered =
        _filter == null ? all : all.where((a) => a.type == _filter).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Compteur global ──────────────────────────────────
          _buildCounter(all.length),
          const SizedBox(height: 12),

          // ─── Filtres par type ─────────────────────────────────
          _buildFilterChips(),
          const SizedBox(height: 12),

          // ─── Liste des alertes ───────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _buildAlertCard(filtered[i]),
                  ),
          ),
        ],
      ),
    );
  }

  // ─── Compteur ──────────────────────────────────────────────────
  Widget _buildCounter(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: count > 0
            ? const Color(0xFFFFF3E0) // accentSurface
            : const Color(0xFFE8F5ED), // primarySurface
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: count > 0 ? AppColors.warning : AppColors.success,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            count > 0
                ? Icons.warning_amber_rounded
                : Icons.check_circle_outline,
            color: count > 0 ? AppColors.warning : AppColors.success,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              count == 0
                  ? 'Aucune alerte. Tout va bien dans votre établissement !'
                  : '$count élève(s) nécessite(nt) votre attention.',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: count > 0
                    ? AppColors.warning
                    : AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Chips filtres ─────────────────────────────────────────────
  Widget _buildFilterChips() {
    final chips = <Widget>[
      _filterChip('Toutes', null),
      _filterChip('Décrochage', AlertType.decrochage),
      _filterChip('Chute de score', AlertType.chuteScore),
      _filterChip('Compétence bloquée', AlertType.competenceBloquee),
    ];
    return Wrap(spacing: 8, runSpacing: 6, children: chips);
  }

  Widget _filterChip(String label, AlertType? type) {
    final selected = _filter == type;
    final color = type == null
        ? AppColors.primary
        : _alertColor(type);
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: color.withOpacity(0.18),
      backgroundColor: AppColors.surface,
      side: BorderSide(
        color: selected ? color : AppColors.divider,
        width: 1,
      ),
      labelStyle: TextStyle(
        color: selected ? color : AppColors.textSecondary,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        fontSize: 13,
      ),
      onSelected: (_) => setState(() => _filter = type),
    );
  }

  // ─── Carte d'alerte ────────────────────────────────────────────
  Widget _buildAlertCard(AdminAlert alert) {
    final color = _alertColor(alert.type);
    final typeLabel = _alertTypeLabel(alert.type);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: color, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar élève
            CircleAvatar(
              radius: 20,
              backgroundColor: color.withOpacity(0.15),
              child: Text(
                _initiales(alert.prenom, alert.nom),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Détails
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          alert.nomComplet,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          typeLabel,
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    alert.classe,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    alert.description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Actions
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _contactStudent(alert),
                        icon: const Icon(Icons.mail_outline, size: 16),
                        label: const Text('Contacter'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          textStyle: const TextStyle(fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () => _viewProfile(alert),
                        icon: const Icon(Icons.person_outline, size: 16),
                        label: const Text('Voir profil'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          textStyle: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── État vide ─────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check,
                size: 44, color: AppColors.success),
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucune alerte. Tout va bien dans votre établissement !',
            style: AppTextStyles.h3,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Aucun élève ne présente actuellement de signe de décrochage, '
            'de chute de score ou de compétence bloquée.',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────
  Color _alertColor(AlertType type) => switch (type) {
        AlertType.decrochage => AppColors.error,
        AlertType.chuteScore => AppColors.warning,
        AlertType.competenceBloquee => const Color(0xFFFBC02D),
      };

  String _alertTypeLabel(AlertType type) => switch (type) {
        AlertType.decrochage => 'Décrochage',
        AlertType.chuteScore => 'Chute de score',
        AlertType.competenceBloquee => 'Compétence bloquée',
      };

  String _initiales(String prenom, String nom) {
    final i1 = prenom.isNotEmpty ? prenom[0].toUpperCase() : '';
    final i2 = nom.isNotEmpty ? nom[0].toUpperCase() : '';
    return '$i1$i2';
  }

  // ─── Actions ───────────────────────────────────────────────────
  void _contactStudent(AdminAlert alert) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Email/SMS de relance préparé pour ${alert.nomComplet} '
          '(${alert.classe}).',
        ),
        backgroundColor: AppColors.info,
      ),
    );
  }

  /// Recherche l'élève correspondant dans la mock data et affiche le
  /// dialog de profil (réutilise le même rendu que l'onglet Élèves).
  void _viewProfile(AdminAlert alert) {
    final student = AdminMockData.students.firstWhere(
      (s) =>
          s.prenom == alert.prenom &&
          s.nom == alert.nom &&
          s.classe == alert.classe,
      orElse: () => AdminMockData.students.first,
    );

    // Affichage simplifié du profil via un Dialog réutilisable
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
                          _alertColor(alert.type).withOpacity(0.15),
                      child: Text(
                        student.initiales,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _alertColor(alert.type),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(student.nomComplet, style: AppTextStyles.h3),
                          Text(
                            '${student.classe} · ${student.derniereActiviteLabel}',
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
                const SizedBox(height: 14),
                _row('Score global', '${student.scoreGlobal}%'),
                _row('Streak', '${student.streakDays} jours'),
                _row('Statut', _statusLabel(student.status)),
                const Divider(height: 24),
                const Text('Alerte active',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _alertColor(alert.type).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(alert.description,
                      style: const TextStyle(fontSize: 13)),
                ),
                const SizedBox(height: 14),
                const Text('Compétences à renforcer',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                if (student.competencesFaibles.isEmpty)
                  const Text('Aucune compétence faible identifiée.',
                      style: AppTextStyles.bodySmall)
                else
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: student.competencesFaibles
                        .map((c) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.error.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(c,
                                  style: const TextStyle(
                                      color: AppColors.error,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500)),
                            ))
                        .toList(),
                  ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
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

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySmall),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _statusLabel(StudentStatus s) => switch (s) {
        StudentStatus.actif => 'Actif',
        StudentStatus.modere => 'Modéré',
        StudentStatus.inactif => 'Inactif',
      };
}
