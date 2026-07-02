// lib/screens/ar/widgets/ar_camera_view.dart
// Vue camera + overlay AR.
//
// En mode AR natif (ar_flutter_plugin branche), ce widget afficherait le flux
// camera en direct via ARSessionManager. En mode simule (par defaut), il
// affiche un arriere-plan gradé qui simule un environnement (sol + horizon)
// pour donner un contexte spatial a la forme 3D.
//
// L'overlay 3D [ArObjectOverlay] est positionne au-dessus de l'arriere-plan
// et capture les gestures de manipulation (rotation, scale, translation).
//
// Le [RepaintBoundary] englobant permet la capture photo (screenshot) via
// `boundary.toImage()` dans l'ecran parent.

import 'package:flutter/material.dart';

import '../models/ar_object.dart';
import 'ar_object_overlay.dart';

/// Vue camera + overlay 3D.
///
/// Le [repaintBoundaryKey] est fourni par l'ecran parent pour permettre la
/// capture photo. Si non fourni, aucune capture ne sera possible.
class ArCameraView extends StatelessWidget {
  final ARObject object;
  final GlobalKey? repaintBoundaryKey;
  final bool autoRotate;
  final VoidCallback? onInteractionStart;

  /// Signal de reinitialisation transmis a [ArObjectOverlay].
  final int resetSignal;

  const ArCameraView({
    super.key,
    required this.object,
    this.repaintBoundaryKey,
    this.autoRotate = true,
    this.onInteractionStart,
    this.resetSignal = 0,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: repaintBoundaryKey,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Arriere-plan simulant un environnement (sol + horizon).
          const _SimulatedCameraBackground(),

          // 2. Overlay 3D (la forme manipulable).
          ArObjectOverlay(
            object: object,
            autoRotate: autoRotate,
            onInteractionStart: onInteractionStart,
            resetSignal: resetSignal,
          ),

          // 3. Indicateur "mode simule" en bas a droite (discret).
          const Positioned(
            right: 12,
            bottom: 12,
            child: _SimulatedModeBadge(),
          ),
        ],
      ),
    );
  }
}

/// Arriere-plan simulant un environnement 3D : ciel/horizon en haut, sol en
/// bas, avec une legere grille en perspective pour aider a juger l'echelle.
class _SimulatedCameraBackground extends StatelessWidget {
  const _SimulatedCameraBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CameraBackgroundPainter(),
      size: Size.infinite,
    );
  }
}

class _CameraBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Gradient vertical : haut (ciel/mur) vers bas (sol).
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFECEFF1), // gris-bleu clair (mur)
          const Color(0xFFCFD8DC), // gris-bleu medium (horizon)
          const Color(0xFF90A4AE), // gris-bleu fonce (sol lointain)
          const Color(0xFF607D8B), // sol devant
        ],
        stops: const [0.0, 0.5, 0.51, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Ligne d'horizon.
    final horizonY = h * 0.5;
    final horizonPaint = Paint()
      ..color = Colors.black.withAlpha(20)
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(0, horizonY),
      Offset(w, horizonY),
      horizonPaint,
    );

    // Grille de perspective sur le sol (lignes fuyantes).
    final gridPaint = Paint()
      ..color = Colors.white.withAlpha(40)
      ..strokeWidth = 1.0;

    // Lignes horizontales (parallel a l'horizon, s'espacent en s'approchant).
    for (var i = 1; i <= 6; i++) {
      final t = i / 6.0;
      final y = horizonY + (h - horizonY) * t * t; // espacement non-lineaire
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    // Lignes fuyantes (du point de fuite central vers les bords bas).
    const vanishX = 0.5; // point de fuite au centre.
    final cx = w * vanishX;
    for (var i = -4; i <= 4; i++) {
      if (i == 0) continue;
      final endX = cx + i * (w / 4);
      canvas.drawLine(
        Offset(cx, horizonY),
        Offset(endX, h),
        gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Petit badge discret indiquant que la vue est en mode simule (pas d'AR
/// native). Utile pour que l'utilisateur comprenne pourquoi il n'y a pas de
/// vraie camera.
class _SimulatedModeBadge extends StatelessWidget {
  const _SimulatedModeBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(120),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.view_in_ar,
            color: Colors.white70,
            size: 12,
          ),
          SizedBox(width: 4),
          Text(
            'Vue 3D (AR simulée)',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
