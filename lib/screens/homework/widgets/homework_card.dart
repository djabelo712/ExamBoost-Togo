// lib/screens/homework/widgets/homework_card.dart
// Carte affichant un devoir dans une liste (élève ou enseignant).
//
// Affiche :
//   - bandeau couleur matière + icône matière,
//   - titre, description courte,
//   - chips : matière, classe(s), nb questions, points,
//   - deadline avec icône (et pastille rouge si dépassée),
//   - badge statut (à faire / en cours / rendu / manqué) pour élève,
//   - badge progression (% rendus) pour enseignant.
//
// Tap → navigue vers l'écran cible passé en paramètre.

import 'package:flutter/material.dart';

import '../../../theme/adaptive_colors.dart';
import '../../../theme/app_theme.dart';
import '../models/homework.dart';
import '../models/homework_submission.dart';

class HomeworkCard extends StatelessWidget {
  final Homework homework;

  /// Soumission de l'élève courant (null si pas commencé).
  /// Utilisée pour afficher le statut côté élève. Ignorée si null.
  final HomeworkSubmission? soumission;

  /// Stats agrégées (côté enseignant) — affiche % de rendus.
  /// Si fournie, la carte bascule en mode enseignant.
  final int? nbRendus;
  final int? effectif;

  /// Action au tap.
  final VoidCallback? onTap;

  const HomeworkCard({
    super.key,
    required this.homework,
    this.soumission,
    this.nbRendus,
    this.effectif,
    this.onTap,
  });

  bool get _isTeacherMode => nbRendus != null && effectif != null;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 10),
              Text(
                homework.titre,
                style: AppTextStyles.h3.copyWith(
                  color: AdaptiveColors.textPrimary(context),
                  fontSize: 16,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                homework.description,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AdaptiveColors.textSecondary(context),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              _buildChipsRow(context),
              const SizedBox(height: 10),
              _buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Header : icône matière + badge statut ─────────────────────
  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: homework.matiereColor.withOpacity(
                Theme.of(context).brightness == Brightness.dark
                    ? 0.20
                    : 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(homework.matiereIcon,
              color: homework.matiereColor, size: 22),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            homework.matiere,
            style: AppTextStyles.label.copyWith(
              color: homework.matiereColor,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
        _buildStatusBadge(context),
      ],
    );
  }

  // ─── Badge de statut (élève ou enseignant) ────────────────────
  Widget _buildStatusBadge(BuildContext context) {
    if (_isTeacherMode) {
      // Mode enseignant : badge "% rendus"
      final taux = effect! > 0 ? (nbRendus! / effect!) * 100 : 0;
      return _Badge(
        label: '$nbRendus/$effectif rendus',
        color: _tauxColor(taux),
        bgColor: _tauxColor(taux).withOpacity(
            Theme.of(context).brightness == Brightness.dark ? 0.20 : 0.12),
      );
    }

    // Mode élève : statut basé sur soumission
    final statut = homework.statutPourEleve(
      aRendu: soumission?.termine ?? false,
      enCours: soumission?.enCours ?? false,
    );
    return _Badge(
      label: _statutLabel(statut),
      color: _statutColor(statut),
      bgColor: _statutColor(statut).withOpacity(
          Theme.of(context).brightness == Brightness.dark ? 0.20 : 0.12),
    );
  }

  // ─── Chips : classe(s) + nb questions + points ────────────────
  Widget _buildChipsRow(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _Chip(
          icon: Icons.group_outlined,
          label: homework.classes.join(', '),
          color: AdaptiveColors.textSecondary(context),
        ),
        _Chip(
          icon: Icons.quiz_outlined,
          label: '${homework.nbQuestions} questions',
          color: AdaptiveColors.textSecondary(context),
        ),
        _Chip(
          icon: Icons.star_outline,
          label: '${homework.pointsTotal} pts',
          color: AppColors.accent,
        ),
      ],
    );
  }

  // ─── Footer : deadline + durée ────────────────────────────────
  Widget _buildFooter(BuildContext context) {
    final isLate = homework.isDeadlineDepassee;
    return Row(
      children: [
        Icon(
          isLate ? Icons.warning_amber_rounded : Icons.event_outlined,
          size: 16,
          color: isLate ? AppColors.error : AdaptiveColors.textSecondary(context),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            _deadlineLabel(),
            style: AppTextStyles.bodySmall.copyWith(
              color: isLate
                  ? AppColors.error
                  : AdaptiveColors.textSecondary(context),
              fontWeight: isLate ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Icon(
          Icons.timer_outlined,
          size: 16,
          color: AdaptiveColors.textSecondary(context),
        ),
        const SizedBox(width: 4),
        Text(
          '${homework.dureeMinutes} min',
          style: AppTextStyles.bodySmall.copyWith(
            color: AdaptiveColors.textSecondary(context),
          ),
        ),
      ],
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────

  String _deadlineLabel() {
    final now = DateTime.now();
    final diff = homework.dateLimit.difference(now);
    if (homework.isDeadlineDepassee) {
      if (diff.inDays.abs() == 0) return 'Deadline dépassée (aujourd\'hui)';
      return 'Deadline dépassée (${diff.inDays.abs()} j)';
    }
    if (diff.inDays > 0) return 'À rendre dans ${diff.inDays} jour(s)';
    if (diff.inHours > 0) return 'À rendre dans ${diff.inHours} h';
    return 'À rendre aujourd\'hui';
  }

  String _statutLabel(HomeworkStatus s) {
    switch (s) {
      case HomeworkStatus.aFaire:
        return 'À FAIRE';
      case HomeworkStatus.enCours:
        return 'EN COURS';
      case HomeworkStatus.rendu:
        return 'RENDU';
      case HomeworkStatus.manque:
        return 'MANQUÉ';
    }
  }

  Color _statutColor(HomeworkStatus s) {
    switch (s) {
      case HomeworkStatus.aFaire:
        return AppColors.info;
      case HomeworkStatus.enCours:
        return AppColors.warning;
      case HomeworkStatus.rendu:
        return AppColors.success;
      case HomeworkStatus.manque:
        return AppColors.error;
    }
  }

  Color _tauxColor(double taux) {
    if (taux >= 75) return AppColors.success;
    if (taux >= 50) return AppColors.warning;
    return AppColors.error;
  }
}

// ─── Widgets privés réutilisables ──────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;
  const _Badge({required this.label, required this.color, required this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Chip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AdaptiveColors.surfaceVariant(context),
        borderRadius: BorderRadius.circular(8),
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
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
