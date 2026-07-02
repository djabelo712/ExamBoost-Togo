// lib/screens/ar/ar_instructions_sheet.dart
// Bottom sheet d'instructions d'utilisation du module AR.
//
// Affiche les gestes de manipulation (rotation, scale, translation), les
// fonctionnalites disponibles (capture photo, modification dimensions) et les
// prerequis techniques (Android 8+ / iOS 12+ pour AR native, fallback simule).
//
// Le sheet est concu pour etre affiche en overlay (showModalBottomSheet) au
// premier lancement ou via un bouton "Aide" dans l'AppBar.

import 'package:flutter/material.dart';

/// Bottom sheet d'instructions d'utilisation.
class ArInstructionsSheet extends StatelessWidget {
  const ArInstructionsSheet({super.key});

  /// Affiche le sheet modal.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ArInstructionsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Poignee de drag.
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Titre.
            Row(
              children: [
                Icon(Icons.school_outlined,
                    color: colorScheme.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Utiliser le module AR Géométrie',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Section : gestes de manipulation.
            _SectionTitle(text: 'Gestes de manipulation'),
            const SizedBox(height: 8),
            _InstructionRow(
              icon: Icons.swipe,
              iconBgColor: const Color(0xFF006837),
              title: 'Rotation (1 doigt)',
              description:
                  'Glissez avec un doigt sur la forme pour la faire pivoter '
                  'horizontalement et verticalement.',
            ),
            _InstructionRow(
              icon: Icons.pinch,
              iconBgColor: const Color(0xFFD97700),
              title: 'Zoom (2 doigts)',
              description:
                  'Pincez avec deux doigts pour agrandir ou réduire la forme. '
                  'Échelle limitée entre 0,3× et 3×.',
            ),
            _InstructionRow(
              icon: Icons.open_with,
              iconBgColor: const Color(0xFF1565C0),
              title: 'Translation (2 doigts)',
              description:
                  'Glissez avec deux doigts ensemble pour déplacer la forme '
                  'dans le plan de l\'écran.',
            ),
            _InstructionRow(
              icon: Icons.refresh,
              iconBgColor: const Color(0xFF2E7D32),
              title: 'Réinitialiser',
              description:
                  'Bouton "Réinit." en bas : replace la forme au centre, '
                  'annule rotation, zoom et translation.',
            ),

            const SizedBox(height: 16),

            // Section : fonctionnalités.
            _SectionTitle(text: 'Fonctionnalités'),
            const SizedBox(height: 8),
            _InstructionRow(
              icon: Icons.tune,
              iconBgColor: const Color(0xFF006837),
              title: 'Modifier les dimensions',
              description:
                  'Ouvrez le panneau d\'infos (swipe up) et utilisez les '
                  'sliders pour changer rayon, hauteur, côté, etc. Le volume '
                  'et la surface sont recalculés en direct.',
            ),
            _InstructionRow(
              icon: Icons.photo_camera_outlined,
              iconBgColor: const Color(0xFFD97700),
              title: 'Capturer une photo',
              description:
                  'Bouton appareil photo : sauvegarde un PNG de la vue '
                  'actuelle (forme 3D + arrière-plan) dans la galerie.',
            ),
            _InstructionRow(
              icon: Icons.auto_mode,
              iconBgColor: const Color(0xFF1565C0),
              title: 'Rotation automatique',
              description:
                  'La forme tourne lentement tant que vous ne la touchez pas. '
                  'Elle reprend dès que vous relâchez.',
            ),

            const SizedBox(height: 16),

            // Section : prérequis techniques.
            _SectionTitle(text: 'Prérequis techniques'),
            const SizedBox(height: 8),
            _InfoBanner(
              icon: Icons.view_in_ar,
              color: const Color(0xFFD97700),
              text: 'AR native (ARCore/ARKit) requiert Android 8.0+ ou '
                  'iOS 12.0+. Sur les appareils non compatibles, le module '
                  'bascule automatiquement en vue 3D simulée (sans caméra).',
            ),
            const SizedBox(height: 8),
            _InfoBanner(
              icon: Icons.info_outline,
              color: const Color(0xFF1565C0),
              text: 'Mode actuel : vue 3D simulée. La forme est manipulable '
                  '(rotation, zoom, translation) mais n\'est pas ancrée dans '
                  'l\'environnement réel via la caméra.',
            ),

            const SizedBox(height: 20),

            // Bouton de fermeture.
            FilledButton.icon(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.check),
              label: const Text('J\'ai compris'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Titre de section du sheet d'instructions.
class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: theme.colorScheme.onSurfaceVariant,
        letterSpacing: 0.5,
      ),
    );
  }
}

/// Ligne d'instruction avec icone ronde coloree + texte.
class _InstructionRow extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final String title;
  final String description;

  const _InstructionRow({
    required this.icon,
    required this.iconBgColor,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBgColor.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconBgColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Petit bandeau d'information avec icone + texte.
class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _InfoBanner({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
