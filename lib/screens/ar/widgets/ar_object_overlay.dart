// lib/screens/ar/widgets/ar_object_overlay.dart
// Widget de rendu 3D pour les formes geometriques (mode simule).
//
// Ce widget affiche une forme 3D (cylindre, pyramide, cone, sphere, cube,
// prisme) en projection perspective, avec :
//   - Auto-rotation lente (yaw) tant que l'utilisateur ne touche pas l'ecran.
//   - Rotation par drag a 1 doigt (yaw + pitch).
//   - Translation par drag a 2 doigts.
//   - Scale par pincement a 2 doigts (zoom).
//   - Rendu avec ombrage Lambert (normale face × direction lumiere).
//   - Algorithme du peintre (tri des faces par profondeur moyenne).
//
// Implementation : pur Flutter (CustomPainter + GestureDetector), aucun plugin
// AR requis. Lorsque ar_flutter_plugin sera branche (voir README.md), ce widget
// restera utilise en mode simule et sera masque en mode AR natif (la camera AR
// affichera l'objet 3D directement via ARCore/ARKit).
//
// Conventions 3D :
//   - Repere main droite : +x droite, +y haut, +z vers le spectateur.
//   - Yaw = rotation autour de Y ; Pitch = rotation autour de X.
//   - Lumiere directionnelle normalisee, angle constant.

import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../models/ar_object.dart';

// ─── Types internes pour le rendu 3D ────────────────────────────────────────

/// Vertex 3D (x, y, z) en cm. Liste de 3 doubles pour eviter l'import de
/// vector_math (qui n'est pas une dependance directe du projet).
typedef Vec3 = List<double>;

/// Polygone 3D (face de la forme). Contient ses sommets (3+), sa couleur de
/// base, et un drapeau indiquant si c'est une face "tronquee" (cercles
/// approches par polygones — pas de contours noirs sur les bords circulaires).
class _Poly {
  final List<Vec3> vertices;
  final Color baseColor;
  final bool drawEdges;

  _Poly(this.vertices, this.baseColor, {this.drawEdges = true});
}

// ─── Helpers mathematiques 3D ───────────────────────────────────────────────

Vec3 _vec3(double x, double y, double z) => <double>[x, y, z];

/// Rotation autour de l'axe Y (yaw).
Vec3 _rotY(Vec3 v, double angle) {
  final c = math.cos(angle);
  final s = math.sin(angle);
  return <double>[
    c * v[0] + s * v[2],
    v[1],
    -s * v[0] + c * v[2],
  ];
}

/// Rotation autour de l'axe X (pitch).
Vec3 _rotX(Vec3 v, double angle) {
  final c = math.cos(angle);
  final s = math.sin(angle);
  return <double>[
    v[0],
    c * v[1] - s * v[2],
    s * v[1] + c * v[2],
  ];
}

/// Applique yaw puis pitch (ordre : yaw d'abord, puis pitch).
Vec3 _rotate(Vec3 v, double yaw, double pitch) {
  return _rotX(_rotY(v, yaw), pitch);
}

/// Normale d'un polygone (produit vectoriel des 2 premiers edges).
/// Retourne un vecteur unitaire.
Vec3 _faceNormal(List<Vec3> verts) {
  if (verts.length < 3) return _vec3(0, 0, 1);
  final a = verts[0];
  final b = verts[1];
  final c = verts[2];
  final ux = b[0] - a[0];
  final uy = b[1] - a[1];
  final uz = b[2] - a[2];
  final vx = c[0] - a[0];
  final vy = c[1] - a[1];
  final vz = c[2] - a[2];
  final nx = uy * vz - uz * vy;
  final ny = uz * vx - ux * vz;
  final nz = ux * vy - uy * vx;
  final len = math.sqrt(nx * nx + ny * ny + nz * nz);
  if (len < 1e-9) return _vec3(0, 0, 1);
  return <double>[nx / len, ny / len, nz / len];
}

/// Produit scalaire.
double _dot(Vec3 a, Vec3 b) => a[0] * b[0] + a[1] * b[1] + a[2] * b[2];

