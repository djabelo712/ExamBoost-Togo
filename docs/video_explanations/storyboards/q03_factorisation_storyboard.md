# Storyboard détaillé — Factorisation x² - 9 (Q03)

## Métadonnées
- **Video ID** : q03_factorisation
- **Script associé** : `scripts/q03_factorisation_script.md`
- **Question ID** : TG-BEPC-MATHS-2021-Q02
- **Durée totale** : 25,0 s
- **Format** : 1280×720, 30 fps
- **Style** : algébrique, substitutions de termes en couleur

## Palette & Typo
Identique à Q01. Bleu ajouté (#1565C0) pour "a", rouge (#C62828) pour "b" afin de différencier les variables dans l'identité remarquable.

## Asset list
- Standard (logo, jingle, ding, craie, pop)

---

## Plans shot par shot

### Plan 1 — Logo + Titre (0:00 → 0:02, 2,0 s)
- **Composition** : fond vert Togo, logo + "Factorisation" Outfit 32 px gras + sous-titre "Identités remarquables — BEPC" 14 px
- **Animation** : fade-in 0,3 s
- **Audio** : jingle_debut.mp3 (0,5 s)
- **Transition** : fade-out vers blanc

### Plan 2 — Expression (0:02 → 0:05, 3,0 s)
- **Composition** : fond blanc, "x² - 9" plein centre, Outfit 40 px gras noir. Le "²" en exposant taille 60 %
- **Animation** : fade-in + zoom 0,5× → 1,0× avec rebond léger (effet elasticOut)
- **Audio** : voix off "Pour factoriser x² moins 9..."

### Plan 3 — Étiquette "différence de deux carrés" (0:05 → 0:09, 4,0 s)
- **Composition** : étiquette orange #D97700 arrondie avec texte blanc "Différence de deux carrés" qui tombe du haut et se positionne au-dessus de "x² - 9"
- **Animation** : slide-down depuis hors champ + rebond à l'arrivée (effet easeOutBounce)
- **Audio** : voix off "...on reconnaît une différence de deux carrés." + SFX ding.mp3 à 0,5 s

### Plan 4 — Identité remarquable (0:09 → 0:14, 5,0 s)
- **Composition** : l'expression "x² - 9" se décale vers le bas. En haut, formule "a² - b² = (a - b)(a + b)" en Times 28 px. Variables en couleurs : a² en bleu #1565C0, b² en rouge #C62828, (a-b)(a+b) en vert #006837
- **Animation** : les 4 termes (a², -, b², =, (a-b)(a+b)) apparaissent un par un, 0,3 s chacun
- **Audio** : voix off "Identité remarquable : a² moins b² égale a moins b fois a plus b."

### Plan 5 — Identification (0:14 → 0:17, 3,0 s)
- **Composition** : à gauche, deux colonnes côte à côte :
  - "x² = a² → a = x" (en bleu)
  - "9 = b² → b = 3 (car 3² = 9)" (en rouge)
- **Animation** : flèches qui se dessinent depuis x² vers a, et depuis 9 vers b (effet draw)
- **Audio** : voix off "Ici, a égale x et b égale 3, parce que 9 égale 3²." + SFX son_stylo.mp3 à 1,0 s

### Plan 6 — Substitution (0:17 → 0:21, 4,0 s)
- **Composition** : l'identité générale s'efface. Au centre : "(a - b)(a + b)" puis transformations progressives :
  - "(a - b)(a + b)" → "(x - b)(x + b)" (a remplacé par x, en bleu)
  - → "(x - 3)(x + 3)" (b remplacé par 3, en rouge)
- **Animation** : chaque remplacement en fondu (crossfade), 0,4 s
- **Audio** : voix off "Donc x² moins 9 égale x moins 3 fois x plus 3." + SFX pop.mp3 à chaque substitution

### Plan 7 — Résultat (0:21 → 0:24, 3,0 s)
- **Composition** : "(x - 3)(x + 3)" plein centre, Outfit 40 px gras vert #006837 + checkmark vert à gauche. En bas, en plus petit : "Vérification : (x-3)(x+3) = x² + 3x - 3x - 9 = x² - 9 ✓"
- **Animation** : zoom-in 0,8× → 1,0× + checkmark animé (scale 0× → 1,2× → 1,0×)
- **Audio** : voix off "Voilà, c'est factorisé !" + SFX jingle_fin.mp3 à 1,5 s

### Plan 8 — Outro (0:24 → 0:25, 1,0 s)
- **Composition** : fond vert Togo, logo + "Télécharge l'app" + QR
- **Animation** : fade-in 0,3 s
- **Audio** : silence

## Sous-titres (FR — WebVTT)
```
WEBVTT

00:00:00.000 --> 00:00:02.000
[ExamBoost Togo] Factorisation

00:00:02.000 --> 00:00:05.000
Pour factoriser x² moins 9...

00:00:05.000 --> 00:00:09.000
...on reconnaît une différence de deux carrés.

00:00:09.000 --> 00:00:14.000
Identité remarquable : a² moins b² égale a moins b fois a plus b.

00:00:14.000 --> 00:00:17.000
Ici, a égale x et b égale 3, parce que 9 égale 3².

00:00:17.000 --> 00:00:21.000
Donc x² moins 9 égale x moins 3 fois x plus 3.

00:00:21.000 --> 00:00:24.000
Voilà, c'est factorisé !

00:00:24.000 --> 00:00:25.000
Télécharge l'app
```

## Notes de montage
- Transitions : CUT SEC entre plans 2-3-4-5-6-7. Fade entre plan 1→2 et plan 7→8
- Les substitutions (a → x, b → 3) sont le moment clé : bien synchroniser le SFX "pop" avec chaque remplacement
- La vérification finale en sous-titre est importante pédagogiquement — ne pas l'omettre

## Récapitulatif timecodes
| Plan | Début | Fin | Durée | Élément principal |
|---|---|---|---|---|
| 1 | 0:00 | 0:02 | 2,0 s | Logo + titre |
| 2 | 0:02 | 0:05 | 3,0 s | Expression x² - 9 |
| 3 | 0:05 | 0:09 | 4,0 s | Étiquette "différence de deux carrés" |
| 4 | 0:09 | 0:14 | 5,0 s | Identité a² - b² |
| 5 | 0:14 | 0:17 | 3,0 s | Identification a=x, b=3 |
| 6 | 0:17 | 0:21 | 4,0 s | Substitution |
| 7 | 0:21 | 0:24 | 3,0 s | Résultat (x-3)(x+3) |
| 8 | 0:24 | 0:25 | 1,0 s | Outro + QR |
| **Total** | | | **25,0 s** | |
