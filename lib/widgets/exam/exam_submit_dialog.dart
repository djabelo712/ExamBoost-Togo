// lib/widgets/exam/exam_submit_dialog.dart
// Dialogue de soumission officielle d'examen.
//
// Format :
//   SOUMISSION DE L'EPREUVE
//
//   Tu as repondu a X / Y questions.
//   Temps restant : HH:MM:SS
//
//   Une fois soumise, tu ne pourras plus modifier tes reponses.
//
//   [Confirmer la soumission] [Continuer l'examen]
//
// - Style sobre (pas de couleurs criardes).
// - Si questions sans reponse : avertissement en rouge "ATTENTION : X questions
//   sans reponse".
// - Animation de "cachet officiel" (rotation + scale) quand on confirme.
//
// OUVERTURE : ExamSubmitDialog.show(context, ...). Retourne true si l'utilisateur
// a confirme la soumission, false sinon.

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Dialogue de soumission officielle.
class ExamSubmitDialog extends StatefulWidget {
  const ExamSubmitDialog({
    super.key,
    required this.totalQuestions,
    required this.questionsRepondues,
    required this.tempsRestant,
    required this.nomExamen,
  });

  /// Nombre total de questions.
  final int totalQuestions;
  /// Nombre de questions auxquelles l'eleve a repondu.
  final int questionsRepondues;
  /// Temps restant affiche (formate HH:MM:SS).
  final String tempsRestant;
  /// Nom de l'examen (ex: "BEPC - Mathematiques").
  final String nomExamen;

  /// Affiche le dialogue. Retourne true si l'utilisateur confirme, false sinon.
  static Future<bool> show(
    BuildContext context, {
    required int totalQuestions,
    required int questionsRepondues,
    required String tempsRestant,
    required String nomExamen,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ExamSubmitDialog(
        totalQuestions: totalQuestions,
        questionsRepondues: questionsRepondues,
        tempsRestant: tempsRestant,
        nomExamen: nomExamen,
      ),
    ).then((v) => v ?? false);
  }

  @override
  State<ExamSubmitDialog> createState() => _ExamSubmitDialogState();
}

class _ExamSubmitDialogState extends State<ExamSubmitDialog>
    with SingleTickerProviderStateMixin {
  bool _enConfirmation = false;
  late AnimationController _cachetCtrl;
  late Animation<double> _cachetAnim;

  @override
  void initState() {
    super.initState();
    _cachetCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _cachetAnim = CurvedAnimation(
      parent: _cachetCtrl,
      curve: Curves.easeOutBack,
    );
  }

  @override
  void dispose() {
    _cachetCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmer() async {
    setState(() => _enConfirmation = true);
    await _cachetCtrl.forward();
    // Petite pause pour laisser l'utilisateur voir le cachet.
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final sansReponse = widget.totalQuestions - widget.questionsRepondues;
    final taux = widget.totalQuestions == 0
        ? 0
        : (widget.questionsRepondues / widget.totalQuestions * 100).round();

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Colors.black54, width: 1),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _enConfirmation ? _buildCachet() : _buildFormulaire(sansReponse, taux),
        ),
      ),
    );
  }

  // ─── Formulaire de soumission ────────────────────────────────

  Widget _buildFormulaire(int sansReponse, int taux) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tete type document officiel
        Center(
          child: Column(
            children: [
              Text(
                'SOUMISSION DE L\'EPREUVE',
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 80,
                height: 1,
                color: Colors.black54,
              ),
              const SizedBox(height: 6),
              Text(
                widget.nomExamen,
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 12,
                  color: Colors.black54,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Statistiques
        _buildStatRow(
          'Questions repondues',
          '${widget.questionsRepondues} / ${widget.totalQuestions}',
        ),
        const SizedBox(height: 8),
        _buildStatRow('Temps restant', widget.tempsRestant),
        const SizedBox(height: 8),
        _buildStatRow('Taux de completion', '$taux%'),

        const SizedBox(height: 16),

        // Avertissement si questions sans reponse
        if (sansReponse > 0) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.08),
              border: Border.all(color: AppColors.error.withOpacity(0.4)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: AppColors.error, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ATTENTION : $sansReponse question${sansReponse > 1 ? 's' : ''} '
                    'sans reponse',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Avertissement general
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            border: Border.all(color: const Color(0xFFFFD54F)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              const Icon(Icons.lock_outline, color: Colors.black87, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Une fois soumise, tu ne pourras plus modifier tes reponses.',
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 12,
                    color: Colors.black87,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Boutons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  foregroundColor: Colors.black87,
                  side: const BorderSide(color: Colors.black54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Text('Continuer l\'examen'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: _confirmer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Text('Confirmer'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String valeur) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: 13,
            color: Colors.black87,
          ),
        ),
        Text(
          valeur,
          style: TextStyle(
            fontFamily: 'RobotoMono',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  // ─── Animation du cachet officiel ────────────────────────────

  Widget _buildCachet() {
    return SizedBox(
      height: 220,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cachet qui apparait avec rotation + scale
            ScaleTransition(
              scale: _cachetAnim,
              child: RotationTransition(
                turns: Tween<double>(begin: -0.25, end: 0.0)
                    .animate(_cachetAnim),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.success,
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified,
                        size: 56,
                        color: AppColors.success,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'EPREUVE\nSOUMISE',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            FadeTransition(
              opacity: _cachetAnim,
              child: Text(
                'Redirection vers le rapport...',
                style: AppTextStyles.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
