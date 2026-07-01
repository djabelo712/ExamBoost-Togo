# Storyboard détaillé — Loi d'Ohm (Q04)

## Métadonnées
- **Video ID** : q04_ohm
- **Script associé** : `scripts/q04_ohm_script.md`
- **Question ID** : TG-BEPC-PHYS-2022-Q02
- **Durée totale** : 30,0 s
- **Format** : 1280×720, 30 fps
- **Style** : schéma électrique normalisé + triangle magique

## Palette & Typo
Identique à Q01. Ajout : rouge flèche courant (#D32F2F), jaune surlignage (#FFEB3B).

## Asset list
- `symbole_pile.svg` : symbole normalisé pile (2 traits parallèles inégaux)
- `symbole_resistance.svg` : rectangle zigzag
- `symbole_amperemetre.svg` : cercle avec "A"
- `symbole_voltmetre.svg` : cercle avec "V"
- `triangle_magique.svg` : triangle avec U en haut, R·I en bas

---

## Plans shot par shot

### Plan 1 — Logo + Titre (0:00 → 0:03, 3,0 s)
- **Composition** : fond vert Togo, logo + "Loi d'Ohm" Outfit 32 px gras + sous-titre "Électricité — BEPC" 14 px
- **Animation** : fade-in 0,3 s
- **Audio** : jingle_debut.mp3 (0,5 s)
- **Transition** : fade-out vers blanc

### Plan 2 — Schéma circuit (0:03 → 0:08, 5,0 s)
- **Composition** : fond blanc, circuit électrique : pile à gauche (symbole normalisé), résistance en haut (rectangle zigzag), ampèremètre en série (cercle "A"), voltmètre en parallèle de la résistance (cercle "V"). Fils noirs 2 px. Flèche rouge indiquant le sens du courant (de la borne + de la pile vers la résistance)
- **Animation** : tracé progressif du circuit, 1 s (effet "stylo qui dessine"). Ordre : pile → fil haut → résistance → fil droit → ampèremètre → fil bas → voltmètre en parallèle
- **Audio** : voix off "La loi d'Ohm relie la tension, le courant et la résistance."

### Plan 3 — Triangle magique (0:08 → 0:13, 5,0 s)
- **Composition** : schéma réduit à gauche (40 % écran). À droite, triangle magique "U / R·I" :
  - Triangle noir 2 px, hauteur ~200 px
  - "U" en haut (orange #D97700, Outfit 32 px gras)
  - "R" et "I" en bas, séparés par "×" (vert #006837, Outfit 24 px gras)
  - Ligne horizontale au milieu séparant U de R·I
- En dessous du triangle, formule "U = R × I" en Times 28 px gras noir
- **Animation** : triangle se dessine (effet draw, 0,5 s), puis lettres apparaissent (U en premier, R et I ensuite), puis formule apparaît en fondu
- **Audio** : voix off "Formule : U égale R fois I." + SFX ding.mp3 à 0,5 s

### Plan 4 — Valeurs sur le schéma (0:13 → 0:17, 4,0 s)
- **Composition** : sur le schéma (à gauche), surlignage des valeurs :
  - "R = 20 Ω" en orange à côté de la résistance (badge arrondi)
  - "I = 0,5 A" en orange à côté de l'ampèremètre
  - "U = ?" en orange italique à côté du voltmètre
- **Animation** : balayage gauche-droite, 0,3 s par étiquette
- **Audio** : voix off "Ici, R vaut 20 ohms et I vaut 0,5 ampère."

### Plan 5 — Calcul (0:17 → 0:22, 5,0 s)
- **Composition** : schéma réduit à 25 % en haut-gauche. En grand au centre-droite, cascade en Patrick Hand 28 px :
  - "U = R × I" (rappel formule)
  - "U = 20 × 0,5" (valeurs en orange)
- **Animation** : chaque ligne fondu + slide-up, 0,4 s de décalage
- **Audio** : voix off "Donc U égale 20 fois 0,5." + SFX craie.mp3 à 0,5 s et 1,0 s

### Plan 6 — Astuce "un demi" (0:22 → 0:26, 4,0 s)
- **Composition** : "20 × 0,5 = 10" en grand. En dessous, en plus petit : "0,5 = 1/2, donc 20 × 1/2 = 10". Une barre de fraction "20/2 = 10" apparaît avec animation de coupe
- **Animation** : la barre de fraction se dessine (effet draw), 0,3 s
- **Audio** : voix off "Et 20 fois un demi, ça fait 10." + SFX pop.mp3 à 0,5 s

### Plan 7 — Résultat (0:26 → 0:29, 3,0 s)
- **Composition** : "U = 10 V" plein centre, Outfit 40 px gras vert #006837 + checkmark vert à gauche. En bas, en plus petit : "U = R × I (loi d'Ohm, conducteur ohmique)"
- **Animation** : zoom-in 0,8× → 1,0× + checkmark animé
- **Audio** : voix off "Donc la tension U vaut 10 volts. Simple comme bonjour !" + SFX jingle_fin.mp3 à 2,5 s

### Plan 8 — Outro (0:29 → 0:30, 1,0 s)
- **Composition** : fond vert Togo, logo + "Télécharge l'app" + QR
- **Animation** : fade-in 0,3 s
- **Audio** : silence

## Sous-titres (FR — WebVTT)
```
WEBVTT

00:00:00.000 --> 00:00:03.000
[ExamBoost Togo] Loi d'Ohm

00:00:03.000 --> 00:00:08.000
La loi d'Ohm relie la tension, le courant et la résistance.

00:00:08.000 --> 00:00:13.000
Formule : U égale R fois I.

00:00:13.000 --> 00:00:17.000
Ici, R vaut 20 ohms et I vaut 0,5 ampère.

00:00:17.000 --> 00:00:22.000
Donc U égale 20 fois 0,5.

00:00:22.000 --> 00:00:26.000
Et 20 fois un demi, ça fait 10.

00:00:26.000 --> 00:00:29.000
Donc la tension U vaut 10 volts. Simple comme bonjour !

00:00:29.000 --> 00:00:30.000
Télécharge l'app
```

## Notes de montage
- Le schéma électrique doit respecter les normes (symboles normalisés, sens du courant de + vers - à l'extérieur de la pile)
- Le triangle magique est le mnémotechnique clé — bien le mettre en valeur (gros, centré)
- Couleur des unités : U en volts (V), I en ampères (A), R en ohms (Ω) — bien les afficher

## Récapitulatif timecodes
| Plan | Début | Fin | Durée | Élément principal |
|---|---|---|---|---|
| 1 | 0:00 | 0:03 | 3,0 s | Logo + titre |
| 2 | 0:03 | 0:08 | 5,0 s | Schéma circuit |
| 3 | 0:08 | 0:13 | 5,0 s | Triangle magique U/R·I |
| 4 | 0:13 | 0:17 | 4,0 s | Valeurs R=20, I=0,5 |
| 5 | 0:17 | 0:22 | 5,0 s | Calcul U = 20 × 0,5 |
| 6 | 0:22 | 0:26 | 4,0 s | Astuce "un demi" |
| 7 | 0:26 | 0:29 | 3,0 s | Résultat U = 10 V |
| 8 | 0:29 | 0:30 | 1,0 s | Outro + QR |
| **Total** | | | **30,0 s** | |
