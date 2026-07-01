// lib/widgets/animations/bounce_button.dart
// Bouton avec effet bounce au tap (scale 1.0 -> 0.95 -> 1.0 avec spring).
//
// Ajoute un retour tactile premium sans dependre de InkWell.
// A utiliser pour les CTA importants (valider, demarrer une session, etc.).
//
// Utilisation :
//   BounceButton(
//     onPressed: () => _startSession(),
//     child: Container(
//       padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
//       decoration: BoxDecoration(
//         color: AppColors.primary,
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: const Text('Demarrer la session', style: AppTextStyles.button),
//     ),
//   )
//
// Pour un bouton plus " mou " :
//   BounceButton(scale: 0.90, onPressed: ..., child: ...)

import 'package:flutter/material.dart';

class BounceButton extends StatefulWidget {
  /// Contenu du bouton (Container, Row, Text, etc.).
  final Widget child;

  /// Callback appelle au tap. Si null, le bouton est desactive.
  final VoidCallback? onPressed;

  /// Facteur d'echelle au tap (defaut 0.95 = reduit de 5%).
  final double scale;

  /// Duree de l'animation aller (down) en ms.
  final Duration downDuration;

  /// Duree de l'animation retour (up) en ms.
  final Duration upDuration;

  /// Courbe de retour (defaut spring leger).
  final Curve upCurve;

  const BounceButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.scale = 0.95,
    this.downDuration = const Duration(milliseconds: 60),
    this.upDuration = const Duration(milliseconds: 180),
    this.upCurve = Curves.elasticOut,
  });

  @override
  State<BounceButton> createState() => _BounceButtonState();
}

class _BounceButtonState extends State<BounceButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  bool _isDown = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.downDuration,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scale).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
  }

  void _onTapDown(TapDownDetails _) {
    if (widget.onPressed == null) return;
    setState(() => _isDown = true);
    _controller.duration = widget.downDuration;
    _controller.forward();
  }

  void _onTapUp(TapUpDetails _) {
    _reset();
    widget.onPressed?.call();
  }

  void _onTapCancel() {
    _reset();
  }

  void _reset() {
    setState(() => _isDown = false);
    _controller.duration = widget.upDuration;
    // On joue l'animation inverse avec une courbe spring pour l'effet bounce.
    _controller.reverse();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return GestureDetector(
      onTapDown: enabled ? _onTapDown : null,
      onTapUp: enabled ? _onTapUp : null,
      onTapCancel: enabled ? _onTapCancel : null,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Opacity(
          opacity: enabled ? 1.0 : 0.5,
          child: widget.child,
        ),
      ),
    );
  }
}
