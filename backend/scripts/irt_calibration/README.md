# Calibration IRT 3PL — ExamBoost Togo

Pipeline Python complet pour **calibrer les parametres IRT (a, b, c)** de
chaque question a partir des donnees de reponses reelles collectees.
Genere des **ICC curves** (Item Characteristic Curves) en matplotlib, un
**rapport markdown** de qualite, et un nouveau `questions.json` avec les
parametres calibres (`irt.calibre = true`).

La formule IRT 3PL utilisee est strictement identique a celle implementee
cote Flutter (`lib/services/srs_service.dart`) et cote backend
(`backend/services/irt_service.py`) :

```
P(theta) = c + (1 - c) * 1 / (1 + exp(-1.7 * a * (theta - b)))
```

ou :
- **a** = discrimination (capacite de la question a differencier les eleves
  faibles des forts). Valeurs typiques : 0.3 a 2.5.
- **b** = difficulte (theta pour lequel P = (1+c)/2). Valeurs typiques :
  -3 (tres facile) a +3 (tres difficile).
- **c** = guessing (probabilite de reussite par chance pure, surtout pour
  les QCM). Valeurs typiques : 0 (question ouverte) a 1/k (QCM avec k choix).
- **theta** = niveau de competence de l'eleve, sur l'echelle -3 (faible)
  a +3 (fort). Moyenne 0, ecart-type 1.
- **1.7** = constante d'echelle logistique de Birnbaum (permet d'aligner
  l'echelle IRT logistique avec l'echelle normale standard).

---

## Structure du dossier

```
backend/scripts/irt_calibration/
├── __init__.py                       # Marqueur de package Python
├── generate_synthetic_data.py        # Genere 500 eleves x 50+ questions (demo)
├── calibrate_irt.py                  # Calibration principale (py-irt + numpy MLE)
├── analyze_calibration.py            # ICC curves + distributions + rapport
├── export_calibrated_questions.py    # Export questions.json calibre
├── requirements.txt                  # Dependances Python
├── README.md                         # Ce fichier
├── .gitignore                        # Ignore output/ et caches Python
└── output/                           # (gitignored) tous les artefacts
    ├── synthetic_responses.csv       # Donnees synthetiques
    ├── calibrated_params.json        # a, b, c par question + theta eleves
    ├── icc_curves/                   # 1 PNG par question (ICC)
    ├── parameter_distributions.png   # Histogrammes a, b, c
    ├── theta_distribution.png        # Distribution des theta eleves
    ├── ll_history.png                # Convergence log-vraisemblance
    ├── calibration_report.md         # Rapport markdown complet
    └── updated_questions.json        # questions.json avec irt.calibre=true
```

---

## Installation

```bash
cd backend/scripts/irt_calibration
pip install -r requirements.txt
```

**Python 3.11+** requis (testé sur 3.12).

> Note : `py-irt` est optionnel. Le pipeline fonctionne **sans** py-irt
> grace au fallback numpy MLE (estimation EM-like alternee). py-irt est
> utile si une API 3PL native est disponible (py-irt >= 0.2 theorique).
> Sur l'etat actuel de PyPI (py-irt 0.1.1, qui ne fournit que 1PL/2PL via
> Pyro), le fallback numpy MLE est automatiquement active.

---

## Workflow complet (4 etapes)

### Etape 1 : Generer ou collecter les donnees de reponses

#### Option A — Donnees synthetiques (pour demo / tests)

```bash
cd backend/scripts/irt_calibration
python generate_synthetic_data.py --n-students 500
```

Genere `output/synthetic_responses.csv` avec 500 eleves x 64 questions
= 32 000 reponses. Chaque eleve a un theta tire depuis N(0, 1), chaque
reponse est simulee selon la formule IRT 3PL avec les valeurs initiales
de `questions.json`, plus 5% de bruit.

#### Option B — Vraies donnees backend

