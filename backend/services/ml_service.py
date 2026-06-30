"""services/ml_service.py — Prediction du score a l'examen via XGBoost.

Strategie :
    1. Si un modele XGBoost serialise (joblib) existe et qu'on a assez de
       donnees (>= MIN_RESPONSES_FOR_ML) -> predict via XGBoost.
    2. Sinon -> heuristique basee sur la moyenne des P(L) BKT par matiere,
       projetee sur une echelle 0-20.

Features attendues (ordre important) :
    [pL_global, pL_maths, pL_fr, pL_sciences, sessions_7j,
     avg_time_per_q, simulations_completed, last_score_simulation]
"""

from __future__ import annotations

import os
from dataclasses import dataclass
from typing import Optional, Sequence

import numpy as np

from config import settings


# joblib + xgboost + sklearn sont importes en lazy (uniquement pour
# l'entrainement / la prediction XGBoost). Cela permet a l'API de
# demarrer avec un requirements minimal (pas de xgboost/pandas/py-irt)
# tant qu'on reste sur l'heuristique BKT.


# ─── Constantes ──────────────────────────────────────────────────────
MODEL_DIR = os.path.join(os.path.dirname(__file__), "models")
MODEL_PATH = os.path.join(MODEL_DIR, "score_predictor.joblib")

FEATURE_NAMES = [
    "pL_global",
    "pL_maths",
    "pL_fr",
    "pL_sciences",
    "sessions_7j",
    "avg_time_per_q",
    "simulations_completed",
    "last_score_simulation",
]


@dataclass
class ScorePrediction:
    predicted_score: float  # sur 20
    confidence: float       # 0 a 1
    method: str             # heuristic | xgboost | insufficient_data


def model_exists() -> bool:
    """Verifie si un modele XGBoost serialise est disponible."""
    return os.path.exists(MODEL_PATH)


def _load_model():
    """Charge le modele XGBoost serialise."""
    import joblib  # import lazy

    return joblib.load(MODEL_PATH)


# ─── Prediction par heuristique (fallback) ───────────────────────────
def heuristic_score(pL_by_matiere: dict, total_responses: int) -> ScorePrediction:
    """Score heuristique : moyenne des P(L) projetee sur /20.

    La confiance augmente avec le nombre de reponses collectees.
    """
    if not pL_by_matiere:
        return ScorePrediction(
            predicted_score=0.0,
            confidence=0.0,
            method="insufficient_data",
        )

    avg_pL = float(np.mean(list(pL_by_matiere.values())))
    score = float(np.clip(avg_pL * 20.0, 0.0, 20.0))

    # Confiance : 0.3 minimum, plafonnee a 0.7 pour l'heuristique
    conf = float(np.clip(0.3 + 0.4 * (total_responses / 100.0), 0.3, 0.7))
    return ScorePrediction(
        predicted_score=round(score, 2),
        confidence=round(conf, 2),
        method="heuristic",
    )


# ─── Prediction via XGBoost ──────────────────────────────────────────
def predict_score(
    features: Sequence[float],
    pL_by_matiere: Optional[dict] = None,
    total_responses: int = 0,
) -> ScorePrediction:
    """Predit le score a l'examen.

    Parameters
    ----------
    features:
        Vecteur de features (voir FEATURE_NAMES). Si None ou incomplet,
        fallback sur l'heuristique.
    pL_by_matiere:
        Dictionnaire {matiere: pL} pour le fallback heuristique.
    total_responses:
        Nombre total de reponses de l'utilisateur.

    Returns
    -------
    ScorePrediction
    """
    # Conditions pour utiliser XGBoost :
    #  - modele disponible
    #  - assez de donnees
    #  - features completes
    if (
        model_exists()
        and total_responses >= settings.MIN_RESPONSES_FOR_ML
        and features is not None
        and len(features) == len(FEATURE_NAMES)
    ):
        try:
            model = _load_model()
            X = np.array(features, dtype=float).reshape(1, -1)
            raw = float(model.predict(X)[0])
            score = float(np.clip(raw, 0.0, 20.0))
            return ScorePrediction(
                predicted_score=round(score, 2),
                confidence=0.85,
                method="xgboost",
            )
        except Exception:
            # Modele casse -> fallback
            pass

    # Fallback heuristique
    if pL_by_matiere is None:
        pL_by_matiere = {}
    return heuristic_score(pL_by_matiere, total_responses)


