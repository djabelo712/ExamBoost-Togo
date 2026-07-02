// lib/screens/flash/flash_results_screen.dart
// Écran de résultats rapides de la session Flash 5 min.
//
// Affiche :
//   - Score X / 5 (grand, coloré selon performance)
//   - Temps total utilisé (MM:SS) + comparaison avec les 5 min
//   - Message "Tu as amélioré P(L) en {matiere}" (calculé via FlashService
//     en comparant P(L) avant et après session)
//   - Détail question par question (vert/rouge)
//   - Boutons "Recommencer" et "Révision complète"
//
// Logique de progression :
//   - Si le score >= 1 et qu'une matière a progressé, on affiche le message
//     motivant avec la matière.
//   - Si le score == 0 ou aucune matière n'a progressé, on affiche un message
//     d'encouragement avec la matière la plus faible (à retravailler).

import 'package:flutter/material.dart';

import '../../models/question.dart';
import '../../models/user.dart';
import '../../theme/adaptive_colors.dart';
import '../../theme/app_theme.dart';
import 'flash_intro_screen.dart';
import 'services/flash_service.dart';

class FlashResultsScreen extends StatelessWidget {
  final String userId;
  final int score;
  final int total;
  final Duration tempsUtilise;
  final Map<String, double> pLearnAvant;
  final AppUser? userApres;
  final FlashService flashService;
  final List<Question> questionsVues;

  /// Résultats par question : null = non répondu, true = correct, false = incorrect.
  /// Aligné avec [questionsVues] (même longueur, même ordre).
  final List<bool?> resultats;

  const FlashResultsScreen({
    super.key,
    required this.userId,
    required this.score,
    required this.total,
    required this.tempsUtilise,
    required this.pLearnAvant,
    required this.userApres,
    required this.flashService,
    required this.questionsVues,
    required this.resultats,
  });

  @override
  Widget build(BuildContext context) {
    final taux = total > 0 ? (score / total * 100).round() : 0;
    final couleurScore = _scoreColor(taux);

    // Temps formaté MM:SS.
    final minutes = tempsUtilise.inMinutes;
    final secondes = tempsUtilise.inSeconds % 60;
    final tempsTexte =
        '${minutes.toString()}:${secondes.toString().padLeft(2, '0')}';

    // Calcul de la matière avec le plus de progression.
    String? matiereProgression;
    String? matiereFaible;
    double? deltaPLearn;
    if (userApres != null) {
      matiereProgression = flashService.matiereAvecPlusDeProgression(
        user: userApres!,
        pLearnAvant: pLearnAvant,
      );
      matiereFaible =
          flashService.matiereLaPlusFaible(user: userApres!);

      // Calcule le delta moyen de P(L) sur les compétences vues.
      if (matiereProgression != null) {
        double sommeAvant = 0, sommeApres = 0;
        int count = 0;
        final compToMatiere = _buildCompToMatiere();
        for (final entry in pLearnAvant.entries) {
          if (compToMatiere[entry.key] == matiereProgression) {
            sommeAvant += entry.value;
            sommeApres += userApres!.getMaitrise(entry.key);
            count++;
          }
        }
        if (count > 0) {
          deltaPLearn =
              (sommeApres - sommeAvant) / count;
        }
      }
    }

    // Décide quel message afficher.
    final bool aProgression = matiereProgression != null &&
        deltaPLearn != null &&
        deltaPLearn > 0.01;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),