Recuperer les reponses depuis l'endpoint backend `/sessions` ou directement
depuis la table `responses` en base. Le CSV doit contenir au minimum :

```csv
student_id,question_id,correct
user_001,TG-BEPC-MATHS-2022-Q01,1
user_001,TG-BEPC-MATHS-2022-Q02,0
...
```

Exemple de requete SQL :

```sql
SELECT user_id AS student_id, question_id, CAST(correct AS INT) AS correct
FROM responses
WHERE correct IS NOT NULL
ORDER BY user_id, question_id;
```

Exporter en CSV (via `psql --csv -c "..." > responses.csv` ou un script
Python avec `pandas.read_sql`).

### Etape 2 : Calibrer les parametres IRT

```bash
# Methode recommandee (py-irt si dispo, sinon fallback numpy automatique)
python calibrate_irt.py --input output/synthetic_responses.csv

# Methode forcee a numpy MLE (EM-like alterne)
python calibrate_irt.py --input output/synthetic_responses.csv --method numpy

# Methode forcee a py-irt
python calibrate_irt.py --input output/synthetic_responses.csv --method py-irt --iterations 1000
```

**Sortie** : `output/calibrated_params.json` contenant :

```json
{
  "metadata": {
    "method": "numpy-em-3pl",
    "n_iterations": 13,
    "final_log_likelihood": -16070.51,
    "convergence_achieved": true,
    "n_students": 500,
    "n_items": 64,
    "n_responses": 32000,
    "ll_history": [-16077.09, -16070.79, ...]
  },
  "item_params": [
    {
      "question_id": "TG-BEPC-MATHS-2022-Q01",
      "a": 1.321, "b": -0.437, "c": 0.0,
      "n_responses": 500,
      "p_observed": 0.688,
      "method": "numpy-em-3pl",
      "log_likelihood": -318.42
    },
    ...
  ],
  "student_params": [
    {"student_id": "synthetic_0000", "theta": -0.85, "n_responses": 64},
    ...
  ]
}
```

### Etape 3 : Analyser les resultats

```bash
python analyze_calibration.py
```

**Genere** :
- `output/icc_curves/<question_id>.png` : ICC curve par question (64 PNG)
- `output/parameter_distributions.png` : histogrammes de a, b, c
- `output/theta_distribution.png` : distribution des theta eleves
- `output/ll_history.png` : convergence de la log-vraisemblance
- `output/calibration_report.md` : rapport markdown complet

### Etape 4 : Exporter questions.json calibre

```bash
python export_calibrated_questions.py
```

**Genere** : `output/updated_questions.json` (copie de `questions.json` avec
`irt.a`, `irt.b`, `irt.c` mis a jour et `irt.calibre = true`).

L'administrateur (ou l'agent wiring) peut ensuite remplacer
`assets/data/questions.json` par ce fichier pour activer les parametres
calibres dans l'app Flutter.

---

## Brancher sur les vraies donnees backend

Le pipeline est designe pour etre agnostique a la source des donnees. Pour
utiliser les reponses reelles collectees par l'app via le backend FastAPI :

### Etape 1 — Exporter les reponses depuis la base

```python
# backend/scripts/irt_calibration/fetch_real_responses.py (a creer)
import pandas as pd
from sqlalchemy import create_engine, text

engine = create_engine("sqlite:///backend/examboost.db")  # ajuster l'URL
with engine.connect() as conn:
    df = pd.read_sql(text("""
        SELECT user_id AS student_id, question_id, correct
        FROM responses
        WHERE correct IS NOT NULL
    """), conn)

df.to_csv("output/real_responses.csv", index=False)
```

### Etape 2 — Lancer le pipeline normal

```bash
python calibrate_irt.py --input output/real_responses.csv
python analyze_calibration.py --responses output/real_responses.csv
python export_calibrated_questions.py
```

### Etape 3 — (Optionnel) Mettre a jour la base backend

