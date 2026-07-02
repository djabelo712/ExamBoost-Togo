# ML Training — Pipeline XGBoost pour prediction du score BEPC/BAC

Pipeline complet d'entrainement, d'evaluation et d'explicabilite (SHAP) d'un
modele XGBoost predist le score final (0-20) d'un eleve togolais au BEPC ou BAC,
a partir de ses donnees d'apprentissage dans l'application ExamBoost Togo.

## Objectif

Disposer d'un modele de regression pret pour la production, avec :

- Un **dataset synthetique realiste** de 5000 eleves (correlations reproduisant
  la litterature EdTech : BKT, SRS, effet "practice", regularite).
- Un **XGBoost Regressor** optimise par grid search 5-fold CV (54 combinaisons).
- Une **evaluation approfondie** : RMSE, MAE, R2, performance par segment,
  plots residuals + predicted-vs-actual + feature importance.
- Une **explicabilite SHAP** : summary plot, dependence plots, waterfalls pour
  3 eleves types (faible / moyen / fort).
- Une **model card** standard (Google Model Cards) pour transparence vis-a-vis
  des jurys DJANTA, investisseurs et enseignants.

## Installation

### 1. Creer un environnement virtuel (Python 3.11+)

```bash
cd backend/scripts/ml_training
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

### 2. Verifier les versions

```bash
python -c "import xgboost, sklearn, shap, matplotlib, pandas, numpy, seaborn, joblib; print('OK')"
```

## Workflow

Le pipeline se lance en 5 etapes (depuis le dossier `ml_training/`) :

```bash
# 1. Generer le dataset synthetique (5000 eleves, ~2 sec)
python generate_synthetic_students.py

# 2. Entrainer XGBoost avec grid search + CV 5-fold (~2-5 min)
python train_score_predictor.py

# 3. Evaluer le modele (RMSE, MAE, R2, plots, performance par segment)
python evaluate_model.py

# 4. Analyser SHAP (summary + dependence + waterfall)
python shap_analysis.py

# 5. Generer la model card markdown
python generate_model_card.py
```

A la fin, le dossier `output/` contient :

```
output/
├── synthetic_students.csv         # Dataset (5000 lignes x 15 colonnes)
├── trained_model.joblib           # Modele serialise (format production)
├── training_metrics.json          # Metriques + CV results + best params
├── evaluation_plots.png           # 3 plots : pred vs actual, residuals, distrib
├── feature_importance.png         # Feature importance XGBoost native
├── evaluation_report.md           # Rapport markdown d'evaluation
├── shap_summary.png               # SHAP summary (beeswarm, top 10)
├── shap_bar.png                   # SHAP bar plot (|SHAP| moyen)
├── shap_dependence_pL_global.png
├── shap_dependence_last_score_simulation.png
├── shap_dependence_pL_maths.png
├── shap_waterfall_faible.png      # SHAP waterfall eleve faible
├── shap_waterfall_moyen.png       # SHAP waterfall eleve moyen
├── shap_waterfall_fort.png        # SHAP waterfall eleve fort
└── model_card.md                  # Model card standard ML
```

## Remplacer les donnees synthetiques par de vraies donnees

Le simulateur `generate_synthetic_students.py` produit un dataset realiste mais
**synthetique**. Pour utiliser les vraies donnees du backend en production,
remplacer la fonction `generate_synthetic_students()` par un chargement depuis
la base PostgreSQL.

### Option A — Reutiliser le script existant

Le script `backend/scripts/train_score_model.py` (Agent F Session 1) construit
déjà un dataset a partir des tables `users`, `responses`, `simulations`. Pour
integrer les 14 features de ce pipeline :

1. Etendre `build_training_dataset()` dans `train_score_model.py` pour calculer
   aussi `pL_svt`, `pL_histoire`, `pL_anglais`, `total_questions_answered`,
   `streak_days`, `days_to_exam`.
2. Renommer la colonne cible de `score` a `score_final`.
3. Exporter en CSV vers `ml_training/output/synthetic_students.csv` (ou un
   nouveau nom, et adapter le `DATASET_PATH`).

### Option B — Requete SQL directe

```sql
-- Exemple : construire le dataset depuis PostgreSQL
SELECT
    u.id AS user_id,
    AVG(u.bkt_maitrise->>*) AS pL_global,        -- a adapter (JSON agg)
    AVG(... maths ...)     AS pL_maths,
    AVG(... francais ...)  AS pL_francais,
    AVG(... sciences ...)  AS pL_sciences,
    AVG(... svt ...)       AS pL_svt,
    AVG(... histoire ...)  AS pL_histoire,
    AVG(... anglais ...)   AS pL_anglais,
    COUNT(DISTINCT DATE(r.created_at))
        FILTER (WHERE r.created_at > NOW() - INTERVAL '7 days') AS sessions_7j,
    AVG(r.time_spent_sec)  AS avg_time_per_q,
    COUNT(DISTINCT s.id)   AS simulations_completed,
    (SELECT score FROM simulations
       WHERE user_id = u.id
       ORDER BY created_at DESC LIMIT 1) AS last_score_simulation,
    u.total_questions_answered,
    -- streak_days : calculer depuis lastActiveDate (a adapter)
    EXTRACT(DAY FROM u.last_active_date - u.date_inscription) AS streak_days,
    -- days_to_exam : estimer depuis niveauScolaire (a adapter)
    90 AS days_to_exam,
    -- Target : score de la DERNIERE simulation
    (SELECT score FROM simulations
       WHERE user_id = u.id
       ORDER BY created_at DESC LIMIT 1) AS score_final
