// lib/screens/homework/homework_results_screen.dart
// Résultats d'un devoir pour l'élève (auto-correction détaillée).
//
// Affiche :
//   - Header : score circulaire %, note /20, temps passé, badge "EN RETARD",
//   - Récap rapide : nb questions correctes / total,
//   - Feedback pédagogique automatique (encart orange avec message
//     motivant + phrase clé "Tu progresses en {matière} ! Continue !"),
//   - Liste détaillée des questions avec :
//       * énoncé,
//       * ta réponse (surlignée rouge si faux, verte si juste),
//       * bonne réponse (si faux),
//       * explication pédagogique.
//   - Boutons : "Retour aux devoirs" / "Refaire le devoir" (si possible).
//
// Pour les questions ouvertes sans réponse stricte, l'élève doit
// s'auto-évaluer (juste/faux) avant de voir la correction.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/adaptive_colors.dart';
import '../../theme/app_theme.dart';
import '../models/homework.dart';
import '../models/homework_submission.dart';
import '../services/homework_service.dart';
import 'widgets/homework_progress.dart';

class HomeworkResultsScreen extends StatelessWidget {
  final String homeworkId;

  const HomeworkResultsScreen({super.key, required this.homeworkId});

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeworkService>(
      builder: (context, service, _) {
        final homework = service.homeworks.firstWhere(
          (h) => h.id == homeworkId,
          orElse: () => service.homeworks.first,
        );
        final sub = service.getSoumissionForCurrentEleve(homeworkId);

        if (sub == null || !sub.termine) {
          return _buildNotSubmitted(context, homework);
        }

        final pourcentage = ((sub.score / homework.pointsTotal) * 100).round();
        final note20 = (sub.score / homework.pointsTotal) * 20;
        final correctCount =
            sub.reponses.values.where((a) => a.isCorrect).length;
        final enRetard = sub.isEnRetard(homework);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Résultats'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildScoreHeader(
                  context,
                  homework: homework,
                  sub: sub,
                  pourcentage: pourcentage,
                  note20: note20,
                  correctCount: correctCount,
                  enRetard: enRetard,
                ),
                const SizedBox(height: 20),
                _buildFeedback(context, homework, pourcentage),
                const SizedBox(height: 20),
                _buildStatsRow(context, sub, homework),
                const SizedBox(height: 20),
                _buildDetailTitle(context),
                const SizedBox(height: 12),
                ..._buildDetailedCorrections(context, homework, sub),
                const SizedBox(height: 24),
                _buildActionButtons(context, homework),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Cas non soumis ──────────────────────────────────────────
  Widget _buildNotSubmitted(BuildContext context, Homework homework) {
    return Scaffold(
      appBar: AppBar(title: const Text('Résultats')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.hourglass_empty,
                  size: 64, color: AppColors.textSecondary),
              const SizedBox(height: 16),
              Text(
                'Tu n\'as pas encore soumis ce devoir.',
                style: AppTextStyles.h2.copyWith(
                  color: AdaptiveColors.textPrimary(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Termine toutes les questions pour voir tes résultats.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AdaptiveColors.textSecondary(context),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Header score ────────────────────────────────────────────
  Widget _buildScoreHeader(
    BuildContext context, {
    required Homework homework,
    required HomeworkSubmission sub,
    required int pourcentage,
    required double note20,
    required int correctCount,
    required bool enRetard,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            homework.matiereColor.withOpacity(0.10),
            homework.matiereColor.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: homework.matiereColor.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(homework.matiereIcon,
                  color: homework.matiereColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  homework.titre,
                  style: AppTextStyles.h3.copyWith(
                    color: AdaptiveColors.textPrimary(context),
                    fontSize: 15,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          HomeworkProgressRing(
            pourcentage: pourcentage,
            size: 130,
            subtitle: '$correctCount/${homework.nbQuestions} justes',
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _scoreStat(
                context,
                label: 'Note',
                value: '${note20.toStringAsFixed(1)}/20',
                color: _noteColor(note20),
              ),
              _scoreStat(
                context,
                label: 'Points',
                value: '${sub.score}/${homework.pointsTotal}',
                color: AppColors.accent,
              ),
              _scoreStat(
                context,
                label: 'Temps',
                value: sub.tempsLabel,
                color: AppColors.info,
              ),
            ],
          ),
          if (enRetard) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: AppColors.warning, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Rendu en retard (après la deadline)',
                    style: TextStyle(
                      color: AppColors.warning,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _scoreStat(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.h3.copyWith(
            color: color,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: AdaptiveColors.textSecondary(context),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  // ─── Feedback motivant ───────────────────────────────────────
  Widget _buildFeedback(BuildContext context, Homework hw, int pourcentage) {
    final message = _messageMotivant(hw.matiere, pourcentage);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AdaptiveColors.accentSurface(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_fire_department,
              color: AppColors.accent, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w600,
                color: AdaptiveColors.accent(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _messageMotivant(String matiere, int taux) {
    if (taux >= 80) {
      return 'Excellent ! Tu progresses en $matiere ! Continue !';
    } else if (taux >= 50) {
      return 'Bon travail ! Tu progresses en $matiere ! Continue !';
    } else if (taux > 0) {
      return 'Ne lâche rien ! Tu progresses en $matiere ! Continue !';
    }
    return "C'est en se trompant qu'on apprend. Tu progresses en $matiere ! Continue !";
  }

  // ─── Stats ligne (correctes / incorrectes) ───────────────────
  Widget _buildStatsRow(
      BuildContext context, HomeworkSubmission sub, Homework hw) {
    final correct = sub.reponses.values.where((a) => a.isCorrect).length;
    final incorrect = sub.reponses.length - correct;
    final noAnswer = hw.nbQuestions - sub.reponses.length;

    return Row(
      children: [
        Expanded(
          child: _statCard(
            context,
            icon: Icons.check_circle_outline,
            color: AppColors.success,
            value: '$correct',
            label: 'Correctes',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statCard(
            context,
            icon: Icons.cancel_outlined,
            color: AppColors.error,
            value: '$incorrect',
            label: 'Incorrectes',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statCard(
            context,
            icon: Icons.help_outline,
            color: AppColors.textSecondary,
            value: '$noAnswer',
            label: 'Sans réponse',
          ),
        ),
      ],
    );
  }

  Widget _statCard(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AdaptiveColors.surface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdaptiveColors.divider(context)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.h3.copyWith(fontSize: 18),
          ),
          Text(
            label,
            style: TextStyle(
              color: AdaptiveColors.textSecondary(context),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Titre section détails ───────────────────────────────────
  Widget _buildDetailTitle(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.menu_book_outlined, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          'Correction détaillée',
          style: AppTextStyles.h3.copyWith(fontSize: 16),
        ),
      ],
    );
  }

  // ─── Cartes de correction par question ───────────────────────
  List<Widget> _buildDetailedCorrections(
    BuildContext context,
    Homework homework,
    HomeworkSubmission sub,
  ) {
    final list = <Widget>[];
    for (var i = 0; i < homework.questions.length; i++) {
      final q = homework.questions[i];
      final ans = sub.reponses[q.id];
      list.add(_buildQuestionCorrection(context, i + 1, q, ans));
      list.add(const SizedBox(height: 12));
    }
    return list;
  }

  Widget _buildQuestionCorrection(
    BuildContext context,
    int numero,
    HomeworkQuestion q,
    HomeworkAnswer? ans,
  ) {
    final isCorrect = ans?.isCorrect ?? false;
    final isAnswered = ans != null;
    final color = !isAnswered
        ? AppColors.textSecondary
        : (isCorrect ? AppColors.success : AppColors.error);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AdaptiveColors.surface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête : numéro + statut + points
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
                  child: Icon(
                    isCorrect
                        ? Icons.check
                        : (isAnswered ? Icons.close : Icons.help),
                    color: color,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Question $numero',
                  style: AppTextStyles.label.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${ans?.pointsObtenus ?? 0} / ${q.points} pt${q.points > 1 ? 's' : ''}',
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Énoncé
          Text(
            q.enonce,
            style: AppTextStyles.body.copyWith(
              color: AdaptiveColors.textPrimary(context),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),

          // Ta réponse
          _buildLigne(
            context,
            label: 'Ta réponse :',
            value: _reponseLabel(q, ans),
            color: isAnswered
                ? (isCorrect ? AppColors.success : AppColors.error)
                : AppColors.textSecondary,
            bgColor: isAnswered
                ? (isCorrect
                    ? AppColors.success.withOpacity(0.08)
                    : AppColors.error.withOpacity(0.08))
                : AdaptiveColors.surfaceVariant(context),
          ),

          // Bonne réponse (si faux ou non répondu)
          if (!isCorrect) ...[
            const SizedBox(height: 8),
            _buildLigne(
              context,
              label: 'Bonne réponse :',
              value: _bonneReponseLabel(q),
              color: AppColors.success,
              bgColor: AppColors.success.withOpacity(0.08),
            ),
          ],

          // Explication
          if (q.explication != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AdaptiveColors.primarySurface(context),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline,
                      size: 16, color: AdaptiveColors.primary(context)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      q.explication!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AdaptiveColors.primary(context),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLigne(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AdaptiveColors.textSecondary(context),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _reponseLabel(HomeworkQuestion q, HomeworkAnswer? ans) {
    if (ans == null) return '(pas de réponse)';
    if (q.isQcm) {
      if (ans.qcmIndex == null) return '(pas de réponse)';
      final choix = q.choix![ans.qcmIndex!];
      return '${String.fromCharCode(65 + ans.qcmIndex!)}. $choix';
    }
    return ans.texteOuvert?.isNotEmpty == true
        ? ans.texteOuvert!
        : '(pas de réponse)';
  }

  String _bonneReponseLabel(HomeworkQuestion q) {
    if (q.isQcm) {
      return '${String.fromCharCode(65 + q.bonIndex!)}. ${q.choix![q.bonIndex!]}';
    }
    return q.bonneReponseOuverte ?? '(réponse libre)';
  }

  // ─── Boutons d'action ────────────────────────────────────────
  Widget _buildActionButtons(BuildContext context, Homework hw) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: () {
            // L'écran de résultats a remplacé la session (pushReplacement).
            // Pile courante : ... → detail → results.
            // On pop deux fois pour retourner à la liste des devoirs
            // (si elle est derrière le détail).
            Navigator.of(context).pop();
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
          icon: const Icon(Icons.list_alt, size: 20),
          label: const Text('Retour aux devoirs'),
        ),
        const SizedBox(height: 8),
        if (!hw.isDeadlineDepassee)
          TextButton.icon(
            onPressed: () {
              // Pour cette démo, on ne gère pas encore une 2e tentative
              // (le devoir est déjà rendu, la soumission existe).
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Tu as déjà rendu ce devoir. Une 2e tentative '
                    'sera disponible dans une prochaine version.',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Refaire le devoir'),
          ),
      ],
    );
  }

  Color _noteColor(double note) {
    if (note >= 14) return AppColors.success;
    if (note >= 10) return AppColors.warning;
    return AppColors.error;
  }
}
