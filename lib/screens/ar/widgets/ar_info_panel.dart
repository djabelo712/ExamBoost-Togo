// lib/screens/ar/widgets/ar_info_panel.dart
// Panneau d'informations temps reel sur la forme 3D.
//
// Affiche :
//   - Le nom de la forme et sa description pedagogique.
//   - Les dimensions (symbole, libelle, valeur, unite) — modifiables via
//     sliders, ce qui recalcule en direct le volume et la surface.
//   - Le volume et la surface totale (avec la formule litterale).
//   - La surface laterale (formule + valeur) — utile pour le cours.
//
// Le panneau est concu pour etre affiche en bas de l'ecran (BottomSheet
// persistant ou draggable). Il se reconfigurer dynamiquement quand la forme
// selectionnee change.

import 'package:flutter/material.dart';

import '../models/ar_object.dart';

/// Panneau d'informations temps reel sur la forme AR courante.
///
/// Les [onDimensionChanged] signale les changements de dimensions pour que le
/// parent mette a jour l'ARObject (et recalcule volume/surface).
class ArInfoPanel extends StatelessWidget {
  final ARObject object;
  final ValueChanged<Map<String, double>> onDimensionsChanged;

  /// Vrai si les sliders de dimensions sont visibles (modifiables).
  /// Quand false, le panneau affiche juste les valeurs en lecture seule.
  final bool editable;

  const ArInfoPanel({
    super.key,
    required this.object,
    required this.onDimensionsChanged,
    this.editable = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 4,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Poignee de drag (barre horizontale discrete).
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // En-tete : nom + description.
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: object.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    object.label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              object.type.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),

            const Divider(height: 20),

            // Dimensions (sliders ou lecture seule).
            ..._buildDimensionsSection(theme, colorScheme),

            const Divider(height: 20),

            // Volume + surface (en temps reel).
            _MetricRow(
              icon: Icons.inventory_2_outlined,
              label: 'Volume',
              formula: object.formuleVolume,
              value: _formatVolume(object.volume),
              accentColor: const Color(0xFF006837), // vert Togo
            ),
            const SizedBox(height: 8),
            _MetricRow(
              icon: Icons.crop_square,
              label: 'Surface totale',
              formula: object.formuleSurface,
              value: _formatSurface(object.surfaceTotale),
              accentColor: const Color(0xFFD97700), // orange Togo
            ),
            const SizedBox(height: 8),
            _MetricRow(
              icon: Icons.view_agenda_outlined,
              label: 'Surface latérale',
              formula: '(sans les bases)',
              value: _formatSurface(object.surfaceLaterale),
              accentColor: const Color(0xFF1565C0), // bleu info
            ),
          ],
        ),
      ),
    );
  }

  /// Construit la section "Dimensions" : soit des sliders, soit des valeurs
  /// en lecture seule, selon [editable].
  List<Widget> _buildDimensionsSection(
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final dims = object.dimensionsListees;
    return [
      Row(
        children: [
          Text(
            'Dimensions',
            style: theme.textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          if (!editable)
            Text(
              '(lecture seule)',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
      const SizedBox(height: 8),
      for (final d in dims) ...[
        if (editable)
          _DimensionSlider(
            dimension: d,
            onChanged: (newValue) {
              final updated = Map<String, double>.from(object.dimensions);
              // Le mapping symbole -> cle de la map depend du type.
              updated[_keyForSymbol(d.symbole)] = newValue;
              onDimensionsChanged(updated);
            },
          )
        else
          _DimensionReadonly(dimension: d),
        const SizedBox(height: 4),
      ],
    ];
  }

  /// Retrouve la cle de la map [dimensions] correspondant a un symbole.
  /// Necessaire car le symbole affiche (ex: 'a') peut differer de la cle
  /// interne (ex: 'cote').
  String _keyForSymbol(String symbole) {
    switch (object.type) {
      case ARShapeType.cylindre:
      case ARShapeType.cone:
      case ARShapeType.sphere:
        return symbole == 'r' ? 'r' : 'h';
      case ARShapeType.pyramide:
        return symbole == 'a' ? 'cote' : 'h';
      case ARShapeType.cube:
        return 'cote';
      case ARShapeType.prisme:
        return symbole == 'a' ? 'cote' : 'longueur';
    }
  }

  /// Formate un volume en cm^3 avec un suffixe d'unite.
  String _formatVolume(double v) {
    if (v >= 1000) {
      return '${(v / 1000).toStringAsFixed(2)} dm³';
    }
    return '${_formatNumber(v)} cm³';
  }

  /// Formate une surface en cm^2 avec un suffixe d'unite.
  String _formatSurface(double v) {
    if (v >= 10000) {
      return '${(v / 10000).toStringAsFixed(2)} dm²';
    }
    return '${_formatNumber(v)} cm²';
  }

  /// Formate un nombre : entier si possible, sinon 2 decimales.
  String _formatNumber(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }
}

/// Ligne "Volume / Surface" avec icone, label, formule et valeur.
class _MetricRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String formula;
  final String value;
  final Color accentColor;

  const _MetricRow({
    required this.icon,
    required this.label,
    required this.formula,
    required this.value,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: accentColor.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: accentColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                formula,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: accentColor,
          ),
        ),
      ],
    );
  }
}

/// Slider pour une dimension modifiable.
class _DimensionSlider extends StatelessWidget {
  final ARDimension dimension;
  final ValueChanged<double> onChanged;

  const _DimensionSlider({
    required this.dimension,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              dimension.symbole,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFFD97700),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              dimension.libelle,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Expanded(
            flex: 5,
            child: Slider(
              value: dimension.valeur.clamp(1.0, 20.0),
              min: 1.0,
              max: 20.0,
              divisions: 19,
              label: '${dimension.valeurFormatee} ${dimension.unite}',
              onChanged: onChanged,
            ),
          ),
          SizedBox(
            width: 64,
            child: Text(
              '${dimension.valeurFormatee} ${dimension.unite}',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

/// Affichage en lecture seule d'une dimension (pas de slider).
class _DimensionReadonly extends StatelessWidget {
  final ARDimension dimension;

  const _DimensionReadonly({required this.dimension});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              dimension.symbole,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFFD97700),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              dimension.libelle,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Text(
            '${dimension.valeurFormatee} ${dimension.unite}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
