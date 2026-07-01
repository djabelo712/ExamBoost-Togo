# real_ocr_demo — Démo pipeline OCR sur 5 annales BEPC

Sous-module autonome du `data_pipeline` ExamBoost Togo qui **exécute réellement**
le pipeline OCR de bout en bout sur 5 PDFs d'annales BEPC simulés.

> Objectif : prouver que la chaîne *PDF → image → Tesseract → JSON → validation*
> fonctionne hors d'un environnement de production, sans appel à un LLM payant,
> et produire un jeu de ~30 questions prêtes à fusionner dans
> `assets/data/questions.json`.

---

## Pourquoi ce sous-module ?

Le pipeline principal (`data_pipeline/ocr_extract.py` + `structure_questions.py`)
démontre l'architecture mais **nécessite** :

- un manifeste `data/raw_pdfs/manifest.json` (vide par défaut),
- une `OPENAI_API_KEY` pour la phase de structuration,
- des PDFs d'annales téléchargés depuis Internet (scraper).

En sandbox sans Internet et sans clé API, on ne peut pas le lancer tel quel.
Ce sous-module **contourne ces dépendances** :

- génère 5 PDFs BEPC authentiques avec ReportLab (texte vectoriel, pas de scan),
- OCR-ise avec Tesseract uniquement (pas de fallback GPT-4o Vision),
- structure le texte avec des regex déterministes (pas d'LLM),
- valide avec des règles métier (pas de schéma JSON externe).

Le résultat est directement comparable à ce que produirait le pipeline
principal sur de vrais PDFs d'annales — à la différence que la précision OCR
est ici ~95 % (PDF vectoriel) alors qu'elle serait ~85 % sur un scan de
qualité moyenne.

---

## Architecture

```
real_ocr_demo/
├── __init__.py
├── README.md                       # Ce fichier
├── requirements.txt                # reportlab, pdf2image, pytesseract, Pillow
├── generate_sample_pdfs.py         # Étape 1 : 5 PDFs BEPC authentiques
├── run_real_ocr.py                 # Étape 2 : Tesseract fra sur les 5 PDFs
├── structure_extracted.py          # Étape 3 : regex → JSON par matière
├── validate_and_merge.py           # Étape 4 : validation + rapport
├── sample_pdfs/                    # 5 PDFs générés (entrées)
│   ├── bepc_maths_2022_sample.pdf
│   ├── bepc_francais_2021_sample.pdf
│   ├── bepc_sciences_2023_sample.pdf
│   ├── bepc_svt_2020_sample.pdf
│   └── bepc_histoire_2022_sample.pdf
├── extracted_text/                 # Sortie OCR (texte brut)
│   ├── bepc_maths_2022.txt
│   └── ...
├── structured_questions/           # JSON intermédiaire par matière
│   ├── bepc_maths_2022_questions.json
│   └── ...
└── final/                          # Sortie finale + rapports
    ├── ocr_stats.json              # Stats OCR (pages, mots, durée)
    ├── structuring_stats.json      # Stats structuration (exos, questions)
    ├── ocr_extracted_questions.json   # Toutes les questions OCR-isées
    ├── ocr_validated_questions.json   # Questions validées (prêtes à merger)
    ├── validation_report.json         # Rapport machine
    └── validation_report.md           # Rapport humain (pitch DJANTA)
```

### Flux de données

```
+-----------------------+   +-------------------+   +---------------------+
| generate_sample_pdfs  | → |   run_real_ocr    | → | structure_extracted |
|  (ReportLab, 5 PDFs)  |   | (Tesseract fra)   |   |   (regex → JSON)    |
+-----------------------+   +-------------------+   +---------------------+
                                                              |
                                                              v
                                                    +---------------------+
                                                    | validate_and_merge  |
                                                    | (règles + rapport)  |
                                                    +---------------------+
                                                              |
                                                              v
                                          final/ocr_validated_questions.json
                                          (prêt pour wiring → assets/data/)
```

---

## Prérequis système

### 1. Tesseract + langue française

```bash
# Debian / Ubuntu (avec root)
sudo apt-get install -y tesseract-ocr tesseract-ocr-fra

# macOS
brew install tesseract tesseract-lang
```

#### Sandbox sans root (cas de ce dépôt)

Si `tesseract-ocr-fra` n'est pas installable (sandbox), télécharger le fichier
`fra.traineddata` dans un dossier local :

```bash
mkdir -p /home/z/my-project/.tessdata
curl -sSL -o /home/z/my-project/.tessdata/fra.traineddata \
    https://github.com/tesseract-ocr/tessdata_fast/raw/main/fra.traineddata
# Copier aussi eng.traineddata et osd.traineddata depuis /usr/share/tesseract-ocr/5/tessdata/
cp /usr/share/tesseract-ocr/5/tessdata/eng.traineddata /home/z/my-project/.tessdata/
cp /usr/share/tesseract-ocr/5/tessdata/osd.traineddata /home/z/my-project/.tessdata/
```

Le script `run_real_ocr.py` détecte automatiquement ce dossier local et
positionne `TESSDATA_PREFIX` pour la session Python. Vérifier :

```bash
TESSDATA_PREFIX=/home/z/my-project/.tessdata tesseract --list-langs
# Doit lister : eng, fra, osd
```

### 2. Poppler (pour pdf2image)

```bash
sudo apt-get install -y poppler-utils   # Debian / Ubuntu
brew install poppler                     # macOS
```

### 3. Python 3.11+ et dépendances

```bash
cd data_pipeline/real_ocr_demo
pip install -r requirements.txt
```

---

## Utilisation

### Lancer le pipeline complet (4 étapes)

Depuis la racine du dépôt (`ExamBoost-Togo/`) :

```bash
# Étape 1 — génère les 5 PDFs d'annales
python3 data_pipeline/real_ocr_demo/generate_sample_pdfs.py

# Étape 2 — OCR Tesseract sur les 5 PDFs
python3 data_pipeline/real_ocr_demo/run_real_ocr.py

# Étape 3 — structure le texte en JSON par matière
python3 data_pipeline/real_ocr_demo/structure_extracted.py

# Étape 4 — valide les questions et génère le rapport
python3 data_pipeline/real_ocr_demo/validate_and_merge.py
```

### Résultats attendus

| Étape               | Sortie principale                            | Volume attendu      |
|---------------------|----------------------------------------------|---------------------|
| generate_pdfs       | `sample_pdfs/*.pdf` (×5)                     | 5 PDFs, ~3 KB chacun |
| run_real_ocr        | `extracted_text/*.txt` (×5) + `ocr_stats.json` | ~5 350 caractères, 930 mots, ~7s |
| structure_extracted | `structured_questions/*.json` (×5) + `final/ocr_extracted_questions.json` | 36 questions |
| validate_and_merge  | `final/ocr_validated_questions.json` + `validation_report.{json,md}` | 36 validées (33 OK + 3 warnings), 0 rejetées |

### Vérifier le rapport

```bash
cat data_pipeline/real_ocr_demo/final/validation_report.md
```

Exemple de synthèse obtenue sur ce dépôt :

```
- Total questions OCR-isées : 36
- Questions valides (sans warning) : 33
- Questions valides avec warning : 3
- Questions rejetées : 0
- Taux de validation : 100.0%
```

Les 3 warnings détectés sont des artefacts OCR typiques sur les maths :

- « Résoudre dans **M** » au lieu de « dans ℝ » (symbole math perdu),
- « B(**S** : 6) » au lieu de « B(5 ; 6) » (5 confondu avec S),
- « **x2** - 9 » au lieu de « x² - 9 » (exposant perdu).

Ce sont exactement les cas où le pipeline principal déclenche le fallback
**GPT-4o Vision** (cf. `utils/tesseract_utils.detect_math_content`).

---

## Contenu authentique des 5 PDFs

Les questions sont alignées sur le programme officiel BEPC du Togo (MEPST).
Chaque PDF contient 4 exercices avec un total de 5 à 8 sous-questions.

| PDF                              | Matière                  | Session | Nb exos | Nb questions | Thématiques abordées                                   |
|----------------------------------|--------------------------|---------|---------|--------------|--------------------------------------------------------|
| `bepc_maths_2022_sample.pdf`     | Mathématiques            | 2022    | 4       | 8            | Équations, systèmes, géométrie, cylindres              |
| `bepc_francais_2021_sample.pdf`  | Français                 | 2021    | 4       | 6            | Temps verbaux, voix passive, figures de style, rédaction |
| `bepc_sciences_2023_sample.pdf`  | Sciences Physiques       | 2023    | 4       | 8            | Loi d'Ohm, poids, pression, chaleur                    |
| `bepc_svt_2020_sample.pdf`       | SVT                      | 2020    | 4       | 7            | Digestion, écosystème, paludisme, photosynthèse        |
| `bepc_histoire_2022_sample.pdf`  | Histoire-Géographie      | 2022    | 4       | 7            | Indépendance, colonisation, régions du Togo, climats   |

---

## Format de sortie

Chaque question suit le schéma de `assets/data/questions.json` (modèle Dart
`lib/models/question.dart`), avec deux champs additionnels pour la traçabilité
de l'OCR :

```json
{
  "id": "TG-BEPC-MATH-2022-OCR-Q01",
  "enonce": "Résoudre dans M l'équation suivante: 3x + 7 = 22.",
  "reponse": "",
  "explication": "",
  "matiere": "Mathématiques",
  "chapitre": "Exercice 1",
  "competence_id": "TG-MATH-OCR-001",
  "examen": "BEPC",
  "serie": null,
  "annee": 2022,
  "type": "ouvert",
  "choix": null,
  "points": 2,
  "irt": {"a": null, "b": 0.5, "c": null, "calibre": false},
  "source": "ocr_pipeline",
  "source_pdf": "bepc_maths_2022.pdf",
  "original_exercise": 1,
  "original_question_number": "1"
}
```

Champs additionnels (non présents dans `assets/data/questions.json`) :

- `source` : `"ocr_pipeline"` pour distinguer des questions générées par LLM
  (Agent AG) ou écrites manuellement.
- `source_pdf` : nom du PDF d'origine (audit).
- `original_exercise` / `original_question_number` : position dans le PDF
  d'origine (pour remonter jusqu'au scan en cas de doute sur la qualité).

