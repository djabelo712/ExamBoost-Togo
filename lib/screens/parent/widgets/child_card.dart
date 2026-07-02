// lib/screens/parent/widgets/child_card.dart
// Carte résumée d'un enfant dans l'onglet "Enfants".
//
// Affiche : avatar (initiales), nom complet, classe, établissement,
// score global (avec barre de progression horizontale), streak, dernière
// activité, badge écart vs moyenne classe (+N pts / -N pts).
//
// Tap sur la carte → callback onChildTap (le dashboard bascule vers
// l'onglet Progression avec l'enfant pré-sélectionné).
//
// Style : carte arrondie, surface adaptative, bordure latérale colorée
// selon le statut (vert = actif, orange = modéré, rouge = inactif).

import 'package:flutter/material.dart';

import '../../../theme/adaptive_colors.dart';
import '../../../theme/app_theme.dart';
import '../services/parent_service.dart';

class ChildCard extends StatelessWidget {
  final Child child;
  final VoidCallback? onChildTap;

  const ChildCard({super.key, required this.child, this.onChildTap});

  // ─── Statut dérivé ─────────────────────────────────────────────
  // Actif : <2j sans activité. Modéré : 2-7j. Inactif : >7j (décrochage).
  ChildStatus get _status {
    if (child.daysSinceLastActive <= 1) return ChildStatus.actif;
    if (child.daysSinceLastActive <= 7) return ChildStatus.modere;
    return ChildStatus.inactif;
  }

  Color _statusColor(BuildContext context) => switch (_status) {
        ChildStatus.actif => AppColors.success,
        ChildStatus.modere => AppColors.warning,
        ChildStatus.inactif => AppColors.error,
      };

  String _statusLabel() => switch (_status) {
        ChildStatus.actif => 'Actif',
        ChildStatus.modere => 'Modéré',
        ChildStatus.inactif => 'Inactif',
      };

  String _lastActiveLabel() {
    if (child.daysSinceLastActive == 0) return 'Aujourd\'hui';
    if (child.daysSinceLastActive == 1) return 'Hier';
    return 'Il y a ${child.daysSinceLastActive} jours';
  }

  // ─── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(context);
    final ecart = child.ecartClasse;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onChildTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color: AdaptiveColors.surface(context),
            borderRadius: BorderRadius.circular(14),
            border: Border(
              left: BorderSide(color: statusColor, width: 4),
            ),
            boxShadow: [
              BoxShadow(
                color: AdaptiveColors.shadowColor(context),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Ligne 1 : avatar + nom + statut ──────────
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AdaptiveColors.primarySurface(context),
                      child: Text(
                        child.initiales,
                        style: TextStyle(
                          color: AdaptiveColors.primary(context),
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            child.nomComplet,
                            style: AppTextStyles.h3.copyWith(
                                color: AdaptiveColors.textPrimary(context),
                                fontSize: 16),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${child.classe} · ${child.etablissement}',
                            style: AppTextStyles.bodySmall.copyWith(
                                color: AdaptiveColors.textSecondary(context),
                                fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _statusLabel(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ─── Ligne 2 : score global + barre ───────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '${child.scoreGlobal}%',
                      style: AppTextStyles.h2.copyWith(
                          color: AdaptiveColors.textPrimary(context),
                          fontSize: 22,
                          fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Score global (BKT)',
                            style: AppTextStyles.bodySmall.copyWith(
                                color: AdaptiveColors.textSecondary(context),
                                fontSize: 11),
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: child.scoreGlobal / 100,
                              minHeight: 6,
                              backgroundColor:
                                  AdaptiveColors.surfaceVariant(context),
                              color: AdaptiveColors.primary(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ─── Ligne 3 : 3 chips (streak, dernière activité, écart) ─
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _chip(
                      Icons.local_fire_department_outlined,
                      '${child.streakDays} j',
                      AppColors.accent,
                      context,
                    ),
                    _chip(
                      Icons.access_time,
                      _lastActiveLabel(),
                      AdaptiveColors.textSecondary(context),
                      context,
                    ),
                    _chip(
                      ecart >= 0
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      '${ecart >= 0 ? '+' : ''}$ecart vs classe',
                      ecart >= 0 ? AppColors.success : AppColors.error,
                      context,
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

  Widget _chip(
      IconData icon, String label, Color color, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

enum ChildStatus { actif, modere, inactif }
