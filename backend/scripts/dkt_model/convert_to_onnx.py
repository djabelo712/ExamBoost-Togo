"""Export the trained DKT model to ONNX for on-device Flutter inference.

The resulting ``dkt_model.onnx`` file can be loaded in the Flutter app
via the ``onnxruntime`` package, so that predictions run locally on
the phone (no network round-trip, works offline -- a hard requirement
for ExamBoost Togo where many students have intermittent connectivity).

The export uses dynamic axes for both batch size and sequence length,
so the same model file can serve a single student or a batch.

A sanity check is performed at the end of the export: we run a few
random inputs through both the PyTorch model and the ONNX model and
compare the outputs. The max absolute difference must be below 1e-5.
"""

from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
import onnxruntime as ort
import pandas as pd
import torch

from dkt_model import DKTModel
from train_dkt import split_students, RANDOM_SEED

OPSET_VERSION = 14
DEFAULT_OPSET = OPSET_VERSION
# Tolérance pour le sanity check PyTorch vs ONNX.
RTOL = 1e-4
ATOL = 1e-5


def convert(opset: int = DEFAULT_OPSET) -> Path:
    """Export the trained model to ONNX.

    Parameters
    ----------
    opset:
        ONNX opset version (>= 14 recommended).

    Returns
    -------
    Path
        Path to the exported ``.onnx`` file.
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

    model = DKTModel(n_questions=n_questions)
    model.load_state_dict(torch.load(model_path, map_location="cpu"))
    model.eval()

    # Entree factice pour le tracing (batch=1, seq=50).
    dummy_input = torch.zeros(1, 50, 2 * n_questions, dtype=torch.float32)

    onnx_path = output_dir / "dkt_model.onnx"
    torch.onnx.export(
        model,
        dummy_input,
        str(onnx_path),
        export_params=True,
        opset_version=opset,
        do_constant_folding=True,
        input_names=["input"],
        output_names=["output"],
        dynamic_axes={
            "input": {0: "batch_size", 1: "sequence_length"},
            "output": {0: "batch_size", 1: "sequence_length"},
        },
    )

    # --- Verification d'integrite ---
    _sanity_check(model, onnx_path, n_questions)
    print(f"[OK] Modele ONNX exporte : {onnx_path}")
    print(f"[INFO] Taille du fichier : {onnx_path.stat().st_size / 1024:.1f} KB")
    return onnx_path


def _sanity_check(
    model: DKTModel,
    onnx_path: Path,
    n_questions: int,
    n_samples: int = 5,
) -> None:
    """Compare PyTorch and ONNX outputs on random inputs.

    Raises ``AssertionError`` if the max absolute difference exceeds
    the configured tolerance.
    """
    session = ort.InferenceSession(str(onnx_path), providers=["CPUExecutionProvider"])
    input_name = session.get_inputs()[0].name

    max_diff = 0.0
    for _ in range(n_samples):
        batch = np.random.randint(1, 4)
        seq_len = np.random.randint(5, 50)
        x_np = np.random.rand(batch, seq_len, 2 * n_questions).astype(np.float32)
        x_torch = torch.from_numpy(x_np)

        with torch.no_grad():
            out_torch = model(x_torch).numpy()
        out_onnx = session.run(None, {input_name: x_np})[0]

        diff = float(np.max(np.abs(out_torch - out_onnx)))
        max_diff = max(max_diff, diff)

    print(f"[INFO] Sanity check -> max abs diff (PyTorch vs ONNX) = {max_diff:.2e}")
    assert max_diff < ATOL, (
        f"ONNX export mismatch: max diff {max_diff:.2e} >= atol {ATOL:.2e}"
    )
    print(f"[OK] Sanity check passe (tolerance={ATOL}).")


def main() -> None:
    """CLI entry point."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--opset", type=int, default=DEFAULT_OPSET)
    args = parser.parse_args()
    convert(opset=args.opset)


if __name__ == "__main__":
    main()