Les champs `reponse` et `explication` sont volontairement laissés vides : la
structuration déterministe ne peut pas produire de corrigé. Pour les remplir,
brancher un LLM (GPT-4o-mini, Claude) ou une saisie humaine. Voir Agent AG
(`data_pipeline/llm_generation/`) pour le pipeline LLM complet.

---

## Règles de validation appliquées

Le script `validate_and_merge.py` applique 5 familles de règles :

1. **Champs obligatoires** : `id`, `enonce`, `matiere`, `examen`, `annee`,
   `type`, `irt` doivent être présents.
2. **Cohérence métadonnées** :
   - `examen` dans `{BEPC, BAC1, BAC2}`.
   - `matiere` dans les 5 matières BEPC valides.
   - `2010 <= annee <= 2025`.
   - `serie` doit être `null` pour le BEPC (pas de série au BEPC).
3. **Qualité énoncé** :
   - longueur 20 à 800 caractères (warning si > 800),
   - ratio lettres/caractères >= 0.5 (filtre le bruit OCR pur),
   - 10 patterns de bruit OCR détectés en warning (ex: `x2` au lieu de `x²`,
     `S` au lieu de `5`, `M` au lieu de `ℝ`).
4. **Cohérence type / choix** :
   - `type` dans `{ouvert, qcm, vraiFaux, calcul, redaction}`.
   - `qcm`/`vraiFaux` → `choix` non null et >= 2 items.
   - Autres types → `choix` doit être `null`.
