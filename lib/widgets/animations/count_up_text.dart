// lib/widgets/animations/count_up_text.dart
// Texte qui s'incremente de 0 a `value` avec animation.
//
// Utilisation typique : afficher un score final ou une statistique qui
// " monte " progressivement (effet premium) au lieu d'apparaitre direct.
//
// Exemples :
//   CountUpText(value: 78, suffix: '%', style: AppTextStyles.h1)
//   CountUpText(value: 1250, prefix: '+', suffix: ' XP', duration: Duration(seconds: 2))
//   CountUpText(value: 12, suffix: ' cartes', style: AppTextStyles.h3)

import 'package:flutter/material.dart';

class CountUpText extends StatefulWidget {
  /// Valeur cible a atteindre (entier).
  final int value;

  /// Duree de l'animation d'increment.
  final Duration duration;

  /// Style du texte.
  final TextStyle? style;

  /// Prefixe optionnel (ex: "+", "-").
  final String? prefix;

  /// Suffixe optionnel (ex: "%", " pts", " XP", " cartes").
  final String? suffix;

  /// Courbe d'animation (defaut : easeOut pour ralentir vers la fin).
  final Curve curve;

  const CountUpText({
    super.key,
    required this.value,
    this.duration = const Duration(milliseconds: 1500),
    this.style,
    this.prefix,
    this.suffix,
    this.curve = Curves.easeOut,
  });

  @override
  State<CountUpText> createState() => _CountUpTextState();
}

class _CountUpTextState extends State<CountUpText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  // Valeur de depart courante (permet de reanimer depuis l'etat actuel
  // si `value` change pendant le cycle de vie du widget).
  int _startValue = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.forward();
    });
  }

  @override
  void didUpdateWidget(covariant CountUpText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      // On garde la derniere valeur affichee comme depart, puis on relance.
      _startValue = _currentDisplayedValue(oldWidget.value, _controller.value);
      _controller.duration = widget.duration;
      _controller.forward(from: 0.0);
    }
  }

  /// Calcule la valeur affichee a un instant t (pour reanimer proprement).
  int _currentDisplayedValue(int target, double t) {
    final eased = widget.curve.transform(t);
    return (_startValue + (target - _startValue) * eased).round();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        // Animation<double> plutot que IntTween : on calcule l'entier a la main
        // pour pouvoir reanimer depuis _startValue si value change.
        final eased = widget.curve.transform(_controller.value);
        final current = (_startValue +
                (widget.value - _startValue) * eased)
            .round();
        return Text(
          '${widget.prefix ?? ''}$current${widget.suffix ?? ''}',
          style: widget.style,
        );
      },
    );
  }
}
