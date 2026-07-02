# Model Card : ExamBoost Score Predictor

## Details du modele

| Champ | Valeur |
|---|---|
| **Type** | XGBoost Regressor (gradient boosted trees) |
| **Version** | 1.0.0 |
| **Date d'entrainement** | 2026-07-01 |
| **Auteurs** | ExamBoost Togo Team (Agent AJ, Session 3 Vague 2) |
| **Licence** | MIT |
| **Objectif** | Predire le score final (0-20) d'un eleve au BEPC ou BAC togolais |
| **Framework** | xgboost 2.1.3 + scikit-learn 1.5.2 |

## Description

Le modele predit le score final qu'un eleve obtiendra a l'examen national
(BEPC ou BAC), a partir de son historique d'apprentissage dans l'application
ExamBoost Togo. Les features sont derivees du BKT (Bayesian Knowledge Tracing),
du SRS (Spaced Repetition System SM-2) et des metriques d'engagement
(simulations, regularite, streak).

## Donnees d'entrainement

| Champ | Valeur |
|---|---|
| **Source** | Donnees synthetiques (5,000 profils eleves generes) |
| **Distribution** | Simulee avec correlations realistes entre P(L) et score final |
| **Biais connus** | Donnees synthetiques : a recalibrer avec donnees reelles du pilote (M5-M6) |
| **Cible** | `score_final` (0-20), combinaison lineaire + bruit gaussien sigma=1.5 |
| **Split** | 80% train / 20% test (random_state=42) |
| **Validation croisee** | 5-fold sur le train set |

### Notes sur la generation synthetique

Le simulateur reproduit les correlations observees dans la litterature
EDTech :

- P(L) maths / sciences / svt sont correlees (sciences exactes)
- P(L) francais / histoire sont correlees (lettres)
- P(L) anglais reste independant
- Le score de derniere simulation est fortement correle avec P(L) global
  (effet "practice effect" classique)

## Features (14)

| # | Feature | Description | Source |
|---|---|---|---|
| 1 | `pL_global` | Moyenne P(L) BKT toutes matieres | user.dart (BKT) |
| 2 | `pL_maths` | P(L) moyen en mathematiques | user.bktMaitrise filtre |
| 3 | `pL_francais` | P(L) moyen en francais | user.bktMaitrise filtre |
| 4 | `pL_sciences` | P(L) moyen en sciences physiques | user.bktMaitrise filtre |
| 5 | `pL_svt` | P(L) moyen en SVT | user.bktMaitrise filtre |
| 6 | `pL_histoire` | P(L) moyen en histoire-geo | user.bktMaitrise filtre |
| 7 | `pL_anglais` | P(L) moyen en anglais | user.bktMaitrise filtre |
| 8 | `sessions_7j` | Nombre de sessions sur les 7 derniers jours | backend Response table |
| 9 | `avg_time_per_q` | Temps moyen par question (sec) | backend Response table |
| 10 | `simulations_completed` | Nombre de simulations d'examen realises | backend Simulation table |
| 11 | `last_score_simulation` | Score de la derniere simulation (0-20) | backend Simulation table |
| 12 | `total_questions_answered` | Total de questions repondues | user.totalQuestionsAnswered |
| 13 | `streak_days` | Jours consecutifs d'activite | calcule sur lastActiveDate |
| 14 | `days_to_exam` | Jours restants avant l'examen | user.niveauScolaire + date |

## Hyperparametres optimaux (grid search)

```python
{
  "learning_rate": 0.01,
  "max_depth": 3,
  "n_estimators": 500,
  "subsample": 0.8
}
```

Grille exploree : `max_depth` in [3, 5, 7] x `learning_rate` in [0.01, 0.1, 0.3]
x `n_estimators` in [100, 200, 500] x `subsample` in [0.8, 1.0] = 54 combinaisons.

## Performance

### Metriques globales (test set)

| Metrique | Valeur | Interpretation |
|---|---|---|
| **RMSE** | 1.466 / 20 | Erreur quadratique moyenne |
| **MAE**  | 1.183 / 20 | Erreur absolue moyenne |
| **R2**   | 0.663 | Variance expliquee (66.3%) |
| **CV RMSE** | 1.510 +/- 0.284 | Validation croisee 5-fold |

### Top 5 features par importance

| Rang | Feature | Importance |
|---|---|---|
| 1 | `pL_global` | 0.6705 |
| 2 | `last_score_simulation` | 0.0530 |
| 3 | `pL_francais` | 0.0402 |
| 4 | `pL_maths` | 0.0332 |
| 5 | `pL_sciences` | 0.0309 |

### Performance par segment d'eleve

Voir `evaluation_report.md` pour le detail par segment (Faible / Moyen / Bon /
Excellent). En general, le modele est le plus precis dans le segment Moyen
(8-12/20) qui contient le plus d'eleves, et peut sous-estimer le segment
Excellent (16-20) si sous-represente.