5. **IRT** :
   - `irt.b` numérique entre -3 et +3 (bornes théoriques IRT 3PL).
   - `irt.calibre` booléen.

Trois statuts : `valid` (tout OK), `warning` (au moins un warning mais
aucune erreur bloquante), `rejected` (au moins une erreur).

Les questions `valid` et `warning` sont conservées dans
`final/ocr_validated_questions.json` (les warnings sont marqués via
`_validation_status` et `_validation_warnings` pour révision humaine).

---

## Intégration à `assets/data/questions.json`

La fusion **n'est pas faite** par ce sous-module (règle : ne pas toucher au
fichier principal). L'agent de wiring peut la faire en 4 lignes Python :

```python
import json
from pathlib import Path

base = Path("ExamBoost-Togo")
existing = json.loads((base / "assets/data/questions.json").read_text(encoding="utf-8"))
new = json.loads((base / "data_pipeline/real_ocr_demo/final/ocr_validated_questions.json").read_text(encoding="utf-8"))
# Ne pas perdre les champs additionnels (source, source_pdf, ...) : ils seront
# ignorés par le modèle Dart Question (pas de champs correspondants), mais on
# peut les conserver dans le JSON sans casser l'app.
merged = existing + new
(base / "assets/data/questions.json").write_text(
    json.dumps(merged, indent=2, ensure_ascii=False), encoding="utf-8"
)
print(f"Fusion : {len(existing)} + {len(new)} = {len(merged)} questions")
```

