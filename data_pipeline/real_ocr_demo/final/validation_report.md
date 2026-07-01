# Rapport de validation OCR — démo BEPC

Généré automatiquement par `validate_and_merge.py`.

## Synthèse

- Total questions OCR-isées : **36**
- Questions valides (sans warning) : **33**
- Questions valides avec warning : **3**
- Questions rejetées : **0**
- Taux de validation : **100.0%**

## Répartition par matière

| Matière | Total | Valides | Warnings | Rejetées |
|---------|-------|---------|----------|----------|
| Français | 6 | 6 | 0 | 0 |
| Histoire-Géographie | 7 | 7 | 0 | 0 |
| Mathématiques | 8 | 5 | 3 | 0 |
| Sciences Physiques | 8 | 8 | 0 | 0 |
| Sciences de la Vie et de la Terre | 7 | 7 | 0 | 0 |

## Issues détectées (par règle)

| Règle | Occurrences |
|-------|-------------|
| `ocr_noise` | 4 |

## Exemples de questions rejetées

_Aucune question rejetée._
## Exemples de warnings (questions conservées)

### TG-BEPC-MATH-2022-OCR-Q01

**Extrait** : Résoudre dans M l'équation suivante: 3x + 7 = 22....

**Warnings** :
- `[warning]` ocr_noise : bruit OCR suspecté : M au lieu de ℝ (symbole math perdu)
- `[warning]` ocr_noise : bruit OCR suspecté : M au lieu de ℝ

### TG-BEPC-MATH-2022-OCR-Q05

**Extrait** : Dans un repère orthonormé, soient les points A(1; 2) et B(S: 6). Calculer la distance AB....

**Warnings** :
- `[warning]` ocr_noise : bruit OCR suspecté : S au lieu de 5 (confusion OCR)

### TG-BEPC-MATH-2022-OCR-Q06

**Extrait** : Factoriser l'expression suivante: x2 - 9....

**Warnings** :
- `[warning]` ocr_noise : bruit OCR suspecté : x2 au lieu de x² (exposant perdu)
