"""Train the DKT model on the synthetic sequences.

Pipeline
--------
1. Load ``output/sequences.csv``.
2. Group rows by ``student_id`` to obtain one trajectory per student.
3. Split train / val / test by student id (70 / 15 / 15).
4. Build a PyTorch ``Dataset`` that returns, for each student:
   - ``x``     : (max_length, 2*n_questions)  one-hot input sequence.
   - ``target``: (max_length, n_questions)    correctness of the NEXT
                 question placed at its question index.
   - ``mask``  : (max_length,) bool           True where a target exists.
5. Train with BCE loss (reduction='none' + manual mask) and Adam.
6. Early stopping on val loss (patience=5).
7. Save best weights to ``output/dkt_model.pt`` and the loss curve to
   ``output/training_history.png``.

The target shifting (target[t] = next question's outcome) is critical:
without it the model could trivially copy the current answer from its
input, which would inflate AUC artificially.
"""

from __future__ import annotations

import argparse
import random
from pathlib import Path
from typing import Sequence

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import torch
import torch.nn as nn
from torch.utils.data import DataLoader, Dataset

from dkt_model import DKTModel

# --- Palette Togo (cf. lib/theme/app_theme.dart) ---------------------------
TOGO_GREEN = "#006837"
TOGO_ORANGE = "#D97700"
TOGO_GREEN_LIGHT = "#4CAF7A"

# --- Hyperparametres par defaut --------------------------------------------
# Le batch_size est monte a 128 (vs. 32 dans la spec originale) pour
# accelérer l'entraînement CPU ; le lr reste a 1e-3 (compatible avec
# Adam). Le nombre d'epochs est 30 avec early stopping (patience=5),
# largement suffisant pour converger sur les donnees synthetiques.
DEFAULT_EPOCHS = 30
DEFAULT_BATCH_SIZE = 128
DEFAULT_LR = 1e-3
DEFAULT_PATIENCE = 5
DEFAULT_HIDDEN_DIM = 200
DEFAULT_DROPOUT = 0.5
DEFAULT_MAX_LENGTH = 50
RANDOM_SEED = 42


class SequenceDataset(Dataset):
    """PyTorch dataset of student trajectories.

    Each item is a tuple ``(x, target, mask)`` where:

    - ``x``      : float tensor ``(max_length, 2 * n_questions)``
    - ``target`` : float tensor ``(max_length, n_questions)``
    - ``mask``   : bool tensor ``(max_length,)`` -- True at timestep ``t``
      if a next-step target exists at ``t`` (i.e. ``t < len(seq) - 1``).
    """

    def __init__(
        self,
        df: pd.DataFrame,
        n_questions: int,
        max_length: int = DEFAULT_MAX_LENGTH,
    ) -> None:
        self.n_questions = int(n_questions)
        self.max_length = int(max_length)
        # Une trajectoire par eleve, triee par position chronologique.
        self.sequences: list[list[tuple[int, int]]] = []
        for _, group in df.groupby("student_id"):
            group = group.sort_values("sequence_position")
            seq = [
                (int(row["question_idx"]), int(row["correct"]))
                for _, row in group.iterrows()
            ]
            self.sequences.append(seq)

    def __len__(self) -> int:
        return len(self.sequences)

    def __getitem__(self, idx: int) -> tuple[torch.Tensor, torch.Tensor, torch.Tensor]:
        seq = self.sequences[idx]
        T = min(len(seq), self.max_length)

        x = torch.zeros(self.max_length, 2 * self.n_questions, dtype=torch.float32)
        target = torch.zeros(self.max_length, self.n_questions, dtype=torch.float32)
        mask = torch.zeros(self.max_length, dtype=torch.bool)

        # Encodage de l'observation a chaque timestep.
        for t in range(T):
            q_idx, correct = seq[t]
            x[t, q_idx] = 1.0
            if correct:
                x[t, self.n_questions + q_idx] = 1.0

        # Cible decalee : output[t] predit la question suivante.
        # target[t, q_next] = correct_next ; mask[t] = True si t+1 < T.
        for t in range(T - 1):
            next_q, next_c = seq[t + 1]
            if t + 1 < self.max_length:
                target[t, next_q] = float(next_c)
                mask[t] = True

        return x, target, mask


