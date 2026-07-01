// lib/widgets/states/error_state.dart
// Error state generique reutilisable pour tous les ecrans ExamBoost.
//
// Affiche un etat d'erreur standardise :
//   - icone grande (rouge / orange selon gravite)
//   - message d'erreur (titre court)
//   - description (detail de l'erreur, suggestion de resolution)
//   - code erreur technique optionnel (en gris tout petit)
//   - bouton "Reessayer"
//   - lien secondaire optionnel ("Signaler le bug", "Continuer hors-ligne"...)
//
// Utilisation :
//   ErrorState(
//     message: 'Impossible de charger les questions',
//     description: 'Verifie ta connexion Internet et reessaie.',
//     onRetry: () => _chargerQuestions(),
//     icon: Icons.wifi_off,
//   )
//
// Pour les cas specifiques (reseau, base de donnees, sync...), preferer les
// wrappers dedies dans error_states/ qui pre-configurent icone + couleurs +
// textes.

import 'package:flutter/material.dart';

import '../../theme/adaptive_colors.dart';
import '../../theme/app_theme.dart';

class ErrorState extends StatelessWidget {
  /// Message court affiche en titre (1-2 lignes).
  /// Defaut : "Une erreur est survenue".
  final String message;

  /// Description longue (2-3 lignes) avec suggestion de resolution.
  final String? description;

  /// Code erreur technique affiche en gris tout petit (optionnel).
  /// Typiquement : "ERR_NETWORK_001", "DB_READ_FAILED"...
  /// Fournir un code court ; ne pas afficher un stacktrace complet.
  final String? errorCode;

  /// Callback du bouton "Reessayer".
  /// Si null, le bouton n'est pas affiche (erreur non recuperable).
  final VoidCallback? onRetry;

  /// Libelle du bouton principal. Defaut : "Reessayer".
  final String retryLabel;

  /// Lien secondaire (optionnel) en dessous du bouton.
  /// Typiquement : "Signaler le bug", "Contacter le support"...
  final String? secondaryActionLabel;

  /// Callback du lien secondaire.
  final VoidCallback? onSecondaryAction;

  /// Icone affichee en grand. Defaut : Icons.error_outline.
  final IconData icon;

  /// Couleur de l'icone. Defaut : AppColors.error (rouge).
  /// Passer AppColors.warning (orange) pour les erreurs non bloquantes
  /// (sync impossible, mode hors-ligne partiel...).
  final Color? iconColor;

  /// Taille de l'icone. Defaut : 80.
  final double iconSize;

  /// Si false, le bouton "Reessayer" n'est pas affiche meme si onRetry est
  /// fourni. Utile pour les erreurs fatales (restart necessaire).
  final bool showRetry;

  /// Padding interne. Defaut : 32 horizontal, 24 vertical.
  final EdgeInsetsGeometry padding;

  /// Alignement vertical. Defaut : centré.
  final Alignment alignment;

  const ErrorState({
    super.key,
    this.message = 'Une erreur est survenue',
    this.description,
    this.errorCode,
    this.onRetry,
    this.retryLabel = 'Réessayer',
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.icon = Icons.error_outline,
    this.iconColor,
    this.iconSize = 80,
    this.showRetry = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? AppColors.error;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconBg = isDark
        ? effectiveIconColor.withOpacity(0.12)
        : effectiveIconColor.withOpacity(0.10);

    return Align(
      alignment: alignment,
      child: SingleChildScrollView(
        child: Padding(
          padding: padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ─── Icone (avec cercle de fond teinte) ───────────────
              Container(
                width: iconSize + 32,
                height: iconSize + 32,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: iconSize,
                  color: effectiveIconColor,
                ),
              ),
              const SizedBox(height: 24),

              // ─── Titre (message d'erreur) ──────────────────────────
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTextStyles.h3.copyWith(
                  color: AdaptiveColors.textPrimary(context),
                ),
              ),

              // ─── Description ───────────────────────────────────────
              if (description != null) ...[
                const SizedBox(height: 8),
                Text(
                  description!,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(
                    color: AdaptiveColors.textSecondary(context),
                    height: 1.5,
                  ),
                ),
              ],

              // ─── Code erreur technique ─────────────────────────────
              if (errorCode != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AdaptiveColors.surfaceVariant(context),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    errorCode!,
                    style: AppTextStyles.label.copyWith(
                      fontSize: 11,
                      color: AdaptiveColors.textSecondary(context),
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],

              // ─── Bouton "Reessayer" ────────────────────────────────
              if (showRetry && onRetry != null) ...[
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh, size: 20),
                    label: Text(retryLabel),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AdaptiveColors.primary(context),
                      foregroundColor: AdaptiveColors.onPrimary(context),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],

              // ─── Lien secondaire ───────────────────────────────────
              if (secondaryActionLabel != null &&
                  onSecondaryAction != null) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: onSecondaryAction,
                  style: TextButton.styleFrom(
                    foregroundColor: AdaptiveColors.textSecondary(context),
                  ),
                  child: Text(secondaryActionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
