# Script vidéo — Dérivée d'un polynôme (Q09)

## Métadonnées
- **Question ID** : TG-BAC-MATHC-2023-Q01
- **Video ID** : q09_derivee
- **Matière** : Mathématiques (BAC C)
- **Chapitre** : Dérivation — Fonctions polynômes
- **Compétence** : TG-MATHS-DERIV-001
- **Examen** : BAC1, Série C
- **Année** : 2023
- **Durée cible** : 35 secondes
- **Niveau** : Terminale C (BAC)
- **Points** : 5
- **Difficulté IRT (b)** : 0,6 (difficile)
- **Question originale** : "Calculer la dérivée de f(x) = 3x² + 2x - 5."
- **Réponse attendue** : f'(x) = 6x + 2

## Script voix off (FR)

> "Pour dériver f de x égale 3x carré plus 2x moins 5, on utilise la règle : la dérivée de a x puissance n égale n fois a x puissance n moins 1. Pour 3x carré, ça donne 6x. Pour 2x, la dérivée est 2. Et pour la constante moins 5, c'est 0. Donc f prime de x égale 6x plus 2."

(68 mots, environ 32 secondes à 130 mots/min)

## Script voix off (EN) — version internationale

> "To differentiate f of x equals 3x squared plus 2x minus 5, we use the rule : the derivative of a times x to the n equals n times a times x to the n minus 1. For 3x squared, that gives 6x. For 2x, the derivative is 2. And for the constant minus 5, it's 0. So f prime of x equals 6x plus 2."

(66 words, about 32 seconds at 130 wpm)

## Notes de prononciation et d'intonation (FR)
- "f de x" : prononcer "èff de iks".
- "3x carré" : prononcer "trois iks carré".
- "n fois a x puissance n moins 1" : décomposer, marquer les pauses.
- "f prime de x" : prononcer "èff prime de iks".
- Ton : technique, posé, légèrement universitaire.

## Storyboard (8 plans sur 35 sec)

| Plan | Timecode | Visuel | Voix off | SFX |
|---|---|---|---|---|
| 1 | 0:00-0:03 | Logo + titre "Dérivée" | (silence) | jingle |
| 2 | 0:03-0:07 | Fonction f(x) = 3x² + 2x - 5 apparaît en grand | "Pour dériver f de x égale 3x carré plus 2x moins 5..." | — |
| 3 | 0:07-0:13 | Règle générale : d/dx[a·xⁿ] = n·a·x^(n-1) | "...on utilise la règle : la dérivée de a x puissance n égale n fois a x puissance n moins 1." | "ding" |
| 4 | 0:13-0:18 | Terme 3x² isolé, application : 2·3·x¹ = 6x | "Pour 3x carré, ça donne 6x." | son de stylo |
| 5 | 0:18-0:22 | Terme 2x isolé, application : dérivée = 2 | "Pour 2x, la dérivée est 2." | son de stylo |
| 6 | 0:22-0:26 | Terme -5 isolé, application : dérivée = 0 | "Et pour la constante moins 5, c'est 0." | son de stylo |
| 7 | 0:26-0:31 | Assemblage : f'(x) = 6x + 2 + 0 = 6x + 2 | "Donc f prime de x égale 6x plus 2." | "pop" |
| 8 | 0:31-0:35 | Résultat final + "Télécharge l'app" | (silence) | jingle fin |

## Éléments visuels à produire

### Plan 1 — Logo + Titre
- Fond vert Togo #006837
- Logo + "Dérivée" Outfit 32 px gras blanc
- Sous-titre "Fonctions polynômes — BAC C" 14 px
- Fade in 0,3 s

### Plan 2 — Fonction
- Fond blanc
- "f(x) = 3x² + 2x - 5" plein centre, Outfit 40 px gras noir
- Le "²" en exposant
- Animation : fade-in + zoom 0,8× → 1,0×

