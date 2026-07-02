// lib/screens/parent/widgets/alert_card.dart
// Carte d'alerte affichée dans l'onglet "Alertes".
//
// Structure : icône type (couleur sémantique) + enfant concerné + titre
// + description + date + chip "non lue" + bouton "Marquer comme lue".
//
// 5 types d'alerte :
//   - décrochage (rouge, icône trending_down)
//   - chuteNotes (orange, icône south_west)
//   - chapitreFaible (jaune, icône priority_high)
//   - finPremium (violet, icône workspace_premium)
//   - messageEnseignant (bleu info, icône chat_bubble)

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../theme/adaptive_colors.dart';
import '../../../theme/app_theme.dart';
import '../services/parent_service.dart';

class AlertCard extends StatelessWidget {
  final ParentAlert alert;
  final VoidCallback? onMarkRead;

  const AlertCard({super.key, required this.alert, this.onMarkRead});

  // ─── Helpers sémantiques ───────────────────────────────────────
  Color _color(BuildContext context) => switch (alert.type) {
        AlertType.decrochage => AppColors.error,
        AlertType.chuteNotes => AppColors.warning,
        AlertType.chapitreFaible => const Color(0xFFFBC02D),
        AlertType.finPremium => const Color(0xFF6A1B9A),
        AlertType.messageEnseignant => AppColors.info,
      };

  IconData _icon() => switch (alert.type) {
        AlertType.decrochage => Icons.trending_down,
        AlertType.chuteNotes => Icons.south_west,
        AlertType.chapitreFaible => Icons.priority_high,
        AlertType.finPremium => Icons.workspace_premium_outlined,
        AlertType.messageEnseignant => Icons.chat_bubble_outline,
      };

  String _typeLabel() => switch (alert.type) {
        AlertType.decrochage => 'Décrochage',
        AlertType.chuteNotes => 'Chute de notes',
        AlertType.chapitreFaible => 'Chapitre faible',
        AlertType.finPremium => 'Fin premium',
        AlertType.messageEnseignant => 'Message enseignant',
      };

  String _formatDate() {
    final now = DateTime.now();
    final diff = now.difference(alert.date);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays} j';
    return DateFormat('dd/MM/yyyy').format(alert.date);
  }

  // ─── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final color = _color(context);

    return Container(
      decoration: BoxDecoration(
        color: AdaptiveColors.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border(
          left: BorderSide(color: color, width: 4),
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Icône type ──────────────────────────────────────
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_icon(), color: color, size: 22),
            ),
            const SizedBox(width: 12),

            // ─── Contenu ─────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          alert.childName,
                          style: AppTextStyles.bodySmall.copyWith(
                              color: AdaptiveColors.textSecondary(context),
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (!alert.lue)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    alert.titre,
                    style: AppTextStyles.h3.copyWith(
                        color: AdaptiveColors.textPrimary(context),
                        fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alert.description,
                    style: AppTextStyles.bodySmall.copyWith(
                        color: AdaptiveColors.textPrimary(context),
                        fontSize: 13,
                        height: 1.4),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _typeLabel(),
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(),
                        style: AppTextStyles.bodySmall.copyWith(
                            color: AdaptiveColors.textSecondary(context),
                            fontSize: 11),
                      ),
                      const Spacer(),
                      if (!alert.lue && onMarkRead != null)
                        TextButton.icon(
                          onPressed: onMarkRead,
                          icon: const Icon(Icons.check_circle_outline,
                              size: 16),
                          label: const Text('Marquer lue'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            minimumSize: const Size(0, 28),
                            tapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            textStyle: const TextStyle(fontSize: 12),
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
}
