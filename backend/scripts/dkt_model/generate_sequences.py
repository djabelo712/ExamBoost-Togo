"""Generate synthetic student trajectories for DKT training.

Each trajectory simulates a single student answering ``seq_length``
questions sampled (with replacement) from a bank of ``n_questions``
items. The probability of a correct answer at each step is given by
the IRT 3PL model, and the latent ability ``theta`` drifts upward on
a correct answer and downward on an incorrect one (a simple learning
dynamic).

Output CSV schema (one row per interaction)
-------------------------------------------
student_id          : str  -- e.g. ``student_00042``
sequence_position   : int  -- 0 .. seq_length-1
question_id         : str  -- e.g. ``Q007``
question_idx        : int  -- 0 .. n_questions-1 (used by the model)
correct             : int  -- 0 or 1
theta_at_time       : float -- latent ability right before answering

The script writes ``output/sequences.csv`` relative to this file.
"""

from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
import pandas as pd

# --- Parametres par defaut (cf. instructions AK-dkt-lstm) -----------------
N_STUDENTS_DEFAULT = 10_000
SEQ_LENGTH_DEFAULT = 50
N_QUESTIONS_DEFAULT = 50
SEED_DEFAULT = 42

# Bornes de la probabilite de deviner pour le modele IRT 3PL.
# c = 0.25 simule un QCM a 4 choix ; c = 0 simule une question ouverte.
P_GUESS_VALUES = (0.0, 0.25)
P_GUESS_PROBS = (0.5, 0.5)

# Pente de la fonction logistique IRT (constante 1.7 de Birnbaum).
IRT_SLOPE = 1.7

# Dynamique d'apprentissage : theta monte si correct, descend si faux.
LEARNING_GAIN_CORRECT = 0.10
LEARNING_PENALTY_WRONG = 0.05
THETA_CLIP = (-3.0, 3.0)


def generate_sequences(
    n_students: int = N_STUDENTS_DEFAULT,
    seq_length: int = SEQ_LENGTH_DEFAULT,
    n_questions: int = N_QUESTIONS_DEFAULT,
    seed: int = SEED_DEFAULT,
) -> pd.DataFrame:
    """Generate synthetic student trajectories.

    Parameters
    ----------
    n_students:
        Number of students to simulate.
    seq_length:
        Number of questions answered per student.
    n_questions:
        Size of the question bank.
    seed:
        Random seed for reproducibility.

    Returns
    -------
    pd.DataFrame
        One row per interaction with the columns described in the
        module docstring.
    """
    rng = np.random.default_rng(seed)

    # Parametres IRT 3PL tirs une fois pour toutes (banque de questions).
    a = rng.uniform(0.5, 2.0, size=n_questions)  # discrimination
    b = rng.normal(0.0, 1.0, size=n_questions)   # difficulte
    c = rng.choice(P_GUESS_VALUES, size=n_questions, p=P_GUESS_PROBS)

    rows: list[dict] = []
    for student_idx in range(n_students):
        theta = float(rng.normal(0.0, 1.0))

        for pos in range(seq_length):
            # Tire une question (avec repetitions possibles).
            q_idx = int(rng.integers(0, n_questions))

            # IRT 3PL : P(correct) = c + (1 - c) * sigma(1.7 * a * (theta - b))
            z = IRT_SLOPE * a[q_idx] * (theta - b[q_idx])
            p_correct = float(c[q_idx] + (1.0 - c[q_idx]) * (1.0 / (1.0 + np.exp(-z))))
            # Bornage numerique (evite log(0) plus tard).
            p_correct = float(np.clip(p_correct, 1e-6, 1.0 - 1e-6))
            correct = 1 if rng.random() < p_correct else 0

            rows.append(
                {
                    "student_id": f"student_{student_idx:05d}",
                    "sequence_position": pos,
                    "question_id": f"Q{q_idx:03d}",
                    "question_idx": q_idx,
                    "correct": correct,
                    "theta_at_time": round(theta, 6),
                }
            )

            # Mise a jour de theta (apprentissage).
            if correct:
                theta += LEARNING_GAIN_CORRECT
            else:
                theta -= LEARNING_PENALTY_WRONG
            theta = float(np.clip(theta, THETA_CLIP[0], THETA_CLIP[1]))

    return pd.DataFrame(rows)


def main() -> None:
    """CLI entry point: parse arguments and write CSV."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--n-students", type=int, default=N_STUDENTS_DEFAULT)
    parser.add_argument("--seq-length", type=int, default=SEQ_LENGTH_DEFAULT)
    parser.add_argument("--n-questions", type=int, default=N_QUESTIONS_DEFAULT)
    parser.add_argument("--seed", type=int, default=SEED_DEFAULT)
    args = parser.parse_args()

    df = generate_sequences(
        n_students=args.n_students,
        seq_length=args.seq_length,
        n_questions=args.n_questions,
        seed=args.seed,
    )

    output_dir = Path(__file__).parent / "output"
    output_dir.mkdir(parents=True, exist_ok=True)
    csv_path = output_dir / "sequences.csv"
    df.to_csv(csv_path, index=False)

    n_inter = len(df)
    mean_correct = float(df["correct"].mean())
    print(
        f"[OK] {n_inter} interactions generees "
        f"({args.n_students} eleves x {args.seq_length} questions)"
    )
    print(f"     Taux de reussite moyen : {mean_correct:.3f}")
    print(f"     Fichier ecrit          : {csv_path}")


if __name__ == "__main__":
    main()
