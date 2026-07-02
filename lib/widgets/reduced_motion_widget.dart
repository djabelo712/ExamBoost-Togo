// lib/widgets/reduced_motion_widget.dart
// Wrapper pour réduire ou désactiver les animations selon les préférences
// système (MediaQuery.disableAnimations) et/ou une option app.
//
// Conformité WCAG 2.1 :
//   - SC 2.3.3 Animation from Interactions (Level AAA) : les animations
//     déclenchées par interaction doivent pouvoir être désactivées.
//   - Recommendation : respecter la préférence OS "réduire les animations"
//     (iOS : Réduire les animations ; Android : Supprimer les animations ;
//     Web/macOS/Windows : prefers-reduced-motion).
//
// Trois mécanismes :
//   1. [ReducedMotionWidget] : wrapper générique qui exécute un builder
//      different selon que les animations sont activées ou non.
//   2. [ReducedMotionFadeIn] : widget de commodité pour un fadeIn (instantané
//      si animations réduites).
//   3. [ReducedMotionAnimatedSwitcher] : wrapper d'AnimatedSwitcher qui
//      devient un simple enfant sans transition si animations réduites.
//
// Helpers statiques (utilisables sans wrapper) :
//   - [ReducedMotionWidget.shouldReduceMotion(context)]
//   - [ReducedMotionWidget.duration(context, original)]
//   - [ReducedMotionWidget.curve(context, normal)]
//
// Utilisation :
//   ReducedMotionFadeIn(
//     duration: const Duration(milliseconds: 300),
//     child: Text('Bienvenue sur ExamBoost !'),
//   )
//
//   final d = ReducedMotionWidget.duration(
//     context, const Duration(milliseconds: 250),
//   );
//   AnimationController(duration: d, vsync: this);
//
// Référence :
//   https://docs.flutter.dev/ui/accessibility#animations

import 'package:flutter/material.dart';

/// Wrapper générique qui exécute un builder différent selon que les
/// animations sont activées (builder normal) ou réduites (builder réduit).
///
/// Le builder reçoit [reduce] = true si les animations doivent être
/// désactivées. À l'intérieur du builder, choisir la version animée ou
/// instantanée.
///
/// Exemple :
///   ReducedMotionWidget(
///     child: myContent,
///     builder: (context, child, reduce) {
///       if (reduce) return child!;
///       return AnimatedOpacity(
///         opacity: 1.0,
///         duration: const Duration(milliseconds: 300),
///         child: child,
///       );
///     },
///   )
class ReducedMotionWidget extends StatelessWidget {
  /// Enfant passé au builder.
  final Widget child;

  /// Builder qui reçoit (context, child, reduce). Si [reduce] est true,
  /// retourner une version sans animation.
  final Widget Function(BuildContext context, Widget child, bool reduce)
      builder;

  const ReducedMotionWidget({
    super.key,
    required this.child,
    required this.builder,
  });

  /// True si l'utilisateur a activé "Réduire les animations" dans les
  /// préférences système (iOS / Android / Web / desktop).
  ///
  /// Alias de [AccessibilityAdvancedService.shouldReduceMotion].
  static bool shouldReduceMotion(BuildContext context) {
    return MediaQuery.disableAnimationsOf(context);
  }

  /// Renvoie [original] si les animations sont activées, sinon
  /// [Duration.zero] (transition instantanée).
  static Duration duration(BuildContext context, Duration original) {
    return shouldReduceMotion(context) ? Duration.zero : original;
  }

  /// Renvoie [normal] si les animations sont activées, sinon [Curves.linear]
  /// (pas d'effet de courbe).
  static Curve curve(BuildContext context, Curve normal) {
    return shouldReduceMotion(context) ? Curves.linear : normal;
  }

  @override
  Widget build(BuildContext context) {
    final reduce = shouldReduceMotion(context);
    return builder(context, child, reduce);
  }
}

