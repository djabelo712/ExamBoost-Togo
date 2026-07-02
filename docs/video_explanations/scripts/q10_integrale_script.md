# Script vidéo — Intégrale définie (Q10)

## Métadonnées
- **Question ID** : TG-BAC-MATHC-2023-Q03
- **Video ID** : q10_integrale
- **Matière** : Mathématiques (BAC C)
- **Chapitre** : Calcul intégral
- **Compétence** : TG-MATHS-INT-001
- **Examen** : BAC1, Série C
- **Année** : 2023
- **Durée cible** : 40 secondes
- **Niveau** : Terminale C (BAC)
- **Points** : 5
- **Difficulté IRT (b)** : 0,4 (moyen-difficile)
- **Question originale** : "Calculer l'intégrale : I = ∫₀¹ (3x² + 2x) dx."
- **Réponse attendue** : I = 2

## Script voix off (FR)

> "Pour calculer l'intégrale de 0 à 1 de 3x carré plus 2x, on cherche d'abord une primitive. La primitive de 3x carré est x au cube. La primitive de 2x est x carré. Donc F de x égale x au cube plus x carré. On évalue entre 0 et 1 : F de 1 moins F de 0, soit 2 moins 0. L'intégrale vaut 2."

(72 mots, environ 34 secondes à 130 mots/min)

## Script voix off (EN) — version internationale

> "To compute the integral from 0 to 1 of 3x squared plus 2x, we first find an antiderivative. The antiderivative of 3x squared is x cubed. The antiderivative of 2x is x squared. So capital F of x equals x cubed plus x squared. We evaluate between 0 and 1 : F of 1 minus F of 0, that's 2 minus 0. The integral equals 2."

(70 words, about 34 seconds at 130 wpm)

## Notes de prononciation et d'intonation (FR)
- "intégrale de 0 à 1" : prononcer "intègrale de zéro à un".
- "3x carré" : "trois iks carré".
- "x au cube" : "iks au cube".
- "primitive" : prononcer clairement "pri-mi-tiv", pas "primi-tiv".
- "F de 1 moins F de 0" : décomposer, marquer les pauses.
- "L'intégrale vaut 2" : ton conclusif, tomber sur le "2".

## Storyboard (8 plans sur 40 sec)

| Plan | Timecode | Visuel | Voix off | SFX |
|---|---|---|---|---|
| 1 | 0:00-0:03 | Logo + titre "Intégrale" | (silence) | jingle |
| 2 | 0:03-0:08 | Intégrale ∫₀¹ (3x² + 2x) dx apparaît en grand | "Pour calculer l'intégrale de 0 à 1 de 3x carré plus 2x..." | — |
| 3 | 0:08-0:14 | Étape 1 : trouver une primitive. Encadré "Primitive" | "...on cherche d'abord une primitive." | "ding" |
| 4 | 0:14-0:20 | Calcul primitive : 3x² → x³, 2x → x² | "La primitive de 3x carré est x au cube. La primitive de 2x est x carré." | son de stylo |
| 5 | 0:20-0:26 | Assemblage : F(x) = x³ + x² apparaît | "Donc F de x égale x au cube plus x carré." | — |
| 6 | 0:26-0:32 | Théorème fondamental : ∫ = F(b) - F(a) avec F(1) et F(0) | "On évalue entre 0 et 1 : F de 1 moins F de 0..." | son de craie |
| 7 | 0:32-0:37 | Calcul : F(1) = 2, F(0) = 0, I = 2 | "...soit 2 moins 0. L'intégrale vaut 2." | "pop" |
| 8 | 0:37-0:40 | Résultat + "Télécharge l'app" | (silence) | jingle fin |

## Éléments visuels à produire

### Plan 1 — Logo + Titre
- Fond vert Togo #006837
- Logo + "Intégrale" Outfit 32 px gras blanc
- Sous-titre "Calcul intégral — BAC C" 14 px
- Fade in 0,3 s

### Plan 2 — Intégrale
- Fond blanc
- "I = ∫₀¹ (3x² + 2x) dx" plein centre, Outfit 40 px gras noir
- Le symbole ∫ en grand, bornes 0 et 1 en petit à droite
- Animation : le ∫ se dessine en trait vert, puis l'expression apparaît

### Plan 3 — Étape 1
- L'intégrale se réduit en haut
- En bas, encadré orange : "Étape 1 : Trouver une primitive F(x)"
- Animation : encadré apparaît en slide-up

