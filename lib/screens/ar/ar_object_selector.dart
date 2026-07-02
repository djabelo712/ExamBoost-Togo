// lib/screens/ar/ar_object_selector.dart
// Sélecteur de forme 3D pour le module AR.
//
// Affiche les 6 formes disponibles (cylindre, pyramide, cone, sphere, cube,
// prisme) sous forme de grille de cartes. Chaque carte montre :
//   - Une icone vectorielle representative (Material Icons).
//   - Le nom de la forme.
//   - Un indicateur visuel si elle est actuellement selectionnee.
//
// Le selecteur est concu pour etre affiche dans un BottomSheet persistent ou
// en haut de l'ecran AR. Le tap sur une carte declenche [onSelected].

import 'package:flutter/material.dart';

import 'models/ar_object.dart';

/// Selecteur de forme 3D.
class ArObjectSelector extends StatelessWidget {
  final ARShapeType selected;
  final ValueChanged<ARShapeType> onSelected;

  const ArObjectSelector({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final types = ARShapeType.values;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              Text(
                'Choisir une forme',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${types.length} formes',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 116,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: types.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final type = types[index];
              return _ShapeCard(
                type: type,
                isSelected: type == selected,
                onTap: () => onSelected(type),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Carte d'une forme dans le selecteur.
class _ShapeCard extends StatelessWidget {
  final ARShapeType type;
  final bool isSelected;
  final VoidCallback onTap;

  const _ShapeCard({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  /// Retourne l'icone Material representative de la forme.
  IconData _iconFor(ARShapeType t) {
    switch (t) {
      case ARShapeType.cylindre:
        return Icons.local_drink_outlined;
      case ARShapeType.pyramide:
        return Icons.change_history;
      case ARShapeType.cone:
        return Icons.bakery_dining_outlined;
      case ARShapeType.sphere:
        return Icons.sports_baseball_outlined;
      case ARShapeType.cube:
        return Icons.grid_view;
      case ARShapeType.prisme:
        return Icons.view_in_ar_outlined;
    }
  }

  /// Couleur d'accent de la carte (en accord avec la couleur par defaut de
  /// chaque forme definie dans ARObject.defaultFor).
  Color _accentFor(ARShapeType t) {
    switch (t) {
      case ARShapeType.cylindre:
        return const Color(0xFF006837);
      case ARShapeType.pyramide:
        return const Color(0xFFD97700);
      case ARShapeType.cone:
        return const Color(0xFF1565C0);
      case ARShapeType.sphere:
        return const Color(0xFF2E7D32);
      case ARShapeType.cube:
        return const Color(0xFFD97700);
      case ARShapeType.prisme:
        return const Color(0xFF006837);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = _accentFor(type);
    final width = 96.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: width,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? accent.withAlpha(25)
                : theme.colorScheme.surfaceContainerHighest.withAlpha(120),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? accent : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _iconFor(type),
                size: 32,
                color: isSelected ? accent : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 6),
              Text(
                type.label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? accent
                      : theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