### Plan 3 — Règle générale
- En haut, encadré orange : "Règle : d/dx[a·xⁿ] = n·a·x^(n-1)"
- Police serif 26 px noir
- Les variables en couleurs : a en bleu, n en rouge, x en noir
- Animation : encadré apparaît, puis règle s'écrit caractère par caractère

### Plan 4 — Terme 3x²
- La fonction se réduit en haut
- En bas à gauche, encadré :
  - "3x²"
  - Flèche vers le bas
  - "n=2, a=3"
  - "2 × 3 × x^(2-1)"
  - "= 6x" (en vert, gras)
- Animation : cascade de transformations

### Plan 5 — Terme 2x
- Encadré à droite :
  - "2x"
  - Flèche
  - "n=1, a=2"
  - "1 × 2 × x^(1-1)"
  - "= 2·x⁰ = 2" (en vert)
- Animation : cascade

### Plan 6 — Terme -5
- Encadré en bas centre :
  - "-5"
  - Flèche
  - "constante"
  - "dérivée = 0" (en vert)
- Animation : cascade

### Plan 7 — Assemblage
- En grand, plein centre :
  - "f'(x) = 6x + 2 + 0"
  - Puis "= 6x + 2" (en gros vert, le "+ 0" s'efface)
- Animation : "+ 0" s'efface en fondu, "= 6x + 2" apparaît en pop

### Plan 8 — Résultat + Outro
- "f'(x) = 6x + 2" plein centre, Outfit 40 px gras vert #006837
- Checkmark vert à gauche
- Puis fond vert Togo, logo + "Télécharge l'app"
- Animation : zoom-in + checkmark, puis fade transition

## Production

### Outils recommandés
- **Animation** : Manim (Python, parfait pour les dérivées symboliques avec `TransformMatchingTex`) ou LaTeX + Beamer pour export PDF puis animation dans Canva
- **Voix off** : voix masculine posée (ton professoral BAC) — ElevenLabs voix "Adam" ou "Arnold"
- **Montage** : CapCut
- **Export** : MP4 H.264, 1280×720, 30 fps

### Checklist production
- [ ] Script validé par un prof de maths BAC C
- [ ] Règle de dérivation vérifiée (n·a·x^(n-1))
- [ ] Voix FR + EN enregistrées
- [ ] Animations créées (8 plans, 35 s)
- [ ] SFX : jingle, ding, stylo, pop
- [ ] Montage CapCut
- [ ] Sous-titres FR + EN
- [ ] Export MP4 < 12 Mo
- [ ] Copie dans `assets/videos/q09_derivee.mp4`

### Coût estimé
- 0 € (mutualisé)

## Intégration in-app
Voir Q01 — même pattern. Cette vidéo cible spécifiquement les élèves de Terminale C, donc le bouton vidéo n'apparaîtra que sur les questions BAC C.

## Astuces pédagogiques
- La règle clé à retenir : "n descend en coefficient, l'exposant baisse de 1". Exemple : 3x² → 2·3x¹ = 6x.
- Pour les constantes (comme -5), la dérivée est TOUJOURS 0. Erreur fréquente : oublier de l'éliminer.
- Autres formules de dérivation à connaître au BAC C :
  - d/dx[1/x] = -1/x²
  - d/dx[√x] = 1/(2√x)
  - d/dx[eˣ] = eˣ
  - d/dx[ln(x)] = 1/x
  - d/dx[sin(x)] = cos(x), d/dx[cos(x)] = -sin(x)
- Astuce gain de temps : pour un polynôme simple, "règle du glaçon" — l'exposant descend et se multiplie. 3x⁴ → 12x³. Pas besoin de réécrire n·a·x^(n-1) à chaque fois.
- Variante "astuce examen" : vérifier en calculant f'(0) et f'(1). Si f'(0) = 2 (constante de la dérivée) et f'(1) = 8, on a une cohérence. Ici f'(0) = 6·0 + 2 = 2 ✓ et f'(1) = 6·1 + 2 = 8 ✓.
- Pour la version EN : "f prime" se dit "f prime" ou "f dash" selon les pays. "Derivative" est le terme général.
