# Pipeline OCR ExamBoost Togo

Pipeline Python d'OCR et de structuration automatique des annales togolaises
(BEPC, BAC series A/B/C/D/F, annees 2010-2025). Transforme les PDFs scannes
en questions JSON prêtes à être intégrées dans l'app Flutter.

Objectif : passer de **20 questions de démo** à **5000+ questions** couvrant
toutes les matières du BEPC et du BAC, de manière reproductible et auditable.

---

## Vue d'ensemble

```
              +-----------------+
              |  scrape_pdfs    |  requests + BeautifulSoup
              |  (5 sources)    |  -> data/raw_pdfs/{source}/{examen}/{matiere}/{annee}.pdf
              +--------+--------+
                       |
                       v
              +--------+--------+
              |  ocr_extract    |  pdf2image (300 dpi) -> Tesseract (fra)
              |  Tesseract+V    |  -> fallback GPT-4o Vision si maths detectees
              +--------+--------+  -> data/extracted_text/{id}.txt
                       |
                       v
              +--------+--------+
              | structure_q     |  GPT-4o-mini, prompt structure
              |  (LLM)          |  -> data/structured_questions/{src}_{annee}_{matiere}.json
              +--------+--------+
                       |
                       v
              +--------+--------+
              | validate_q      |  jsonschema + regles metier + detection doublons
              |                 |  -> data/final/validation_report.md
              +--------+--------+
                       |
                       v
              +--------+--------+
              |  deduplicate    |  SimHash 64 bits + distance de Hamming
              |                 |  -> data/final/questions_dedup.json
              +--------+--------+
                       |
                       v
              +--------+--------+
              |  estimate_irt   |  b = inv_norm(1 - taux_reussite) si historique
              |                 |  sinon heuristique (type + points + examen + serie)
              +--------+--------+
                       |
                       v
                 data/final/questions.json   <- pret pour assets/data/questions.json
```

---

## Installation

### 1. Dépendances système

```bash
# Debian/Ubuntu
sudo apt-get install -y tesseract-ocr tesseract-ocr-fra poppler-utils

# macOS
brew install tesseract tesseract-lang poppler
```

### 2. Environnement Python

```bash
cd data_pipeline
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

### 3. Configuration

```bash
cp .env.example .env
# Editer .env et renseigner OPENAI_API_KEY=sk-...
```

### 4. Vérification

```bash
python -m pytest tests/ -v
# 57 tests attendus en succes
```

---

## Usage

### Lancer tout le pipeline

```bash
python run_pipeline.py --full
```

### Cibler une source / année / matière

```bash
python run_pipeline.py \
    --source epreuvesetcorriges \
    --year 2022 \
    --matiere Mathématiques
```

### Reprendre après une interruption

Le pipeline est **resumable** : le manifeste `data/raw_pdfs/manifest.json` et
le cache OCR `data/.ocr_cache/` évitent de retélécharger / retraiter les PDFs
déjà vus.

```bash
# Skip le scrape, reprendre à l'OCR
python run_pipeline.py --from-ocr

# Skip scrape + OCR, reprendre à la structuration
python run_pipeline.py --from-structure