FROM users u
LEFT JOIN responses r ON r.user_id = u.id
LEFT JOIN simulations s ON s.user_id = u.id
GROUP BY u.id
HAVING COUNT(s.id) > 0;  -- au moins une simulation pour avoir un target
```

Exporter en CSV avec `\copy (SELECT ...) TO 'output/synthetic_students.csv' CSV HEADER`
depuis `psql`.

## Frequence de re-entrainement

| Phase projet | Frequence | Source donnees | RMSE attendu |
|---|---|---|---|
| Pre-pilote (M1-M4) | Une fois (initial) | Synthetique 5000 | ~1.85 / 20 |
| Pilote (M5-M6) | Bi-mensuel | Synthetique + 100-500 vrais eleves | ~1.5 / 20 |
| Production (M7+) | Mensuel (cron) | 5000+ vrais eleves | ~1.0 / 20 |

### Seuils d'alerte

- **RMSE > 3.0** sur nouvelles donnees : recalibrer en urgence
- **Drift P(L) moyen > 0.15** vs training : investiguer + re-entrainer
- **% predictions hors [0, 20] > 1%** : bug critique

## Deploiement en production

### Etape 1 — Copier le modele serialise

```bash
cp backend/scripts/ml_training/output/trained_model.joblib \
   backend/services/models/trained_model.joblib
```

### Etape 2 — Adapter ml_service.py

Le fichier actuel `backend/services/ml_service.py` attend un modele a 8
features. Pour utiliser ce modele 14 features, ajouter dans `ml_service.py` :

```python
MODEL_PATH_14F = os.path.join(MODEL_DIR, "trained_model.joblib")

FEATURE_NAMES_14F = [
    "pL_global", "pL_maths", "pL_francais", "pL_sciences", "pL_svt",
    "pL_histoire", "pL_anglais", "sessions_7j", "avg_time_per_q",
    "simulations_completed", "last_score_simulation",
    "total_questions_answered", "streak_days", "days_to_exam",
]

def predict_score_14f(features_14):
    """Prediction avec le modele XGBoost 14 features."""
    if len(features_14) != len(FEATURE_NAMES_14F):
        return heuristic_score(...)
    model = _load_model_14f()
    X = np.array(features_14, dtype=float).reshape(1, -1)
    raw = float(model.predict(X)[0])
    return ScorePrediction(
        predicted_score=round(float(np.clip(raw, 0, 20)), 2),
        confidence=0.90,
        method="xgboost_14f",
    )
