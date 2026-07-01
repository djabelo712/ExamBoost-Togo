# Storyboard détaillé — Pythagore (Q01)

## Métadonnées
- **Video ID** : q01_pythagore
- **Script associé** : `scripts/q01_pythagore_script.md`
- **Question ID** : TG-BEPC-MATHS-2023-Q01
- **Durée totale** : 30,0 s
- **Format** : 1280×720 (16:9), 30 fps
- **Style visuel** : tableau vert #006837 + traits noirs sur fond blanc, animations Manim-style
- **Référence visuelle** : chaînes YouTube "Yvan Monka" et "Lumni"

## Palette de couleurs (rappel)
| Couleur | Hex | Usage |
|---|---|---|
| Vert Togo | #006837 | Fond plans 1/8, traits figures |
| Orange Togo | #D97700 | Valeurs numériques, accents |
| Blanc | #FFFFFF | Fond plans 2-7 |
| Noir | #000000 | Texte principal |
| Gris clair | #F5F5F5 | Encadrés de formules |
| Rouge alerte | #C62828 | (réservé aux erreurs — non utilisé ici) |

## Typographies
- **Outfit** (Google Fonts) : titres et résultats finaux, 28-48 px
- **Times New Roman** : formules mathématiques générales, 24-28 px
- **Patrick Hand** (Google Fonts) : calculs manuscrits effet tableau noir, 26-28 px