              // ─── Icône trophée ────────────────────────────────────
              Center(
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: couleurScore
                        .withOpacity(context.isDark ? 0.22 : 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    taux >= 60
                        ? Icons.emoji_events
                        : taux >= 30
                            ? Icons.thumb_up_outlined
                            : Icons.refresh,
                    size: 48,
                    color: couleurScore,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ─── Titre ────────────────────────────────────────────
              Text(
                _titreSelonScore(taux),
                style: AppTextStyles.h1
                    .copyWith(color: AdaptiveColors.textPrimary(context)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Session terminée',
                style: AppTextStyles.body
                    .copyWith(color: AdaptiveColors.textSecondary(context)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // ─── Score X/5 (grand, coloré) ────────────────────────
              Center(
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: couleurScore.withOpacity(context.isDark ? 0.18 : 0.12),
                    border: Border.all(color: couleurScore, width: 4),
                  ),
                  child: Center(
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '$score',
                            style: AppTextStyles.h1.copyWith(
                              color: couleurScore,
                              fontSize: 48,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          TextSpan(
                            text: '/$total',
                            style: AppTextStyles.h3.copyWith(
                              color: AdaptiveColors.textSecondary(context),
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // ─── Pourcentage ──────────────────────────────────────
              Center(
                child: Text(
                  '$taux% de réussite',
                  style: AppTextStyles.body.copyWith(
                    color: couleurScore,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ─── Temps utilisé ────────────────────────────────────
              _StatRow(
                icon: Icons.timer_outlined,
                iconColor: AppColors.accent,
                label: 'Temps utilisé',
                value: '$tempsTexte / 5:00',
              ),
              const SizedBox(height: 10),

              // ─── Message progression P(L) ─────────────────────────
              _ProgressionMessage(
                aProgression: aProgression,
                matiereProgression: matiereProgression,
                matiereFaible: matiereFaible,
                deltaPLearn: deltaPLearn,
              ),
              const SizedBox(height: 20),

              // ─── Détail question par question ─────────────────────
              _DetailQuestions(
                questions: questionsVues,
                resultats: resultats,
              ),
              const SizedBox(height: 28),

              // ─── Boutons d'action ─────────────────────────────────
              ElevatedButton.icon(
                onPressed: () => _recommencer(context),
                icon: const Icon(Icons.refresh, size: 22),
                label: const Text('Recommencer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: AppTextStyles.button.copyWith(fontSize: 17),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => _retourAccueil(context),
                icon: const Icon(Icons.menu_book, size: 22),
                label: const Text('Révision complète'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: AppTextStyles.button.copyWith(fontSize: 17),
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────

  /// Construit la map competenceId -> matiere à partir des questions vues.
  /// (Évite de dépendre de QuestionService ici.)
  Map<String, String> _buildCompToMatiere() {
    final map = <String, String>{};
    for (final q in questionsVues) {
      map[q.competenceId] = q.matiere;
    }
    return map;
  }

  Color _scoreColor(int taux) {
    if (taux >= 60) return AppColors.success;
    if (taux >= 30) return AppColors.warning;
    return AppColors.error;
  }

  String _titreSelonScore(int taux) {
    if (taux >= 80) return 'Excellent !';
    if (taux >= 60) return 'Bien joué !';
    if (taux >= 30) return 'Pas mal !';
    if (taux > 0) return 'Continue !';
    return 'Ne lâche rien !';
  }

  // ─── Actions ──────────────────────────────────────────────────────

  void _recommencer(BuildContext context) {
    // Pop le results screen, puis push un nouveau intro screen
    // (qui relancera une session fraîche).
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => FlashIntroScreen(userId: userId),
      ),
    );
  }

  void _retourAccueil(BuildContext context) {
    // Pop tout jusqu'à la racine. L'utilisateur pourra choisir "Révision
    // adaptative" depuis la home pour une révision complète.
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}

// ════════════════════════════════════════════════════════════════════
// Ligne de statistique (icône + label + valeur)
// ════════════════════════════════════════════════════════════════════

class _StatRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _StatRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AdaptiveColors.surface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdaptiveColors.divider(context)),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.body
                  .copyWith(color: AdaptiveColors.textPrimary(context)),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.h3.copyWith(color: iconColor),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// Message de progression P(L)
// ════════════════════════════════════════════════════════════════════

class _ProgressionMessage extends StatelessWidget {
  final bool aProgression;
  final String? matiereProgression;
  final String? matiereFaible;
  final double? deltaPLearn;

  const _ProgressionMessage({
    required this.aProgression,
    required this.matiereProgression,
    required this.matiereFaible,
    required this.deltaPLearn,
  });

  @override
  Widget build(BuildContext context) {
    // Cas 1 : progression détectée -> message motivant.
    if (aProgression && matiereProgression != null) {
      final deltaPct = ((deltaPLearn ?? 0) * 100).round();
      return _MessageCard(
        color: AppColors.success,
        icon: Icons.trending_up,
        texte:
            'Tu as amélioré P(L) en $matiereProgression '
            '(+$deltaPct% de maîtrise). Continue !',
      );
    }

    // Cas 2 : pas de progression -> matière à retravailler.
    if (matiereFaible != null) {
      return _MessageCard(
        color: AppColors.warning,
        icon: Icons.trending_flat,
        texte:
            'Concentre-toi sur $matiereFaible : c\'est ta matière la plus '
            'faible. Une session dédiée ferait des étincelles.',
      );
    }

    // Cas 3 : pas assez de données (nouvel élève, pas de BKT).
    return _MessageCard(
      color: AppColors.info,
      icon: Icons.lightbulb_outline,
      texte:
          'Continue tes sessions Flash : on calibre ton profil au fur et '
          'à mesure pour mieux cibler tes points faibles.',
    );
  }
}

class _MessageCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String texte;

  const _MessageCard({
    required this.color,
    required this.icon,
    required this.texte,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(context.isDark ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(context.isDark ? 0.50 : 0.35),
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              texte,
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// Détail question par question (5 lignes vert/rouge)
// ════════════════════════════════════════════════════════════════════

class _DetailQuestions extends StatelessWidget {
  final List<Question> questions;
  final List<bool?> resultats;

  const _DetailQuestions({
    required this.questions,
    required this.resultats,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AdaptiveColors.surface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdaptiveColors.divider(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Détail',
            style: AppTextStyles.label.copyWith(
              color: AdaptiveColors.textSecondary(context),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          ...questions.asMap().entries.map((entry) {
            final i = entry.key;
            final q = entry.value;
            final correct = i < resultats.length ? resultats[i] : null;
            // Couleur et icône selon le résultat.
            final Color couleurIcone;
            final IconData icon;
            if (correct == true) {
              couleurIcone = AppColors.success;
              icon = Icons.check_circle;
            } else if (correct == false) {
              couleurIcone = AppColors.error;
              icon = Icons.cancel;
            } else {
              couleurIcone = AdaptiveColors.textDisabled(context);
              icon = Icons.remove_circle_outline;
            }
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: couleurIcone, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          q.matiere,
                          style: AppTextStyles.label.copyWith(
                            color: AdaptiveColors.textSecondary(context),
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          q.enonce,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AdaptiveColors.textPrimary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
