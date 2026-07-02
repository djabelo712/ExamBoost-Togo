// lib/screens/level/widgets/xp_gain_animation.dart
// Animation "+X XP" qui flotte vers le haut après chaque action qui donne de l'XP.
//
// Affiche un overlay temporaire (1,5 s) avec :
//   - Le montant "+10 XP" en gros, couleur selon la source
//   - L'icône de la source à gauche
//   - Une montée vers le haut + fade out
//
// Usage (depuis n'importe quel écran après un gain d'XP) :
//   final result = await levelService.addXpQuestionCorrecte(userId);
//   if (result.amount > 0) {
//     XpGainAnimation.show(context, amount: result.amount, source: result.source);
//   }
//
// L'overlay se positionne par défaut au-dessus du centre de l'écran.
// On peut le repositionner via [alignment] (par ex. Alignment.topCenter
// si l'action vient du bas de l'écran).

import 'package:flutter/material.dart';

import '../../../models/user_level.dart';

class XpGainAnimation {
  XpGainAnimation._();

  /// Affiche l'animation "+X XP" pendant 1,5 s.
  /// À appeler juste après [LevelService.addXp] si le montant est > 0.
  ///
  /// [alignment] contrôle la position de l'overlay sur l'écran.
  /// Par défaut : en haut, légèrement décalé du centre pour éviter
  /// de masquer le contenu principal.
  static void show(
    BuildContext context, {
    required int amount,
    required XpSource source,
    Alignment alignment = const Alignment(0, -0.6),
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _XpGainOverlay(
        amount: amount,
        source: source,
        alignment: alignment,
        onDismiss: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }
}

// ─── Widget overlay (Stateful pour l'animation) ────────────────────

class _XpGainOverlay extends StatefulWidget {
  const _XpGainOverlay({
    required this.amount,
    required this.source,
    required this.alignment,
    required this.onDismiss,
  });

  final int amount;
  final XpSource source;
  final Alignment alignment;
  final VoidCallback onDismiss;

  @override
  State<_XpGainOverlay> createState() => _XpGainOverlayState();
}

class _XpGainOverlayState extends State<_XpGainOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // ─── Animations composites ────────────────────────────────────
  // Séquence (~ 1,5 s) :
  //   0.0 - 0.2 s : scale 0.5 → 1.1 (easeOutBack) + opacity 0 → 1
  //   0.2 - 0.3 s : scale 1.1 → 1.0 (settle)
  //   0.3 - 1.0 s : translation Y 0 → -60 + opacity reste 1
  //   1.0 - 1.5 s : opacity 1 → 0 (fade out)
  late final Animation<double> _scale;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward().then((_) {
        if (mounted) widget.onDismiss();
      });

    const easeOutBack = Curves.easeOutBack;
    const easeOut = Curves.easeOut;
    const easeIn = Curves.easeIn;

    // Scale : 0.5 → 1.1 → 1.0 (overshoot puis settle)
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.5, end: 1.1)
            .chain(CurveTween(curve: easeOutBack)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.1, end: 1.0)
            .chain(CurveTween(curve: easeOut)),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 60,
      ),
    ]).animate(_controller);

    // Opacité : 0 → 1 (fade in), puis 1 → 0 (fade out)
    _opacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: easeOut)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: easeIn)),
        weight: 25,
      ),
    ]).animate(_controller);

    // Slide vers le haut : 0 → -60 px (translation Y)
    _slide = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -60),
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 1.0, curve: easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Ignore les taps pour ne pas bloquer l'UI sous-jacente.
    return Positioned.fill(
      child: IgnorePointer(
        child: Align(
          alignment: widget.alignment,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return SlideTransition(
                position: _slide,
                child: Opacity(
                  opacity: _opacity.value,
                  child: Transform.scale(
                    scale: _scale.value,
                    child: _buildContent(),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ─── Contenu : pastille "+X XP" + icône source ───────────────

  Widget _buildContent() {
    final color = widget.source.color;
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.source.icon, color: Colors.white, size: 22),
            const SizedBox(width: 8),
            Text(
              '+${widget.amount} XP',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
                shadows: [
                  Shadow(
                    color: Colors.black38,
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
