// lib/widgets/tts_settings_widget.dart
// Composants UI reutilisables pour l'ecran de configuration TTS.
//
// Regroupe les briques elementaires pour eviter la duplication dans
// tts_settings_screen.dart :
//   - TtsSectionTitle   : titre de section avec sous-ligne discret
//   - TtsSettingsCard   : carte blanche standardisee (radius 16, ombre leger)
//   - TtsSwitchRow      : ligne switch avec icone + titre + sous-titre
//   - TtsSliderRow      : ligne slider avec label + valeur numerique
//   - HighlightedTextPreview : texte avec mot courant surligne (synchro TTS)
//
// Tous les widgets consomment TtsService via Provider pour rebuild reactif.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/tts_service.dart';
import '../theme/app_theme.dart';

/// Titre de section type "Parametres de voix", en majuscules, espacement
/// letter-spacing important (style iOS settings).
class TtsSectionTitle extends StatelessWidget {
  final String text;
  final IconData? icon;

  const TtsSectionTitle({super.key, required this.text, this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 6),
          ],
          Text(
            text.toUpperCase(),
            style: AppTextStyles.label.copyWith(
              color: AppColors.textSecondary,
              fontSize: 12,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Carte blanche standardisee pour regrouper des sous-elements.
class TtsSettingsCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const TtsSettingsCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Ligne switch avec icone + titre + sous-titre.
class TtsSwitchRow extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  const TtsSwitchRow({
    super.key,
    required this.icon,
    this.iconColor,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? AppColors.primary;
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w500,
                )),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: AppTextStyles.bodySmall),
                ],
              ],
            ),
          ),
          Switch(value: value, onChanged: enabled ? onChanged : null),
        ],
      ),
    );
  }
}

/// Ligne slider avec label + valeur numerique formatee.
class TtsSliderRow extends StatelessWidget {
  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;
  final String? helper;

  const TtsSliderRow({
    super.key,
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
    this.helper,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                valueLabel,
                style: AppTextStyles.label.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
        if (helper != null)
          Padding(
            padding: const EdgeInsets.only(top: 2, left: 4),
            child: Text(helper!, style: AppTextStyles.bodySmall),
          ),
      ],
    );
  }
}

/// Apercu de texte avec surlignage synchro du mot en cours de lecture.
///
/// Ecoute TtsService pour mettre a jour le mot surligne en temps reel.
/// Si aucun texte en lecture (ou texte different), n'affiche pas de
/// surlignage mais rend le texte normal.
class HighlightedTextPreview extends StatelessWidget {
  final String text;
  final TextStyle? baseStyle;
  final Color highlightColor;
  final Color highlightedTextColor;

  const HighlightedTextPreview({
    super.key,
    required this.text,
    this.baseStyle,
    this.highlightColor = const Color(0xFFFFF59D), // jaune pale
    this.highlightedTextColor = const Color(0xFF1A1A1A),
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<TtsService>(
      builder: (context, tts, _) {
        final isCurrent = tts.currentlySpokenText == text && tts.isSpeaking;
        final start = tts.currentWordStartOffset;
        final end = tts.currentWordEndOffset;

        if (!isCurrent || end <= start || end > text.length) {
          return Text(text, style: baseStyle ?? AppTextStyles.questionText);
        }

        // Construit un RichText avec le mot courant surligne.
        return RichText(
          text: TextSpan(
            style: baseStyle ?? AppTextStyles.questionText,
            children: [
              TextSpan(text: text.substring(0, start)),
              TextSpan(
                text: text.substring(start, end),
                style: (baseStyle ?? AppTextStyles.questionText).copyWith(
                  backgroundColor: highlightColor,
                  color: highlightedTextColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextSpan(text: text.substring(end)),
            ],
          ),
        );
      },
    );
  }
}

/// Petit indicateur "EN LECTURE" pulse pour les en-tetes de carte.
class TtsNowPlayingBadge extends StatelessWidget {
  const TtsNowPlayingBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TtsService>(
      builder: (context, tts, _) {
        if (!tts.isSpeaking) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                tts.isPaused ? Icons.pause_circle : Icons.graphic_eq,
                size: 12,
                color: AppColors.primary,
              ),
              const SizedBox(width: 4),
              Text(
                tts.isPaused ? 'EN PAUSE' : 'EN LECTURE',
                style: AppTextStyles.label.copyWith(
                  color: AppColors.primary,
                  fontSize: 10,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
