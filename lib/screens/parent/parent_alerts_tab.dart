// lib/screens/parent/parent_alerts_tab.dart
// Onglet "Alertes" du dashboard parent.
//
// Liste les alertes remontées au parent, classées en 5 catégories :
//   - Décrochage (rouge) : >7j sans révision
//   - Chute de notes (orange) : >5 points sur 30 jours
//   - Chapitre faible (jaune) : compétence <35% persistante
//   - Fin premium (violet) : abonnement arrive à échéance
//   - Message enseignant (bleu) : nouveau message non lu
//
// Filtres par type (chips). État vide rassurant.
// Chaque carte propose "Marquer comme lue".

import 'package:flutter/material.dart';

import '../../theme/adaptive_colors.dart';
import '../../theme/app_theme.dart';
import 'services/parent_service.dart';
import 'widgets/alert_card.dart';

class AlertsTab extends StatefulWidget {
  final List<ParentAlert> alerts;
  final ValueChanged<String> onMarkRead;

  const AlertsTab({
    super.key,
    required this.alerts,
    required this.onMarkRead,
  });

  @override
  State<AlertsTab> createState() => _AlertsTabState();
}

class _AlertsTabState extends State<AlertsTab> {
  AlertType? _filter; // null = toutes

  @override
  Widget build(BuildContext context) {
    final filtered = _filter == null
        ? widget.alerts
        : widget.alerts.where((a) => a.type == _filter).toList();

    // Trier par date décroissante (plus récent en premier) puis non lues
    // en premier.
    filtered.sort((a, b) {
      if (a.lue != b.lue) return a.lue ? 1 : -1;
      return b.date.compareTo(a.date);
    });

    final nonLues = widget.alerts.where((a) => !a.lue).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Bandeau compteur ─────────────────────────────────
          _buildCounter(nonLues),
          const SizedBox(height: 12),

          // ─── Filtres par type ─────────────────────────────────
          _buildFilterChips(),
          const SizedBox(height: 12),

          // ─── Liste des alertes ────────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? _buildEmptyState(context)
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => AlertCard(
                      alert: filtered[i],
                      onMarkRead: filtered[i].lue
                          ? null
                          : () => widget.onMarkRead(filtered[i].id),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ─── Bandeau compteur ──────────────────────────────────────────
  Widget _buildCounter(int nonLues) {
    final hasAlerts = nonLues > 0;
    final color = hasAlerts ? AppColors.warning : AppColors.success;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        children: [
          Icon(
            hasAlerts
                ? Icons.notifications_active
                : Icons.check_circle_outline,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              hasAlerts
                  ? '$nonLues alerte(s) nécessite(nt) votre attention.'
                  : 'Aucune alerte. Tout va bien pour vos enfants !',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: color,
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
      _filterChip('Toutes', null, AppColors.primary),
      _filterChip('Décrochage', AlertType.decrochage, AppColors.error),
      _filterChip('Chute de notes', AlertType.chuteNotes, AppColors.warning),
      _filterChip('Chapitre faible', AlertType.chapitreFaible,
          const Color(0xFFFBC02D)),
      _filterChip('Fin premium', AlertType.finPremium,
          const Color(0xFF6A1B9A)),
      _filterChip('Messages', AlertType.messageEnseignant, AppColors.info),
    ];
    return Wrap(spacing: 8, runSpacing: 6, children: chips);
  }

  Widget _filterChip(String label, AlertType? type, Color color) {
    final selected = _filter == type;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: color.withOpacity(0.18),
      backgroundColor: AdaptiveColors.surface(context),
      side: BorderSide(
        color: selected ? color : AdaptiveColors.divider(context),
        width: 1,
      ),
      labelStyle: TextStyle(
        color: selected ? color : AdaptiveColors.textSecondary(context),
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        fontSize: 13,
      ),
      onSelected: (_) => setState(() => _filter = type),
    );
  }

  // ─── État vide ─────────────────────────────────────────────────
  Widget _buildEmptyState(BuildContext context) {
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
            child:
                const Icon(Icons.check, size: 44, color: AppColors.success),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune alerte. Tout va bien pour vos enfants !',
            style: AppTextStyles.h3
                .copyWith(color: AdaptiveColors.textPrimary(context)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Vous serez notifié si un de vos enfants présente un signe de '
            'décrochage, une chute de notes ou un chapitre faible persistant.',
            style: AppTextStyles.bodySmall
                .copyWith(color: AdaptiveColors.textSecondary(context)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
