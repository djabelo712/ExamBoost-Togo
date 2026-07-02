"""ml_training — Pipeline d'entrainement XGBoost pour la prediction du score BEPC/BAC.

Modules :
    - generate_synthetic_students : genere un dataset d'eleves synthetiques
    - train_score_predictor       : entraine XGBoost + grid search + CV
    - evaluate_model              : RMSE/MAE/R2 + plots + analyse par segment
    - generate_model_card         : model card standard (Google Model Cards)
    - shap_analysis               : feature importance SHAP + waterfall

Usage typique (depuis le dossier ml_training/) :
    python generate_synthetic_students.py
    python train_score_predictor.py
    python evaluate_model.py
    python shap_analysis.py
    python generate_model_card.py

Tous les artefacts sont ecrits dans ./output/.
"""

__version__ = "1.0.0"