# ─── Prediction du risque de decrochage (mock pour demo DJANTA) ──────
@dataclass
class DropoutPrediction:
    probability: float
    risk_level: str
    factors: dict


def predict_dropout(
    sessions_7j: int = 0,
    avg_time_per_q: float = 0.0,
    last_active_days_ago: int = 0,
    simulations_completed: int = 0,
    pL_global: float = 0.0,
) -> DropoutPrediction:
    """Estime la probabilite de decrochage (mock).

    Modele volontairement simple et transparent pour le pitch :
        - Inactivite prolongee -> facteur fort
        - Trop peu de sessions recentes -> facteur moyen
        - Faible pL global -> facteur moyen

    Returns
    -------
    DropoutPrediction
    """
    factors: dict = {}

    # Facteur inactivite (jusqu'a 0.6 si > 14 jours)
    inactivity_factor = float(np.clip(last_active_days_ago / 14.0, 0.0, 1.0)) * 0.6
    factors["inactivity_days"] = last_active_days_ago
    factors["inactivity_weight"] = round(inactivity_factor, 3)

    # Facteur engagement (sessions 7j) : moins de 3 sessions = penalite
    if sessions_7j < 3:
        engagement_factor = (3 - sessions_7j) / 3.0 * 0.2
    else:
        engagement_factor = 0.0
    factors["sessions_7j"] = sessions_7j
    factors["engagement_weight"] = round(engagement_factor, 3)

    # Facteur performance : faible pL global = +0.2
    perf_factor = float(np.clip(1.0 - pL_global, 0.0, 1.0)) * 0.2
    factors["pL_global"] = round(pL_global, 3)
    factors["performance_weight"] = round(perf_factor, 3)

    prob = float(np.clip(inactivity_factor + engagement_factor + perf_factor, 0.0, 1.0))

    if prob < 0.3:
        risk = "faible"
    elif prob < 0.6:
        risk = "modere"
    else:
        risk = "eleve"

    factors["simulations_completed"] = simulations_completed
    factors["avg_time_per_q"] = avg_time_per_q

    return DropoutPrediction(
        probability=round(prob, 3),
        risk_level=risk,
        factors=factors,
    )


# ─── Entrainement du modele ──────────────────────────────────────────
def train_model(X, y) -> dict:
    """Entraîne XGBoost et sauvegarde dans ``MODEL_PATH``.

    Parameters
    ----------
    X:
        Matrice de features (n_samples, n_features).
    y:
        Cibles (score sur 20).

    Returns
    -------
    dict
        Metriques d'entrainement (R2, RMSE).
    """
    import xgboost as xgb
    from sklearn.model_selection import train_test_split
    from sklearn.metrics import r2_score, mean_squared_error

    os.makedirs(MODEL_DIR, exist_ok=True)

    X = np.asarray(X, dtype=float)
    y = np.asarray(y, dtype=float)

    if X.ndim == 1:
        X = X.reshape(-1, 1)
    if len(X) != len(y):
        raise ValueError("X et y doivent avoir le meme nombre de lignes")

    # Split si assez de donnees
    if len(X) >= 20:
        X_tr, X_te, y_tr, y_te = train_test_split(X, y, test_size=0.2, random_state=42)
    else:
        X_tr, X_te, y_tr, y_te = X, X, y, y

    model = xgb.XGBRegressor(
        n_estimators=200,
        max_depth=4,
        learning_rate=0.1,
        objective="reg:squarederror",
        random_state=42,
        n_jobs=-1,
    )
    model.fit(X_tr, y_tr)

    y_pred = model.predict(X_te)
    r2 = float(r2_score(y_te, y_pred))
    rmse = float(np.sqrt(mean_squared_error(y_te, y_pred)))

    joblib.dump(model, MODEL_PATH)

    return {
        "r2": round(r2, 4),
        "rmse": round(rmse, 4),
        "n_samples": int(len(X)),
        "n_features": int(X.shape[1]),
        "model_path": MODEL_PATH,
    }
