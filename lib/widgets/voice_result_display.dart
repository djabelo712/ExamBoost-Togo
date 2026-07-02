// lib/widgets/voice_result_display.dart
// Affichage du verdict de comparaison vocale (transcription + score + verdict).
//
// Trois variantes visuelles selon le verdict :
//   - correct   : carte verte + icône check + "Bravo !"
//   - partial   : carte orange + icône help + "Partiellement correct"
//   - incorrect : carte rouge + icône close + "Réponse incorrecte"
//
// Affiche aussi :
//   - La transcription (ce que l'élève a dit)
//   - La réponse attendue (pour comparaison visuelle)
//   - Le score de similarité (pourcentage)
//   - Le détail des nombres matchés/manquants/erronés (debug pédagogique)
//
// Animations :
//   - Apparition en fade-in + slide-up (300 ms)
//   - Burst de couleur lors de la transition (cf. success_burst.dart existe déjà)

import 'package:flutter/material.dart';

import '../services/voice_comparison_service.dart';
import '../theme/adaptive_colors.dart';
import '../theme/app_theme.dart';

/// Affiche le résultat d'une comparaison vocale.
///
/// Prend un [VoiceComparisonResult] (produit par VoiceComparisonService.compare)
/// et l'affiche avec un code couleur selon le verdict.
class VoiceResultDisplay extends StatefulWidget {
  const VoiceResultDisplay({
    super.key,
    required this.result,
    required this.spokenText,
    required this.expectedText,
    this.onRetry,
    this.onNext,
    this.showDetails = true,
  });

  /// Résultat de la comparaison (verdict + similarité + nombres).
  final VoiceComparisonResult result;

  /// Texte brut tel que transcrit par speech_to_text (avant normalisation).
  /// Affiché tel quel pour que l'élève voie ce qu'il a dit.
  final String spokenText;

  /// Texte brut de la réponse attendue (avant normalisation).
  final String expectedText;

  /// Callback optionnel pour le bouton "Réessayer" (ré-enregistrer).
  final VoidCallback? onRetry;

  /// Callback optionnel pour le bouton "Question suivante".
  final VoidCallback? onNext;

  /// True pour afficher le détail des nombres (matched/missing/wrong).
  /// False pour un affichage simplifié (juste verdict + score).
  final bool showDetails;

  @override
  State<VoiceResultDisplay> createState() => _VoiceResultDisplayState();
}

class _VoiceResultDisplayState extends State<VoiceResultDisplay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    ));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final verdict = widget.result.verdict;
    final colors = _verdictColors(verdict);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surface(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.accent, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ─── En-tête : icône + verdict + score ───────────
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.accent,
                    ),
                    child: Icon(colors.icon, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          colors.title,
                          style: AppTextStyles.h3.copyWith(
                            color: colors.accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Similarité : ${widget.result.similarityPercent}%',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AdaptiveColors.textSecondary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ─── Transcription (ce que l'élève a dit) ─────────
              _buildTextBlock(
                context: context,
                label: 'Tu as dit :',
                text: widget.spokenText.isEmpty
                    ? '(rien détecté)'
                    : '"${widget.spokenText}"',
                textColor: AdaptiveColors.textPrimary(context),
              ),

              const SizedBox(height: 10),

              // ─── Réponse attendue ─────────────────────────────
              _buildTextBlock(
                context: context,
                label: 'Réponse attendue :',
                text: '"${widget.expectedText}"',
                textColor: colors.accent,
              ),

              // ─── Détail des nombres (optionnel) ───────────────
              if (widget.showDetails && _hasNumberDetails()) ...[
                const SizedBox(height: 12),
                _buildNumbersDetail(context),
              ],

              // ─── Boutons d'action ─────────────────────────────
              if (widget.onRetry != null || widget.onNext != null) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (widget.onRetry != null)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: widget.onRetry,
                          icon: const Icon(Icons.mic_none, size: 18),
                          label: const Text('Réessayer'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colors.accent,
                            side: BorderSide(color: colors.accent),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    if (widget.onRetry != null && widget.onNext != null)
                      const SizedBox(width: 12),
                    if (widget.onNext != null)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: widget.onNext,
                          icon: const Icon(Icons.arrow_forward, size: 18),
                          label: const Text('Suivant'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ─── Helpers UI ─────────────────────────────────────────────

  Widget _buildTextBlock({
    required BuildContext context,
    required String label,
    required String text,
    required Color textColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.label.copyWith(
            color: AdaptiveColors.textSecondary(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          text,
          style: AppTextStyles.body.copyWith(
            color: textColor,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  bool _hasNumberDetails() {
    final r = widget.result;
    return r.matchingNumbers.isNotEmpty ||
        r.missingNumbers.isNotEmpty ||
        r.wrongNumbers.isNotEmpty;
  }

  Widget _buildNumbersDetail(BuildContext context) {
    final r = widget.result;
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        if (r.matchingNumbers.isNotEmpty)
          _buildNumberChip(
            context: context,
            label: 'Corrects : ${r.matchingNumbers.join(", ")}',
            color: AppColors.success,
            icon: Icons.check_circle,
          ),
        if (r.missingNumbers.isNotEmpty)
          _buildNumberChip(
            context: context,
            label: 'Manquants : ${r.missingNumbers.join(", ")}',
            color: AppColors.warning,
            icon: Icons.help_outline,
          ),
        if (r.wrongNumbers.isNotEmpty)
          _buildNumberChip(
            context: context,
            label: 'Erronés : ${r.wrongNumbers.join(", ")}',
            color: AppColors.error,
            icon: Icons.cancel,
          ),
      ],
    );
  }

  Widget _buildNumberChip({
    required BuildContext context,
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.label.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Retourne les couleurs, icône et titre associés au verdict.
  _VerdictVisuals _verdictColors(VoiceVerdict verdict) {
    switch (verdict) {
      case VoiceVerdict.correct:
        return _VerdictVisuals(
          accent: AppColors.success,
          icon: Icons.check_circle,
          title: 'Bravo, réponse correcte !',
          surface: (ctx) => AdaptiveColors.surface(ctx),
        );
      case VoiceVerdict.partial:
        return _VerdictVisuals(
          accent: AppColors.accent,
          icon: Icons.help_outline,
          title: 'Partiellement correct',
          surface: (ctx) => AdaptiveColors.accentSurface(ctx),
        );
      case VoiceVerdict.incorrect:
        return _VerdictVisuals(
          accent: AppColors.error,
          icon: Icons.cancel,
          title: 'Réponse incorrecte',
          surface: (ctx) => AdaptiveColors.surface(ctx),
        );
    }
  }
}

/// Regroupe les attributs visuels (couleur, icône, titre) d'un verdict.
class _VerdictVisuals {
  final Color accent;
  final IconData icon;
  final String title;
  final Color Function(BuildContext) surface;

  const _VerdictVisuals({
    required this.accent,
    required this.icon,
    required this.title,
    required this.surface,
  });
}
