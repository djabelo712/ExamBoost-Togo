// lib/screens/classroom/widgets/live_question_display.dart
// Affichage d'une question en live pendant une session classe.
//
// Affiche :
//   - l'enonce en grand
//   - si QCM : 4 gros boutons colores (rouge / bleu / jaune / vert style Kahoot)
//     avec les lettres A / B / C / D
//   - si vraiFaux : 2 boutons Vrai / Faux
//   - si autre type : champ texte + bouton Valider
//
// Apres reponse : les boutons sont grises, un overlay "En attente des autres"
// est affiche (delegue a l'ecran parent via [onAnswered]).

import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../models/classroom_session.dart';

class LiveQuestionDisplay extends StatefulWidget {
  final ClassroomQuestion question;
  final int questionNumber;
  final int totalQuestions;
  final bool answered;
  final String? selectedAnswer;
  final bool? lastCorrect;
  final ValueChanged<String> onAnswer;

  const LiveQuestionDisplay({
    super.key,
    required this.question,
    required this.questionNumber,
    required this.totalQuestions,
    this.answered = false,
    this.selectedAnswer,
    this.lastCorrect,
    required this.onAnswer,
  });

  @override
  State<LiveQuestionDisplay> createState() => _LiveQuestionDisplayState();
}

class _LiveQuestionDisplayState extends State<LiveQuestionDisplay>
    with SingleTickerProviderStateMixin {
  late TextEditingController _textController;
  String? _selectedChoice;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _submit(String answer) {
    if (widget.answered || _submitted) return;
    setState(() {
      _selectedChoice = answer;
      _submitted = true;
    });
    widget.onAnswer(answer);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Compteur de question
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Question ${widget.questionNumber} / ${widget.totalQuestions}',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Enonce
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              widget.question.enonce,
              style: AppTextStyles.h3.copyWith(height: 1.4),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          // Zone de reponse
          Expanded(child: _buildAnswerArea()),
          // Feedback apres reponse
          if (widget.answered || _submitted) ...[
            const SizedBox(height: 12),
            _buildWaitingFeedback(),
          ],
        ],
      ),
    );
  }

  Widget _buildAnswerArea() {
    final q = widget.question;
    if (q.isQcm) {
      return _buildQcmButtons(q.choix!);
    }
    if (q.isVraiFaux) {
      return _buildVraiFauxButtons();
    }
    return _buildTextInput();
  }

  // ─── QCM : 4 boutons colores style Kahoot ──────────────────────
  Widget _buildQcmButtons(List<String> choix) {
    final colors = [
      const Color(0xFFE53935), // Rouge
      const Color(0xFF1E88E5), // Bleu
      const Color(0xFFFDD835), // Jaune
      const Color(0xFF43A047), // Vert
    ];
    final letters = ['A', 'B', 'C', 'D', 'E', 'F'];

    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: List.generate(choix.length.clamp(0, 6), (i) {
        final color = colors[i % colors.length];
        final letter = letters[i];
        final isSelected = _selectedChoice == choix[i];
        final isDisabled = widget.answered || _submitted;
        return _QcmButton(
          letter: letter,
          label: choix[i],
          color: color,
          isSelected: isSelected,
          isDisabled: isDisabled,
          onTap: () => _submit(choix[i]),
        );
      }),
    );
  }

  // ─── Vrai / Faux ───────────────────────────────────────────────
  Widget _buildVraiFauxButtons() {
    return Row(
      children: [
        Expanded(
          child: _QcmButton(
            letter: 'V',
            label: 'Vrai',
            color: AppColors.success,
            isSelected: _selectedChoice == 'Vrai',
            isDisabled: widget.answered || _submitted,
            onTap: () => _submit('Vrai'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QcmButton(
            letter: 'F',
            label: 'Faux',
            color: AppColors.error,
            isSelected: _selectedChoice == 'Faux',
            isDisabled: widget.answered || _submitted,
            onTap: () => _submit('Faux'),
          ),
        ),
      ],
    );
  }

  // ─── Reponse texte ─────────────────────────────────────────────
  Widget _buildTextInput() {
    final isDisabled = widget.answered || _submitted;
    return Column(
      children: [
        TextField(
          controller: _textController,
          enabled: !isDisabled,
          decoration: const InputDecoration(
            labelText: 'Ta reponse',
            hintText: 'Saisis ta reponse ici...',
          ),
          onSubmitted: (v) {
            if (v.trim().isNotEmpty) _submit(v.trim());
          },
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isDisabled
                ? null
                : () {
                    final v = _textController.text.trim();
                    if (v.isNotEmpty) _submit(v);
                  },
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Valider'),
          ),
        ),
      ],
    );
  }

  // ─── Feedback d'attente ────────────────────────────────────────
  Widget _buildWaitingFeedback() {
    final correct = widget.lastCorrect;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (correct == true
                ? AppColors.success
                : correct == false
                    ? AppColors.error
                    : AppColors.info)
            .withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          if (correct == true)
            Icon(Icons.check_circle, color: AppColors.success)
          else if (correct == false)
            Icon(Icons.cancel, color: AppColors.error)
          else
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.info,
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              correct == true
                  ? 'Bonne reponse ! En attente des autres eleves...'
                  : correct == false
                      ? 'Reponse incorrecte. En attente des autres...'
                      : 'Reponse envoyee. En attente des autres eleves...',
              style: AppTextStyles.body.copyWith(
                color: correct == true
                    ? AppColors.success
                    : correct == false
                        ? AppColors.error
                        : AppColors.info,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bouton QCM colore ──────────────────────────────────────────────
class _QcmButton extends StatelessWidget {
  final String letter;
  final String label;
  final Color color;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onTap;

  const _QcmButton({
    required this.letter,
    required this.label,
    required this.color,
    required this.isSelected,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: isDisabled && !isSelected ? 0.45 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: isSelected ? color : color.withOpacity(0.92),
        borderRadius: BorderRadius.circular(16),
        elevation: isSelected ? 8 : 4,
        child: InkWell(
          onTap: isDisabled ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    letter,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