/// Ombrage Lambert : intensity = max(0, dot(normal, lightDir)).
/// Combinaison ambient + diffuse pour eviter les faces totalement noires.
Color _shade(Color base, Vec3 normal, Vec3 lightDir) {
  final dot = _dot(normal, lightDir);
  final diffuse = math.max(0.0, dot);
  const ambient = 0.35;
  final factor = ambient + (1.0 - ambient) * diffuse;
  return Color.fromARGB(
    base.alpha,
    (base.red * factor).round().clamp(0, 255),
    (base.green * factor).round().clamp(0, 255),
    (base.blue * factor).round().clamp(0, 255),
  );
}

// ─── Constructeurs de formes 3D ─────────────────────────────────────────────

const int _kSegments = 28; // segments pour approximer les cercles.
const int _kLatBands = 14; // bandes de latitude pour la sphere.

/// Genere les polygones d'une forme selon son type et ses dimensions.
List<_Poly> _buildPolygons(ARObject obj) {
  switch (obj.type) {
    case ARShapeType.cube:
      return _buildCube(obj);
    case ARShapeType.pyramide:
      return _buildPyramide(obj);
    case ARShapeType.cylindre:
      return _buildCylindre(obj);
    case ARShapeType.cone:
      return _buildCone(obj);
    case ARShapeType.sphere:
      return _buildSphere(obj);
    case ARShapeType.prisme:
      return _buildPrisme(obj);
  }
}

List<_Poly> _buildCube(ARObject obj) {
  final a = obj.dimensions['cote'] ?? 2.0;
  final h = a / 2;
  final c = obj.color;
  final v = [
    _vec3(-h, -h, -h), // 0 front-bottom-left
    _vec3(h, -h, -h), // 1 front-bottom-right
    _vec3(h, h, -h), // 2 front-top-right
    _vec3(-h, h, -h), // 3 front-top-left
    _vec3(-h, -h, h), // 4 back-bottom-left
    _vec3(h, -h, h), // 5 back-bottom-right
    _vec3(h, h, h), // 6 back-top-right
    _vec3(-h, h, h), // 7 back-top-left
  ];
  return [
    _Poly([v[0], v[1], v[2], v[3]], c), // front (z = -h)
    _Poly([v[5], v[4], v[7], v[6]], c), // back (z = +h)
    _Poly([v[3], v[2], v[6], v[7]], c), // top (y = +h)
    _Poly([v[4], v[5], v[1], v[0]], c), // bottom (y = -h)
    _Poly([v[4], v[0], v[3], v[7]], c), // left (x = -h)
    _Poly([v[1], v[5], v[6], v[2]], c), // right (x = +h)
  ];
}

List<_Poly> _buildPyramide(ARObject obj) {
  final a = obj.dimensions['cote'] ?? 4.0;
  final h = obj.dimensions['h'] ?? 6.0;
  final half = a / 2;
  final halfH = h / 2;
  final c = obj.color;
  final base0 = _vec3(-half, -halfH, -half);
  final base1 = _vec3(half, -halfH, -half);
  final base2 = _vec3(half, -halfH, half);
  final base3 = _vec3(-half, -halfH, half);
  final apex = _vec3(0, halfH, 0);
  return [
    _Poly([base0, base1, apex], c), // front
    _Poly([base1, base2, apex], c), // right
    _Poly([base2, base3, apex], c), // back
    _Poly([base3, base0, apex], c), // left
    _Poly([base0, base3, base2, base1], c), // base (face bas)
  ];
}

List<_Poly> _buildCylindre(ARObject obj) {
  final r = obj.dimensions['r'] ?? 1.5;
  final h = obj.dimensions['h'] ?? 5.0;
  final halfH = h / 2;
  final c = obj.color;
  final polys = <_Poly>[];

  // Anneaux de sommets (top et bottom).
  final top = <Vec3>[];
  final bot = <Vec3>[];
  for (var i = 0; i < _kSegments; i++) {
    final theta = 2 * math.pi * i / _kSegments;
    final x = r * math.cos(theta);
    final z = r * math.sin(theta);
    top.add(_vec3(x, -halfH, z));
    bot.add(_vec3(x, halfH, z));
  }

  // Surface laterale (quads).
  for (var i = 0; i < _kSegments; i++) {
    final j = (i + 1) % _kSegments;
    polys.add(_Poly([top[i], top[j], bot[j], bot[i]], c, drawEdges: false));
  }

  // Couvercle top (eventail depuis le centre).
  final topCenter = _vec3(0, -halfH, 0);
  for (var i = 0; i < _kSegments; i++) {
    final j = (i + 1) % _kSegments;
    polys.add(_Poly([topCenter, top[j], top[i]], c, drawEdges: false));
  }

  // Couvercle bottom.
  final botCenter = _vec3(0, halfH, 0);
  for (var i = 0; i < _kSegments; i++) {
    final j = (i + 1) % _kSegments;
    polys.add(_Poly([botCenter, bot[i], bot[j]], c, drawEdges: false));
  }

  return polys;
}

