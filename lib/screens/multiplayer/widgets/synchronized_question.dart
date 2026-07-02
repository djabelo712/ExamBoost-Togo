// lib/screens/multiplayer/widgets/synchronized_question.dart
// Affiche la question synchronisée partagée par tous les joueurs, avec
// un anneau de timer 30s et les 4 choix de réponse (QCM).
//
// Pendant que le joueur n'a pas répondu :
//   - les choix sont cliquables
//   - le timer décompte de 30s à 0
//
// Après réponse :
//   - le choix sélectionné est mis en surbrillance
//   - si on est en mode "révélation" (showResult = true), la bonne
//     réponse s'affiche en vert et les mauvaises en rouge
//   - les choix sont désactivés
//
// Usage :
//   SynchronizedQuestion(
//     question: question,
//     timeRemaining: 18,
//     timeLimit: 30,
//     hasAnswered: true,
//     selectedIndex: 2,
//     showResult: false,
//     onAnswer: (i) => service.sendAnswer(selectedIndex: i),
//   )

import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../models/multiplayer_room.dart';

class SynchronizedQuestion extends StatelessWidget {
  final MultiplayerQuestion question;
  final int timeRemaining;
  final int timeLimit;
  final bool hasAnswered;
  final int? selectedIndex;
  final bool showResult;
  final ValueChanged<int> onAnswer;

  const SynchronizedQuestion({
    super.key,
    required this.question,
    required this.timeRemaining,
    required this.timeLimit,
    required this.hasAnswered,
    required this.onAnswer,
    this.selectedIndex,
    this.showResult = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // En-tête : numéro de question + timer
            Row(
              children: [
                _QuestionCounter(),
                const Spacer(),
                _TimerRing(
                  remaining: timeRemaining,
                  total: timeLimit,
                ),
              ],
            ),
            const SizedBox(height: 18),
            // Énoncé
            Text(
              question.enonce,
              style: AppTextStyles.questionText.copyWith(fontSize: 18),
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 18),
            // Choix
            ...List.generate(question.choices.length, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ChoiceTile(
                  index: i,
                  label: question.choices[i],
                  letter: _letter(i),
                  isSelected: selectedIndex == i,
                  isCorrect: i == question.correctIndex,
                  showResult: showResult,
                  disabled: hasAnswered,
                  onTap: hasAnswered ? null : () => onAnswer(i),
                ),
              );
            }),
            // Explication (si mode révélation et fournie)
            if (showResult && question.explanation != null) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primaryLight),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_outline,
                        color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        question.explanation!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _letter(int i) => String.fromCharCode(65 + i); // A, B, C, D
}

// ─── Compteur "Question X / Y" ──────────────────────────────────────
class _QuestionCounter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.help_outline,
              color: AppColors.primary, size: 16),
          const SizedBox(width: 4),
          Text(
            'Question',
            style: AppTextStyles.label.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Anneau de timer ────────────────────────────────────────────────
class _TimerRing extends StatelessWidget {
  final int remaining;
  final int total;

  const _TimerRing({required this.remaining, required this.total});

  Color get _color {
    if (remaining <= 5) return AppColors.error;
    if (remaining <= 10) return AppColors.warning;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final progress = total <= 0 ? 0.0 : remaining / total;
    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            strokeWidth: 4,
            backgroundColor: AppColors.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(_color),
          ),
          Text(
            '$remaining',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: _color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tuile de choix de réponse ──────────────────────────────────────
class _ChoiceTile extends StatelessWidget {
  final int index;
  final String label;
  final String letter;
  final bool isSelected;
  final bool isCorrect;
  final bool showResult;
  final bool disabled;
  final VoidCallback? onTap;

  const _ChoiceTile({
    required this.index,
    required this.label,
    required this.letter,
    required this.isSelected,
    required this.isCorrect,
    required this.showResult,
    required this.disabled,
    required this.onTap,
  });

  Color _backgroundColor() {
    if (showResult) {
      if (isCorrect) return AppColors.success.withOpacity(0.15);
      if (isSelected && !isCorrect) return AppColors.error.withOpacity(0.15);
      return AppColors.surface;
    }
    if (isSelected) return AppColors.primary.withOpacity(0.10);
    return AppColors.surfaceVariant;
  }

  Color _borderColor() {
    if (showResult) {
      if (isCorrect) return AppColors.success;
      if (isSelected && !isCorrect) return AppColors.error;
      return AppColors.divider;
    }
    if (isSelected) return AppColors.primary;
    return AppColors.divider;
  }

  Color _letterColor() {
    if (showResult) {
      if (isCorrect) return Colors.white;
      if (isSelected && !isCorrect) return Colors.white;
      return AppColors.textSecondary;
    }
    if (isSelected) return Colors.white;
    return AppColors.primary;
  }

  Color _letterBackground() {
    if (showResult) {
      if (isCorrect) return AppColors.success;
      if (isSelected && !isCorrect) return AppColors.error;
      return AppColors.surfaceVariant;
    }
    if (isSelected) return AppColors.primary;
    return AppColors.primarySurface;
  }

  IconData? _trailingIcon() {
    if (!showResult) return null;
    if (isCorrect) return Icons.check_circle;
    if (isSelected && !isCorrect) return Icons.cancel;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: _backgroundColor(),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _borderColor(), width: 1.5),
          ),
          child: Row(
            children: [
              // Lettre A/B/C/D
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: _letterBackground(),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  letter,
                  style: TextStyle(
                    color: _letterColor(),
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Texte du choix
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.body.copyWith(
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              // Icône de résultat
              if (_trailingIcon() != null) ...[
                Icon(
                  _trailingIcon(),
                  color: _trailingIcon() == Icons.check_circle
                      ? AppColors.success
                      : AppColors.error,
                  size: 22,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
