// lib/screens/homework/homework_detail_screen.dart
// Détail d'un devoir (côté élève) + bouton "Commencer" / "Reprendre" /
// "Voir mes résultats".
//
// Affiche :
//   - Header couleur matière (icône, matière, classe),
//   - Titre, description,
//   - Méta-info : deadline, durée, nb questions, points,
//   - Liste des questions (aperçu énoncé, sans réponses),
//   - CTA principal : adapté au statut de l'élève.
//
// Redirige vers :
//   - HomeworkSessionScreen si "Commencer"/"Reprendre",
//   - HomeworkResultsScreen si "Voir mes résultats".

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/adaptive_colors.dart';
import '../../theme/app_theme.dart';
import '../models/homework.dart';
import '../models/homework_submission.dart';
import '../services/homework_service.dart';
import 'homework_results_screen.dart';
import 'homework_session_screen.dart';

class HomeworkDetailScreen extends StatelessWidget {
  final String homeworkId;

  const HomeworkDetailScreen({super.key, required this.homeworkId});

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeworkService>(
      builder: (context, service, _) {
        final homework = service.homeworks.firstWhere(
          (h) => h.id == homeworkId,
          orElse: () => service.homeworks.first,
        );
        final soumission = service.getSoumissionForCurrentEleve(homeworkId);

        return Scaffold(
          appBar: AppBar(
            title: Text(homework.matiere),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeaderCard(context, homework),
                const SizedBox(height: 20),
                _buildMetaRow(context, homework),
                const SizedBox(height: 20),
                _buildDescription(context, homework),
                const SizedBox(height: 20),
                _buildQuestionsPreview(context, homework),
                const SizedBox(height: 24),
                _buildCtaButton(context, homework, soumission, service),
                const SizedBox(height: 12),
                if (soumission?.termine == true)
                  TextButton.icon(
                    onPressed: () => _voirResultats(context, homework.id),
                    icon: const Icon(Icons.analytics_outlined, size: 18),
                    label: const Text('Revoir mes résultats'),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Header couleur matière ──────────────────────────────────
  Widget _buildHeaderCard(BuildContext context, Homework hw) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            hw.matiereColor,
            hw.matiereColor.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: hw.matiereColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(hw.matiereIcon, color: Colors.white, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  hw.matiere,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _buildDeadlineBadge(hw),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            hw.titre,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Par ${hw.enseignantNom}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeadlineBadge(Homework hw) {
    final isLate = hw.isDeadlineDepassee;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isLate
            ? Colors.red.withOpacity(0.25)
            : Colors.white.withOpacity(0.20),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isLate ? 'CLOS' : 'OUVERT',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ─── Méta-info en grille ─────────────────────────────────────
  Widget _buildMetaRow(BuildContext context, Homework hw) {
    return Row(
      children: [
        Expanded(
          child: _metaCard(
            context,
            icon: Icons.quiz_outlined,
            label: 'Questions',
            value: '${hw.nbQuestions}',
            color: AppColors.info,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _metaCard(
            context,
            icon: Icons.star_outline,
            label: 'Points',
            value: '${hw.pointsTotal}',
            color: AppColors.accent,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _metaCard(
            context,
            icon: Icons.timer_outlined,
            label: 'Durée',
            value: '${hw.dureeMinutes} min',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _metaCard(
            context,
            icon: Icons.event_outlined,
            label: 'Deadline',
            value: _deadlineShort(hw),
            color: hw.isDeadlineDepassee ? AppColors.error : AppColors.success,
          ),
        ),
      ],
    );
  }

  Widget _metaCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AdaptiveColors.surface(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AdaptiveColors.divider(context)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.h3.copyWith(
              color: AdaptiveColors.textPrimary(context),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: AdaptiveColors.textSecondary(context),
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _deadlineShort(Homework hw) {
    final now = DateTime.now();
    final diff = hw.dateLimit.difference(now);
    if (hw.isDeadlineDepassee) return 'CLOS';
    if (diff.inDays > 0) return '${diff.inDays} j';
    if (diff.inHours > 0) return '${diff.inHours} h';
    return 'Urgent';
  }

  // ─── Description ─────────────────────────────────────────────
  Widget _buildDescription(BuildContext context, Homework hw) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdaptiveColors.surface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdaptiveColors.divider(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Consignes',
                style: AppTextStyles.h3.copyWith(fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            hw.description,
            style: AppTextStyles.body.copyWith(
              color: AdaptiveColors.textPrimary(context),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Aperçu des questions ────────────────────────────────────
  Widget _buildQuestionsPreview(BuildContext context, Homework hw) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Questions (${hw.nbQuestions})',
          style: AppTextStyles.h3.copyWith(fontSize: 16),
        ),
        const SizedBox(height: 10),
        ...hw.questions.asMap().entries.map((entry) {
          final i = entry.key;
          final q = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AdaptiveColors.surface(context),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AdaptiveColors.divider(context)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        q.enonce,
                        style: AppTextStyles.body.copyWith(
                          color: AdaptiveColors.textPrimary(context),
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            q.isQcm ? Icons.list_alt : Icons.edit_outlined,
                            size: 12,
                            color: AdaptiveColors.textSecondary(context),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            q.isQcm
                                ? 'QCM • ${q.choix!.length} propositions'
                                : 'Question ouverte',
                            style: TextStyle(
                              color: AdaptiveColors.textSecondary(context),
                              fontSize: 11,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${q.points} pt${q.points > 1 ? 's' : ''}',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ─── CTA adapté au statut ────────────────────────────────────
  Widget _buildCtaButton(
    BuildContext context,
    Homework hw,
    HomeworkSubmission? sub,
    HomeworkService service,
  ) {
    final statut = hw.statutPourEleve(
      aRendu: sub?.termine ?? false,
      enCours: sub?.enCours ?? false,
    );

    String label;
    IconData icon;
    Color color;
    VoidCallback onTap;

    switch (statut) {
      case HomeworkStatus.aFaire:
        label = 'Commencer le devoir';
        icon = Icons.play_arrow_rounded;
        color = AppColors.primary;
        onTap = () => _commencer(context, hw.id, service);
        break;
      case HomeworkStatus.enCours:
        // Calcule la progression
        final repondues = sub?.reponses.length ?? 0;
        label = 'Reprendre ($repondues/${hw.nbQuestions} répondues)';
        icon = Icons.refresh_rounded;
        color = AppColors.warning;
        onTap = () => _reprendre(context, hw.id);
        break;
      case HomeworkStatus.rendu:
        label = 'Voir mes résultats';
        icon = Icons.analytics_outlined;
        color = AppColors.success;
        onTap = () => _voirResultats(context, hw.id);
        break;
      case HomeworkStatus.manque:
        // L'élève peut quand même faire le devoir en "auto-correction"
        // (ne sera pas compté dans les stats, mais il pourra s'auto-évaluer).
        label = 'Faire en auto-correction (deadline dépassée)';
        icon = Icons.history_edu_outlined;
        color = AppColors.error;
        onTap = () => _commencer(context, hw.id, service);
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 22),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // ─── Navigation ──────────────────────────────────────────────
  void _commencer(BuildContext context, String homeworkId, HomeworkService service) {
    // Crée la soumission "en cours" si première ouverture
    service.commencerHomework(homeworkId);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HomeworkSessionScreen(homeworkId: homeworkId),
      ),
    );
  }

  void _reprendre(BuildContext context, String homeworkId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HomeworkSessionScreen(homeworkId: homeworkId),
      ),
    );
  }

  void _voirResultats(BuildContext context, String homeworkId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HomeworkResultsScreen(homeworkId: homeworkId),
      ),
    );
  }
}