List<_Poly> _buildCone(ARObject obj) {
  final r = obj.dimensions['r'] ?? 2.0;
  final h = obj.dimensions['h'] ?? 5.0;
  final halfH = h / 2;
  final c = obj.color;
  final polys = <_Poly>[];

  // Anneau de base.
  final base = <Vec3>[];
  for (var i = 0; i < _kSegments; i++) {
    final theta = 2 * math.pi * i / _kSegments;
    base.add(_vec3(r * math.cos(theta), halfH, r * math.sin(theta)));
  }
  final apex = _vec3(0, -halfH, 0);

  // Surface laterale (triangles).
  for (var i = 0; i < _kSegments; i++) {
    final j = (i + 1) % _kSegments;
    polys.add(_Poly([apex, base[i], base[j]], c, drawEdges: false));
  }

  // Base (eventail depuis le centre).
  final baseCenter = _vec3(0, halfH, 0);
  for (var i = 0; i < _kSegments; i++) {
    final j = (i + 1) % _kSegments;
    polys.add(_Poly([baseCenter, base[j], base[i]], c, drawEdges: false));
  }

  return polys;
}

List<_Poly> _buildSphere(ARObject obj) {
  final r = obj.dimensions['r'] ?? 2.5;
  final c = obj.color;
  final polys = <_Poly>[];

  // Grille latitude/longitude.
  final grid = <List<Vec3>>[];
  for (var lat = 0; lat <= _kLatBands; lat++) {
    final theta = math.pi * lat / _kLatBands; // 0 (nord) a pi (sud)
    final sinT = math.sin(theta);
    final cosT = math.cos(theta);
    final row = <Vec3>[];
    for (var lon = 0; lon <= _kSegments; lon++) {
      final phi = 2 * math.pi * lon / _kSegments;
      row.add(_vec3(
        r * cosT * math.cos(phi),
        r * sinT,
        r * cosT * math.sin(phi),
      ));
    }
    grid.add(row);
  }

  // Quads entre bandes adjacentes.
  for (var lat = 0; lat < _kLatBands; lat++) {
    for (var lon = 0; lon < _kSegments; lon++) {
      polys.add(_Poly([
        grid[lat][lon],
        grid[lat][lon + 1],
        grid[lat + 1][lon + 1],
        grid[lat + 1][lon],
      ], c, drawEdges: false));
    }
  }

  return polys;
}

List<_Poly> _buildPrisme(ARObject obj) {
  final a = obj.dimensions['cote'] ?? 2.0;
  final l = obj.dimensions['longueur'] ?? 5.0;
  final halfL = l / 2;
  final c = obj.color;
  // Triangle equilateral de cote a, centre a l'origine.
  // Hauteur du triangle = a * sqrt(3) / 2.
  // Centrons le triangle : sommet en haut, base en bas.
  final triH = a * math.sqrt(3) / 2;
  // Coord y : sommet a +triH/2, base a -triH/2.
  final top = _vec3(0, triH / 2, 0);
  final bl = _vec3(-a / 2, -triH / 2, 0);
  final br = _vec3(a / 2, -triH / 2, 0);

  // Faces avant (z = -halfL) et arriere (z = +halfL).
  final front = [top, bl, br].map((v) => _vec3(v[0], v[1], -halfL)).toList();
  final back = [top, br, bl].map((v) => _vec3(v[0], v[1], halfL)).toList();

  return [
    _Poly(front, c), // base avant
    _Poly(back, c), // base arriere (sens inverse pour normale exterieure)
    _Poly([front[0], back[0], back[1], front[1]], c), // face superieure (top-bl)
    _Poly([front[1], back[1], back[2], front[2]], c), // face inferieure (bl-br)
    _Poly([front[2], back[2], back[0], front[0]], c), // face droite (br-top)
  ];
}

