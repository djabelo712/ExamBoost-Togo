# lib/widgets/math/ — Rendu LaTeX pour formules mathématiques

Module de rendu de formules mathématiques LaTeX intégrées dans du texte Flutter.
Construit autour de `flutter_math_fork` (fork maintenu de `flutter_math`) avec
fallback automatique en texte brut monospace si l'expression n'est pas
supportée ou échoue à parser.

## Fichiers

| Fichier | Rôle |
|---|---|
| `latex_parser.dart` | Détecte les blocs `$...$` dans un texte mixte et produit une liste de `TextSegment`. |
| `latex_to_fluttermath.dart` | Convertit la syntaxe LaTeX standard vers la syntaxe `flutter_math_fork` (`\leq` → `\le`, `\R` → `\mathbb{R}`, …) et liste les constructions non supportées. |
| `math_expression.dart` | Widget wrapper autour de `Math.tex(...)` avec try/catch + fallback monospace. |
| `math_text.dart` | Widget principal : texte mixte normal + LaTeX. C'est ce widget qu'on branche à la place de `Text` dans les écrans. |
| `README.md` | Ce document. |

## Usage simple

```dart
import 'package:examboost_togo/widgets/math/math_text.dart';

// Au lieu de :
Text('Résoudre : AB = √32 = 4√2 ≈ 5,66')

// Utiliser :
MathText(
  text: r'Résoudre : $AB = \sqrt{32} = 4\sqrt{2} \approx 5{,}66$',
  style: AppTextStyles.questionText,
)

// Multi-formules dans la même chaîne :
MathText(
  text: r'Aire : $A = \frac{b \times h}{2} = 20 \text{ cm}^2$ et volume : $V = \pi r^2 h$.',
)

// Sans aucune formule : renvoie un Text natif (zéro overhead).
MathText(text: 'Question sans formule.', style: AppTextStyles.body);
```

> **Note Dart** : préfixer la chaîne par `r` (raw string) évite d'avoir à
> échapper les backslashes : `r'\frac{a}{b}'` plutôt que `'\\frac{a}{b}'`.

## Convention

Les formules LaTeX sont **encadrées par `$...$`** (style Markdown). Le parseur
est volontairement simple : pas de `$$...$$` bloc, pas d'échappement complexe.
Pour les énoncés BAC/BEPC c'est largement suffisant.

## Conversions Unicode → LaTeX

Les questions existantes dans `assets/data/questions.json` utilisent des
caractères Unicode (√, ², ≈, π, …). Pour activer le rendu LaTeX, convertir :

| Caractère Unicode | LaTeX équivalent | Exemple |
|---|---|---|
| √x | `\sqrt{x}` | `\sqrt{32}` |
| ², ³ | `^2`, `^3` | `x^2 + 2x + 1` |
| xⁿ | `x^{n}` | `2^{10}` |
| ≈ | `\approx` | `\pi \approx 3{,}14` |
| × | `\times` | `a \times b` |
| ÷ | `\div` | `a \div b` |
| ≤ | `\leq` | `x \leq 5` |
| ≥ | `\geq` | `x \geq 5` |
| ≠ | `\neq` | `a \neq b` |
| ± | `\pm` | `x = \pm 2` |
| π | `\pi` | `2\pi r` |
| α β γ θ | `\alpha \beta \gamma \theta` | `\cos \theta` |
| ∞ | `\infty` | `\lim_{x \to +\infty}` |
| → | `\rightarrow` (alias `\to`) | `x \to 0` |
| ∫ | `\int_{a}^{b}` | `\int_0^1 x^2 \, dx` |
| ∑ | `\sum_{i=1}^{n}` | `\sum_{i=1}^{n} i = \frac{n(n+1)}{2}` |
| ℂ ℕ ℚ ℝ ℤ | `\mathbb{C}` … (alias `\C`, `\N`, …) | `x \in \mathbb{R}` |
| · | `\cdot` | `u \cdot v` |
| Fraction slash / | `\frac{a}{b}` | `\frac{1}{2}` |

## Intégration — À faire par l'agent de wiring

Ce module est livré **sans dépendance ni modification hors `lib/widgets/math/`**.
Pour l'activer dans l'app :