Apres verification du rapport, on peut egalement mettre a jour les
colonnes `irt_a`, `irt_b`, `irt_c`, `irt_calibrated` de la table
`questions` via le script existant
`backend/scripts/calibrate_irt.py` (qui persiste en base) ou via
une requete SQL manuelle depuis `updated_questions.json`.

---

## Frequence recommandee

- **Recalibration mensuelle** recommandee en production.
- Minimum : **200 eleves par question** pour une calibration 3PL fiable
  (py-irt recommande 500+, notre fallback numpy MLE fonctionne des 100+
  avec une precision acceptable).
- Apres chaque ajout massif de nouvelles questions (>10) : recalibration
  immediate pour leur donner des parametres IRT (sinon `irt.calibre = false`
  et le SRS utilise `b` initial estime a la main).

---

## Critères de qualite

| Parametre | Bon | A surveiller | A retravailler |
|-----------|-----|--------------|----------------|
| **a** (discrimination) | 0.5 - 2.0 | 0.3 - 0.5 ou 2.0 - 2.5 | < 0.3 (non discriminant) |
| **b** (difficulte) | -1.5 a +1.5 | -2.5 a -1.5 ou +1.5 a +2.5 | |b| > 2.5 (trop extreme) |
| **c** (guessing) | 0 - 0.2 (ouvert/calcul) | 0.2 - 0.4 (QCM) | > 0.4 (trop de chance) |

Le rapport `calibration_report.md` liste automatiquement les questions a
retravailler selon ces criteres (section 7).

---

## Limites connues

1. **py-irt 0.1.1** (seule version publiee sur PyPI a ce jour) ne fournit
   que 1PL/2PL via Pyro. La 3PL native necessiterait py-irt >= 0.2 (non
   encore publie). Le script `calibrate_irt.py` detecte automatiquement
   l'API disponible et bascule sur le fallback numpy MLE (EM-like alterne)
   si necessaire.

2. **Echantillon minimum** : 200 eleves par question pour une calibration
   3PL fiable. En dessous, le parametre **c** (guessing) est difficile a
   estimer (il a tendance a etre sous-estime ou a 0). Avec 100 eleves,
   les parametres **a** et **b** sont correctement recupes (correlation
   > 0.9), mais **c** reste approximatif.

3. **Convergence EM** : la regularisation du prior sur theta (faible :
   N(0, sqrt(10)) pour stabiliser les eleves 0% / 100%) casse la
   monotonie EM stricte. Le test de convergence est donc base sur la
   stabilite des parametres (||params_new - params_old|| / ||params_old||
   < 5e-3), pas sur la LL. C'est plus robuste en pratique.

4. **Questions non repondues** : si un eleve n'a pas repondu a une
   question, la case correspondante dans la matrice de reponses est
   encodee a -1 et ignoree dans l'estimation. Pas d'imputation.

5. **Modele 3PL vs 2PL** : pour les questions ouvertes / calcul /
   redaction, on force c = 0 (pas de guessing possible). Seuls les QCM
   et vraiFaux ont c estime. Si on a peu de QCM dans la banque, le
   modele 2PL (c=0 pour tout) peut etre prefere (cf. py-irt 1PL/2PL).