### Plan 4 — Calcul primitive
- Deux colonnes :
  - Gauche : "3x²" → flèche → "x³" (avec annotation "règle : ∫xⁿ dx = x^(n+1)/(n+1)")
  - Droite : "2x" → flèche → "x²"
- Chaque transformation en couleur : "3x²" en bleu, "x³" en vert
- Animation : chaque colonne se remplit en cascade, 0,5 s de décalage

### Plan 5 — Assemblage
- "F(x) = x³ + x²" plein centre, Outfit 36 px gras vert #006837
- Annotation en bas : "+ C (constante d'intégration, ici omise car on calcule une intégrale définie)"
- Animation : assemblage des deux primitives

### Plan 6 — Théorème fondamental
- En haut : "Théorème fondamental : ∫ₐᵇ f(x) dx = F(b) - F(a)"
- En dessous, application :
  - "I = F(1) - F(0)"
  - "I = (1³ + 1²) - (0³ + 0²)"
- Animation : la formule générale apparaît, puis l'application en cascade

### Plan 7 — Calcul final
- "I = (1 + 1) - (0 + 0)"
- "I = 2 - 0"
- "I = 2" (en grand vert)
- Animation : cascade de simplifications, "2" en pop final

### Plan 8 — Résultat + Outro
- "I = 2" plein centre, Outfit 48 px gras vert #006837
- Checkmark vert à gauche
- Puis fond vert Togo, logo + "Télécharge l'app"
- Animation : zoom-in + checkmark, puis fade transition

## Production

### Outils recommandés
- **Animation** : Manim (Python, avec `MathTex` pour LaTeX natif, parfait pour intégrales et primitives) ou LaTeX + dvisvgm pour export SVG animé dans Canva
- **Voix off** : voix masculine posée (ton professoral BAC C) — ElevenLabs voix "Adam" ou "Arnold"
- **Montage** : CapCut
- **Export** : MP4 H.264, 1280×720, 30 fps

### Checklist production
- [ ] Script validé par un prof de maths BAC C
- [ ] Primitive vérifiée (d/dx[x³+x²] = 3x²+2x ✓)
- [ ] Calcul F(1) = 2, F(0) = 0 vérifié
- [ ] Voix FR + EN enregistrées
- [ ] Animations créées (8 plans, 40 s)
- [ ] SFX : jingle, ding, stylo, craie, pop
- [ ] Montage CapCut
- [ ] Sous-titres FR + EN
- [ ] Export MP4 < 15 Mo (durée plus longue)
- [ ] Copie dans `assets/videos/q10_integrale.mp4`

### Coût estimé
- 0 € (mutualisé)

## Intégration in-app
Voir Q01 — même pattern. Cible : élèves de Terminale C.

## Astuces pédagogiques
- Le concept clé : "intégrale définie = différence des primitives aux bornes". C'est le théorème fondamental de l'analyse.
- La constante d'intégration "+ C" peut être omise pour une intégrale DÉFINIE (les C s'annulent dans la différence F(b) - F(a)). Mais elle est OBLIGATOIRE pour une primitive générale (intégrale indéfinie).
- Tableau des primitives à connaître au BAC C :
  - ∫xⁿ dx = x^(n+1)/(n+1) (si n ≠ -1)
  - ∫(1/x) dx = ln|x|
  - ∫eˣ dx = eˣ
  - ∫cos(x) dx = sin(x)
  - ∫sin(x) dx = -cos(x)
  - ∫(1/(1+x²)) dx = arctan(x)
- Astuce gain de temps : "règle du glaçon inversée" — pour intégrer xⁿ, on monte l'exposant de 1 et on divise par le nouvel exposant. 3x² → x³ (car 3/3 = 1), 2x → x² (car 2/2 = 1).
- Interprétation géométrique : l'intégrale ∫ₐᵇ f(x) dx = aire sous la courbe de f entre a et b (avec signe : négatif si f négative).
- Erreur fréquente : oublier les bornes ou les inverser. Toujours écrire F(b) - F(a), pas l'inverse.
- Pour la version EN : "antiderivative" est le terme standard américain ; "primitive" est le terme français et britannique. Les deux sont corrects.
- Variante "astuce examen" : pour vérifier le résultat, dériver F et vérifier qu'on retrouve f. Ici d/dx[x³+x²] = 3x²+2x ✓.