### 1. Ajouter `flutter_math_fork` au `pubspec.yaml`

```yaml
dependencies:
  flutter_math_fork: ^0.7.2
```

Puis `flutter pub get`.

### 2. Remplacer `Text(...)` par `MathText(text: ...)` dans les écrans clés

| Fichier | Variables concernées |
|---|---|
| `lib/widgets/cards/question_card.dart` | `question.enonce`, `question.reponse`, `question.explication` |
| `lib/screens/revision/revision_screen.dart` | énoncé / réponse / explication |
| `lib/screens/simulation/simulation_screen.dart` | énoncé / réponse / explication |
| `lib/widgets/exam/*` (Agent AA) | brouillon, calculatrice — optionnel |

Exemple de remplacement dans `question_card.dart` :

```dart
// Avant :
Text(question.enonce, style: AppTextStyles.questionText),

// Après :
MathText(text: question.enonce, style: AppTextStyles.questionText),
```

### 3. Convertir les questions existantes

Deux options :

**Option A (recommandée) — Script Python** : voir `convert_to_latex.py` ci-dessous.
À lancer une seule fois sur `assets/data/questions.json` pour remplacer les
caractères Unicode par leur équivalent LaTeX encadré par `$...$`.

**Option B — Manuelle** : éditer les questions les plus complexes à la main
(intégrales, fractions, sommes) et laisser les autres en Unicode (le rendu
sera identique à avant, juste sans LaTeX).

### 4. Pour les nouvelles questions générées (Agent AG et suivants)

Préférer la syntaxe LaTeX directement :

```json
{
  "enonce": "Calculer $\\int_0^1 x^2 \\, dx$.",
  "reponse": "$\\frac{1}{3}$",
  "explication": "Une primitive de $x^2$ est $\\frac{x^3}{3}$. Donc $\\int_0^1 x^2 \\, dx = \\left[ \\frac{x^3}{3} \\right]_0^1 = \\frac{1}{3}$."
}
```

> Dans un fichier JSON, le backslash doit être échappé en `\\`. Si la chaîne
> est écrite en Dart source, préfixer par `r` évite ce double-échappement.

## Script Python de conversion (optionnel)

`scripts/convert_to_latex.py` :

```python
#!/usr/bin/env python3
"""Convertit les caractères Unicode mathématiques en LaTeX dans questions.json.

Usage:
    python scripts/convert_to_latex.py assets/data/questions.json
"""
import json
import re
import sys
from pathlib import Path

# Ordre important : traiter les cas composés avant les cas simples.
UNICODE_TO_LATEX = [
    # Fractions explicites (a / b avec espaces) -> \frac{a}{b} si simple
    # (volontairement non converti : ambigu, laisser l'auteur décider)
    ("×", r" \times "),
    ("÷", r" \div "),
    ("≤", r" \leq "),
    ("≥", r" \geq "),
    ("≠", r" \neq "),
    ("±", r" \pm "),
    ("·", r" \cdot "),
    ("→", r" \rightarrow "),
    ("∞", r" \infty "),
    ("π", r" \pi "),
    ("α", r" \alpha "),
    ("β", r" \beta "),
    ("γ", r" \gamma "),
    ("θ", r" \theta "),
    ("Σ", r" \sum "),
    ("∑", r" \sum "),
    ("∫", r" \int "),
    ("ℂ", r" \mathbb{C} "),
    ("ℕ", r" \mathbb{N} "),
    ("ℚ", r" \mathbb{Q} "),
    ("ℝ", r" \mathbb{R} "),
    ("ℤ", r" \mathbb{Z} "),
    ("≈", r" \approx "),
    # Racines : √x ou √(expr) -> \sqrt{...}
    (re.compile(r"√\(([^)]+)\)"), r"\\sqrt{\1}"),
    (re.compile(r"√(\d+)"), r"\\sqrt{\1}"),
    (re.compile(r"√([a-zA-Z])"), r"\\sqrt{\1}"),
    # Exposants : x² -> x^2, x³ -> x^3, xⁿ -> x^{n}
    (re.compile(r"([a-zA-Z0-9\)])²"), r"\1^2"),
    (re.compile(r"([a-zA-Z0-9\)])³"), r"\1^3"),
    (re.compile(r"([a-zA-Z0-9\)])⁴"), r"\1^4"),
    (re.compile(r"([a-zA-Z0-9\)])⁵"), r"\1^5"),
    (re.compile(r"([a-zA-Z0-9\)])ⁿ"), r"\1^{n}"),
]

# Champs à convertir dans chaque question
FIELDS = ("enonce", "reponse", "explication")


def convert_value(s: str) -> str:
    if not s:
        return s
    out = s
    for pattern, repl in UNICODE_TO_LATEX:
        if isinstance(pattern, str):
            out = out.replace(pattern, repl)
        else:
            out = pattern.sub(repl, out)
    return out.strip()


def main(path: Path) -> None:
    data = json.loads(path.read_text(encoding="utf-8"))
    questions = data if isinstance(data, list) else data.get("questions", [])
    n = 0
    for q in questions:
        for field in FIELDS:
            if field in q and q[field]:
                q[field] = convert_value(q[field])
                n += 1
    backup = path.with_suffix(path.suffix + ".bak")
    backup.write_text(path.read_text(encoding="utf-8"), encoding="utf-8")
    path.write_text(
        json.dumps(data, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"Converti {n} champ(s). Backup: {backup}")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python convert_to_latex.py <questions.json>")
        sys.exit(1)
    main(Path(sys.argv[1]))
```