## Asset list globale
- `logo_examboost_white.svg` (déjà dans `assets/branding/`)
- `qrcode_examboost_tg.svg` (à créer, pointe vers https://examboost.tg/app)
- `jingle_debut.mp3` (0,5 s, à récupérer sur Pixabay Music)
- `ding.mp3` (effet pop/notification, 0,2 s)
- `craie.mp3` (effet écriture tableau, 0,3 s)
- `pop.mp3` (effet apparition, 0,15 s)
- `jingle_fin.mp3` (0,5 s, même timbre que jingle début mais tonique)

---

## Plan 1 — Logo + Titre (0:00 → 0:03, 3,0 s)

### Composition
- Plein écran : fond vert Togo #006837
- Au centre vertical, empilé :
  1. Logo ExamBoost blanc (80×80 px)
  2. Espace 12 px
  3. Titre "Pythagore" Outfit 32 px gras blanc
  4. Espace 4 px
  5. Sous-titre "Théorème — BEPC" Outfit 14 px blanc opacité 60 %

### Animation
- 0,00-0,30 s : fade-in global (tous les éléments ensemble)
- 0,30-0,80 s : zoom lent 0,95× → 1,00× (effet de "respiration")
- 0,80-2,70 s : maintien statique (lecture du titre)
- 2,70-3,00 s : fade-out + slide-up 30 px (transition vers plan 2)

### Audio
- 0,00-0,50 s : jingle_debut.mp3 (mixé à -6 dBFS)
- 0,50-3,00 s : silence

### Lower-third / Branding
- Petit logo ExamBoost 24×24 px en bas à droite pendant toute la vidéo (overlay permanent à partir du plan 2)
- Mention "ExamBoost Togo" en Outfit 10 px blanc 40 % à côté du logo

---

## Plan 2 — Triangle ABC (0:03 → 0:07, 4,0 s)

### Composition
- Fond blanc #FFFFFF
- Triangle ABC rectangle en A, centré, dimension ~400×300 px
- A en bas-gauche (angle droit), B en haut-gauche, C en bas-droite
- Côtés : AB vertical (gauche), AC horizontal (bas), BC hypoténuse (diagonale haut-droite)
- Traits verts #006837 épaisseur 2 px (style tableau)
- Petit carré noir 6×6 px à l'angle droit A
- Étiquettes des sommets en Outfit 16 px gras noir : A, B, C
- Légendes des côtés :
  - "AB = 6" à gauche du segment AB (Outfit 18 px noir)
  - "AC = 8" en dessous du segment AC (Outfit 18 px noir)
  - "BC = ?" à droite de l'hypoténuse (Outfit 18 px italique orange #D97700)

### Animation
- 0,00-1,00 s : tracé progressif du triangle sommet par sommet (effet "stylo qui dessine") :
  - 0,00-0,33 s : tracé segment AB (de A vers B)
  - 0,33-0,67 s : tracé segment AC (de A vers C)
  - 0,67-1,00 s : tracé segment BC (de B vers C)
- 1,00-1,30 s : apparition des étiquettes A, B, C + petit carré angle droit
- 1,30-2,00 s : apparition des légendes "AB = 6", "AC = 8", "BC = ?" (fondu individuel, 0,2 s de décalage)
- 2,00-4,00 s : maintien statique (voix off parle)

### Audio
- 0,00-4,00 s : voix off "Pour calculer l'hypoténuse d'un triangle rectangle..."
- Pas de SFX (la voix porte)

### Transitions
- Plan 1 → 2 : fade-out blanc (le vert s'estompe vers blanc)

---

## Plan 3 — Formule (0:07 → 0:12, 5,0 s)

### Composition
- Fond blanc
- Le triangle (plan 2) se réduit à gauche, occupant 50 % de l'écran (gauche)
- À droite (50 % écran) : encadré gris clair #F5F5F5 avec coins arrondis 8 px, padding 24 px
- Dans l'encadré : formule "BC² = AB² + AC²" en Times New Roman 28 px gras noir
- Le "²" en exposant, taille 60 %, surélevé de 8 px
- Surlignage orange #D97700 léger derrière "AB² + AC²" (effet surligneur)

### Animation
- 0,00-0,50 s : le triangle se redimensionne (scale 1,0× → 0,7×) et se décale vers la gauche
- 0,50-0,80 s : l'encadré apparaît en fondu
- 0,80-1,30 s : "BC²" apparaît (fondu + slide-up)
- 1,30-1,60 s : "=" apparaît
- 1,60-2,20 s : "AB²" apparaît
- 2,20-2,50 s : "+" apparaît
- 2,50-3,00 s : "AC²" apparaît
- 3,00-5,00 s : maintien statique, voix off détaille

### Audio
- 0,50 s : SFX ding.mp3 à l'apparition de la formule (-12 dBFS)
- 0,00-5,00 s : voix off "...on utilise Pythagore. BC² = AB² + AC²."

### Implementation Manim (snippet)
```python
from manim import *

class Pythagore(Scene):
    def construct(self):
        formule = MathTex(r"BC^2 = AB^2 + AC^2", font_size=48)
        formule.set_color_by_tex("BC^2", WHITE)
        self.play(Write(formule[:1]))  # BC²
        self.wait(0.3)
        self.play(Write(formule[1:2]))  # =
        self.wait(0.3)
        self.play(Write(formule[2:3]))  # AB²
        self.wait(0.3)
        self.play(Write(formule[3:4]))  # +
        self.wait(0.3)
        self.play(Write(formule[4:5]))  # AC²
```

---

## Plan 4 — Valeurs sur le triangle (0:12 → 0:16, 4,0 s)

### Composition
- Le triangle (à gauche) grossit légèrement (scale 0,7× → 1,1×)
- Les légendes "AB = 6" et "AC = 8" se mettent en orange gras (transitions de couleur)
- L'encadré de formule à droite reste visible mais opacité 50 %
- Ajout d'une flèche courbe reliant chaque valeur à sa position dans la formule

### Animation
- 0,00-0,30 s : zoom du triangle (scale 0,7× → 1,1×)
- 0,30-0,60 s : "AB = 6" passe en orange #D97700 (color animation)
- 0,60-0,90 s : "AC = 8" passe en orange
- 0,90-1,50 s : flèches courbes se dessinent depuis le triangle vers l'encadré de formule ( reliant visuellement valeur réelle ↔ variable)
- 1,50-4,00 s : maintien

### Audio
- 0,00-4,00 s : voix off "Ici, AB = 6, AC = 8."
- Pas de SFX (focus sur la voix)

---

## Plan 5 — Calcul 6² + 8² (0:16 → 0:21, 5,0 s)

### Composition
- Le triangle se réduit encore (scale 1,1× → 0,4×), se décale en haut-gauche
- En grand au centre-droite, succession de 3 lignes en cascade (police Patrick Hand 28 px) :
  - Ligne 1 : "6² + 8²"
  - Ligne 2 : "= 36 + 64"
  - Ligne 3 : "= 100" (en orange gras, plus gros 32 px)
- Effet visuel : fond gris très clair #FAFAFA pour simuler un tableau noir

### Animation
- 0,00-0,30 s : le triangle rétrécit et se repositionne
- 0,30-0,60 s : "6² + 8²" apparaît (effet écriture manuscrite, 0,3 s)
- 0,60-1,50 s : "= 36 + 64" apparaît (effet écriture, 0,4 s plus tard)
- 1,50-2,20 s : "= 100" apparaît en orange gras (effet pop + zoom 1,0× → 1,1×)
- 2,20-5,00 s : maintien, focus sur le "100"

### Audio
- 0,30 s : SFX craie.mp3 à l'apparition de "6² + 8²"
- 0,70 s : SFX craie.mp3 à l'apparition de "= 36 + 64"
- 1,50 s : SFX craie.mp3 + pop.mp3 (légèrement plus fort) à l'apparition de "= 100"
- 0,00-5,00 s : voix off "Donc BC² = 36 + 64, ça donne 100."

---

## Plan 6 — Racine carrée (0:21 → 0:25, 4,0 s)

### Composition
- Le triangle et les calculs précédents s'effacent
- Plein écran, centré : "√100 = 10"
- Le symbole "√" en vert #006837 taille 64 px (très grand)
- Le "100" sous la racine, Outfit 40 px noir
- Le "= 10" en orange #D97700 Outfit 56 px gras (1,5× plus grand que le reste)

### Animation
- 0,00-0,30 s : tracé du "√" en trait vert (effet stylo qui trace, 0,3 s)
- 0,30-0,50 s : "100" apparaît sous la racine (fondu)
- 0,50-0,80 s : "= 10" apparaît en orange avec effet pop (scale 0× → 1,2× → 1,0×)
- 0,80-4,00 s : maintien, voix off détaille

### Audio
- 0,50 s : SFX pop.mp3 à l'apparition de "= 10"
- 0,00-4,00 s : voix off "Et la racine de 100, c'est 10."

### Implementation Manim (snippet)
```python
racine = MathTex(r"\sqrt{100} = 10", font_size=72)
racine.set_color_by_tex("10", "#D97700")
self.play(Write(racine[:1]))  # √
self.wait(0.2)
self.play(Write(racine[1:2]))  # 100
self.wait(0.2)
self.play(FadeIn(racine[2:], shift=UP, scale=1.2))
```

---

## Plan 7 — Résultat final (0:25 → 0:28, 3,0 s)

### Composition
- Fond blanc
- Plein centre : "BC = 10 cm" en Outfit 36 px gras vert #006837
- Checkmark vert à gauche du résultat (icône SVG check_circle 40×40 px)
- En dessous, en plus petit (Outfit 16 px italique gris) : "Triplet pythagoricien : (6, 8, 10)"
- Petite étoile SVG (pas d'emoji) à droite du triplet, en orange

### Animation
- 0,00-0,50 s : zoom-in du texte "BC = 10 cm" (scale 0,8× → 1,0×)
- 0,30 s : checkmark apparaît (scale 0× → 1,2× → 1,0×, effet pop)
- 0,50-0,80 s : sous-titre "Triplet pythagoricien..." apparaît en fondu
- 0,80-3,00 s : maintien, voix off conclut

### Audio
- 0,30 s : SFX pop.mp3 (checkmark)
- 2,50 s : SFX jingle_fin.mp3 (conclusion)
- 0,00-3,00 s : voix off "Donc BC = 10 cm. Le triplet 6-8-10 est un classique, retiens-le !"

---

## Plan 8 — Outro (0:28 → 0:30, 2,0 s)

### Composition
- Fond vert Togo #006837
- Logo ExamBoost blanc 80×80 px centré haut
- Espace 12 px
- Texte "Télécharge l'app" Outfit 24 px gras blanc
- Espace 16 px
- QR code (100×100 px) pointant vers https://examboost.tg/app
- Sous le QR code, en petit (Outfit 12 px blanc 60 %) : "iOS • Android • Web"

### Animation
- 0,00-0,30 s : fade-in global
- 0,30-2,00 s : maintien statique

### Audio
- 0,00-0,50 s : jingle_fin.mp3 (en continuité du plan 7, mixé à -8 dBFS)
- 0,50-2,00 s : silence

---

## Sous-titres (piste FR)

Format : WebVTT (.vtt), police Outfit 24 px, blanc sur fond noir semi-transparent 60 %, position bas-centre

```
WEBVTT

00:00:00.000 --> 00:00:03.000
[ExamBoost Togo] Pythagore

00:00:03.000 --> 00:00:07.000
Pour calculer l'hypoténuse d'un triangle rectangle...

00:00:07.000 --> 00:00:12.000
...on utilise Pythagore. BC² = AB² + AC².

00:00:12.000 --> 00:00:16.000
Ici, AB = 6, AC = 8.

00:00:16.000 --> 00:00:21.000
Donc BC² = 36 + 64, ça donne 100.

00:00:21.000 --> 00:00:25.000
Et la racine de 100, c'est 10.

00:00:25.000 --> 00:00:28.000
Donc BC = 10 cm. Le triplet 6-8-10 est un classique, retiens-le !

00:00:28.000 --> 00:00:30.000
Télécharge l'app
```

## Sous-titres (piste EN)

Même format, traduction depuis le script EN.

## Notes de montage
- Transitions entre plans : CUT SEC (pas de fondus, sauf plan 1→2 et plan 7→8)
- Durée totale cible : 30,0 s (à 0,1 s près)
- Bitrate : 4-8 Mbps pour rester sous 10 Mo
- Format export : MP4 H.264, AAC 192 kbps stereo, 1280×720, 30 fps
- Couleur : pas de correction colorimétrique (les couleurs sont volontairement saturées pour le style éducatif)

## Récapitulatif timecodes
| Plan | Début | Fin | Durée | Élément principal |
|---|---|---|---|---|
| 1 | 0:00 | 0:03 | 3,0 s | Logo + titre |
| 2 | 0:03 | 0:07 | 4,0 s | Triangle dessiné |
| 3 | 0:07 | 0:12 | 5,0 s | Formule BC² = AB² + AC² |
| 4 | 0:12 | 0:16 | 4,0 s | Valeurs AB=6, AC=8 |
| 5 | 0:16 | 0:21 | 5,0 s | Calcul 6²+8² = 100 |
| 6 | 0:21 | 0:25 | 4,0 s | √100 = 10 |
| 7 | 0:25 | 0:28 | 3,0 s | Résultat BC = 10 cm |
| 8 | 0:28 | 0:30 | 2,0 s | Outro + QR |
| **Total** | | | **30,0 s** | |