def set_seed(seed: int) -> None:
    """Fix all random seeds for reproducibility."""
    random.seed(seed)
    np.random.seed(seed)
    torch.manual_seed(seed)
    torch.use_deterministic_algorithms(False)


def split_students(
    df: pd.DataFrame, seed: int = RANDOM_SEED
) -> tuple[list[str], list[str], list[str]]:
    """Split unique student ids into train / val / test (70/15/15)."""
    student_ids = list(df["student_id"].unique())
    rng = np.random.default_rng(seed)
    rng.shuffle(student_ids)
    n_train = int(0.70 * len(student_ids))
    n_val = int(0.15 * len(student_ids))
    train_ids = student_ids[:n_train]
    val_ids = student_ids[n_train : n_train + n_val]
    test_ids = student_ids[n_train + n_val :]
    return train_ids, val_ids, test_ids


def masked_bce(
    output: torch.Tensor,
    target: torch.Tensor,
    mask: torch.Tensor,
) -> torch.Tensor:
    """Mean BCE loss over masked timesteps.

    Parameters
    ----------
    output:
        ``(batch, seq, n_questions)`` predicted probabilities.
    target:
        ``(batch, seq, n_questions)`` target probabilities (0 or 1).
    mask:
        ``(batch, seq)`` bool tensor -- True where the loss should count.
    """
    criterion = nn.BCELoss(reduction="none")
    loss = criterion(output, target.float())
    mask_f = mask.unsqueeze(-1).float()
    numerator = (loss * mask_f).sum()
    denominator = mask_f.sum().clamp(min=1.0)
    return numerator / denominator


def train(
    epochs: int = DEFAULT_EPOCHS,
    batch_size: int = DEFAULT_BATCH_SIZE,
    lr: float = DEFAULT_LR,
    patience: int = DEFAULT_PATIENCE,
    hidden_dim: int = DEFAULT_HIDDEN_DIM,
    dropout: float = DEFAULT_DROPOUT,
    max_length: int = DEFAULT_MAX_LENGTH,
    seed: int = RANDOM_SEED,
) -> dict:
    """Run the full training loop and save artefacts.

    Returns
    -------
    dict
        Summary metrics (best_val_loss, epochs_trained, paths...).
    """
    set_seed(seed)

    output_dir = Path(__file__).parent / "output"
    output_dir.mkdir(parents=True, exist_ok=True)

    csv_path = output_dir / "sequences.csv"
    if not csv_path.exists():
        raise FileNotFoundError(
            f"Sequences file not found: {csv_path}. "
            "Run generate_sequences.py first."
        )

    df = pd.read_csv(csv_path)
    n_questions = int(df["question_idx"].max()) + 1
    print(f"[INFO] {len(df)} interactions, {df['student_id'].nunique()} eleves, "
          f"{n_questions} questions.")

    # Split par eleve (pas de fuite train -> val).
    train_ids, val_ids, _ = split_students(df, seed=seed)
    train_df = df[df["student_id"].isin(train_ids)]
    val_df = df[df["student_id"].isin(val_ids)]
    print(f"[INFO] Split -> train: {len(train_ids)} eleves, "
          f"val: {len(val_ids)} eleves.")

    train_ds = SequenceDataset(train_df, n_questions, max_length=max_length)
    val_ds = SequenceDataset(val_df, n_questions, max_length=max_length)
    train_loader = DataLoader(train_ds, batch_size=batch_size, shuffle=True)
    val_loader = DataLoader(val_ds, batch_size=batch_size, shuffle=False)

    device = torch.device("cpu")  # Mode CPU (suffisant pour 10k eleves).
    model = DKTModel(
        n_questions=n_questions,
        hidden_dim=hidden_dim,
        dropout=dropout,
    ).to(device)
    optimizer = torch.optim.Adam(model.parameters(), lr=lr)

    train_losses: list[float] = []
    val_losses: list[float] = []
    best_val_loss = float("inf")
    patience_counter = 0
    epochs_trained = 0
    best_model_path = output_dir / "dkt_model.pt"

    for epoch in range(epochs):
        # --- Entraînement ---
        model.train()
        epoch_loss = 0.0
        for x, target, mask in train_loader:
            x = x.to(device)
            target = target.to(device)
            mask = mask.to(device)
            optimizer.zero_grad()
            output = model(x)
            loss = masked_bce(output, target, mask)
            loss.backward()
            optimizer.step()
            epoch_loss += loss.item()
        train_loss = epoch_loss / max(len(train_loader), 1)
        train_losses.append(train_loss)

        # --- Validation ---
        model.eval()
        val_loss_sum = 0.0
        with torch.no_grad():
            for x, target, mask in val_loader:
                x = x.to(device)
                target = target.to(device)
                mask = mask.to(device)
                output = model(x)
                loss = masked_bce(output, target, mask)
                val_loss_sum += loss.item()
        val_loss = val_loss_sum / max(len(val_loader), 1)
        val_losses.append(val_loss)

        epochs_trained = epoch + 1
        print(
            f"Epoch {epoch + 1:02d}/{epochs} - "
            f"train: {train_loss:.4f} - val: {val_loss:.4f}"
        )

        # --- Early stopping ---
        if val_loss < best_val_loss - 1e-6:
            best_val_loss = val_loss
            torch.save(model.state_dict(), best_model_path)
            patience_counter = 0
        else:
            patience_counter += 1
            if patience_counter >= patience:
                print(f"[INFO] Early stopping at epoch {epoch + 1} "
                      f"(patience={patience}).")
                break

    # --- Courbe de perte ---
    history_path = output_dir / "training_history.png"
    _plot_training_history(train_losses, val_losses, history_path)

    summary = {
        "epochs_trained": epochs_trained,
        "best_val_loss": best_val_loss,
        "n_questions": n_questions,
        "hidden_dim": hidden_dim,
        "dropout": dropout,
        "model_path": str(best_model_path),
        "history_path": str(history_path),
    }
    print(f"[OK] Meilleur val loss : {best_val_loss:.4f}")
    print(f"[OK] Modele sauvegarde : {best_model_path}")
    print(f"[OK] Courbe d'entrainement : {history_path}")
    return summary