> À exécuter dans un virtualenv Python 3.10+. Aucune dépendance externe.

## Limites connues

- **Constructions non supportées** par `flutter_math_fork` : `\begin{align}`,
  `\begin{cases}`, `\substack`, `\overset`, `\underset`, `\boxed`, `\textbf`,
  `\mathit`, `\mathsf`. Si l'une d'elles est détectée, l'expression est
  affichée en police monospace (lisible, non typographiée). Voir
  `LatexToFlutterMath.isSupported`.
- **Pas de coloration syntaxique** des formules. Possible à ajouter plus tard
  en wrappant `MathExpression` dans un `CustomPaint` ou en surchargeant le
  `textStyle` par morceau (non trivial avec flutter_math_fork).
- **Performance** : pour les listes longues (banque de questions complète),
  le rendu `Math.tex` n'est pas mis en cache. Si on observe des saccades,
  envisager de pré-rendre les expressions (RepaintBoundary + cache) ou
  d'utiliser `ListView.builder` avec `addAutomaticKeepAlives: true`.
- **`maxLines` / `overflow`** : ignorés quand le texte contient du LaTeX (le
  `Wrap` ne les supporte pas). Quand il n'y a pas de LaTeX, un `Text` natif
  est renvoyé et ces paramètres fonctionnent normalement.
- **`$$...$$` (display math en bloc)** non supporté par le parseur. Pour une
  formule seule sur sa ligne, utiliser un `MathText` dédié avec
  `textAlign: TextAlign.center` et une chaîne ne contenant que `$...$`.

## Tests rapides recommandés (à faire par l'agent de wiring)

```dart
// Dans un écran de test temporaire :
Column(
  children: [
    MathText(text: r'Pythagore : $BC^2 = AB^2 + AC^2 = 6^2 + 8^2 = 100$'),
    MathText(text: r'Aire : $A = \frac{b \times h}{2}$ cm$^2$'),
    MathText(text: r'Intégrale : $I = \int_0^1 (3x^2 + 2x) \, dx = 2$'),
    MathText(text: r'Complexe : $z = -1 \pm 2i$, $|z| = \sqrt{5}$'),
    MathText(text: r'Limite : $\lim_{x \to +\infty} \frac{3x^2 + 2x}{x^2 - 5} = 3$'),
    MathText(text: r'Texte sans formule -> reste un Text natif.'),
  ],
)
```

Si une formule ne s'affiche pas correctement, vérifier :
1. Que `$...$` entoure bien la formule.
2. Que le nombre de `$` est pair (`LatexToFlutterMath.isBalanced`).
3. Que la commande LaTeX est dans la liste supportée (sinon fallback
   monospace — c'est voulu, pas un bug).
