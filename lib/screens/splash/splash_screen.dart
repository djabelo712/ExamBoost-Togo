// lib/screens/splash/splash_screen.dart
// Splash screen animé d'ExamBoost Togo.
//
// Comportement :
//   1. Au lancement de l'app, le splash s'affiche pendant 2.5 secondes.
//   2. Animation en 4 temps (via un seul AnimationController 2500ms) :
//        - 0.0s -> 0.5s  : fond vert Togo plein écran + logo fade-in (scale 0.8 -> 1.0, easeOutBack)
//        - 0.5s -> 1.0s  : tagline "ExamBoost Togo" qui slide up sous le logo
//        - 1.0s -> 1.5s  : sous-tagline "Préparation intelligente aux examens" qui fade in
//        - 1.5s -> 2.5s  : LinearProgressIndicator + texte "Chargement..."
//   3. A 2.5s : vérifier UserProvider.isAuthenticated :
//        - oui  -> context.go('/')           (home)
//        - non  -> context.go('/onboarding') (auth)
//
// Design :
//   - Fond dégradé vertical AppColors.primary -> AppColors.primaryDark
//   - Logo : container blanc arrondi 80x80 + Icons.school (vert Togo)
//   - Texte en blanc (avec opacité pour la sous-tagline)
//   - LinearProgressIndicator couleur AppColors.accent (orange)
//   - Pas de Scaffold, juste Material avec décor custom
//
// Pas de lib externe : uniquement AnimationController + Tween + CurvedAnimation.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/user_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.durationMs = 2500});

  /// Durée totale du splash (ms). Par défaut 2500 ms.
  /// Peut être surchargée via le constructeur si l'agent principal veut
  /// personnaliser la temporisation (ne pas descendre sous 1500 ms).
  final int durationMs;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ─── Contrôleur principal (timeline 2500ms) ─────────────────────
  late final AnimationController _controller;

  // ─── Animations par phase ──────────────────────────────────────
  // Phase 1 (0.0 -> 0.5s) : logo (fade + scale 0.8 -> 1.0, easeOutBack)
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;

  // Phase 2 (0.5 -> 1.0s) : tagline (slide up + fade)
  late final Animation<double> _taglineFade;
  late final Animation<Offset> _taglineSlide;

  // Phase 3 (1.0 -> 1.5s) : sous-tagline (fade in)
  late final Animation<double> _subTaglineFade;

  // Phase 4 (1.5 -> 2.5s) : progress bar + texte "Chargement..."
  late final Animation<double> _progressFade;
  late final Animation<double> _progressValue;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.durationMs),
    );

    // Phase 1 : logo (0% -> 20% de la timeline = 0.0s -> 0.5s)
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.00, 0.20, curve: Curves.easeIn),
      ),
    );
    _logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.00, 0.20, curve: Curves.easeOutBack),
      ),
    );

    // Phase 2 : tagline (20% -> 40% = 0.5s -> 1.0s)
    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.20, 0.40, curve: Curves.easeIn),
      ),
    );
    _taglineSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.5), // arrive d'en bas
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.20, 0.40, curve: Curves.easeOut),
      ),
    );

    // Phase 3 : sous-tagline (40% -> 60% = 1.0s -> 1.5s)
    _subTaglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.40, 0.60, curve: Curves.easeIn),
      ),
    );

    // Phase 4 : progress + texte (60% -> 100% = 1.5s -> 2.5s)
    // Fade rapide du bloc (60% -> 70%) puis remplissage linéaire (60% -> 100%).
    _progressFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.60, 0.70, curve: Curves.easeIn),
      ),
    );
    _progressValue = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.60, 1.00, curve: Curves.linear),
      ),
    );

    // Lance la timeline puis redirige à la fin.
    // Le .then() garantit qu'on n'appelle context.go() qu'après l'animation complète,
    // même si l'utilisateur reste sur l'écran.
    _controller.forward().then((_) {
      if (mounted) _redirect();
    });
  }

  /// Redirige vers / (home) ou /onboarding selon l'état d'authentification.
  Future<void> _redirect() async {
    if (!mounted) return;

    final UserProvider userProvider =
        Provider.of<UserProvider>(context, listen: false);

    // Petit délai pour laisser le dernier frame se stabiliser avant la nav.
    await Future.delayed(const Duration(milliseconds: 50));
    if (!mounted) return;

    if (userProvider.isAuthenticated) {
      context.go(AppRoutes.home);
    } else {
      context.go(AppRoutes.onboarding);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      // Pas de Scaffold : on dessine un dégradé plein écran.
      color: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              AppColors.primary,     // Vert Togo (#006837)
              AppColors.primaryDark, // Vert foncé (#004A26)
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: <Widget>[
              // ─── Bloc central : logo + tagline + sous-tagline ───
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    // Logo (Phase 1)
                    FadeTransition(
                      opacity: _logoFade,
                      child: ScaleTransition(
                        scale: _logoScale,
                        child: _buildLogo(),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Tagline (Phase 2)
                    SlideTransition(
                      position: _taglineSlide,
                      child: FadeTransition(
                        opacity: _taglineFade,
                        child: const Text(
                          'ExamBoost Togo',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Sous-tagline (Phase 3)
                    FadeTransition(
                      opacity: _subTaglineFade,
                      child: Text(
                        'Préparation intelligente aux examens',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),

              // ─── Progress + texte en bas (Phase 4) ───
              Positioned(
                left: 48,
                right: 48,
                bottom: 48,
                child: FadeTransition(
                  opacity: _progressFade,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      // AnimatedBuilder pour re-peindre la barre à chaque tick
                      AnimatedBuilder(
                        animation: _progressValue,
                        builder: (BuildContext context, Widget? child) {
                          return LinearProgressIndicator(
                            value: _progressValue.value,
                            backgroundColor: Colors.white24,
                            color: AppColors.accent, // Orange Togo
                            minHeight: 4,
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Chargement...',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.80),
                          fontSize: 13,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Logo : container blanc arrondi 80x80 + Icons.school (vert Togo).
  /// Le shadow porte légèrement le logo sur le fond vert.
  Widget _buildLogo() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Icon(
        Icons.school,
        color: AppColors.primary,
        size: 44,
      ),
    );
  }
}
