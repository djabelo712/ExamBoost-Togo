# Storyboard détaillé — Intégrale définie (Q10)

## Métadonnées
- **Video ID** : q10_integrale
- **Script associé** : `scripts/q10_integrale_script.md`
- **Question ID** : TG-BAC-MATHC-2023-Q03
- **Durée totale** : 40,0 s
- **Format** : 1280×720, 30 fps
- **Style** : universitaire, théorème fondamental explicite, calcul par étapes

## Palette & Typo
- Vert Togo #006837, Orange #D97700, Blanc, Noir, Vert résultat #2E7D32
- Bleu #1565C0 (variables F, a, b), Rouge #C62828 (bornes 0, 1)
- Outfit pour titres, Times New Roman pour formules LaTeX

## Asset list
- Standard

---

## Plans shot par shot

### Plan 1 — Logo + Titre (0:00 → 0:03, 3,0 s)
- **Composition** : fond vert Togo, logo + "Intégrale" Outfit 32 px gras + sous-titre "Calcul intégral — BAC C" 14 px
- **Animation** : fade-in 0,3 s
- **Audio** : jingle_debut.mp3 (0,5 s)
- **Transition** : fade-out vers blanc

### Plan 2 — Intégrale (0:03 → 0:08, 5,0 s)
- **Composition** : fond blanc, "I = ∫₀¹ (3x² + 2x) dx" plein centre, Outfit 40 px gras noir. Le symbole ∫ en grand (taille 80 px), vert #006837. Bornes 0 et 1 en petit (rouge #C62828) à droite du ∫
- **Animation** : le ∫ se dessine en trait vert (effet draw, 0,5 s), puis l'expression "3x² + 2x" et le "dx" apparaissent en fondu
- **Audio** : voix off "Pour calculer l'intégrale de 0 à 1 de 3x carré plus 2x..."

### Plan 3 — Étape 1 : primitive (0:08 → 0:14, 6,0 s)
- **Composition** : l'intégrale se réduit en haut. En bas, encadré orange #D97700 : "Étape 1 : Trouver une primitive F(x)"
- **Animation** : encadré apparaît en slide-up (0,5 s)
- **Audio** : voix off "...on cherche d'abord une primitive." + SFX ding.mp3 à 0,5 s

### Plan 4 — Calcul primitive (0:14 → 0:20, 6,0 s)
- **Composition** : deux colonnes côte à côte :
  - Gauche : "3x²" → flèche → "x³" (en bleu), avec annotation en bas "règle : ∫xⁿ dx = x^(n+1)/(n+1)"
  - Droite : "2x" → flèche → "x²" (en bleu)
- Chaque transformation en couleur : fonction source en noir, primitive en bleu #1565C0
- **Animation** : chaque colonne se remplit en cascade, 0,5 s de décalage entre colonnes
- **Audio** : voix off "La primitive de 3x carré est x au cube. La primitive de 2x est x carré." + SFX son_stylo.mp3 à 0,5 s et 2,5 s

### Plan 5 — Assemblage F(x) (0:20 → 0:26, 6,0 s)
- **Composition** : "F(x) = x³ + x²" plein centre, Outfit 36 px gras vert #006837. Annotation en bas (Outfit 14 px italique gris) : "+ C (constante d'intégration, ici omise car on calcule une intégrale définie)"
- **Animation** : assemblage des deux primitives (crossfade), 0,5 s
- **Audio** : voix off "Donc F de x égale x au cube plus x carré."

### Plan 6 — Théorème fondamental (0:26 → 0:32, 6,0 s)
- **Composition** : en haut, encadré gris clair : "Théorème fondamental : ∫ₐᵇ f(x) dx = F(b) - F(a)". En dessous, application en cascade :
  - "I = F(1) - F(0)"
  - "I = (1³ + 1²) - (0³ + 0²)"
- Police Times 22 px noir
- **Animation** : la formule générale apparaît (0,5 s), puis l'application en cascade (0,5 s par ligne)
- **Audio** : voix off "On évalue entre 0 et 1 : F de 1 moins F de 0..." + SFX craie.mp3 à 1,0 s et 2,5 s

### Plan 7 — Calcul final (0:32 → 0:37, 5,0 s)
- **Composition** : cascade en Patrick Hand 26 px :
  - "I = (1 + 1) - (0 + 0)"
  - "I = 2 - 0"
  - "I = 2" (en grand vert Outfit 36 px gras)
- **Animation** : cascade de simplifications (0,5 s par ligne), "2" en pop final
- **Audio** : voix off "...soit 2 moins 0. L'intégrale vaut 2." + SFX pop.mp3 à 2,5 s

### Plan 8 — Résultat + Outro (0:37 → 0:40, 3,0 s)
- **Composition** : "I = 2" plein centre, Outfit 48 px gras vert #006837 + checkmark vert à gauche. Puis fond vert Togo, logo + "Télécharge l'app" + QR
- **Animation** : zoom-in + checkmark animé, puis fade transition vers outro à 2,0 s
- **Audio** : SFX jingle_fin.mp3 à 1,0 s, puis silence

## Sous-titres (FR — WebVTT)
```
WEBVTT

00:00:00.000 --> 00:00:03.000
[ExamBoost Togo] Intégrale

00:00:03.000 --> 00:00:08.000
Pour calculer l'intégrale de 0 à 1 de 3x carré plus 2x...

00:00:08.000 --> 00:00:14.000
...on cherche d'abord une primitive.

00:00:14.000 --> 00:00:20.000
La primitive de 3x carré est x au cube. La primitive de 2x est x carré.

00:00:20.000 --> 00:00:26.000
Donc F de x égale x au cube plus x carré.

00:00:26.000 --> 00:00:32.000
On évalue entre 0 et 1 : F de 1 moins F de 0...

00:00:32.000 --> 00:00:37.000
...soit 2 moins 0. L'intégrale vaut 2.

00:00:37.000 --> 00:00:40.000
Télécharge l'app
```

## Notes de montage
- Vidéo la plus longue (40 s) — rythme posé, BAC C exige de la rigueur
- Le théorème fondamental (plan 6) doit être explicite — c'est le concept-clé du calcul intégral
- L'annotation sur la constante d'intégration "+ C" est subtile mais importante pour les élèves qui iront plus loin
- Vérifier la cohérence mathématique : ∫₀¹ 3x² dx = [x³]₀¹ = 1 - 0 = 1 ; ∫₀¹ 2x dx = [x²]₀¹ = 1 - 0 = 1. Total : 1 + 1 = 2 ✓

## Récapitulatif timecodes
| Plan | Début | Fin | Durée | Élément principal |
|---|---|---|---|---|
| 1 | 0:00 | 0:03 | 3,0 s | Logo + titre |
| 2 | 0:03 | 0:08 | 5,0 s | Intégrale ∫₀¹(3x²+2x)dx |
| 3 | 0:08 | 0:14 | 6,0 s | Étape 1 : primitive |
| 4 | 0:14 | 0:20 | 6,0 s | Calcul primitive x³ + x² |
| 5 | 0:20 | 0:26 | 6,0 s | Assemblage F(x) |
| 6 | 0:26 | 0:32 | 6,0 s | Théorème fondamental |
| 7 | 0:32 | 0:37 | 5,0 s | Calcul final I = 2 |
| 8 | 0:37 | 0:40 | 3,0 s | Résultat + Outro |
| **Total** | | | **40,0 s** | |
