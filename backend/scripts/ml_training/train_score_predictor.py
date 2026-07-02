"""train_score_predictor — Entraine XGBoost pour predire score_final.

Methodologie :
    1. Split train/test (80/20) avec random_state fixe (reproductibilite).
    2. Validation croisee 5-fold sur le train.
    3. Grid search sur les hyperparametres cles :
       - max_depth      : [3, 5, 7]
       - learning_rate  : [0.01, 0.1, 0.3]
       - n_estimators   : [100, 200, 500]
       - subsample      : [0.8, 1.0]
    4. Modele final entraine sur tout le train avec les meilleurs hyperparams.
    5. Serialisation joblib pour production (backend/services/ml_service.py).

Le modele est sauvegarde dans output/trained_model.joblib sous la forme :
    {
        "model": XGBRegressor,
        "features": list[str],
        "metrics": {"rmse": float, "mae": float, "r2": float},
        "best_params": dict,
        "feature_importances": dict,
    }

Usage :
    python train_score_predictor.py
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import Final

import joblib
import numpy as np
import pandas as pd
import xgboost as xgb
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score
from sklearn.model_selection import GridSearchCV, train_test_split, cross_val_score

# ─── Constantes ────────────────────────────────────────────────────────
OUTPUT_DIR: Final[Path] = Path(__file__).resolve().parent / "output"
DATASET_PATH: Final[Path] = OUTPUT_DIR / "synthetic_students.csv"
MODEL_PATH: Final[Path] = OUTPUT_DIR / "trained_model.joblib"
METRICS_PATH: Final[Path] = OUTPUT_DIR / "training_metrics.json"

FEATURES: Final[list[str]] = [
    "pL_global",
    "pL_maths",
    "pL_francais",
    "pL_sciences",
    "pL_svt",
    "pL_histoire",
    "pL_anglais",
    "sessions_7j",
    "avg_time_per_q",
    "simulations_completed",
    "last_score_simulation",
    "total_questions_answered",
    "streak_days",
    "days_to_exam",
]
TARGET: Final[str] = "score_final"

RANDOM_STATE: Final[int] = 42

# Grille d'hyperparametres (3 x 3 x 3 x 2 = 54 combinaisons)
PARAM_GRID: Final[dict] = {
    "max_depth": [3, 5, 7],
    "learning_rate": [0.01, 0.1, 0.3],
    "n_estimators": [100, 200, 500],
    "subsample": [0.8, 1.0],
}


def train() -> dict:
    """Entraine XGBoost avec grid search + CV et sauvegarde le modele.

    Returns
    -------
    dict
        Dictionnaire des metriques finales (rmse, mae, r2, best_params).
    """
    if not DATASET_PATH.exists():
        raise FileNotFoundError(
            f"Dataset introuvable : {DATASET_PATH}. "
            "Lance d'abord : python generate_synthetic_students.py"
        )

    print("[train] Chargement du dataset...")
    df = pd.read_csv(DATASET_PATH)
    print(f"[train] Dataset : {df.shape[0]} lignes, {df.shape[1]} colonnes.")

    X = df[FEATURES]
    y = df[TARGET]

    # 1. Split train/test 80/20
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=RANDOM_STATE
    )
    print(f"[train] Train : {X_train.shape[0]} | Test : {X_test.shape[0]}")

    # 2. Modele de base
    base_model = xgb.XGBRegressor(
        objective="reg:squarederror",
        random_state=RANDOM_STATE,
        n_jobs=-1,
        tree_method="hist",  # plus rapide, equivalent exact pour petits datasets
    )

    # 3. Grid search 5-fold
    print(f"[train] Grid search : {len(PARAM_GRID['max_depth']) * len(PARAM_GRID['learning_rate']) * len(PARAM_GRID['n_estimators']) * len(PARAM_GRID['subsample'])} combinaisons, CV=5...")
    grid = GridSearchCV(
        base_model,
        PARAM_GRID,
        cv=5,
        scoring="neg_mean_squared_error",
        verbose=1,
        n_jobs=-1,
        return_train_score=False,
    )
    grid.fit(X_train, y_train)

    best_model = grid.best_estimator_
    best_params = grid.best_params_
    print(f"[train] Meilleurs hyperparams : {best_params}")

    # 4. Cross-validation additionnelle avec le meilleur modele
    cv_scores = cross_val_score(
        best_model, X_train, y_train,
        cv=5, scoring="neg_mean_squared_error", n_jobs=-1,
    )
    cv_rmse = float(np.sqrt(-cv_scores.mean()))
    cv_rmse_std = float(np.sqrt(cv_scores.std()))
    print(f"[train] CV 5-fold RMSE : {cv_rmse:.3f} (+/- {cv_rmse_std:.3f})")

    # 5. Evaluation finale sur le test set
    y_pred = best_model.predict(X_test)
    rmse = float(np.sqrt(mean_squared_error(y_test, y_pred)))
    mae = float(mean_absolute_error(y_test, y_pred))
    r2 = float(r2_score(y_test, y_pred))

    print()
    print("=" * 60)
    print(f"[train] RMSE : {rmse:.3f} / 20")
    print(f"[train] MAE  : {mae:.3f} / 20")
    print(f"[train] R2   : {r2:.3f}")
    print("=" * 60)

    # 6. Feature importances (XGBoost native)
    importances = best_model.feature_importances_
    feat_imp = dict(sorted(
        zip(FEATURES, importances.tolist()),
        key=lambda kv: kv[1],
        reverse=True,
    ))
    print()
    print("[train] Feature importances (XGBoost) :")
    for feat, imp in feat_imp.items():
        print(f"  {feat:<28s} {imp:.4f}")

    # 7. Sauvegarde du modele serialise (format production)
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    joblib.dump(
        {
            "model": best_model,
            "features": FEATURES,
            "metrics": {"rmse": rmse, "mae": mae, "r2": r2},
            "best_params": best_params,
            "feature_importances": feat_imp,
            "cv_rmse": cv_rmse,
            "cv_rmse_std": cv_rmse_std,
            "training_date": pd.Timestamp.now().isoformat(),
            "n_samples": int(len(df)),
            "target_range": [0.0, 20.0],
        },
        MODEL_PATH,
    )
    print(f"[train] Modele sauvegarde : {MODEL_PATH}")

    # 8. Sauvegarde des metriques (JSON, lisible par le model_card generator)
    cv_results_summary = []
    for i, params in enumerate(grid.cv_results_["params"]):
        cv_results_summary.append({
            "params": params,
            "mean_test_rmse": float(np.sqrt(-grid.cv_results_["mean_test_score"][i])),
            "rank": int(grid.cv_results_["rank_test_score"][i]),
        })

    with open(METRICS_PATH, "w", encoding="utf-8") as f:
        json.dump(
            {
                "rmse": rmse,
                "mae": mae,
                "r2": r2,
                "cv_rmse": cv_rmse,
                "cv_rmse_std": cv_rmse_std,
                "best_params": best_params,
                "feature_importances": feat_imp,
                "n_samples": int(len(df)),
                "n_train": int(len(X_train)),
                "n_test": int(len(X_test)),
                "features": FEATURES,
                "target": TARGET,
                "cv_results_summary": cv_results_summary,
                "training_date": pd.Timestamp.now().isoformat(),
            },
            f,
            indent=2,
            ensure_ascii=False,
        )
    print(f"[train] Metriques sauvegardees : {METRICS_PATH}")

    return {
        "rmse": rmse,
        "mae": mae,
        "r2": r2,
        "cv_rmse": cv_rmse,
        "cv_rmse_std": cv_rmse_std,
        "best_params": best_params,
    }


def main() -> None:
    """Point d'entree CLI."""
    train()


if __name__ == "__main__":
    main()
