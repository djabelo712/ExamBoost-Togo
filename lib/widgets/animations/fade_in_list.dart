// lib/widgets/animations/fade_in_list.dart
// Apparition en cascade d'une liste d'items.
//
// Le 1er item apparait a 0ms, le 2e a `itemDelay`, le 3e a 2*`itemDelay`, etc.
// Chaque item combine un fade + un slide depuis `offset` vers (0, 0).
//
// Utilisation (dashboard, liste de statistiques, badges, etc.) :
//   FadeInList(
//     children: [
//       _buildStatCard('Cartes maitrisees', '42'),
//       _buildStatCard('Streak', '12 jours'),
//       _buildStatCard('Score moyen', '78%'),
//     ],
//   )
//
// Pour un delai plus marque (effet theatral) :
//   FadeInList(
//     itemDelay: const Duration(milliseconds: 200),
//     itemDuration: const Duration(milliseconds: 600),
//     offset: const Offset(0, 40),
//     children: [...],
//   )

import 'package:flutter/material.dart';

class FadeInList extends StatelessWidget {
  /// Items a afficher en cascade.
  final List<Widget> children;

  /// Delai entre chaque item (defaut 100ms).
  final Duration itemDelay;

  /// Duree d'animation de chaque item (defaut 400ms).
  final Duration itemDuration;

  /// Offset de depart (defaut (0, 20) = slide up + fade).
  final Offset offset;

  /// Courbe d'animation (defaut easeOut).
  final Curve curve;

  /// Direction de la colonne (defaut vertical). Si false, ligne horizontale.
  final bool vertical;

  /// Espacement entre chaque item (defaut 12).
  final double spacing;

  /// Alignement de la colonne/ligne.
  final CrossAxisAlignment crossAxisAlignment;

  /// Alignement principal.
  final MainAxisAlignment mainAxisAlignment;

  const FadeInList({
    super.key,
    required this.children,
    this.itemDelay = const Duration(milliseconds: 100),
    this.itemDuration = const Duration(milliseconds: 400),
    this.offset = const Offset(0, 20),
    this.curve = Curves.easeOut,
    this.vertical = true,
    this.spacing = 12,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
    this.mainAxisAlignment = MainAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      if (i > 0) {
        items.add(SizedBox(
          width: vertical ? 0 : spacing,
          height: vertical ? spacing : 0,
        ));
      }
      items.add(
        _FadeInItem(
          child: children[i],
          delay: itemDelay * i,
          duration: itemDuration,
          offset: offset,
          curve: curve,
        ),
      );
    }

    if (vertical) {
      return Column(
        crossAxisAlignment: crossAxisAlignment,
        mainAxisAlignment: mainAxisAlignment,
        children: items,
      );
    }
    return Row(
      crossAxisAlignment: crossAxisAlignment == CrossAxisAlignment.stretch
          ? CrossAxisAlignment.center
          : crossAxisAlignment,
      mainAxisAlignment: mainAxisAlignment,
      children: items,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Item unique : fade + slide avec delai
// ─────────────────────────────────────────────────────────────────────

class _FadeInItem extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset offset;
  final Curve curve;

  const _FadeInItem({
    required this.child,
    required this.delay,
    required this.duration,
    required this.offset,
    required this.curve,
  });

  @override
  State<_FadeInItem> createState() => _FadeInItemState();
}

class _FadeInItemState extends State<_FadeInItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = CurvedAnimation(parent: _controller, curve: widget.curve);

    // Demarrage differe : delai = widget.delay
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(
              widget.offset.dx * (1 - _animation.value),
              widget.offset.dy * (1 - _animation.value),
            ),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
