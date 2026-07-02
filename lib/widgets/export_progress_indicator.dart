// lib/widgets/export_progress_indicator.dart
// Indicateur de progression pour la génération du rapport PDF.
//
// Affiché pendant que [PdfExportService] charge les données et construit
// le document. Deux états possibles :
//   - [ExportProgressIndicator.indeterminate] : étape avec durée inconnue
//     (chargement Hive, calcul BKT, appel ScorePredictor).
//   - [ExportProgressIndicator.determinate] : étape avec pourcentage connu
//     (génération du PDF, écriture fichier).
//
// Utilisation :
//   ExportProgressIndicator(
//     status: 'Chargement des données de progression…',
//     step: 2,
//     totalSteps: 4,
//   )

import 'package:flutter/material.dart';

import '../theme/adaptive_colors.dart';
import '../theme/app_theme.dart';

/// Étapes standard du pipeline d'export PDF (cohérent avec les `status`
/// affichés par [ExportPreviewScreen]).
enum ExportStep {
  /// Lecture Hive (AppUser + ReviewCards).
  loadingData('Chargement des données de progression…'),

  /// Calcul mastery/weak chapters + ScorePredictor.
  computingStats('Calcul des statistiques et de la prédiction…'),

  /// Construction du Document (pdf package).
  buildingPdf('Construction du document PDF…'),

  /// Écriture du fichier temporaire pour le partage.
  writingFile('Préparation du fichier pour le partage…'),

  /// Terminé avec succès.
  done('Rapport généré avec succès.'),

  /// Erreur pendant la génération.
  error('Échec de la génération du rapport.');

  const ExportStep(this.message);
  final String message;
}

class ExportProgressIndicator extends StatelessWidget {
  /// Étape courante du pipeline.
  final ExportStep step;

  /// Étape courante (1-indexed) sur le total, pour l'affichage « Étape 2/4 ».
  final int currentStep;

  /// Nombre total d'étapes (par défaut 4 : load, compute, build, write).
  final int totalSteps;

  /// Optionnel : message personnalisé qui surcharge `step.message`.
  final String? customMessage;

  /// Optionnel : pourcentage 0-1 pour la barre déterminée. Si null, barre
  /// indéterminée (animation infinie).
  final double? progress;

  const ExportProgressIndicator({
    super.key,
    required this.step,
    this.currentStep = 1,
    this.totalSteps = 4,
    this.customMessage,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = step == ExportStep.done;
    final isError = step == ExportStep.error;
    final showSteps = !isDone && !isError && totalSteps > 0;

    final Color accentColor = isError
        ? AppColors.error
        : isDone
            ? AppColors.success
            : AppColors.primary;

    final String message = customMessage ?? step.message;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AdaptiveColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AdaptiveColors.shadow(context),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ─── Icône / indicateur circulaire ───────────────────────
          _buildIndicator(context, accentColor, isDone, isError),
          const SizedBox(height: 20),

          // ─── Message de statut ───────────────────────────────────
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.h3.copyWith(
              color: AdaptiveColors.textPrimary(context),
              fontSize: 15,
            ),
          ),
          if (showSteps) ...[
            const SizedBox(height: 6),
            Text(
              'Étape $currentStep / $totalSteps',
              style: AppTextStyles.bodySmall.copyWith(
                color: AdaptiveColors.textSecondary(context),
              ),
            ),
          ],
          const SizedBox(height: 16),

          // ─── Barre de progression ────────────────────────────────
          _buildProgressBar(context, accentColor, isDone, isError),
        ],
      ),
    );
  }

  Widget _buildIndicator(
    BuildContext context,
    Color color,
    bool isDone,
    bool isError,
  ) {
    if (isDone) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.check_circle, color: color, size: 36),
      );
    }
    if (isError) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.error_outline, color: color, size: 36),
      );
    }
    return SizedBox(
      width: 48,
      height: 48,
      child: CircularProgressIndicator(
        value: progress, // null -> indéterminé
        strokeWidth: 4,
        color: color,
        backgroundColor: color.withOpacity(0.12),
      ),
    );
  }

  Widget _buildProgressBar(
    BuildContext context,
    Color color,
    bool isDone,
    bool isError,
  ) {
    final double? value = isDone
        ? 1.0
        : isError
            ? null
            : progress;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LinearProgressIndicator(
        value: value,
        minHeight: 6,
        color: color,
        backgroundColor: color.withOpacity(0.12),
      ),
    );
  }
}
