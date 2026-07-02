// lib/widgets/figures/figures_library.dart
// Bibliothèque de figures SVG prédéfinies pour les questions de géométrie.
//
// Chaque figure est identifiée par une clé (figureId) et livrée sous forme de
// chaîne SVG inline. Le rendu est assuré par `SvgFigure` (flutter_svg 2.x).
//
// Palette : vert Togo #006837 + orange #D97700 + neutres (#1A1A1A texte,
// #757575 texte secondaire, #9E9E9E axes). Toutes les chaînes SVG :
//   - possèdent un viewBox explicite,
//   - utilisent xmlns="http://www.w3.org/2000/svg",
//   - n'utilisent que des éléments supportés par flutter_svg 2.x
//     (svg, g, polygon, line, rect, circle, ellipse, path, text, line, polyline).
//
// Convention d'orientation : les sommets A, B, C... sont placés près du sommet
// géométrique correspondant (et non au milieu du dessin), pour éviter toute
// ambiguïté lors de la lecture de l'énoncé.

/// Bibliothèque centrale des figures SVG d'ExamBoost Togo.
///
/// Usage :
/// ```dart
/// final svg = FiguresLibrary.getFigure('triangle_rectangle_3_4_5');
/// if (svg != null) {
///   SvgPicture.string(svg, width: 200, height: 200);
/// }
/// ```
///
/// Ou plus simplement via le widget [SvgFigure] :
/// ```dart
/// SvgFigure(figureId: 'triangle_rectangle_3_4_5', width: 220);
/// ```
class FiguresLibrary {
  FiguresLibrary._(); // constructeur privé — classe utilitaire statique

  /// Retourne le SVG string pour une figure donnée, ou `null` si l'identifiant
  /// n'est pas reconnu.
  static String? getFigure(String figureId) {
    return _figures[figureId];
  }

  /// Liste toutes les figures disponibles (clés triées par ordre d'insertion).
  static List<String> get availableFigures => _figures.keys.toList();

  /// Nombre total de figures disponibles.
  static int get count => _figures.length;

  /// Vrai si la figure existe dans la bibliothèque.
  static bool exists(String figureId) => _figures.containsKey(figureId);

