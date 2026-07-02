// lib/screens/homework/homework_session_screen.dart
// Session de devoir (élève répond aux questions une par une).
//
// Inspiré de revision_screen.dart mais adapté au contexte devoir :
//   - barre de progression "Question X / N",
//   - QCM : radio-list des propositions, sélection unique,
//   - question ouverte : champ texte (auto-correction souple à la soumission),
//   - bouton "Suivant" / "Terminer et corriger" sur la dernière,
//   - dialog de confirmation avant soumission finale,
//   - enregistrement de chaque réponse via HomeworkService.enregistrerReponse,
//   - timer interne (temps total passé),
//   - dialog "Quitter" avec confirmation (la progression est conservée).
//
// Après soumission → navigation vers HomeworkResultsScreen.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/adaptive_colors.dart';
import '../../theme/app_theme.dart';
import '../models/homework.dart';
import '../services/homework_service.dart';
import 'homework_results_screen.dart';
import 'widgets/homework_progress.dart';

class HomeworkSessionScreen extends StatefulWidget {
  final String homeworkId;

  const HomeworkSessionScreen({super.key, required this.homeworkId});

  @override
  State<HomeworkSessionScreen> createState() => _HomeworkSessionScreenState();
}

class _HomeworkSessionScreenState extends State<HomeworkSessionScreen> {
  late final Homework _homework;
  int _currentIndex = 0;

  // Réponses temporaires (avant soumission au service)
  int? _selectedQcmIndex;
  final TextEditingController _texteController = TextEditingController();

