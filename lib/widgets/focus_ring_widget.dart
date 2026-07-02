// lib/widgets/focus_ring_widget.dart
// Anneau de focus visible pour la navigation clavier (WCAG 2.1 SC 2.4.7).
//
// Wrapper a placer autour de tout element interactif (bouton, carte, item de
// liste) pour afficher un anneau colore lorsque l'element recoit le focus
// clavier (Tab) ou programmatique.
//
// Le comportement par defaut montre l'anneau a CHAQUE focus (clavier OU
// programmatique). C'est le comportement le plus accessible (WCAG 2.4.7
// Focus Visible) : un utilisateur qui navigue au clavier voit toujours ou il
// est, meme apres un clic souris.
//
// Utilisation simple :
//   FocusRing(
//     child: ElevatedButton(
//       onPressed: () {},
//       child: Text('Valider'),
//     ),
//   )
//
// Utilisation avec FocusNode personnalise :
//   final _node = FocusNode();
//   FocusRing(
//     focusNode: _node,
//     borderRadius: 12,
//     child: MyCustomButton(),
//   )
//
// Pour les elements non rectangulaires (cercle, etc.), utiliser [shape].
//
// Reference : Material 3 spec - Focus indicators
//   https://m3.material.io/foundations/interaction-states#6dbc4c7d-5f5c-454c-9221-6e8da9d5d514

import 'package:flutter/material.dart';

import '../services/accessibility_advanced_service.dart';

/// Forme de l'anneau de focus. Par defaut rectangle avec bordures arrondies.
enum FocusRingShape {
  /// Rectangle avec bordures arrondies (defaut, pour boutons/cartes).
  roundedRect,

  /// Cercle (pour avatars, boutons circulaires type FAB).
  circle,

  /// Stadium (pillule, pour chips et switches).
  stadium,
}

/// Wrapper qui affiche un anneau colore autour de [child] lorsque celui-ci
/// recoit le focus.
///
/// L'anneau a une epaisseur de 3.0 px (recommandation WCAG 2.4.13 draft) et
/// une couleur adaptee au theme (jaune sur dark, bleu sur light) via
/// [AccessibilityAdvancedService.focusRingColor].
class FocusRing extends StatefulWidget {
  /// Element interactif a entourer.
  final Widget child;

  /// Noeud de focus optionnel. Si null, un FocusNode interne est cree.
  final FocusNode? focusNode;

  /// Couleur de l'anneau. Si null, utilise
  /// [AccessibilityAdvancedService.focusRingColor].
  final Color? ringColor;

  /// Epaisseur de l'anneau en px (defaut 3.0).
  final double ringWidth;

  /// Rayon des coins pour [FocusRingShape.roundedRect] (defaut 8.0).
  final double borderRadius;

  /// Marge entre l'anneau et [child] en px (defaut 2.0).
  /// Permet a l'anneau de "respirer" autour de l'element.
  final double padding;

  /// Forme de l'anneau (defaut [FocusRingShape.roundedRect]).
  final FocusRingShape shape;

  /// Si true (defaut), l'anneau reste visible meme quand l'element n'a pas le
  /// focus mais est survole par la souris (desktop/web). Utile pour les
  /// boutons secondaires.
  final bool showOnHover;

  /// Si true (defaut false), l'anneau est masque tant que l'utilisateur n'a
  /// pas utilise le clavier. Active si vous voulez le comportement "anneau
  /// clavier uniquement" (Material spec) plutot que "anneau permanent".
  ///
  /// Detection : Flutter ne distingue pas nativement focus clavier vs
  /// focus clic. Ce flag est un emplacement reserve ; actuellement l'anneau
  /// s'affiche des que [FocusNode.hasFocus] est true.
  final bool keyboardOnly;

  const FocusRing({
    super.key,
    required this.child,
    this.focusNode,
    this.ringColor,
    this.ringWidth = AccessibilityAdvancedService.kFocusRingWidth,
    this.borderRadius = 8.0,
    this.padding = 2.0,
    this.shape = FocusRingShape.roundedRect,
    this.showOnHover = false,
    this.keyboardOnly = false,
  });

  @override
  State<FocusRing> createState() => _FocusRingState();
}

class _FocusRingState extends State<FocusRing> {
  late final FocusNode _node;
  bool _ownsNode = false;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode != null) {
      _node = widget.focusNode!;
      _ownsNode = false;
    } else {
      _node = FocusNode();
      _ownsNode = true;
    }
    _node.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _node.removeListener(_onFocusChange);
    if (_ownsNode) _node.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isFocused = _node.hasFocus;
    final showRing = isFocused || (widget.showOnHover && _isHovering);

    final ringColor = widget.ringColor ??
        AccessibilityAdvancedService.focusRingColor(context);

    final padding = EdgeInsets.all(widget.padding);

    return Focus(
      focusNode: _node,
      child: MouseRegion(
        onEnter: widget.showOnHover ? (_) => setState(() => _isHovering = true) : null,
        onExit: widget.showOnHover ? (_) => setState(() => _isHovering = false) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: padding,
          decoration: _buildDecoration(showRing, ringColor),
          child: widget.child,
        ),
      ),
    );
  }

  Decoration _buildDecoration(bool showRing, Color ringColor) {
    if (!showRing) {
      return BoxDecoration(
        borderRadius: widget.shape == FocusRingShape.roundedRect
            ? BorderRadius.circular(widget.borderRadius)
            : null,
        shape: widget.shape == FocusRingShape.circle
            ? BoxShape.circle
            : BoxShape.rectangle,
      );
    }
    switch (widget.shape) {
      case FocusRingShape.roundedRect:
        return BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(
            color: ringColor,
            width: widget.ringWidth,
          ),
        );
      case FocusRingShape.circle:
        return BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: ringColor,
            width: widget.ringWidth,
          ),
        );
      case FocusRingShape.stadium:
        return BoxDecoration(
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(
            color: ringColor,
            width: widget.ringWidth,
          ),
        );
    }
  }
}

/// Widget de convenance qui wrappe [child] dans un [FocusRing] avec les
/// valeurs par defaut. Alias semantique pour la lisibilite du code appelant.
///
/// Exemple :
///   FocusableButton(
///     onPressed: () {},
///     child: Text('Valider'),
///   )
class FocusableButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final FocusNode? focusNode;
  final Color? ringColor;
  final double borderRadius;

  const FocusableButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.focusNode,
    this.ringColor,
    this.borderRadius = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    return FocusRing(
      focusNode: focusNode,
      ringColor: ringColor,
      borderRadius: borderRadius,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        child: child,
      ),
    );
  }
}

/// Widget de convenance pour les elements de liste focusables (ex : items
/// d'un menu, cartes dans une liste). Wrappe [child] dans un [FocusRing] +
/// gere Enter/Space pour activer via [onActivate].
///
/// Exemple :
///   FocusableListItem(
///     onActivate: () => Navigator.push(...),
///     child: ListTile(title: Text('Item 1')),
///   )
class FocusableListItem extends StatelessWidget {
  final Widget child;
  final VoidCallback? onActivate;
  final FocusNode? focusNode;
  final double borderRadius;
  final bool autofocus;

  const FocusableListItem({
    super.key,
    required this.child,
    this.onActivate,
    this.focusNode,
    this.borderRadius = 12.0,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return FocusRing(
      focusNode: focusNode,
      borderRadius: borderRadius,
      child: InkWell(
        onTap: onActivate,
        borderRadius: BorderRadius.circular(borderRadius),
        child: child,
      ),
    );
  }
}
