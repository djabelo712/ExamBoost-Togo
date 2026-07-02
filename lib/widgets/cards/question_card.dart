// lib/widgets/cards/question_card.dart
// Carte question/réponse avec animation flip

import 'dart:math' show pi;
import 'package:flutter/material.dart';
import '../../models/question.dart';
import '../../theme/adaptive_colors.dart';
import '../../theme/app_theme.dart';

class QuestionCard extends StatelessWidget {
  final Question question;
  final bool reponseVisible;
  final Animation<double> flipAnimation;

  const QuestionCard({
    super.key,
    required this.question,
    required this.reponseVisible,
    required this.flipAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: flipAnimation,
      builder: (context, child) {
        final isBack = flipAnimation.value > 0.5;
        final angle = flipAnimation.value * pi;

        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateX(isBack ? pi - angle : angle),
          alignment: Alignment.center,
          child: isBack ? _buildReponse(context) : _buildQuestion(context),
        );
      },
    );
  }

  Widget _buildQuestion(BuildContext context) {
    return _CardBase(
      color: AdaptiveColors.surface(context),
      borderColor: AppColors.primary.withOpacity(0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête de la carte
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AdaptiveColors.primarySurface(context),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  question.chapitre,
                  style: AppTextStyles.label.copyWith(color: AppColors.primary),
                ),
              ),
              const Spacer(),
              if (question.points != null)
                Text(
                  '${question.points} pts',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AdaptiveColors.textSecondary(context)),
                ),
            ],
          ),

          const SizedBox(height: 20),

          // Icône question
          const Icon(Icons.help_outline, size: 32, color: AppColors.primary),
          const SizedBox(height: 12),

          // Énoncé de la question
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                question.enonce,
                style: AppTextStyles.questionText.copyWith(
                    color: AdaptiveColors.textPrimary(context)),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Indice en bas
          Center(
            child: Text(
              'Appuyez sur "Voir la réponse" quand vous êtes prêt',
              style: AppTextStyles.bodySmall.copyWith(
                fontStyle: FontStyle.italic,
                color: AdaptiveColors.textSecondary(context),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReponse(BuildContext context) {
    return Transform(
      transform: Matrix4.identity()..rotateX(pi), // retourner le côté verso
      alignment: Alignment.center,
      child: _CardBase(
        color: AdaptiveColors.primarySurface(context),
        borderColor: AppColors.primary.withOpacity(0.4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête réponse
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AdaptiveColors.primary(context),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Réponse',
                    style: AppTextStyles.label
                        .copyWith(color: AdaptiveColors.onPrimary(context)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            const Icon(Icons.check_circle_outline, size: 32, color: AppColors.primary),
            const SizedBox(height: 12),

            // La réponse
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      question.reponse,
                      style: AppTextStyles.questionText.copyWith(
                        color: AdaptiveColors.primary(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    // Explication si disponible
                    if (question.explication != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AdaptiveColors.surface(context),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Explication',
                              style: AppTextStyles.label.copyWith(
                                color: AdaptiveColors.textSecondary(context),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(question.explication!,
                                style: AppTextStyles.body.copyWith(
                                    color:
                                        AdaptiveColors.textPrimary(context))),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardBase extends StatelessWidget {
  final Widget child;
  final Color color;
  final Color borderColor;

  const _CardBase({
    required this.child,
    required this.color,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AdaptiveColors.shadow(context),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
