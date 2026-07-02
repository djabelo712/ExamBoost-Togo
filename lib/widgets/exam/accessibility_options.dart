// lib/widgets/exam/accessibility_options.dart
// Boite de dialogue des options d'accessibilite.
//
// Sections :
//   1. Visuel : police dyslexie, contraste eleve, taille texte, espacement
//   2. Temps : temps additionnel +25%, pauses autorisees
//   3. Cognitif : instructions simplifiees, surligneur, lecture audio (TTS)
//   4. Divers : mode sobre (masquer en-tete officiel), vibration alertes
//
// Sauvegarde dans AccessibilitySettings (Hive) - persistance entre sessions.
//
// OUVERTURE : AccessibilityOptionsDialog.show(context).

import 'package:flutter/material.dart';
import '../../models/accessibility_settings.dart';
import '../../services/accessibility_service.dart';
import '../../theme/app_theme.dart';

class AccessibilityOptionsDialog extends StatefulWidget {
  const AccessibilityOptionsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => const AccessibilityOptionsDialog(),
    );
  }

  @override
  State<AccessibilityOptionsDialog> createState() =>
      _AccessibilityOptionsDialogState();
}

class _AccessibilityOptionsDialogState
    extends State<AccessibilityOptionsDialog> {
  late AccessibilitySettings _settings;

  @override
  void initState() {
    super.initState();
    // On travaille sur une copie : les modifs sont persistees a "Appliquer".
    _settings = AccessibilityService.settings.copyWith();
  }

  Future<void> _appliquer() async {
    await AccessibilityService.update(_settings);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _reinitialiser() async {
    setState(() {
      _settings = AccessibilitySettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildEnTete(),
                const Divider(height: 24),
                _buildSection('Visuel', Icons.visibility, _buildOptionsVisuel()),
                const SizedBox(height: 16),
                _buildSection('Temps', Icons.timer, _buildOptionsTemps()),
                const SizedBox(height: 16),
                _buildSection(
                    'Cognitif', Icons.psychology, _buildOptionsCognitif()),
                const SizedBox(height: 16),
                _buildSection('Divers', Icons.tune, _buildOptionsDivers()),
                const SizedBox(height: 24),
                _buildApercu(),
                const SizedBox(height: 16),
                _buildActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnTete() {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: AppColors.primarySurface,
          child: const Icon(Icons.accessibility, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Accessibilite', style: AppTextStyles.h3),
              Text(
                'Adapte l\'affichage de l\'examen a tes besoins',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildSection(
      String titre, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(titre, style: AppTextStyles.h3.copyWith(fontSize: 15)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  // ─── Section Visuel ──────────────────────────────────────────

  List<Widget> _buildOptionsVisuel() {
    return [
      _switchOption(
        titre: 'Police dyslexie',
        sousTitre:
            'Police adaptee aux eleves dyslexiques (OpenDyslexic si installee)',
        valeur: _settings.dyslexiaFont,
        onChanged: (v) =>
            setState(() => _settings = _settings.copyWith(dyslexiaFont: v)),
      ),
      _divider(),
      _switchOption(
        titre: 'Contraste eleve',
        sousTitre: 'Texte noir sur fond jaune clair pour une lisibilite max',
        valeur: _settings.highContrast,
        onChanged: (v) =>
            setState(() => _settings = _settings.copyWith(highContrast: v)),
      ),
      _divider(),
      _sliderOption(
        titre: 'Taille du texte',
        valeur: _settings.textSizeScale,
        min: 0.85,
        max: 2.0,
        divisions: 23,
        label: _formatTaille(_settings.textSizeScale),
        onChanged: (v) =>
            setState(() => _settings = _settings.copyWith(textSizeScale: v)),
      ),
      _divider(),
      _sliderOption(
        titre: 'Espacement des lignes',
        valeur: _settings.lineSpacing,
        min: 1.0,
        max: 2.0,
        divisions: 10,
        label: '${_settings.lineSpacing.toStringAsFixed(1)}x',
        onChanged: (v) =>
            setState(() => _settings = _settings.copyWith(lineSpacing: v)),
      ),
    ];
  }

  // ─── Section Temps ───────────────────────────────────────────

  List<Widget> _buildOptionsTemps() {
    return [
      _switchOption(
        titre: 'Temps additionnel +25%',
        sousTitre:
            'Pour les eleves avec handicap. Allonge la duree officielle '
            '(ex : 2h -> 2h30)',
        valeur: _settings.extraTime25,
        onChanged: (v) =>
            setState(() => _settings = _settings.copyWith(extraTime25: v)),
      ),
      _divider(),
      _switchOption(
        titre: 'Pauses autorisees',
        sousTitre:
            'Permet de mettre l\'examen en pause (le temps continue de compter)',
        valeur: _settings.allowPauses,
        onChanged: (v) =>
            setState(() => _settings = _settings.copyWith(allowPauses: v)),
      ),
    ];
  }

  // ─── Section Cognitif ────────────────────────────────────────

  List<Widget> _buildOptionsCognitif() {
    return [
      _switchOption(
        titre: 'Instructions simplifiees',
        sousTitre: 'Reecrit les enonces en phrases plus courtes',
        valeur: _settings.simplifiedInstructions,
        onChanged: (v) => setState(() =>
            _settings = _settings.copyWith(simplifiedInstructions: v)),
      ),
      _divider(),
      _switchOption(
        titre: 'Surligneur',
        sousTitre: 'Tu peux surligner des mots dans l\'enonce',
        valeur: _settings.highlighter,
        onChanged: (v) =>
            setState(() => _settings = _settings.copyWith(highlighter: v)),
      ),
      _divider(),
      _switchOption(
        titre: 'Lecture audio (TTS)',
        sousTitre: 'Bouton "Lire" a cote de chaque question',
        valeur: _settings.textToSpeech,
        onChanged: (v) =>
            setState(() => _settings = _settings.copyWith(textToSpeech: v)),
      ),
    ];
  }

  // ─── Section Divers ──────────────────────────────────────────

  List<Widget> _buildOptionsDivers() {
    return [
      _switchOption(
        titre: 'Mode sobre',
        sousTitre: 'Masque l\'en-tete officiel (Republique Togolaise, etc.)',
        valeur: _settings.soberMode,
        onChanged: (v) =>
            setState(() => _settings = _settings.copyWith(soberMode: v)),
      ),
      _divider(),
      _switchOption(
        titre: 'Vibration alertes',
        sousTitre: 'Vibration aux seuils de temps (30, 10, 5, 1 min, 0:00)',
        valeur: _settings.vibrationAlerts,
        onChanged: (v) =>
            setState(() => _settings = _settings.copyWith(vibrationAlerts: v)),
      ),
    ];
  }

  // ─── Apercu ──────────────────────────────────────────────────

  Widget _buildApercu() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _settings.backgroundColor(AppColors.surface),
        border: Border.all(color: AppColors.divider, width: 1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Apercu',
            style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'L\'aire d\'un triangle rectangle de cotes 6 cm et 8 cm est :',
            style: AccessibilityService.adjustTextStyle(
              AppTextStyles.body.copyWith(
                color: _settings.textColor(AppColors.textPrimary),
                backgroundColor: _settings.backgroundColor(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Actions ─────────────────────────────────────────────────

  Widget _buildActions() {
    return Row(
      children: [
        TextButton(
          onPressed: _reinitialiser,
          child: const Text('Reinitialiser'),
        ),
        const Spacer(),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _appliquer,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: const Text('Appliquer'),
        ),
      ],
    );
  }

  // ─── Helpers UI ──────────────────────────────────────────────

  Widget _switchOption({
    required String titre,
    required String sousTitre,
    required bool valeur,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titre, style: AppTextStyles.body.copyWith(fontSize: 14)),
                const SizedBox(height: 2),
                Text(
                  sousTitre,
                  style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: valeur,
            activeColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _sliderOption({
    required String titre,
    required double valeur,
    required double min,
    required double max,
    required int divisions,
    required String label,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(titre, style: AppTextStyles.body.copyWith(fontSize: 14)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  label,
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          Slider(
            value: valeur,
            min: min,
            max: max,
            divisions: divisions,
            label: label,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _divider() =>
      const Divider(height: 1, color: AppColors.divider, indent: 4, endIndent: 4);

  String _formatTaille(double scale) {
    if (scale <= 0.95) return 'S';
    if (scale <= 1.1) return 'M';
    if (scale <= 1.35) return 'L';
    if (scale <= 1.7) return 'XL';
    return 'XXL';
  }
}
