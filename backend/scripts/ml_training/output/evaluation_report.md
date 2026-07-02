# Rapport d'evaluation du modele XGBoost

- **Date** : 01/07/2026 09:30
- **Dataset** : 5000 eleves synthetiques
- **Modele** : XGBoost Regressor (objective=reg:squarederror)
- **Hyperparametres optimaux** : `{'learning_rate': 0.01, 'max_depth': 3, 'n_estimators': 500, 'subsample': 0.8}`

## Metriques globales

| Metrique | Valeur | Interpretation |
|---|---|---|
| RMSE | 1.437 / 20 | Erreur quadratique moyenne |
| MAE  | 1.142 / 20 | Erreur absolue moyenne |
| R2   | 0.690 | Variance expliquee |
| MAPE | 14.76 % | Erreur relative moyenne |

## Performance par segment d'eleve

| Segment | Effectif | RMSE | MAE | Biais (reel - predit) |
|---|---|---|---|---|
| Faible (0-8) | 1786 | 1.520 | 1.214 | -0.873 |
| Moyen (8-12) | 2616 | 1.253 | 0.994 | +0.278 |
| Bon (12-16) | 586 | 1.830 | 1.540 | +1.469 |
| Excellent (16-20) | 12 | 3.256 | 3.103 | +3.103 |

## Feature importance (XGBoost native)

| Rang | Feature | Importance |
|---|---|---|
| 1 | pL_global | 0.6705 |
| 2 | last_score_simulation | 0.0530 |
| 3 | pL_francais | 0.0402 |
| 4 | pL_maths | 0.0332 |
| 5 | pL_sciences | 0.0309 |
| 6 | days_to_exam | 0.0277 |
| 7 | pL_anglais | 0.0253 |
| 8 | simulations_completed | 0.0204 |
| 9 | streak_days | 0.0200 |
| 10 | pL_histoire | 0.0168 |
| 11 | pL_svt | 0.0168 |
| 12 | sessions_7j | 0.0155 |
| 13 | avg_time_per_q | 0.0153 |
| 14 | total_questions_answered | 0.0143 |

## Plots generes

- `evaluation_plots.png` : prediction vs reel, residus, distribution erreurs
- `feature_importance.png` : feature importance XGBoost
- `shap_summary.png` (cf. `shap_analysis.py`) : feature importance SHAP

## Interpretation

- Un RMSE de **1.44/20** signifie que l'erreur typique est de l'ordre de **1.14 points**.
- Le R2 de **0.690** indique que le modele explique **69.0%** de la variance du score final.
- Le biais global est quasi nul (residus centres), mais peut varier par segment (cf. tableau ci-dessus).

## Limitations connues

- Modele entraine sur donnees synthetiques : a recalibrer avec donnees reelles du pilote.
- Ne capture pas l'effet stress de l'examen, ni le contexte socio-economique.
- Les segments extremes (tres faible ou tres fort) peuvent etre moins bien predits si sous-representes.