// ─── CustomPainter 3D ───────────────────────────────────────────────────────

class _Ar3DPainter extends CustomPainter {
  final List<_Poly> polygons;
  final double yaw;
  final double pitch;
  final double scale;
  final Offset translation;
  final Color baseColor;

  /// Direction de la lumiere (normalisee). Lumiere venant du haut-droit-devant.
  /// Vecteur (0.5, 0.8, 0.6) normalise : longueur = sqrt(0.25+0.64+0.36) = sqrt(1.25) ~ 1.118.
  /// Pre-calcule pour eviter tout probleme d'ordre d'initialisation des champs static.
  static final Vec3 _lightDir = <double>[0.4472, 0.7155, 0.5367];

  _Ar3DPainter({
    required this.polygons,
    required this.yaw,
    required this.pitch,
    required this.scale,
    required this.translation,
    required this.baseColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2) + translation;
    const fov = 4.0; // distance focale (en unites cm)

    // Calcule les polygones rototes + leur z moyen pour le tri.
    final rotated = <_ProjectedPoly>[];
    for (final poly in polygons) {
      final rotatedVerts = poly.vertices
          .map((v) => _rotate(v, yaw, pitch))
          .toList();
      final avgZ = rotatedVerts
              .map((v) => v[2])
              .reduce((a, b) => a + b) /
          rotatedVerts.length;
      // Projette en 2D.
      final screenPoints = rotatedVerts
          .map((v) => _project(v, fov, center, scale * 30.0))
          .toList();
      // Normale rotote pour l'ombrage.
      final normal = _faceNormal(rotatedVerts);
      final color = _shade(poly.baseColor, normal, _lightDir);
      rotated.add(_ProjectedPoly(screenPoints, avgZ, color, poly.drawEdges));
    }

    // Tri : z le plus grand = le plus proche = dessine en dernier.
    rotated.sort((a, b) => a.avgZ.compareTo(b.avgZ));

    // Dessine chaque polygone.
    for (final p in rotated) {
      final path = Path()..moveTo(p.points[0].dx, p.points[0].dy);
      for (var i = 1; i < p.points.length; i++) {
        path.lineTo(p.points[i].dx, p.points[i].dy);
      }
      path.close();

      canvas.drawPath(
        path,
        Paint()
          ..color = p.color
          ..style = PaintingStyle.fill,
      );

      if (p.drawEdges) {
        // Contours discrets pour les faces planes (cube, pyramide, prisme).
        // Sur les surfaces courbes (cylindre, cone, sphere), pas de contours
        // pour eviter l'effet "facette" visible.
        canvas.drawPath(
          path,
          Paint()
            ..color = Colors.black.withAlpha(120)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0,
        );
      }
    }
  }

  /// Projection perspective : (x, y, z) -> Offset sur le canvas.
  /// Le facteur d'echelle applique une conversion cm -> px.
  Offset _project(Vec3 v, double fov, Offset center, double pxPerCm) {
    // Camera a z = -fov, regardant vers +z. On decale le point de fov+3 pour
    // garantir z > 0 (formes centrees a l'origine, taille < 10 cm).
    final z = v[2] + fov + 6.0;
    final factor = fov / z;
    return Offset(
      center.dx + v[0] * factor * pxPerCm,
      center.dy - v[1] * factor * pxPerCm, // y inverse (canvas y vers le bas)
    );
  }

  @override
  bool shouldRepaint(covariant _Ar3DPainter old) {
    return old.yaw != yaw ||
        old.pitch != pitch ||
        old.scale != scale ||
        old.translation != translation ||
        old.baseColor != baseColor ||
        !identical(old.polygons, polygons);
  }
}

/// Polygone projete en 2D, pret a dessiner.
class _ProjectedPoly {
  final List<Offset> points;
  final double avgZ;
  final Color color;
  final bool drawEdges;

  _ProjectedPoly(this.points, this.avgZ, this.color, this.drawEdges);
}

// ─── Widget public : ArObjectOverlay ────────────────────────────────────────

