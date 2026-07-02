"""generate_synthetic_students — Genere 5000 profils eleves synthetiques.

Cette fonction construit un dataset realiste pour entrainer le modele XGBoost
de prediction du score final au BEPC ou au BAC.

Le dataset reproduit les correlations observees dans le projet ExamBoost Togo :
    - P(L) global (BKT) est le meilleur predicteur (correlation ~0.7)
    - P(L) maths et francais ont un poids important (coef eleve au BEPC Togo)
    - Le nombre de simulations ameliore la prediction (effet "practice")
    - La regularite (streak, sessions 7j) reflete la motivation
    - La proximite de l'examen fige la trajectoire

Le bruit gaussien (sigma ~ 1.5 points) represente la part non expliquee par les
features disponibles (stress, sommeil, contexte socio-economique, etc.).

Usage :
    python generate_synthetic_students.py            # default 5000, seed 42
    python generate_synthetic_students.py --n 10000 --seed 7
"""

from __future__ import annotations

import argparse
from pathlib import Path
from typing import Final

import numpy as np
import pandas as pd

# ─── Constantes ────────────────────────────────────────────────────────
OUTPUT_DIR: Final[Path] = Path(__file__).resolve().parent / "output"
DEFAULT_N: Final[int] = 5000
DEFAULT_SEED: Final[int] = 42

FEATURE_COLUMNS: Final[list[str]] = [
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
TARGET_COLUMN: Final[str] = "score_final"


def generate_synthetic_students(n: int = DEFAULT_N, seed: int = DEFAULT_SEED) -> pd.DataFrame:
    """Genere ``n`` eleves synthetiques avec correlations realistes.

    Parameters
    ----------
    n : int
        Nombre d'eleves a generer (default 5000).
    seed : int
        Graine RNG pour reproductibilite (default 42).

    Returns
    -------
    pd.DataFrame
        DataFrame de ``n`` lignes, 15 colonnes (14 features + target).
    """
    np.random.seed(seed)

    # 1. P(L) par matiere — avec correlations partielles realistes
    #    Sciences exactes (maths, sciences, svt) sont correlees entre elles.
    #    Lettres (francais, histoire) sont correlees entre elles.
    #    Anglais reste independant.
    pL_maths = np.random.beta(2, 2, n)  # Moyenne ~0.5
    pL_sciences = 0.7 * pL_maths + 0.3 * np.random.beta(2, 2, n)
    pL_svt = 0.5 * pL_maths + 0.5 * np.random.beta(2, 2, n)
    pL_francais = np.random.beta(2, 2, n)
    pL_histoire = 0.6 * pL_francais + 0.4 * np.random.beta(2, 2, n)
    pL_anglais = np.random.beta(2, 2, n)

    # Clip pour rester dans [0, 1] (les melanges ponderes peuvent depasser)
    pL_maths = np.clip(pL_maths, 0.0, 1.0)
    pL_sciences = np.clip(pL_sciences, 0.0, 1.0)
    pL_svt = np.clip(pL_svt, 0.0, 1.0)
    pL_francais = np.clip(pL_francais, 0.0, 1.0)
    pL_histoire = np.clip(pL_histoire, 0.0, 1.0)
    pL_anglais = np.clip(pL_anglais, 0.0, 1.0)

    pL_global = (
        pL_maths + pL_francais + pL_sciences + pL_svt + pL_histoire + pL_anglais
    ) / 6.0

    # 2. Comportement de l'eleve
    sessions_7j = np.random.poisson(5, n)  # Moyenne 5 sessions/semaine
    avg_time_per_q = np.random.gamma(5, 3, n)  # Moyenne ~15 sec/question
    simulations_completed = np.random.poisson(3, n)  # Moyenne 3 simulations

    # Dernier score de simulation — fortement correle avec pL_global
    last_score_simulation = (
        pL_global * 20.0 * 0.8 + np.random.normal(0, 3, n)
    )
    last_score_simulation = np.clip(last_score_simulation, 0, 20)

    total_questions_answered = np.random.poisson(200, n)  # Moyenne 200 questions
    streak_days = np.random.gamma(2, 3, n)  # Moyenne ~6 jours consecutifs
    days_to_exam = np.random.randint(1, 180, n)  # Entre 1 et 180 jours

    # 3. Score final (target) — combinaison realiste ponderee
    score_final = (
        pL_global * 12.0  # P(L) global = facteur principal
        + pL_maths * 2.0  # Bonus maths (coef eleve au BEPC)
        + pL_francais * 2.0  # Bonus francais
        + (sessions_7j / 30.0) * 1.0  # Regularite hebdomadaire
        + (simulations_completed / 20.0) * 1.0  # Effet "practice"
        + (last_score_simulation / 20.0) * 2.0  # Score simu = signal fort
        + (streak_days / 100.0) * 0.5  # Consistance long terme
        - ((180 - days_to_exam) / 180.0) * 0.5  # Effet "deja fige" si proche
        + np.random.normal(0, 1.5, n)  # Bruit residuel
    )
    score_final = np.clip(score_final, 0, 20)

    df = pd.DataFrame(
        {
            "pL_global": pL_global,
            "pL_maths": pL_maths,
            "pL_francais": pL_francais,
            "pL_sciences": pL_sciences,
            "pL_svt": pL_svt,
            "pL_histoire": pL_histoire,
            "pL_anglais": pL_anglais,
            "sessions_7j": sessions_7j.astype(int),
            "avg_time_per_q": avg_time_per_q,
            "simulations_completed": simulations_completed.astype(int),
            "last_score_simulation": last_score_simulation,
            "total_questions_answered": total_questions_answered.astype(int),
            "streak_days": streak_days,
            "days_to_exam": days_to_exam.astype(int),
            "score_final": score_final,
        }
    )

    return df


def main() -> None:
    """Point d'entree CLI : genere le dataset et l'ecrit dans output/."""
    parser = argparse.ArgumentParser(
        description="Genere un dataset synthetique d'eleves pour XGBoost."
    )
    parser.add_argument("--n", type=int, default=DEFAULT_N, help="Nombre d'eleves (default 5000)")
    parser.add_argument("--seed", type=int, default=DEFAULT_SEED, help="Graine RNG (default 42)")
    args = parser.parse_args()

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    print(f"[generate] Generation de {args.n} eleves synthetiques (seed={args.seed})...")
    df = generate_synthetic_students(n=args.n, seed=args.seed)

    output_path = OUTPUT_DIR / "synthetic_students.csv"
    df.to_csv(output_path, index=False)
    print(f"[generate] Dataset sauvegarde : {output_path}")
    print(f"[generate] Shape : {df.shape}")
    print(f"[generate] Colonnes : {list(df.columns)}")
    print()
    print("[generate] Statistiques descriptives :")
    print(df.describe().round(3).to_string())
    print()
    print(f"[generate] Correlation pL_global <-> score_final : {df['pL_global'].corr(df['score_final']):.3f}")
    print(f"[generate] Correlation last_score_simulation <-> score_final : "
          f"{df['last_score_simulation'].corr(df['score_final']):.3f}")
    print(f"[generate] Correlation simulations_completed <-> score_final : "
          f"{df['simulations_completed'].corr(df['score_final']):.3f}")


if __name__ == "__main__":
    main()