6. **Identifiabilite** : l'echelle IRT est definie a une translation pres.
   On fixe la convention en imposant theta ~ N(0, 1) (prior faible dans
   l'E-step). Sans cette contrainte, theta et b peuvent derivent ensemble.

---

## Architecture technique

### Methode numpy MLE (EM-like alterne)

1. **Initialisation** :
   - theta = 0 pour tous les eleves
   - a = 1.0 pour tous les items
   - b = -probit(taux de reussite observe) pour tous les items
   - c = 0.2 pour QCM/vraiFaux, 0 sinon

2. **E-step** (vectorise sur tous les eleves) :
   - Calcule la log-vraisemblance de chaque eleve sur une grille de 61
     valeurs de theta dans [-3, +3] en une multiplication matricielle.
   - Raffine par Nelder-Mead autour du best de la grille (50 iterations max).
   - Prior faible N(0, sqrt(10)) pour stabiliser.

3. **M-step** (par item) :
   - Optimise (a, b, c) par L-BFGS-B avec bornes physiques.
   - Bornes : a in [0.2, 2.5], b in [-3, 3], c in [0, 0.5].
   - Regularisation faible : 0.01 * (a-1)^2 + 0.01 * (c-0.2)^2.

4. **Convergence** : stabilite des parametres (rel change < 5e-3) ou
   25 iterations max.

### Performance

- 500 eleves x 64 questions x 25 iter (max) = ~15 secondes sur CPU standard
- 1000 eleves x 100 questions x 25 iter = ~1 minute
- 5000 eleves x 200 questions x 25 iter = ~10 minutes (estime)

### Reproductibilite

- `generate_synthetic_data.py` utilise `--seed 42` par defaut.
- `calibrate_irt.py` est deterministe (initialisation fixe).
- Les PNG sont generes en 100 DPI (reglable via `--dpi`).

---

## Exemple de sortie ICC

Chaque PNG `icc_curves/<question_id>.png` contient :

- La **courbe ICC theorique** (en vert Togo #006837) : P(theta) selon
  la formule 3PL avec les parametres calibres.
- Les **lignes de reference** :
  - Ligne orange horizontale a `c` (guessing floor)
  - Ligne verte verticale a `b` (difficulte, point median)
- Le **point d'inflexion** a (b, (1+c)/2) en orange (markersize 10).
- Les **points observes** (en rouge, taille proportionnelle au n) :
  taux de reussite par bin de theta (7 bins sur [-3, 3]).
- Un **label de qualite** en bas a droite : "OK" ou "A surveiller :
  a faible / c eleve / b extreme".

---

## Tests rapides (sans pytest)

```bash
# Smoke test : tout le pipeline en 30 secondes
cd backend/scripts/irt_calibration
python generate_synthetic_data.py --n-students 100 --quiet
python calibrate_irt.py --method numpy --max-iter 5
python analyze_calibration.py --dpi 80
python export_calibrated_questions.py
ls output/
ls output/icc_curves/ | head -5
cat output/calibration_report.md | head -40
```

---

## Integration avec le reste du projet

- **Flutter** : le fichier `output/updated_questions.json` est un drop-in
  replacement de `assets/data/questions.json`. L'app Flutter lira
  automatiquement `irt.a`, `irt.b`, `irt.c`, `irt.calibre` via le factory
  `Question.fromJson` de `lib/models/question.dart`. Les champs
  supplementaires (`methode_calibration`, `n_reponses_calibration`) sont
  ignores par Dart (forward-compatible).

- **Backend FastAPI** : le service `backend/services/irt_service.py`
  expose deja `calibrate_irt()` (probit fallback) et `_calibrate_with_pyirt()`.
  Le pipeline present (`backend/scripts/irt_calibration/`) est plus complet
  (EM-like 3PL + ICC + rapport) et peut etre appele periodiquement (cron,
  Celery beat) pour recalibration mensuelle. Le script
  `backend/scripts/calibrate_irt.py` (existant) peut etre remplace par un
  appel a ce pipeline avec persistence en base via SQLAlchemy.

- **SRS Dart** : `lib/services/srs_service.dart` utilise deja `irtB` dans
  `selectBestQuestion()` (choisit la question dont la difficulte b est la
  plus proche du theta de l'eleve). Avec les parametres calibres, cette
  selection sera beaucoup plus precise.

---

## Contact

- Auteur : **Agent AI** (Session 3, Vague 2 — Task ID `AI-irt-calibration`)
- Projet : ExamBoost Togo
- Repo : https://github.com/djabelo712/ExamBoost-Togo
