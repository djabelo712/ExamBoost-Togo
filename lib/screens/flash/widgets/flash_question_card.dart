// lib/screens/flash/widgets/flash_question_card.dart
// Carte question simplifiée pour le mode Flash 5 min.
//
// Différences avec la QuestionCard classique (lib/widgets/cards/question_card.dart) :
//   - Pas d'animation flip 350 ms (trop longue pour une session transport).
//   - Affichage direct de la question, puis de la réponse via AnimatedSwitcher
//     180 ms (transition instantanée mais fluide).
//   - Pas d'explication détaillée (trop longue à lire en marchant) : on montre
//     juste la réponse attendue.
//   - Gros boutons "Correct" / "Incorrect" intégrés à la carte (l'élève
//     s'auto-évalue, comme dans Anki).
//   - Chips matière + chapitre en en-tête pour situer le contexte.

import 'package:flutter/material.dart';
import '../../../models/question.dart';
import '../../../theme/adaptive_colors.dart';
import '../../../theme/app_theme.dart';

class FlashQuestionCard extends StatelessWidget {
  final Question question;
  final bool reponseVisible;
  final VoidCallback onVoirReponse;
  final void Function(bool correct) onReponse; // true = correct, false = incorrect

  const FlashQuestionCard({
    super.key,
    required this.question,
    required this.reponseVisible,
    required this.onVoirReponse,
    required this.onReponse,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      transitionBuilder: (child, anim) {
        // Fade + léger slide vertical pour effet "flash".
        return FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(anim),
            child: child,
          ),
        );
      },
      child: reponseVisible
          ? _ReponseFace(
              key: const ValueKey('reponse'),
              question: question,
              onReponse: onReponse,
            )
          : _QuestionFace(
              key: const ValueKey('question'),
              question: question,
              onVoirReponse: onVoirReponse,
            ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// Face "Question" : énoncé + bouton "Voir la réponse"
// ════════════════════════════════════════════════════════════════════

class _QuestionFace extends StatelessWidget {
  final Question question;
  final VoidCallback onVoirReponse;

  const _QuestionFace({
    super.key,
    required this.question,
    required this.onVoirReponse,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête : chips matière + chapitre
          _buildHeader(context),
          const SizedBox(height: 20),

          // Icône question
          const Icon(Icons.help_outline, size: 32, color: AppColors.primary),
          const SizedBox(height: 12),

          // Énoncé
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                question.enonce,
                style: AppTextStyles.questionText.copyWith(
                  color: AdaptiveColors.textPrimary(context),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Gros bouton "Voir la réponse"
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onVoirReponse,
              icon: const Icon(Icons.visibility_outlined, size: 22),
              label: const Text('Voir la réponse'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                textStyle: AppTextStyles.button.copyWith(fontSize: 17),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        _Chip(
          label: question.matiere,
          color: AppColors.primary,
        ),
        _Chip(
          label: question.chapitre,
          color: AdaptiveColors.textSecondary(context),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// Face "Réponse" : réponse attendue + boutons Correct / Incorrect
// ════════════════════════════════════════════════════════════════════

class _ReponseFace extends StatelessWidget {
  final Question question;
  final void Function(bool correct) onReponse;

  const _ReponseFace({
    super.key,
    required this.question,
    required this.onReponse,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(context, accent: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête : badge "Réponse"
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Réponse',
              style: AppTextStyles.label.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),

          const Icon(Icons.check_circle_outline, size: 32, color: AppColors.primary),
          const SizedBox(height: 12),

          // Réponse attendue (scrollable si longue)
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                question.reponse,
                style: AppTextStyles.questionText.copyWith(
                  color: AdaptiveColors.primary(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Petit texte d'auto-évaluation
          Center(
            child: Text(
              'Tu as trouvé la bonne réponse ?',
              style: AppTextStyles.bodySmall.copyWith(
                color: AdaptiveColors.textSecondary(context),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),

          // Gros boutons Correct / Incorrect (faciles en marchant)
          Row(
            children: [
              Expanded(
                child: _BigButton(
                  label: 'Correct',
                  icon: Icons.check,
                  color: AppColors.success,
                  onTap: () => onReponse(true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _BigButton(
                  label: 'Incorrect',
                  icon: Icons.close,
                  color: AppColors.error,
                  onTap: () => onReponse(false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// Sous-composants réutilisables
// ════════════════════════════════════════════════════════════════════

class _Chip extends StatelessWidget {
  final String label;
  final Color color;

  const _Chip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(context.isDark ? 0.22 : 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTextStyles.label.copyWith(color: color),
      ),
    );
  }
}

class _BigButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _BigButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(context.isDark ? 0.22 : 0.12),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: color.withOpacity(0.3),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: color.withOpacity(context.isDark ? 0.55 : 0.40),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTextStyles.button.copyWith(
                  color: color,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Décoration commune des deux faces.
BoxDecoration _cardDecoration(BuildContext context, {bool accent = false}) {
  return BoxDecoration(
    color: AdaptiveColors.surface(context),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: accent
          ? AppColors.primary.withOpacity(context.isDark ? 0.55 : 0.40)
          : AppColors.primary.withOpacity(context.isDark ? 0.30 : 0.20),
      width: 1.5,
    ),
    boxShadow: [
      BoxShadow(
        color: AdaptiveColors.shadow(context),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
    ],
  );
}