  /// Catalogue des figures SVG.
  ///
  /// Pour ajouter une nouvelle figure :
  /// 1. Choisir une clé en snake_case explicite (ex: `losange_diag_5_8`).
  /// 2. Dessiner le SVG (viewBox 0 0 W H, xmlns requis).
  /// 3. Vérifier la cohérence sommet/label (un label `A` doit être collé au
  ///    sommet A, pas au milieu du dessin).
  /// 4. Tester via `SvgFigure(figureId: '...')`.
  static const Map<String, String> _figures = {
    // ─── 1. Triangle rectangle 3-4-5 (Pythagore) ───────────────────────
    // ABC rectangle en A. A=(20,180) bas-gauche, B=(180,180) bas-droit,
    // C=(20,60) haut-gauche. AB=4 cm (160 u), AC=3 cm (120 u), BC=5 cm.
    'triangle_rectangle_3_4_5': '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 210 210">
<polygon points="20,180 180,180 20,60" fill="none" stroke="#006837" stroke-width="2"/>
<rect x="20" y="160" width="20" height="20" fill="none" stroke="#006837" stroke-width="1.5"/>
<text x="14" y="198" font-size="14" text-anchor="end" fill="#1A1A1A" font-weight="bold">A</text>
<text x="190" y="198" font-size="14" fill="#1A1A1A" font-weight="bold">B</text>
<text x="14" y="55" font-size="14" text-anchor="end" fill="#1A1A1A" font-weight="bold">C</text>
<text x="100" y="200" font-size="13" text-anchor="middle" fill="#1A1A1A">AB = 4 cm</text>
<text x="38" y="125" font-size="13" fill="#1A1A1A" transform="rotate(-90, 38, 125)">AC = 3 cm</text>
<text x="105" y="115" font-size="13" fill="#D97700" font-weight="bold" transform="rotate(-37, 105, 115)">BC = 5 cm (hypoténuse)</text>
</svg>''',

    // ─── 2. Cercle de rayon 5 cm ───────────────────────────────────────
    'cercle_rayon_5': '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200">
<circle cx="100" cy="100" r="80" fill="none" stroke="#006837" stroke-width="2"/>
<line x1="100" y1="100" x2="180" y2="100" stroke="#D97700" stroke-width="2" stroke-dasharray="5,3"/>
<text x="140" y="92" font-size="14" fill="#D97700" font-weight="bold">r = 5 cm</text>
<circle cx="100" cy="100" r="2.5" fill="#006837"/>
<text x="92" y="118" font-size="14" fill="#1A1A1A" font-weight="bold">O</text>
</svg>''',

    // ─── 3. Triangle avec Thalès (DE) // (AB) ──────────────────────────
    // C=(100,30), A=(20,180), B=(220,180). D milieu de CA = (60,105),
    // E milieu de CB = (160,105). CD/CA = 1/2 → DE = AB / 2.
    'thales_triangle': '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 250 210">
<polygon points="20,180 220,180 100,30" fill="none" stroke="#006837" stroke-width="2"/>
<line x1="60" y1="105" x2="160" y2="105" stroke="#D97700" stroke-width="2"/>
<text x="10" y="198" font-size="13" text-anchor="end" fill="#1A1A1A" font-weight="bold">A</text>
<text x="228" y="198" font-size="13" fill="#1A1A1A" font-weight="bold">B</text>
<text x="95" y="22" font-size="13" fill="#1A1A1A" font-weight="bold">C</text>
<text x="52" y="100" font-size="13" text-anchor="end" fill="#1A1A1A" font-weight="bold">D</text>
<text x="168" y="100" font-size="13" fill="#1A1A1A" font-weight="bold">E</text>
<text x="125" y="175" font-size="11" fill="#757575" font-style="italic">(DE) // (AB)</text>
</svg>''',

    // ─── 4. Parabole y = x² dans un repère ─────────────────────────────
    // Origine O=(150,100). Échelle : 50 u = 1 unité math en x, 17.5 u = 1 en y.
    // Courbe passe par (50,30), (150,100), (250,30) — vertex au point O.
    'fonction_parabole': '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 300 200">
<line x1="0" y1="100" x2="300" y2="100" stroke="#9E9E9E" stroke-width="1"/>
<line x1="150" y1="0" x2="150" y2="200" stroke="#9E9E9E" stroke-width="1"/>
<path d="M 50,30 Q 150,170 250,30" fill="none" stroke="#006837" stroke-width="2.5"/>
<text x="288" y="95" font-size="12" fill="#757575">x</text>
<text x="156" y="14" font-size="12" fill="#757575">y</text>
<text x="138" y="116" font-size="11" fill="#757575">O</text>
<text x="200" y="55" font-size="14" fill="#D97700" font-weight="bold" font-style="italic">y = x²</text>
</svg>''',

    // ─── 5. Cylindre droit (3D) ────────────────────────────────────────
    // r = 3 cm, h = 10 cm. Base = ellipse, parois verticales, fond moitié
    // visible moitié pointillée (effet 3D filaire).
    'cylindre_3d': '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 250">
<ellipse cx="100" cy="50" rx="60" ry="15" fill="#E8F5ED" stroke="#006837" stroke-width="2"/>
<line x1="40" y1="50" x2="40" y2="200" stroke="#006837" stroke-width="2"/>
<line x1="160" y1="50" x2="160" y2="200" stroke="#006837" stroke-width="2"/>
<path d="M 40,200 A 60,15 0 0 0 160,200" fill="#E8F5ED" stroke="#006837" stroke-width="2"/>
<path d="M 40,200 A 60,15 0 0 1 160,200" fill="none" stroke="#006837" stroke-width="1.5" stroke-dasharray="4,3"/>
<line x1="160" y1="50" x2="160" y2="200" stroke="#D97700" stroke-width="2" stroke-dasharray="4,3"/>
<text x="168" y="130" font-size="13" fill="#D97700" font-weight="bold">h = 10 cm</text>
<line x1="100" y1="50" x2="100" y2="200" stroke="#006837" stroke-width="1" stroke-dasharray="2,3"/>
<text x="60" y="225" font-size="13" fill="#1A1A1A">r = 3 cm</text>
</svg>''',

    // ─── 6. Pyramide à base carrée (3D) ────────────────────────────────
    // Base carrée 6 cm, sommet S au-dessus du centre, hauteur h.
    'pyramide': '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 220 260">
<polygon points="110,40 30,200 190,200" fill="#E8F5ED" stroke="#006837" stroke-width="2"/>
<polygon points="110,200 30,200 110,40" fill="none" stroke="#006837" stroke-width="2"/>
<path d="M 30,200 L 70,225 L 150,225 L 190,200" fill="none" stroke="#006837" stroke-width="1.5" stroke-dasharray="4,3"/>
<line x1="70" y1="225" x2="150" y2="225" stroke="#006837" stroke-width="2"/>
<line x1="110" y1="40" x2="110" y2="225" stroke="#D97700" stroke-width="1.5" stroke-dasharray="3,3"/>
<text x="116" y="135" font-size="13" fill="#D97700" font-weight="bold">h</text>
<text x="60" y="245" font-size="12" fill="#1A1A1A">base carrée = 6 cm</text>
<text x="105" y="32" font-size="13" fill="#1A1A1A" font-weight="bold">S</text>
</svg>''',

    // ─── 7. Angle inscrit dans un cercle ───────────────────────────────
    // Cercle de centre O. Arc AB en orange. M point d'angle inscrit.
    // L'angle AMB intercepte l'arc AB (moitié de l'angle central AOB).
    'angle_inscrit': '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 240 220">
<circle cx="120" cy="110" r="80" fill="none" stroke="#006837" stroke-width="2"/>
<path d="M 63,165 A 80,80 0 0 1 177,165" fill="none" stroke="#D97700" stroke-width="3"/>
<line x1="120" y1="110" x2="63" y2="165" stroke="#006837" stroke-width="1.5"/>
<line x1="120" y1="110" x2="177" y2="165" stroke="#006837" stroke-width="1.5"/>
<line x1="40" y1="200" x2="63" y2="165" stroke="#006837" stroke-width="2"/>
<line x1="40" y1="200" x2="177" y2="165" stroke="#006837" stroke-width="2"/>
<circle cx="40" cy="200" r="2.5" fill="#006837"/>
<circle cx="120" cy="110" r="2.5" fill="#006837"/>
<text x="113" y="125" font-size="14" fill="#1A1A1A" font-weight="bold">O</text>
<text x="52" y="178" font-size="14" fill="#1A1A1A" font-weight="bold">A</text>
<text x="180" y="178" font-size="14" fill="#1A1A1A" font-weight="bold">B</text>
<text x="25" y="215" font-size="14" fill="#1A1A1A" font-weight="bold">M</text>
<text x="100" y="160" font-size="11" fill="#D97700" font-style="italic">arc AB</text>
</svg>''',

    // ─── 8. Triangle quelconque (3 côtés) ──────────────────────────────
    'triangle_quelconque': '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200">
<polygon points="30,170 170,150 90,30" fill="none" stroke="#006837" stroke-width="2"/>
<text x="14" y="185" font-size="14" fill="#1A1A1A" font-weight="bold">A</text>
<text x="175" y="165" font-size="14" fill="#1A1A1A" font-weight="bold">B</text>
<text x="85" y="22" font-size="14" fill="#1A1A1A" font-weight="bold">C</text>
<text x="92" y="170" font-size="12" fill="#1A1A1A">7 cm</text>
<text x="138" y="92" font-size="12" fill="#1A1A1A" transform="rotate(-58, 138, 92)">5 cm</text>
<text x="35" y="98" font-size="12" fill="#1A1A1A" transform="rotate(76, 35, 98)">6 cm</text>
</svg>''',

    // ─── 9. Parallélogramme ABCD ───────────────────────────────────────
    // AB = 8 cm (base), la hauteur relative à AB = 5 cm.
    'parallelogramme': '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 220 200">
<polygon points="50,150 170,150 140,50 20,50" fill="none" stroke="#006837" stroke-width="2"/>
<line x1="50" y1="150" x2="50" y2="50" stroke="#D97700" stroke-width="1.5" stroke-dasharray="4,3"/>
<text x="14" y="46" font-size="14" fill="#1A1A1A" font-weight="bold">A</text>
<text x="144" y="46" font-size="14" fill="#1A1A1A" font-weight="bold">B</text>
<text x="175" y="165" font-size="14" fill="#1A1A1A" font-weight="bold">C</text>
<text x="38" y="165" font-size="14" fill="#1A1A1A" font-weight="bold">D</text>
<text x="105" y="172" font-size="12" fill="#1A1A1A">AB = 8 cm (base)</text>
<text x="36" y="105" font-size="12" fill="#D97700" font-weight="bold" transform="rotate(-90, 36, 105)">h = 5 cm</text>
</svg>''',

    // ─── 10. Trapèze ABCD (grande base DC, petite base AB) ─────────────
    'trapeze': '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 250 200">
<polygon points="80,150 180,150 220,50 30,50" fill="none" stroke="#006837" stroke-width="2"/>
<line x1="80" y1="150" x2="80" y2="50" stroke="#D97700" stroke-width="1.5" stroke-dasharray="4,3"/>
<text x="20" y="46" font-size="14" fill="#1A1A1A" font-weight="bold">A</text>
<text x="225" y="46" font-size="14" fill="#1A1A1A" font-weight="bold">B</text>
<text x="185" y="165" font-size="14" fill="#1A1A1A" font-weight="bold">C</text>
<text x="65" y="165" font-size="14" fill="#1A1A1A" font-weight="bold">D</text>
<text x="130" y="172" font-size="12" fill="#1A1A1A">DC = 10 cm (grande base)</text>
<text x="125" y="42" font-size="12" fill="#1A1A1A" text-anchor="middle">AB = 6 cm (petite base)</text>
<text x="66" y="105" font-size="12" fill="#D97700" font-weight="bold" transform="rotate(-90, 66, 105)">h = 4 cm</text>
</svg>''',

    // ─── 11. Courbes sinus (vert) et cosinus (orange pointillé) ────────
    'sinus_cosinus': '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 200">
<line x1="0" y1="100" x2="400" y2="100" stroke="#9E9E9E" stroke-width="1"/>
<line x1="200" y1="10" x2="200" y2="190" stroke="#9E9E9E" stroke-width="1"/>
<path d="M 0,100 Q 50,10 100,100 T 200,100 T 300,100 T 400,100" fill="none" stroke="#006837" stroke-width="2"/>
<path d="M 0,100 Q 50,190 100,100 T 200,100 T 300,100 T 400,100" fill="none" stroke="#D97700" stroke-width="2" stroke-dasharray="5,3"/>
<text x="388" y="95" font-size="12" fill="#757575">x</text>
<text x="206" y="18" font-size="12" fill="#757575">y</text>
<text x="55" y="180" font-size="12" fill="#006837" font-weight="bold">sin(x)</text>
<text x="305" y="35" font-size="12" fill="#D97700" font-weight="bold">cos(x)</text>
</svg>''',

    // ─── 12. Histogramme (stats — effectifs par classe) ────────────────
    // 5 classes : [10;20[ [20;30[ [30;40[ [40;50[ [50;60[.
    // La classe [30;40[ est la classe modale (en orange).
    'histogramme_stats': '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 320 210">
<line x1="30" y1="170" x2="290" y2="170" stroke="#9E9E9E" stroke-width="1"/>
<line x1="30" y1="20" x2="30" y2="170" stroke="#9E9E9E" stroke-width="1"/>
<rect x="45" y="120" width="35" height="50" fill="#006837"/>
<rect x="90" y="80" width="35" height="90" fill="#006837"/>
<rect x="135" y="50" width="35" height="120" fill="#D97700"/>
<rect x="180" y="70" width="35" height="100" fill="#006837"/>
<rect x="225" y="100" width="35" height="70" fill="#006837"/>
<text x="62" y="185" font-size="10" text-anchor="middle" fill="#1A1A1A">[10;20[</text>
<text x="107" y="185" font-size="10" text-anchor="middle" fill="#1A1A1A">[20;30[</text>
<text x="152" y="185" font-size="10" text-anchor="middle" fill="#D97700" font-weight="bold">[30;40[</text>
<text x="197" y="185" font-size="10" text-anchor="middle" fill="#1A1A1A">[40;50[</text>
<text x="242" y="185" font-size="10" text-anchor="middle" fill="#1A1A1A">[50;60[</text>
<text x="15" y="100" font-size="10" fill="#757575" transform="rotate(-90, 15, 100)">Effectifs</text>
</svg>''',

    // ─── 13. Cercle trigonométrique (angle α = π/3 = 60°) ──────────────
    // M est sur le cercle à l'angle α = 60°, donc M = (100 + 70·cos60, 100 - 70·sin60)
    //   = (135, 39.4) ≈ (135, 40). cos(α) = projection sur Ox, sin(α) = projection sur Oy.
    'cercle_trigonometrique': '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200">
<circle cx="100" cy="100" r="70" fill="none" stroke="#006837" stroke-width="2"/>
<line x1="20" y1="100" x2="180" y2="100" stroke="#9E9E9E" stroke-width="1"/>
<line x1="100" y1="20" x2="100" y2="180" stroke="#9E9E9E" stroke-width="1"/>
<line x1="100" y1="100" x2="135" y2="40" stroke="#D97700" stroke-width="2.5"/>
<line x1="135" y1="40" x2="135" y2="100" stroke="#D97700" stroke-width="1.5" stroke-dasharray="3,3"/>
<line x1="100" y1="100" x2="135" y2="100" stroke="#D97700" stroke-width="1.5" stroke-dasharray="3,3"/>
<circle cx="135" cy="40" r="3" fill="#D97700"/>
<circle cx="100" cy="100" r="2.5" fill="#006837"/>
<text x="142" y="35" font-size="14" fill="#D97700" font-weight="bold">M</text>
<text x="92" y="118" font-size="12" fill="#1A1A1A" font-weight="bold">O</text>
<text x="113" y="115" font-size="11" fill="#757575">cos(α)</text>
<text x="140" y="75" font-size="11" fill="#757575" transform="rotate(90, 140, 75)">sin(α)</text>
<text x="117" y="93" font-size="11" fill="#1A1A1A" font-style="italic">α</text>
</svg>''',

    // ─── 14. Repère orthonormé avec 3 points ───────────────────────────
    // A(3 ; 2), B(-2 ; -2), C(4 ; 1). Origine au centre (125, 100).
    'systeme_axes': '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 250 200">
<line x1="20" y1="100" x2="230" y2="100" stroke="#9E9E9E" stroke-width="1"/>
<line x1="125" y1="20" x2="125" y2="180" stroke="#9E9E9E" stroke-width="1"/>
<circle cx="175" cy="50" r="4" fill="#D97700"/>
<circle cx="75" cy="150" r="4" fill="#D97700"/>
<circle cx="200" cy="75" r="4" fill="#D97700"/>
<text x="183" y="46" font-size="12" fill="#1A1A1A" font-weight="bold">A(3 ; 2)</text>
<text x="20" y="156" font-size="12" fill="#1A1A1A" font-weight="bold">B(-2 ; -2)</text>
<text x="208" y="70" font-size="12" fill="#1A1A1A" font-weight="bold">C(4 ; 1)</text>
<text x="238" y="95" font-size="11" fill="#757575">x</text>
<text x="130" y="16" font-size="11" fill="#757575">y</text>
<text x="115" y="115" font-size="11" fill="#757575">O</text>
</svg>''',

    // ─── 15. Losange (diagonales 6 cm et 8 cm) ─────────────────────────
    // Aire = (d1 × d2) / 2 = (6 × 8) / 2 = 24 cm². Côté = 5 cm (Pythagore).
    'losange': '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 220 200">
<polygon points="110,30 190,100 110,170 30,100" fill="none" stroke="#006837" stroke-width="2"/>
<line x1="110" y1="30" x2="110" y2="170" stroke="#D97700" stroke-width="1.5" stroke-dasharray="4,3"/>
<line x1="30" y1="100" x2="190" y2="100" stroke="#D97700" stroke-width="1.5" stroke-dasharray="4,3"/>
<text x="115" y="22" font-size="14" fill="#1A1A1A" font-weight="bold">A</text>
<text x="195" y="105" font-size="14" fill="#1A1A1A" font-weight="bold">B</text>
<text x="115" y="185" font-size="14" fill="#1A1A1A" font-weight="bold">C</text>
<text x="18" y="105" font-size="14" text-anchor="end" fill="#1A1A1A" font-weight="bold">D</text>
<text x="120" y="105" font-size="12" fill="#D97700" font-weight="bold">d₁ = 8 cm</text>
<text x="115" y="195" font-size="12" fill="#D97700" font-weight="bold" text-anchor="middle">d₂ = 6 cm</text>
</svg>''',
  };
}