  // Timer
  late final DateTime _debutSession;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    final service = context.read<HomeworkService>();
    _homework = service.homeworks.firstWhere((h) => h.id == widget.homeworkId);
    _debutSession = DateTime.now();
    _startTimer();
    _loadCurrentAnswer();
  }

  @override
  void dispose() {
    _texteController.dispose();
    super.dispose();
  }

  void _startTimer() {
    // Timer simple : incrémente toutes les secondes
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _elapsedSeconds = DateTime.now().difference(_debutSession).inSeconds;
      });
      _startTimer();
    });
  }

  /// Charge une réponse déjà enregistrée pour la question courante
  /// (utile quand l'élève "Reprend" un devoir en cours).
  void _loadCurrentAnswer() {
    final service = context.read<HomeworkService>();
    final sub = service.getSoumissionForCurrentEleve(widget.homeworkId);
    if (sub == null) return;

    final question = _homework.questions[_currentIndex];
    final existing = sub.reponses[question.id];
    if (existing != null) {
      _selectedQcmIndex = existing.qcmIndex;
      if (existing.texteOuvert != null) {
        _texteController.text = existing.texteOuvert!;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final question = _homework.questions[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(_homework.titre, maxLines: 1, overflow: TextOverflow.ellipsis),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _showQuitDialog,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    _formatTime(_elapsedSeconds),
                    style: AppTextStyles.label.copyWith(
                      color: AdaptiveColors.textSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de progression
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Row(
              children: [
                Text(
                  'Question ${_currentIndex + 1} / ${_homework.nbQuestions}',
                  style: AppTextStyles.label.copyWith(
                    color: AdaptiveColors.textPrimary(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_homework.pointsTotal} pts au total',
                  style: AppTextStyles.label.copyWith(
                    color: AdaptiveColors.textSecondary(context),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: HomeworkProgressBar(
              current: _currentIndex + 1,
              total: _homework.nbQuestions,
            ),
          ),
          const SizedBox(height: 12),

          // Corps : carte question + choix
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildQuestionCard(context, question),
                  const SizedBox(height: 16),
                  if (question.isQcm)
                    _buildQcmChoices(context, question)
                  else
                    _buildOpenAnswer(context, question),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Bouton navigation
          _buildNavButtons(context),
        ],
      ),
    );
  }

  // ─── Carte question ──────────────────────────────────────────
  Widget _buildQuestionCard(BuildContext context, HomeworkQuestion q) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdaptiveColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdaptiveColors.divider(context)),
        boxShadow: [
          BoxShadow(
            color: AdaptiveColors.shadow(context),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _homework.matiereColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _homework.matiere,
                  style: TextStyle(
                    color: _homework.matiereColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${q.points} pt${q.points > 1 ? 's' : ''}',
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            q.enonce,
            style: AppTextStyles.questionText.copyWith(
              color: AdaptiveColors.textPrimary(context),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Choix QCM ───────────────────────────────────────────────
  Widget _buildQcmChoices(BuildContext context, HomeworkQuestion q) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: q.choix!.asMap().entries.map((entry) {
        final i = entry.key;
        final choix = entry.value;
        final isSelected = _selectedQcmIndex == i;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () => setState(() => _selectedQcmIndex = i),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.08)
                    : AdaptiveColors.surface(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AdaptiveColors.divider(context),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AdaptiveColors.textSecondary(context),
                        width: 2,
                      ),
                      color: isSelected
                          ? AppColors.primary
                          : Colors.transparent,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${String.fromCharCode(65 + i)}. $choix',
                      style: AppTextStyles.body.copyWith(
                        color: AdaptiveColors.textPrimary(context),
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── Question ouverte ────────────────────────────────────────
  Widget _buildOpenAnswer(BuildContext context, HomeworkQuestion q) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _texteController,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Saisis ta réponse ici...',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AdaptiveColors.primarySurface(context),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline,
                  size: 16, color: AdaptiveColors.primary(context)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tu pourras t\'auto-évaluer (juste/faux) après avoir saisi ta réponse, '
                  'puis voir la correction.',
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
    );
  }

  // ─── Boutons navigation ──────────────────────────────────────
  Widget _buildNavButtons(BuildContext context) {
    final isLast = _currentIndex == _homework.nbQuestions - 1;
    final canProceed = _canProceed();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdaptiveColors.surface(context),
        border: Border(
          top: BorderSide(color: AdaptiveColors.divider(context)),
        ),
      ),
      child: Row(
        children: [
          if (_currentIndex > 0)
            TextButton.icon(
              onPressed: _prev,
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Précédent'),
            )
          else
            const SizedBox(width: 0),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: canProceed
                ? (isLast ? _showSubmitDialog : _next)
                : null,
            icon: Icon(
              isLast ? Icons.check_circle_outline : Icons.arrow_forward,
              size: 20,
            ),
            label: Text(isLast ? 'Terminer et corriger' : 'Suivant'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────

  bool _canProceed() {
    final q = _homework.questions[_currentIndex];
    if (q.isQcm) return _selectedQcmIndex != null;
    return _texteController.text.trim().isNotEmpty;
  }

  void _next() {
    _enregistrerReponseCourante();
    setState(() {
      _currentIndex++;
      _selectedQcmIndex = null;
      _texteController.clear();
    });
    _loadCurrentAnswer();
  }

  void _prev() {
    if (_currentIndex > 0) {
      _enregistrerReponseCourante();
      setState(() {
        _currentIndex--;
      });
      _loadCurrentAnswer();
    }
  }

  void _enregistrerReponseCourante() {
    final q = _homework.questions[_currentIndex];
    final service = context.read<HomeworkService>();
    service.enregistrerReponse(
      homeworkId: widget.homeworkId,
      questionId: q.id,
      qcmIndex: _selectedQcmIndex,
      texteOuvert: _texteController.text.trim().isEmpty
          ? null
          : _texteController.text.trim(),
      autoEvalueCorrect: q.isQcm
          ? null
          : null, // sera demandé après soumission pour questions ouvertes
    );
  }

  void _showSubmitDialog() {
    // Enregistre la dernière réponse avant de soumettre
    _enregistrerReponseCourante();

    final unanswered = _countUnanswered();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Soumettre le devoir ?'),
        content: Text(
          unanswered > 0
              ? 'Attention : $unanswered question(s) sans réponse sur '
                  '${_homework.nbQuestions}. Tu ne pourras plus modifier '
                  'tes réponses après soumission.'
              : 'Tu as répondu à toutes les questions. Tu ne pourras plus '
                  'modifier tes réponses après soumission. L\'auto-correction '
                  's\'affichera immédiatement.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _soumettre();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Oui, soumettre'),
          ),
        ],
      ),
    );
  }

  int _countUnanswered() {
    final service = context.read<HomeworkService>();
    final sub = service.getSoumissionForCurrentEleve(widget.homeworkId);
    if (sub == null) return _homework.nbQuestions;
    return _homework.nbQuestions - sub.reponses.length;
  }

  void _soumettre() {
    final service = context.read<HomeworkService>();
    final finalSub = service.soumettreHomework(
      homeworkId: widget.homeworkId,
      tempsPasseSecondes: _elapsedSeconds,
    );

    if (finalSub == null) return;

    // Navigation vers l'écran de résultats (en remplaçant la session)
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => HomeworkResultsScreen(homeworkId: widget.homeworkId),
      ),
    );
  }

  void _showQuitDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quitter le devoir ?'),
        content: const Text(
          'Ta progression est sauvegardée. Tu pourras reprendre plus tard '
          'depuis l\'écran de détail du devoir.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Continuer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