def _plot_training_history(
    train_losses: Sequence[float],
    val_losses: Sequence[float],
    out_path: Path,
) -> None:
    """Plot and save the BCE loss curve with the Togo green palette."""
    plt.figure(figsize=(10, 5))
    plt.plot(train_losses, label="Train loss", color=TOGO_GREEN, linewidth=2)
    plt.plot(val_losses, label="Val loss", color=TOGO_ORANGE, linewidth=2)
    plt.xlabel("Epoch")
    plt.ylabel("Loss (BCE)")
    plt.title("DKT Training History")
    plt.legend()
    plt.grid(True, alpha=0.3)
    plt.tight_layout()
    plt.savefig(out_path, dpi=120)
    plt.close()


def main() -> None:
    """CLI entry point."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--epochs", type=int, default=DEFAULT_EPOCHS)
    parser.add_argument("--batch-size", type=int, default=DEFAULT_BATCH_SIZE)
    parser.add_argument("--lr", type=float, default=DEFAULT_LR)
    parser.add_argument("--patience", type=int, default=DEFAULT_PATIENCE)
    parser.add_argument("--hidden-dim", type=int, default=DEFAULT_HIDDEN_DIM)
    parser.add_argument("--dropout", type=float, default=DEFAULT_DROPOUT)
    parser.add_argument("--max-length", type=int, default=DEFAULT_MAX_LENGTH)
    parser.add_argument("--seed", type=int, default=RANDOM_SEED)
    args = parser.parse_args()

    train(
        epochs=args.epochs,
        batch_size=args.batch_size,
        lr=args.lr,
        patience=args.patience,
        hidden_dim=args.hidden_dim,
        dropout=args.dropout,
        max_length=args.max_length,
        seed=args.seed,
    )


if __name__ == "__main__":
    main()
