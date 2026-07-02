// lib/screens/homework/widgets/homework_progress.dart
// Barre de progression d'un devoir en cours (élève) ou stats agrégées.
//
// Variantes :
//   - [HomeworkProgressBar] : barre fine style LinearProgressIndicator,
//     utilisée en en-tête de session (numéro question courante).
//   - [HomeworkProgressRing] : anneau circulaire avec % au centre,
//     utilisé dans le détail devoir / écran de résultats.
//   - [HomeworkClassProgressRow] : 3 mini-cards "Rendus / En cours /
//     Manqués" pour le tableau enseignant.

import 'package:flutter/material.dart';

import '../../../theme/adaptive_colors.dart';
import '../../../theme/app_theme.dart';

// ─── Barre linéaire simple ─────────────────────────────────────

class HomeworkProgressBar extends StatelessWidget {
  final int current;
  final int total;
  final Color? color;

  const HomeworkProgressBar({
    super.key,
    required this.current,
    required this.total,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? current / total : 0.0;
    return LinearProgressIndicator(
      value: progress,
      minHeight: 4,
      backgroundColor: AdaptiveColors.primarySurface(context),
      valueColor: AlwaysStoppedAnimation<Color>(color ?? AppColors.primary),
    );
  }
}

// ─── Anneau circulaire avec % au centre ────────────────────────

class HomeworkProgressRing extends StatelessWidget {
  /// Pourcentage 0-100.
  final int pourcentage;

  /// Taille du widget (carré).
  final double size;

  /// Épaisseur de l'anneau.
  final double strokeWidth;

  /// Couleur de l'anneau (sinon dérivée du %).
  final Color? color;

  /// Texte sous le % (ex: "réussite").
  final String? subtitle;

  const HomeworkProgressRing({
    super.key,
    required this.pourcentage,
    this.size = 110,
    this.strokeWidth = 10,
    this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? _pourcentageColor(pourcentage);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Cercle de fond
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: pourcentage / 100,
              strokeWidth: strokeWidth,
              backgroundColor:
                  c.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(c),
            ),
          ),
          // Texte central
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$pourcentage%',
                style: AppTextStyles.h1.copyWith(
                  color: c,
                  fontSize: size * 0.28,
                  height: 1,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AdaptiveColors.textSecondary(context),
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Color _pourcentageColor(int p) {
    if (p >= 70) return AppColors.success;
    if (p >= 40) return AppColors.warning;
    return AppColors.error;
  }
}

// ─── Ligne de stats agrégées (côté enseignant) ─────────────────

class HomeworkClassProgressRow extends StatelessWidget {
  final int nbRendus;
  final int nbEnCours;
  final int nbManques;
  final int effectif;

  const HomeworkClassProgressRow({
    super.key,
    required this.nbRendus,
    required this.nbEnCours,
    required this.nbManques,
    required this.effectif,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Rendus',
            value: '$nbRendus',
            subtitle: _pct(nbRendus),
            icon: Icons.check_circle_outline,
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            label: 'En cours',
            value: '$nbEnCours',
            subtitle: _pct(nbEnCours),
            icon: Icons.pending_actions_outlined,
            color: AppColors.warning,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            label: 'Manqués',
            value: '$nbManques',
            subtitle: _pct(nbManques),
            icon: Icons.cancel_outlined,
            color: AppColors.error,
          ),
        ),
      ],
    );
  }

  String _pct(int n) {
    if (effectif == 0) return '0%';
    return '${(n / effectif * 100).round()}%';
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AdaptiveColors.surface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdaptiveColors.divider(context), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyles.h2.copyWith(
              color: AdaptiveColors.textPrimary(context),
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.label.copyWith(
              color: AdaptiveColors.textSecondary(context),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