## Limitations

1. **Donnees synthetiques** : le modele est entraine sur 5000 profils simules.
   Les correlations reproduisent la litterature mais ne capturent pas toute la
   variabilite reelle des eleves togolais. **Recalibrer avec donnees pilote.**
2. **Effet stress non modelise** : aucune feature ne capture l'anxiete le jour
   de l'examen, qui peut faire varier le score de +/- 2 points.
3. **Contexte socio-economique absent** : pas de feature sur le milieu
   (urbain/rural), l'acces a l'electricite, la langue maternelle, etc.
4. **Biais temporel** : le modele suppose que les P(L) restent stables entre la
   mesure et l'examen. En realite, ils peuvent evoluer (revision intensive,
   decrochage).
5. **Pas de feature "qualite de l'enseignement"** : ne distingue pas un eleve
   bien encadre d'un eleve autodidacte.
6. **Pas de prise en compte du niveau scolaire** : le meme modele sert pour le
   BEPC et le BAC. En production, on pourrait avoir un modele par examen.

## Usage

### En production (backend FastAPI)

```python
import joblib
import numpy as np

# Chargement au demarrage de l'API
data = joblib.load('backend/services/models/trained_model.joblib')
model = data['model']
features = data['features']

# Prediction pour un eleve
student_features = np.array([
    0.65,  # pL_global
    0.70,  # pL_maths
    0.60,  # pL_francais
    0.55,  # pL_sciences
    0.50,  # pL_svt
    0.65,  # pL_histoire
    0.55,  # pL_anglais
    7,     # sessions_7j
    18.5,  # avg_time_per_q
    4,     # simulations_completed
    12.5,  # last_score_simulation
    250,   # total_questions_answered
    9,     # streak_days
    45,    # days_to_exam
])
score_predite = float(np.clip(model.predict(student_features.reshape(1, -1))[0], 0, 20))
print(f"Score predit : {score_predite:.2f} / 20")
```

### Integration avec ml_service.py

Le fichier `backend/services/ml_service.py` attend un modele a 8 features. Pour
integrer ce modele a 14 features, ajouter dans `ml_service.py` :

```python
MODEL_PATH_14F = os.path.join(MODEL_DIR, "trained_model.joblib")

FEATURE_NAMES_14F = [
    "pL_global", "pL_maths", "pL_francais", "pL_sciences", "pL_svt",
    "pL_histoire", "pL_anglais", "sessions_7j", "avg_time_per_q",
    "simulations_completed", "last_score_simulation",
    "total_questions_answered", "streak_days", "days_to_exam",
]
```

Et adapter `predict_score()` pour utiliser ce chemin si le modele 14 features
est present (prioriser le modele le plus riche).

## Monitoring et maintenance

| Indicateur | Seuil d'alerte | Action |
|---|---|---|
| RMSE sur nouvelles donnees | > 3.0 / 20 | Recalibrer le modele |
| Drift P(L) moyen | > 0.15 vs training | Investiguer + re-entrainer |
| % predictions hors [0, 20] | > 1% | Bug critique, investiguer |
| Frequence re-entrainement | Mensuel | Cron job planifie |

### Pipeline de re-entrainement

```bash
cd backend/scripts/ml_training
python generate_synthetic_students.py   # ou charger vraies donnees
python train_score_predictor.py
python evaluate_model.py
python shap_analysis.py
python generate_model_card.py
# Copier output/trained_model.joblib -> backend/services/models/
```

## Considerations ethiques

- **Equite** : le modele ne doit pas etre utilise pour orienter les eleves de
  maniere definitive. Il s'agit d'un **outil d'aide**, pas d'un juge.
- **Transparence** : les SHAP values permettent d'expliquer chaque prediction a
  l'eleve (cf. `shap_waterfall_*.png`).
- **Privee** : les features sont anonymisees (pas de nom, pas d'etablissement).
- **Recours** : tout eleve peut demander l'explication de sa prediction via
  l'API `/predict/score?explain=true` (a implementer, retourne les SHAP).

## References

1. Mitchell, M., Wu, S., Zaldivar, A., et al. (2019). *Model Cards for Model
   Reporting.* FAT* 2019.
2. Corbett, A. T., & Anderson, J. R. (1995). *Knowledge Tracing: Modeling the
   Acquisition of Human Knowledge.* User Modeling and User-Adapted Interaction.
3. Wozniak, P. (1990). *Optimization of repetition spacing in the practice of
   learning.* PhD thesis.
4. Chen, T., & Guestrin, C. (2016). *XGBoost: A Scalable Tree Boosting System.*
   KDD 2016.
5. Lundberg, S. M., & Lee, S. I. (2017). *A Unified Approach to Interpreting
   Model Predictions.* NeurIPS 2017 (SHAP).

---

*Document genere le 01/07/2026 a 09:31 par Agent AJ
(ExamBoost Togo, Session 3 Vague 2).*
