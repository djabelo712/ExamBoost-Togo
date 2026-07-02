"""Evaluate DKT and compare it against the classical BKT baseline.

The test set is the same 15% slice of students held out by
``train_dkt.py``. For every interaction at position ``t >= 1`` we
record:

- **DKT prediction**: ``model.predict_next(history[:t])[q_t]`` -- the
  model's ``P(correct)`` for the question actually asked at step ``t``.
- **BKT prediction**: classical Bayesian update with the same default
  parameters as ``lib/models/user.dart`` and
  ``backend/services/bkt_service.py`` (``P(T)=0.2``, ``P(S)=0.1``,
  ``P(G)=0.2``, initial ``P(L)=0.1``). The prediction is computed
  **before** the BKT update of step ``t``.

Both models therefore predict exactly the same targets, which makes
the comparison fair.

Metrics reported
----------------
- AUC-ROC (standard for knowledge tracing).
- Accuracy (threshold = 0.5).
- Log-loss.
- F1 score.

Outputs
-------
- ``output/auc_curves.png``     -- superposed ROC curves.
- ``output/bkt_comparison.json``-- machine-readable metrics.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Sequence

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import torch
from sklearn.metrics import (
    accuracy_score,
    f1_score,
    log_loss,
    roc_auc_score,
    roc_curve,
)

from dkt_model import DKTModel
from train_dkt import split_students, RANDOM_SEED

# --- Palette Togo (cf. lib/theme/app_theme.dart) ---------------------------
TOGO_GREEN = "#006837"
TOGO_ORANGE = "#D97700"
TOGO_GREY = "#9E9E9E"

# --- Parametres BKT (miroir de backend/services/bkt_service.py) -----------
BKT_P_LEARN = 0.20
BKT_P_SLIP = 0.10
BKT_P_GUESS = 0.20
BKT_P_L_INIT = 0.10
EPS = 1e-9

# Nombre max d'eleves du test set evalues (limite de temps).
DEFAULT_MAX_STUDENTS = 500


def bkt_predict_and_update(
    pL: float,
    correct: int,
    p_learn: float = BKT_P_LEARN,
    p_slip: float = BKT_P_SLIP,
    p_guess: float = BKT_P_GUESS,
) -> tuple[float, float]:
    """One BKT step.

    Parameters
    ----------
    pL:
        Prior probability of mastery ``P(L)``.
    correct:
        0 or 1, the observed answer at this step.
    p_learn, p_slip, p_guess:
        BKT parameters (P(T), P(S), P(G)).

    Returns
    -------
    (p_correct, pL_next)
        ``p_correct`` is the **prior** ``P(correct)`` (the prediction),
        ``pL_next`` is the posterior ``P(L)`` after the transition step.
    """
    p_correct = pL * (1.0 - p_slip) + (1.0 - pL) * p_guess
    p_correct = float(max(p_correct, EPS))

    if correct:
        pL_given_obs = (pL * (1.0 - p_slip)) / p_correct
    else:
        p_incorrect = 1.0 - p_correct
        p_incorrect = float(max(p_incorrect, EPS))
        pL_given_obs = (pL * p_slip) / p_incorrect

    pL_next = pL_given_obs + (1.0 - pL_given_obs) * p_learn
    pL_next = float(np.clip(pL_next, 0.0, 1.0))
    return p_correct, pL_next


def evaluate(
    max_students: int = DEFAULT_MAX_STUDENTS,
    seed: int = RANDOM_SEED,
) -> dict:
    """Run the evaluation and write artefacts.

    Returns
    -------
    dict
        Full metrics dictionary (also written to JSON).
    """
    output_dir = Path(__file__).parent / "output"
    csv_path = output_dir / "sequences.csv"
    model_path = output_dir / "dkt_model.pt"

    if not csv_path.exists():
        raise FileNotFoundError(
            f"Sequences file not found: {csv_path}. "
            "Run generate_sequences.py first."
        )
    if not model_path.exists():
        raise FileNotFoundError(
            f"Model file not found: {model_path}. "
            "Run train_dkt.py first."
        )

    df = pd.read_csv(csv_path)
    n_questions = int(df["question_idx"].max()) + 1

    # Chargement du modele DKT.
    model = DKTModel(n_questions=n_questions)
    model.load_state_dict(torch.load(model_path, map_location="cpu"))
    model.eval()

    # Meme split que l'entraînement (reproductible).
    _, _, test_ids = split_students(df, seed=seed)
    test_ids = test_ids[:max_students]
    print(f"[INFO] Evaluation sur {len(test_ids)} eleves du test set.")

    dkt_preds: list[float] = []
    dkt_targets: list[int] = []
    bkt_preds: list[float] = []
    bkt_targets: list[int] = []

    for student_id in test_ids:
        student_seq = (
            df[df["student_id"] == student_id]
            .sort_values("sequence_position")
            .reset_index(drop=True)
        )

        # --- DKT ---
        history: list[tuple[int, int]] = []
        for _, row in student_seq.iterrows():
            if len(history) > 0:
                pred = model.predict_next(history)
                dkt_preds.append(float(pred[int(row["question_idx"])]))
                dkt_targets.append(int(row["correct"]))
            history.append((int(row["question_idx"]), int(row["correct"])))

        # --- BKT (baseline) ---
        pL = BKT_P_L_INIT
        for _, row in student_seq.iterrows():
            correct = int(row["correct"])
            p_correct, pL = bkt_predict_and_update(pL, correct)
            bkt_preds.append(p_correct)
            bkt_targets.append(correct)

    dkt_preds_arr = np.array(dkt_preds, dtype=float)
    dkt_targets_arr = np.array(dkt_targets, dtype=int)
    bkt_preds_arr = np.array(bkt_preds, dtype=float)
    bkt_targets_arr = np.array(bkt_targets, dtype=int)

    # Bornage numerique pour log_loss et roc_auc_score.
    dkt_preds_arr = np.clip(dkt_preds_arr, 1e-7, 1.0 - 1e-7)
    bkt_preds_arr = np.clip(bkt_preds_arr, 1e-7, 1.0 - 1e-7)

    # --- Metriques ---
    dkt_auc = float(roc_auc_score(dkt_targets_arr, dkt_preds_arr))
    bkt_auc = float(roc_auc_score(bkt_targets_arr, bkt_preds_arr))
    dkt_acc = float(accuracy_score(dkt_targets_arr, (dkt_preds_arr >= 0.5).astype(int)))
    bkt_acc = float(accuracy_score(bkt_targets_arr, (bkt_preds_arr >= 0.5).astype(int)))
    dkt_ll = float(log_loss(dkt_targets_arr, dkt_preds_arr, labels=[0, 1]))
    bkt_ll = float(log_loss(bkt_targets_arr, bkt_preds_arr, labels=[0, 1]))
    dkt_f1 = float(f1_score(dkt_targets_arr, (dkt_preds_arr >= 0.5).astype(int)))
    bkt_f1 = float(f1_score(bkt_targets_arr, (bkt_preds_arr >= 0.5).astype(int)))

    print("-" * 60)
    print(f"DKT  AUC: {dkt_auc:.4f}  Acc: {dkt_acc:.4f}  "
          f"LogLoss: {dkt_ll:.4f}  F1: {dkt_f1:.4f}")
    print(f"BKT  AUC: {bkt_auc:.4f}  Acc: {bkt_acc:.4f}  "
          f"LogLoss: {bkt_ll:.4f}  F1: {bkt_f1:.4f}")
    print(f"Diff AUC : {(dkt_auc - bkt_auc) * 100:+.2f} points")
    print("-" * 60)

    # --- ROC curves ---
    fpr_dkt, tpr_dkt, _ = roc_curve(dkt_targets_arr, dkt_preds_arr)
    fpr_bkt, tpr_bkt, _ = roc_curve(bkt_targets_arr, bkt_preds_arr)
    roc_path = output_dir / "auc_curves.png"
    _plot_roc_curves(
        fpr_dkt, tpr_dkt, dkt_auc,
        fpr_bkt, tpr_bkt, bkt_auc,
        roc_path,
    )

    # --- JSON ---
    comparison = {
        "dkt": {
            "auc": dkt_auc,
            "accuracy": dkt_acc,
            "log_loss": dkt_ll,
            "f1": dkt_f1,
            "n_predictions": int(len(dkt_preds_arr)),
        },
        "bkt": {
            "auc": bkt_auc,
            "accuracy": bkt_acc,
            "log_loss": bkt_ll,
            "f1": bkt_f1,
            "n_predictions": int(len(bkt_preds_arr)),
            "params": {
                "p_learn": BKT_P_LEARN,
                "p_slip": BKT_P_SLIP,
                "p_guess": BKT_P_GUESS,
                "pL_init": BKT_P_L_INIT,
            },
        },
        "difference_auc": dkt_auc - bkt_auc,
        "difference_accuracy": dkt_acc - bkt_acc,
        "difference_log_loss": dkt_ll - bkt_ll,
        "n_students_evaluated": int(len(test_ids)),
    }
    json_path = output_dir / "bkt_comparison.json"
    with open(json_path, "w", encoding="utf-8") as f:
        json.dump(comparison, f, indent=2, ensure_ascii=False)

    print(f"[OK] ROC curves sauvegardees : {roc_path}")
    print(f"[OK] Metriques JSON           : {json_path}")
    return comparison


def _plot_roc_curves(
    fpr_dkt: Sequence[float],
    tpr_dkt: Sequence[float],
    auc_dkt: float,
    fpr_bkt: Sequence[float],
    tpr_bkt: Sequence[float],
    auc_bkt: float,
    out_path: Path,
) -> None:
    """Plot superposed ROC curves with the Togo palette."""
    plt.figure(figsize=(8, 6))
    plt.plot(fpr_dkt, tpr_dkt, color=TOGO_GREEN, linewidth=2.5,
             label=f"DKT (AUC = {auc_dkt:.3f})")
    plt.plot(fpr_bkt, tpr_bkt, color=TOGO_ORANGE, linewidth=2.5,
             label=f"BKT (AUC = {auc_bkt:.3f})")
    plt.plot([0, 1], [0, 1], color=TOGO_GREY, linestyle="--", alpha=0.6,
             label="Random (AUC = 0.500)")
    plt.xlabel("False Positive Rate")
    plt.ylabel("True Positive Rate")
    plt.title("DKT vs BKT -- ROC Curves")
    plt.legend(loc="lower right")
    plt.grid(True, alpha=0.3)
    plt.tight_layout()
    plt.savefig(out_path, dpi=120)
    plt.close()


def main() -> None:
    """CLI entry point."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--max-students", type=int, default=DEFAULT_MAX_STUDENTS)
    parser.add_argument("--seed", type=int, default=RANDOM_SEED)
    args = parser.parse_args()
    evaluate(max_students=args.max_students, seed=args.seed)


if __name__ == "__main__":
    main()
