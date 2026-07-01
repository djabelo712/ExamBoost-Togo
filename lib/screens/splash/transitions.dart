// lib/screens/splash/transitions.dart
// Transitions personnalisées réutilisables pour GoRouter.
//
// Fournit :
//   - enum TransitionType { fade, slideUp, scale, slideRight }
//   - 3 PageBuilders "prêts à l'emploi" : FadeTransitionBuilder,
//     SlideUpTransitionBuilder, ScaleTransitionBuilder
//   - une fonction helper buildPageWithTransition() qui sélectionne la
//     transition selon le TransitionType fourni.
//
// Intégration GoRouter (à faire par l'agent principal dans app_router.dart) :
//
//   GoRoute(
//     path: '/revision/:matiere',
//     pageBuilder: (context, state) => buildPageWithTransition(
//       child: RevisionScreen(...),
//       type: TransitionType.slideRight,
//     ),
//   ),
//
// Pas de lib externe : uniquement FadeTransition, SlideTransition,
// ScaleTransition et les Curves natives de Flutter.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Types de transition disponibles pour buildPageWithTransition().
enum TransitionType {
  /// Fondu simple (300ms, easeInOut). Sobre, multi-usage.
  fade,

  /// Slide vers le haut (300ms, easeOut). Idéal pour les modales/bottom sheets.
  slideUp,

  /// Scale depuis le centre (350ms, easeOutBack). Effet "pop", dialogues.
  scale,

  /// Slide depuis la droite (300ms, easeInOut). Navigation "push" classique.
  slideRight,
}

/// Durées par défaut (en millisecondes) — ajustables sans toucher au code des
/// builders. L'agent principal peut surcharger en passant une durée explicite
/// aux constructeurs des *TransitionBuilder.
const int _kFadeDurationMs = 300;
const int _kSlideDurationMs = 300;
const int _kScaleDurationMs = 350;
const int _kSlideRightDurationMs = 300;

// ─────────────────────────────────────────────────────────────────────────────
// Builders individuels (CustomTransitionPage<void>)
// ─────────────────────────────────────────────────────────────────────────────

/// Transition en fondu (fade in/out).
///
/// Usage :
/// ```dart
/// GoRoute(
///   path: '/dashboard',
///   pageBuilder: (context, state) => FadeTransitionBuilder(
///     child: DashboardScreen(),
///   ),
/// )
/// ```
class FadeTransitionBuilder extends CustomTransitionPage<void> {
  FadeTransitionBuilder({
    required Widget child,
    super.key,
    Duration? duration,
  }) : super(
          child: child,
          transitionDuration:
              duration ?? const Duration(milliseconds: _kFadeDurationMs),
          reverseTransitionDuration:
              duration ?? const Duration(milliseconds: _kFadeDurationMs),
          transitionsBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) {
            // easeInOut pour un fondu doux et symétrique.
            final CurvedAnimation curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            );
            return FadeTransition(opacity: curved, child: child);
          },
        );
}

/// Transition en glissement vers le haut (slide up).
///
/// Usage : modales plein écran, formulaires multi-étapes, onboarding.
class SlideUpTransitionBuilder extends CustomTransitionPage<void> {
  SlideUpTransitionBuilder({
    required Widget child,
    super.key,
    Duration? duration,
  }) : super(
          child: child,
          transitionDuration:
              duration ?? const Duration(milliseconds: _kSlideDurationMs),
          reverseTransitionDuration:
              duration ?? const Duration(milliseconds: _kSlideDurationMs),
          transitionsBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) {
            // easeOut pour une entrée dynamique, retour soft.
            final CurvedAnimation curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
              reverseCurve: Curves.easeIn,
            );
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 1.0), // arrive d'en bas
                end: Offset.zero,
              ).animate(curved),
              child: child,
            );
          },
        );
}

/// Transition en mise à l'échelle (scale depuis le centre).
///
/// Usage : dialogues, cartes qui s'ouvrent en plein écran, pop-in.
/// Utilise Curves.easeOutBack pour un effet légèrement "rebondissant".
class ScaleTransitionBuilder extends CustomTransitionPage<void> {
  ScaleTransitionBuilder({
    required Widget child,
    super.key,
    Duration? duration,
  }) : super(
          child: child,
          transitionDuration:
              duration ?? const Duration(milliseconds: _kScaleDurationMs),
          reverseTransitionDuration:
              duration ?? const Duration(milliseconds: _kScaleDurationMs),
          transitionsBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) {
            // easeOutBack pour l'entrée "pop", easeInOut pour la sortie douce.
            final CurvedAnimation curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
              reverseCurve: Curves.easeIn,
            );
            return ScaleTransition(
              scale: Tween<double>(begin: 0.85, end: 1.0).animate(curved),
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeIn,
                ),
                child: child,
              ),
            );
          },
        );
}

/// Transition en glissement depuis la droite (slide right, type "push" iOS).
///
/// Usage : navigation hiérarchique classique (liste -> détail).
class SlideRightTransitionBuilder extends CustomTransitionPage<void> {
  SlideRightTransitionBuilder({
    required Widget child,
    super.key,
    Duration? duration,
  }) : super(
          child: child,
          transitionDuration:
              duration ?? const Duration(milliseconds: _kSlideRightDurationMs),
          reverseTransitionDuration:
              duration ?? const Duration(milliseconds: _kSlideRightDurationMs),
          transitionsBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) {
            final CurvedAnimation curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            );
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0), // arrive de la droite
                end: Offset.zero,
              ).animate(curved),
              child: child,
            );
          },
        );
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper générique
// ─────────────────────────────────────────────────────────────────────────────

/// Construit une [CustomTransitionPage] en fonction du [TransitionType] fourni.
///
/// Exemple GoRouter :
/// ```dart
/// GoRoute(
///   path: '/simulation',
///   pageBuilder: (context, state) => buildPageWithTransition(
///     child: SimulationScreen(...),
///     type: TransitionType.slideUp,
///     duration: const Duration(milliseconds: 400), // optionnel
///   ),
/// )
/// ```
///
/// [child]    : le widget d'écran à afficher.
/// [type]     : le type de transition (voir [TransitionType]).
/// [duration] : durée personnalisée (sinon durée par défaut du type).
CustomTransitionPage<void> buildPageWithTransition({
  required Widget child,
  required TransitionType type,
  Duration? duration,
  LocalKey? key,
}) {
  switch (type) {
    case TransitionType.fade:
      return FadeTransitionBuilder(child: child, duration: duration, key: key);
    case TransitionType.slideUp:
      return SlideUpTransitionBuilder(child: child, duration: duration, key: key);
    case TransitionType.scale:
      return ScaleTransitionBuilder(child: child, duration: duration, key: key);
    case TransitionType.slideRight:
      return SlideRightTransitionBuilder(
        child: child,
        duration: duration,
        key: key,
      );
  }
}