# Ne lancer que certaines étapes
python run_pipeline.py --only dedup,irt
```

### OCR précis pour les maths (plus cher)

```bash
python run_pipeline.py --from-ocr --use-vision-only
# Bypass Tesseract : GPT-4o Vision sur chaque page.
# Cout ~0.01 USD/page, ~15 USD pour 1500 pages.
```

### Scripts individuels

```bash
python scrape_pdfs.py --source epreuvesetcorriges --dry-run
python ocr_extract.py --pdf data/raw_pdfs/epreuvesetcorriges/BEPC/Mathematiques/2022_C.pdf
python structure_questions.py --file data/extracted_text/foo.txt
python validate_questions.py --strict
python deduplicate.py --threshold 9
python estimate_irt.py --history data/history_responses.csv
```

---

## Coûts estimés

| Phase                   | Modèle         | Volume estimé | Coût unitaire | Coût total |
|-------------------------|----------------|---------------|---------------|------------|
| OCR Vision (fallback)   | gpt-4o         | ~450 pages*   | ~0.01 USD/page | ~4.5 USD   |
| OCR Vision (mode full)  | gpt-4o         | 1500 pages    | ~0.01 USD/page | ~15 USD    |
| Structuration LLM       | gpt-4o-mini    | ~300 PDFs     | ~0.002 USD/PDF | ~0.6 USD   |
| **Total (mode hybride)**|                |               |               | **~5 USD** |

\* En mode hybride (Tesseract + fallback Vision uniquement sur pages avec
maths), on estime qu'environ 30% des pages déclenchent le fallback Vision.

Budget planifié : **15 USD** couvrent largement un scan complet + marge.

---

## Pipeline de qualité

1. **Validation schéma** (`validate_questions.py`) : chaque question est
   validée contre un JSON Schema strict + règles métier (BEPC → serie null,
   BAC → serie non null, QCM → choix >= 2, etc.).
2. **Détection doublons** : hash SimHash 64 bits sur l'énoncé normalisé
   (lowercase, sans accents, sans ponctuation, shingles de 3 mots). Distance
   de Hamming <= 9 (~85% de similarité) → doublon.
3. **Déduplication intelligente** : sur chaque cluster de doublons, on garde
   la version la plus complète (score 0-5 : enonce + reponse + explication +
   points + IRT).
4. **Rapport Markdown** : `data/final/validation_report.md` contient les
   statistiques (valides/invalides/doublons/suspects), la répartition par
   examen/matière/année, et des exemples concrets d'erreurs.

---

## Format de sortie

Fichier `data/final/questions.json`, conforme au modèle Dart
`lib/models/question.dart` :

```json
[
  {
    "id": "TG-BEPC-MATHS-2022-Q01",
    "enonce": "Résoudre l'équation : 3x + 7 = 22",
    "reponse": "x = 5",
    "explication": "On soustrait 7 des deux membres...",
    "matiere": "Mathématiques",
    "chapitre": "Équations du premier degré",
    "competence_id": "TG-MATHS-EQ1D-001",
    "examen": "BEPC",
    "serie": null,
    "annee": 2022,
    "type": "calcul",
    "choix": null,
    "points": 4,
    "irt": {"a": null, "b": -0.5, "c": null, "calibre": false}
  }
]
```

### Conventions d'ID

| Examen     | Série       | Format d'ID                     | Exemple                       |
|------------|-------------|---------------------------------|-------------------------------|
| BEPC       | (null)      | `TG-BEPC-{MAT}-{ANNEE}-Q{NN}`   | `TG-BEPC-MATHS-2022-Q01`     |
| BAC1/BAC2  | A, B, C, D, F (Maths) | `TG-BAC-MATH{SERIE}-{ANNEE}-Q{NN}` | `TG-BAC-MATHC-2023-Q01` |
| BAC1/BAC2  | (autre matiere) | `TG-BAC-{MAT}-{ANNEE}-Q{NN}` | `TG-BAC-PHYS-2023-Q01`       |

### Estimation IRT

- Si historique de réponses disponible (`--history-csv`) :
  `b = inv_norm(1 - taux_reussite)`
- Sinon, heuristique :
  - `calcul` → +0.5, `qcm` → 0.0, `ouvert` → +0.3, `vraiFaux` → -0.2, `redaction` → +0.8
  - +0.3 si points == 5
  - +0.4 si BAC (vs BEPC)
  - +0.2 si série C ou D (scientifique)
  - -0.1 si explication absente

Le champ `irt.calibre` reste `false` tant que la calibration réelle
(py-irt sur le backend) n'a pas tourné.

---

## Sources d'annales

| Source                  | URL                                            | Couverture                       |
|-------------------------|------------------------------------------------|----------------------------------|
| epreuvesetcorriges      | epreuvesetcorriges.com                         | BEPC + BAC Togo, 2010-2025       |
| banquedesepreuves       | banquedesepreuves.com                          | Togo + Bénin + CI, 2015-2024     |
| examens-concours        | examens-concours.net                           | BAC Maths série C Togo           |
| fomesoutra              | fomesoutra.com                                 | BEPC sujets + corrigés           |
| digischool Afrique      | afrique.digischool.fr                          | BAC Afrique de l'Ouest           |

Toutes les sources sont respectueuses de `robots.txt` (vérifié via
`urllib.robotparser`) avec un délai minimum de 1 s entre requêtes.

---

## Structure des dossiers

```
data_pipeline/
├── README.md                       # Ce fichier
├── requirements.txt
├── .env.example
├── .gitignore
├── config.py                       # Sources, chemins, modeles LLM, seuils
├── scrape_pdfs.py                  # Telechargement PDFs
├── ocr_extract.py                  # OCR Tesseract + GPT-4o Vision
├── structure_questions.py          # LLM -> JSON structure
├── validate_questions.py           # Validation schema + qualite
├── deduplicate.py                  # SimHash deduplication
├── estimate_irt.py                 # Estimation IRT b
├── run_pipeline.py                 # Orchestrateur CLI
├── utils/
│   ├── __init__.py
│   ├── pdf_utils.py                # pdf2image wrappers
│   ├── tesseract_utils.py          # Tesseract config + heuristique maths
│   ├── openai_utils.py             # GPT-4o Vision + GPT-4o-mini
│   └── json_utils.py               # Schema + validation Question
├── data/
│   ├── raw_pdfs/                   # PDFs telecharges (gitignored)
│   ├── extracted_text/             # Texte OCR brut
│   ├── structured_questions/       # JSON intermediaires par matiere
│   ├── final/                      # questions.json final + rapport
│   └── .ocr_cache/                 # Cache OCR (json par PDF)
└── tests/
    ├── conftest.py
    ├── test_ocr.py                 # 14 tests (Tesseract, maths, cache, cout)
    └── test_structure.py           # 43 tests (schema, dedup, IRT, etc.)
```

---

## Limitations connues

- Les sources `epreuvesetcorriges.com` et `fomesoutra.com` peuvent nécessiter
  un user-agent spécifique ou une authentification. Le scraper gère le
  `robots.txt` et le rate-limiting, mais certains sites peuvent bloquer
  en pratique. Prévoir une solution manuelle de secours (upload direct).
- Tesseract peut rater les formules mathématiques complexes (intégrales,
  sommes) — le fallback GPT-4o Vision est conçu pour ces cas.
- L'estimation IRT heuristique est **initiale** : la calibration réelle
  doit se faire via `py-irt` sur le backend (cf. tâche `6-backend`), une
  fois que l'app aura collecté suffisamment de données d'élèves (~100
  réponses par question).

---

## Roadmap

- [ ] Ajouter un scraper pour ` Moodle ISTL Lomé` (annales internes).
- [ ] Support OCR pour tableaux complexes (PyMuPDF + table transformer).
- [ ] Fine-tuning d'un modèle open-source (Donut, Nougat) pour remplacer
      GPT-4o Vision et réduire les coûts à long terme.
- [ ] Boucle de calibration IRT automatique (backend FastAPI + py-irt).

---

## Équipe

SmartFarm Togo / AIMS Ghana — Juin 2026
Pipeline conçu pour le pitch DJANTA Tech Hub (24 juillet 2026).
