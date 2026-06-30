"""scripts/train_score_model.py — Entraîne XGBoost pour la prediction du score.

Utilisation :
    python scripts/train_score_model.py

Etapes :
    1. Pour chaque utilisateur ayant realise au moins une simulation,
       on construit un vecteur de features a partir de son historique de
       reponses (P(L) moyen par matiere, sessions sur 7j, temps moyen,
       nombre de simulations, score de la derniere simulation).
    2. La cible ``y`` est le score obtenu a la simulation.
    3. On entraine XGBoost et on sauve le modele dans
       ``services/models/score_predictor.joblib``.

Note : si peu de donnees sont disponibles (< 20 simulations), le script
genere des donnees synthetiques pour permettre une demo fonctionnelle.
"""

from __future__ import annotations

import sys
from pathlib import Path
from datetime import timedelta, timezone

import numpy as np
import pandas as pd

_HERE = Path(__file__).resolve().parent
_BACKEND_ROOT = _HERE.parent
if str(_BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(_BACKEND_ROOT))

from sqlalchemy import func, select  # noqa: E402

from database import SessionLocal, init_db  # noqa: E402
from models.db_models import Question, Response, Simulation, User  # noqa: E402
from services import ml_service  # noqa: E402


def _utcnow():
    from datetime import datetime

    return datetime.now(timezone.utc)


def build_training_dataset() -> pd.DataFrame:
    """Construit le dataset (X, y) a partir des simulations et reponses."""
    db = SessionLocal()
    try:
        sims = db.execute(
            select(Simulation.user_id, Simulation.examen, Simulation.score, Simulation.created_at)
        ).all()
        if not sims:
            return pd.DataFrame()

        rows = []
        for user_id, examen, score, created_at in sims:
            user = db.get(User, user_id)
            if user is None:
                continue

            # pL global et par matiere
            pL_by_matiere = {}
            competences = list(user.bkt_maitrise.keys())
            if competences:
                q_rows = db.execute(
                    select(Question.competence_id, Question.matiere).where(
                        Question.competence_id.in_(competences)
                    ).distinct()
                ).all()
                comp_to_mat = {r[0]: r[1] for r in q_rows}
                by_mat = {}
                for cid, pL in user.bkt_maitrise.items():
                    m = comp_to_mat.get(cid, "Autre")
                    by_mat.setdefault(m, []).append(float(pL))
                pL_by_matiere = {m: float(np.mean(v)) for m, v in by_mat.items()}

            pL_global = float(np.mean(list(pL_by_matiere.values()))) if pL_by_matiere else 0.0
            pL_maths = pL_by_matiere.get("Mathematiques", 0.0)
            pL_fr = pL_by_matiere.get("Francais", 0.0)
            pL_sciences = pL_by_matiere.get("Sciences", pL_by_matiere.get("SVT", 0.0))

            # Sessions 7j avant la simulation
            since = created_at - timedelta(days=7)
            sessions_7j = int(
                db.execute(
                    select(func.count(Response.id)).where(
                        Response.user_id == user_id,
                        Response.created_at >= since,
                        Response.created_at <= created_at,
                    )
                ).scalar()
                or 0
            )

            avg_time = float(
                db.execute(
                    select(func.avg(Response.time_spent_sec)).where(
                        Response.user_id == user_id,
                        Response.created_at <= created_at,
                    )
                ).scalar()
                or 0.0
            )

            sims_before = int(
                db.execute(
                    select(func.count(Simulation.id)).where(
                        Simulation.user_id == user_id,
                        Simulation.created_at <= created_at,
                    )
                ).scalar()
                or 0
            )

            # Score de la simulation precedente (0 si premiere)
            prev_score_row = db.execute(
                select(Simulation.score)
                .where(
                    Simulation.user_id == user_id,
                    Simulation.created_at < created_at,
                )
                .order_by(Simulation.created_at.desc())
                .limit(1)
            ).scalar_one_or_none()
            last_score = float(prev_score_row) if prev_score_row is not None else 0.0

            rows.append(
                {
                    "pL_global": pL_global,
                    "pL_maths": pL_maths,
                    "pL_fr": pL_fr,
                    "pL_sciences": pL_sciences,
                    "sessions_7j": sessions_7j,
                    "avg_time_per_q": avg_time,
                    "simulations_completed": sims_before,
                    "last_score_simulation": last_score,
                    "score": float(score),
                }
            )

        return pd.DataFrame(rows)
    finally:
        db.close()


def _synthetic_dataset(n: int = 200) -> pd.DataFrame:
    """Genere un dataset synthetique pour demo (quand pas assez de donnees reelles)."""
    rng = np.random.default_rng(42)

    pL_global = rng.uniform(0.1, 0.95, n)
    pL_maths = np.clip(pL_global + rng.normal(0, 0.1, n), 0.0, 1.0)
    pL_fr = np.clip(pL_global + rng.normal(0, 0.1, n), 0.0, 1.0)
    pL_sciences = np.clip(pL_global + rng.normal(0, 0.1, n), 0.0, 1.0)
    sessions_7j = rng.poisson(5, n)
    avg_time = rng.uniform(30, 180, n)
    sims = rng.integers(0, 10, n)
    last_score = np.clip(pL_global * 20 + rng.normal(0, 2, n), 0, 20)

    # Score = combinaison lineaire + bruit
    score = (
        pL_global * 12.0
        + pL_maths * 2.0
        + pL_fr * 2.0
        + pL_sciences * 1.5
        + np.clip(sessions_7j / 10.0, 0, 1) * 1.5
        - np.clip(avg_time / 180.0, 0, 1) * 1.0
        + last_score * 0.1
        + rng.normal(0, 0.7, n)
    )
    score = np.clip(score, 0, 20)

    return pd.DataFrame(
        {
            "pL_global": pL_global,
            "pL_maths": pL_maths,
            "pL_fr": pL_fr,
            "pL_sciences": pL_sciences,
            "sessions_7j": sessions_7j.astype(float),
            "avg_time_per_q": avg_time,
            "simulations_completed": sims.astype(float),
            "last_score_simulation": last_score,
            "score": score,
        }
    )


def main() -> None:
    init_db()

    print("[ml] Construction du dataset d'entrainement...")
    df = build_training_dataset()
    print(f"[ml] {len(df)} echantillons reels.")

    if len(df) < 20:
        print("[ml] Pas assez de donnees reelles. Generation synthetique.")
        df_synth = _synthetic_dataset(n=200)
        if not df.empty:
            df = pd.concat([df, df_synth], ignore_index=True)
        else:
            df = df_synth
        print(f"[ml] Dataset final: {len(df)} echantillons (synthetique + reels).")

    feature_cols = ml_service.FEATURE_NAMES
    X = df[feature_cols].values
    y = df["score"].values

    print(f"[ml] Features: {feature_cols}")
    print(f"[ml] X.shape={X.shape}, y.shape={y.shape}")

    metrics = ml_service.train_model(X, y)
    print(f"[ml] Modele entraîne : R2={metrics['r2']}, RMSE={metrics['rmse']}")
    print(f"[ml] Modele sauvegarde dans : {metrics['model_path']}")


if __name__ == "__main__":
    main()