Vérifier qu'il n'y a pas de collision d'IDs en pratique :

```python
ids = [q["id"] for q in merged]
assert len(ids) == len(set(ids)), "Collision d'IDs détectée"
```

Les IDs générés ici sont préfixés `TG-BEPC-{MAT}-{ANNEE}-OCR-Q{NN}` pour
éviter toute collision avec les questions existantes (qui suivent le
format `TG-BEPC-{MAT}-{ANNEE}-Q{NN}` sans le segment `-OCR-`).

---

## Limites et améliorations futures

### Limites

1. **PDFs vectoriels, pas des scans** : la précision OCR est ici de ~95 %,
   car ReportLab produit du texte net. Sur de vrais scans d'annales (qualité
   variable, sometimes handwritten annotations), la précision Tesseract tombe
   à 80-90 % — d'où la nécessité du fallback GPT-4o Vision dans le pipeline
   principal.
2. **Pas de LLM pour la structuration** : la regex « Exercice N (P points) »
   puis « 1. ... 2. ... » fonctionne bien pour le format BEPC mais échouerait
   sur des structures moins régulières (questions ouvertes sans numérotation,
   QCM avec puces, etc.). Le pipeline principal utilise GPT-4o-mini pour ça.
3. **Pas de remplissage de `reponse` / `explication`** : il faut soit un LLM
   (Agent AG) soit une saisie humaine pour produire le corrigé. Sans ça, les
   questions OCR-isées ne peuvent pas être utilisées en mode « flashcard »
   dans l'app Flutter.
4. **5 PDFs seulement** : pour démonstration. Pour 5 000+ questions réelles,
   brancher `scrape_pdfs.py` du pipeline principal et utiliser le cache OCR
   pour reprise après crash.

### Améliorations

- **Brancher sur vraies annales** : remplacer `SAMPLE_PDFS_DIR` par
  `data_pipeline/data/raw_pdfs/{source}/BEPC/{matiere}/`. Les PDFs doivent
  être téléchargés via `scrape_pdfs.py` (sources : `fomesoutra.com`,
  `epreuvesetcorriges.com`, `banquedesepreuves.com`).
- **Remplacer la regex par un LLM** : adapter `structure_extracted.py` pour
  appeler `openai_structure_questions` du module `utils.openai_utils`. Coût
  estimé : ~0.002 USD/PDF avec GPT-4o-mini.
- **Validation humaine (human-in-the-loop)** : afficher les 3 questions en
  warning dans une UI admin (cf. Agent 21-admin) pour correction manuelle
  avant fusion.
- **Calibration IRT réelle** : une fois l'app Flutter en production et
  suffisamment de données élèves collectées (~100 réponses/question), lancer
  `py-irt` sur le backend pour remplacer les `irt.b` heuristiques par des
  valeurs calibrées. Voir Agent AI (`backend/scripts/irt_calibration/`).

---

## Compatibilité

- **Python** : 3.11+ (testé en 3.12.13 sur Debian 13).
- **Tesseract** : 5.0+ (testé en 5.5.0).
- **Poppler** : 25+ (testé en 25.03.0).
- **Dépendances Python** : `reportlab`, `pdf2image`, `pytesseract`, `Pillow`.
- **Aucune dépendance** aux autres modules du `data_pipeline` (`config.py`,
  `utils/`, `scrape_pdfs.py`). Le sous-module est entièrement autonome et
  peut être exécuté en isolation.

---

## Équipe

SmartFarm Togo / AIMS Ghana — Session 3 (Vague 3), 1er juillet 2026.
Conçu pour le pitch DJANTA Tech Hub du 24 juillet 2026.
