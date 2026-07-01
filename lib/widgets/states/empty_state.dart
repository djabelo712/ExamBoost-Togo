// lib/widgets/states/empty_state.dart
// Empty state generique reutilisable pour tous les ecrans ExamBoost.
//
// Affiche un etat vide standardise :
//   - icone grande (80-120px) en gris leger
//   - titre en gras (h3)
//   - description en gris (bodySmall)
//   - bouton d'action optionnel (CTA)
//
// Utilisation :
//   EmptyState(
//     icon: Icons.inbox,
//     title: 'Aucune question disponible',
//     description: 'Pas encore de questions pour cette matiere.',
//     actionLabel: 'Choisir une autre matiere',
//     onAction: () => context.go('/matieres'),
//   )
//
// Pour les cas specifiques (favoris, badges, simulations...), preferer les
// wrappers dedies dans empty_states/ qui pre-configurent l'icone + les textes.

import 'package:flutter/material.dart';

import '../../theme/adaptive_colors.dart';
import '../../theme/app_theme.dart';

class EmptyState extends StatelessWidget {
  /// Icone affichee en grand (taille iconSize, couleur iconColor).
  final IconData icon;

  /// Titre court (1-2 lignes) en gras.
  final String title;

  /// Description optionnelle (2-3 lignes) en gris secondaire.
  final String? description;

  /// Libelle du bouton d'action principal (optionnel).
  /// Si null, aucun bouton n'est affiche.
  final String? actionLabel;

  /// Callback du bouton d'action principal.
  /// Si null, le bouton est desactive (gris).
  final VoidCallback? onAction;

  /// Libelle d'un lien secondaire (optionnel) en dessous du bouton.
  /// Typiquement : "Continuer hors-ligne", "Voir le statut"...
  final String? secondaryActionLabel;

  /// Callback du lien secondaire.
  final VoidCallback? onSecondaryAction;

  /// Couleur de l'icone. Par defaut : textSecondary (gris leger) pour
  //  signaler un etat non bloquant. Pour les CTAs forts (favoris...),
  //  l'appelant peut passer AppColors.accent ou primary.
  final Color? iconColor;

  /// Taille de l'icone en pixels. Defaut : 96 (gros mais pas envahissant).
  final double iconSize;

  /// Rayon du cercle de fond derriere l'icone. Defaut : 56 (cercle柔和).
  /// Si null, pas de cercle de fond (icone seule).
  final double? iconBackgroundRadius;

  /// Couleur de fond du cercle derriere l'icone.
  /// Par defaut : surfaceVariant avec legere opacite.
  final Color? iconBackgroundColor;

  /// Padding interne (autour de tout le contenu). Defaut : 32 sur les cotes.
  final EdgeInsetsGeometry padding;

  /// Alignement vertical. Defaut : centré verticalement.
  /// Passer Alignment.topCenter pour les ecrans avec AppBar fixe et liste
  /// vide juste en dessous (evite un contenu "tasse" en haut).
  final Alignment alignment;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.iconColor,
    this.iconSize = 96,
    this.iconBackgroundRadius = 56,
    this.iconBackgroundColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveIconColor = iconColor ?? AdaptiveColors.textSecondary(context);
    final effectiveIconBg = iconBackgroundColor ??
        (isDark
            ? Colors.white.withOpacity(0.04)
            : AppColors.primarySurface.withOpacity(0.5));

    return Align(
      alignment: alignment,
      child: SingleChildScrollView(
        // Scroll si ecran petit (notamment paysage ou clavier)
        child: Padding(
          padding: padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ─── Icone (avec cercle de fond optionnel) ─────────────
              if (iconBackgroundRadius != null)
                Container(
                  width: iconBackgroundRadius! * 2,
                  height: iconBackgroundRadius! * 2,
                  decoration: BoxDecoration(
                    color: effectiveIconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: iconSize,
                    color: effectiveIconColor,
                  ),
                )
              else
                Icon(
                  icon,
                  size: iconSize,
                  color: effectiveIconColor,
                ),

              SizedBox(height: iconBackgroundRadius != null ? 24 : 20),

              // ─── Titre ─────────────────────────────────────────────
              Text(
                title,
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

              // ─── Bouton d'action principal ─────────────────────────
              if (actionLabel != null) ...[
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onAction,
                    icon: const Icon(Icons.arrow_forward, size: 20),
                    label: Text(actionLabel!),
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

              // ─── Lien secondaire (TextButton) ──────────────────────
              if (secondaryActionLabel != null) ...[
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