```

### Etape 3 — Construire le vecteur de features dans le router

Dans `routers/predict.py` (ou equivalent), construire les 14 features a partir
des tables `users`, `responses`, `simulations` :

```python
features = [
    user.scoreGlobal / 100,           # pL_global (0-1)
    pL_maths, pL_francais, pL_sciences, pL_svt, pL_histoire, pL_anglais,
    sessions_7j_count,
    avg_time_per_q,
    simulations_count,
    last_sim_score,
    user.totalQuestionsAnswered,
    streak_days,
    days_to_exam,
]
pred = ml_service.predict_score_14f(features)
```

### Etape 4 — Endpoint d'explicabilite (optionnel)

Pour exposer les SHAP values via l'API (transparence pour l'eleve) :

```python
@router.get("/predict/score/explain")
async def explain_score(user_id: str):
    """Retourne la prediction + les SHAP values par feature."""
    features = build_features_for_user(user_id)
    pred = ml_service.predict_score_14f(features)
    shap_vals = ml_service.compute_shap(features)  # a implementer
    return {
        "predicted_score": pred.predicted_score,
        "confidence": pred.confidence,
        "feature_contributions": dict(zip(FEATURE_NAMES_14F, shap_vals)),
    }
```

## Structure du code

```
ml_training/
├── __init__.py                      # Package marker
├── generate_synthetic_students.py   # Simulateur 5000 eleves
├── train_score_predictor.py         # XGBoost + grid search + CV
├── evaluate_model.py                # RMSE/MAE/R2 + plots + segments
├── shap_analysis.py                 # SHAP summary/dependence/waterfall
├── generate_model_card.py           # Model card ML standard
├── requirements.txt                 # Deps xgboost/shap/sklearn/...
├── README.md                        # Ce fichier
└── output/                          # Artefacts (genere par les scripts)
```

## Conventions

- **Python 3.11+** avec type hints (`from __future__ import annotations`)
- **Docstrings EN** (style Google) — conformité règle Session 3
- **Commentaires FR** (conformité règle Session 3)
- **Pas d'emojis** (conformité règle Session 3)
- **Palette vert Togo** : `#006837` (vert primaire) + `#D97700` (orange accent)
- **Reproductibilite** : `random_state=42` partout
- **Outputs** dans `./output/` (jamais a la racine)

## Tests rapides

Sans lancer le pipeline complet, on peut valider chaque module :

```bash
# 1. Test generate (rapide, ~2 sec)
python generate_synthetic_students.py --n 100

# 2. Test train (rapide, ~10 sec sur 100 samples)
python train_score_predictor.py
# Note: avec 100 samples, le grid search peut etre instable — pour un vrai
# test, utiliser n=5000 (default).

# 3. Test evaluate
python evaluate_model.py

# 4. Test SHAP (peut etre lent sur 5000 samples, OK sur 100)
python shap_analysis.py

# 5. Test model card
python generate_model_card.py
```

## Limitations connues

1. **Donnees synthetiques** : le simulateur reproduit les correlations de la
   litterature mais ne capture pas toute la variabilite reelle. **Recalibrer
   avec donnees pilote (M5-M6).**
2. **Pas de feature "qualite enseignement"** : ne distingue pas un eleve bien
   encadre d'un autodidacte.
3. **Pas de feature "stress"** : aucun signal pre-examen (sommeil, anxiete).
4. **Modele unique BEPC+BAC** : en production, prevoir un modele par examen.

## References

- Mitchell et al. (2019) — *Model Cards for Model Reporting* (FAT* 2019)
- Lundberg & Lee (2017) — *A Unified Approach to Interpreting Model Predictions*
  (NeurIPS 2017, SHAP)
- Chen & Guestrin (2016) — *XGBoost: A Scalable Tree Boosting System* (KDD 2016)
- Corbett & Anderson (1995) — *Knowledge Tracing: Modeling the Acquisition of
  Human Knowledge* (BKT)