/// Widget affichant une forme 3D manipulable (rotation, scale, translation).
///
/// En mode AR natif, ce widget est masque et l'objet 3D est rendu par
/// ARCore/ARKit. En mode simule (par defaut), ce widget est le rendu principal.
class ArObjectOverlay extends StatefulWidget {
  final ARObject object;

  /// Vrai si l'auto-rotation est activee (defaut : true).
  final bool autoRotate;

  /// Signal de reinitialisation : quand cette valeur change, l'overlay
  /// reinitialise sa rotation / scale / translation. Le parent l'incremente
  /// a chaque appui sur le bouton "Reset".
  final int resetSignal;

  /// Callback appele quand l'utilisateur demarre une interaction
  /// (utile pour masquer les instructions).
  final VoidCallback? onInteractionStart;

  const ArObjectOverlay({
    super.key,
    required this.object,
    this.autoRotate = true,
    this.resetSignal = 0,
    this.onInteractionStart,
  });

  @override
  State<ArObjectOverlay> createState() => _ArObjectOverlayState();
}

class _ArObjectOverlayState extends State<ArObjectOverlay>
    with SingleTickerProviderStateMixin {
  // Etat de manipulation 3D.
  double _yaw = 0.5; // rotation horizontale initiale (3/4 vue)
  double _pitch = -0.3; // legerement vu du dessus
  double _scale = 1.0;
  Offset _translation = Offset.zero;

  // Etat des gestures.
  Offset _lastFocalPoint = Offset.zero;
  double _lastScale = 1.0;
  bool _userInteracting = false;

  // Auto-rotation.
  late final AnimationController _autoRotateController;
  List<_Poly>? _cachedPolygons;

  @override
  void initState() {
    super.initState();
    _autoRotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..addListener(() {
        if (!_userInteracting && widget.autoRotate) {
          setState(() {
            _yaw += 0.004; // vitesse de rotation lente (~0.23°/frame)
          });
        }
      });
    _autoRotateController.repeat();
  }

  @override
  void didUpdateWidget(covariant ArObjectOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.object.type != widget.object.type ||
        oldWidget.object.dimensions != widget.object.dimensions) {
      _cachedPolygons = null; // force le recalcul des polygones.
    }
    // Detection d'un signal de reinitialisation.
    if (oldWidget.resetSignal != widget.resetSignal) {
      reset();
    }
  }

  @override
  void dispose() {
    _autoRotateController.dispose();
    super.dispose();
  }

  List<_Poly> _getPolygons() {
    return _cachedPolygons ??= _buildPolygons(widget.object);
  }

  void _onScaleStart(ScaleStartDetails details) {
    _lastFocalPoint = details.focalPoint;
    _lastScale = _scale;
    _userInteracting = true;
    widget.onInteractionStart?.call();
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      if (details.pointerCount == 1) {
        // 1 doigt = rotation.
        final dx = details.focalPoint.dx - _lastFocalPoint.dx;
        final dy = details.focalPoint.dy - _lastFocalPoint.dy;
        _yaw += dx * 0.01;
        _pitch += dy * 0.01;
        // Limit pitch to avoid flipping.
        _pitch = _pitch.clamp(-1.4, 1.4);
      } else {
        // 2 doigts = translation.
        _translation += details.focalPoint - _lastFocalPoint;
      }
      // Scale (pincement, 1 ou 2 doigts).
      if ((details.scale - 1.0).abs() > 0.001) {
        _scale = (_lastScale * details.scale).clamp(0.3, 3.0);
      }
      _lastFocalPoint = details.focalPoint;
    });
  }

  void _onScaleEnd(ScaleEndDetails details) {
    _userInteracting = false;
  }

  /// Reinitialise la position / rotation / scale de l'objet.
  void reset() {
    setState(() {
      _yaw = 0.5;
      _pitch = -0.3;
      _scale = 1.0;
      _translation = Offset.zero;
      _userInteracting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onScaleStart: _onScaleStart,
      onScaleUpdate: _onScaleUpdate,
      onScaleEnd: _onScaleEnd,
      child: SizedBox.expand(
        child: ClipRect(
          child: CustomPaint(
            painter: _Ar3DPainter(
              polygons: _getPolygons(),
              yaw: _yaw,
              pitch: _pitch,
              scale: _scale,
              translation: _translation,
              baseColor: widget.object.color,
            ),
          ),
        ),
      ),
    );
  }
}