/// Fade-in qui s'affiche instantanément si les animations sont réduites.
///
/// Utiliser pour les contenus qui apparaissent (SplashScreen -> Home,
/// onboarding, listes chargées).
///
/// Exemple :
///   ReducedMotionFadeIn(
///     duration: const Duration(milliseconds: 400),
///     delay: const Duration(milliseconds: 100),
///     child: Dashboard(),
///   )
class ReducedMotionFadeIn extends StatefulWidget {
  /// Contenu à faire apparaître.
  final Widget child;

  /// Durée du fondu (ignorée si animations réduites).
  final Duration duration;

  /// Délai avant le début du fondu (ignoré si animations réduites).
  final Duration delay;

  /// Opacité initiale (defaut 0.0).
  final double initialOpacity;

  /// Opacité finale (defaut 1.0).
  final double finalOpacity;

  /// Si true (defaut), démarre l'animation automatiquement au build.
  final bool autoStart;

  const ReducedMotionFadeIn({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.delay = Duration.zero,
    this.initialOpacity = 0.0,
    this.finalOpacity = 1.0,
    this.autoStart = true,
  });

  @override
  State<ReducedMotionFadeIn> createState() => _ReducedMotionFadeInState();
}

class _ReducedMotionFadeInState extends State<ReducedMotionFadeIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  bool _reduced = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _opacity = Tween<double>(
      begin: widget.initialOpacity,
      end: widget.finalOpacity,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final wasReduced = _reduced;
    _reduced = ReducedMotionWidget.shouldReduceMotion(context);
    if (_reduced && !wasReduced) {
      _controller.value = 1.0;
    } else if (!_reduced && wasReduced && widget.autoStart) {
      _startAnimation();
    } else if (!_reduced && widget.autoStart && _controller.value == 0.0) {
      _startAnimation();
    }
  }

  void _startAnimation() {
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Si animations réduites : afficher directement l'enfant à opacité finale.
    if (_reduced) {
      return Opacity(opacity: widget.finalOpacity, child: widget.child);
    }
    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, child) {
        return Opacity(opacity: _opacity.value, child: child);
      },
      child: widget.child,
    );
  }
}

/// AnimatedSwitcher qui devient un simple [child] sans transition si les
/// animations sont réduites.
///
/// Utiliser pour les contenus qui changent (carte de question, étape
/// d'onboarding, page de wizard).
class ReducedMotionAnimatedSwitcher extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Widget Function(Widget, Animation<double>)? transitionBuilder;

  const ReducedMotionAnimatedSwitcher({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 250),
    this.transitionBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final reduce = ReducedMotionWidget.shouldReduceMotion(context);
    if (reduce) {
      // Pas de transition : on remplace directement l'enfant.
      return child;
    }
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: transitionBuilder ??
          (child, animation) {
            return FadeTransition(opacity: animation, child: child);
          },
      child: child,
    );
  }
}

/// Wrapper qui désactive les animations d'un [AnimationController] en
/// forçant sa valeur à 1.0 immédiatement si [ReducedMotionWidget.shouldReduceMotion]
/// est true.
///
/// À utiliser dans les StatefulWidget qui possèdent leur propre
/// AnimationController :
///
///   @override
///   void didChangeDependencies() {
///     super.didChangeDependencies();
///     if (ReducedMotionControllerShortcut.skipIfReduced(context, _controller)) {
///       return; // animations désactivées, controller à 1.0
///     }
///     _controller.forward();
///   }
class ReducedMotionControllerShortcut {
  ReducedMotionControllerShortcut._();

  /// Si les animations sont réduites, force [controller] à 1.0 et renvoie
  /// true (l'appelant peut `return` immédiatement). Sinon, renvoie false
  /// (l'appelant peut lancer son animation normalement).
  static bool skipIfReduced(
    BuildContext context,
    AnimationController controller,
  ) {
    if (ReducedMotionWidget.shouldReduceMotion(context)) {
      controller.value = 1.0;
      return true;
    }
    return false;
  }
}
