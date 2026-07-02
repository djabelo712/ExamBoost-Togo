"""shap_analysis — Analyse SHAP pour expliquer les predictions du modele.

SHAP (SHapley Additive exPlanations) decompose chaque prediction en contributions
individuelles des features, base sur la theorie des valeurs de Shapley (jeux
cooperatifs). Pour XGBoost, on utilise TreeExplainer (Lundberg et al. 2020)
qui calcule les SHAP values en temps polynomial via Tree SHAP.

Plots generes :
    - shap_summary.png          : top 10 features par impact SHAP absolu
    - shap_dependence_<feat>.png : dependence plot pour top 3 features
    - shap_waterfall_<type>.png  : waterfall pour 3 eleves types
                                  (faible / moyen / fort)
    - shap_bar.png              : bar plot global (|SHAP| moyen par feature)

Usage :
    python shap_analysis.py
"""

from __future__ import annotations

from pathlib import Path
from typing import Final

import joblib
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import shap

# ─── Constantes ────────────────────────────────────────────────────────
OUTPUT_DIR: Final[Path] = Path(__file__).resolve().parent / "output"
DATASET_PATH: Final[Path] = OUTPUT_DIR / "synthetic_students.csv"
MODEL_PATH: Final[Path] = OUTPUT_DIR / "trained_model.joblib"
SUMMARY_PLOT_PATH: Final[Path] = OUTPUT_DIR / "shap_summary.png"
BAR_PLOT_PATH: Final[Path] = OUTPUT_DIR / "shap_bar.png"

TOP_FEATURES_FOR_DEPENDENCE: Final[list[str]] = [
    "pL_global",
    "last_score_simulation",
    "pL_maths",
]

# 3 eleves types (indice approximatif, ajuste au runtime)
STUDENT_TYPES: Final[list[tuple[str, str]]] = [
    ("faible", "eleve faible (score < 6)"),
    ("moyen", "eleve moyen (10 <= score < 13)"),
    ("fort", "eleve fort (score >= 16)"),
]

# Palette vert Togo
TOGO_GREEN: Final[str] = "#006837"
TOGO_ORANGE: Final[str] = "#D97700"


def _setup_matplotlib() -> None:
    """Configure matplotlib (police, palette, taille)."""
    plt.rcParams.update({
        "font.family": "DejaVu Sans",
        "font.size": 11,
        "axes.titlesize": 13,
        "axes.titleweight": "bold",
        "axes.spines.top": False,
        "axes.spines.right": False,
        "figure.facecolor": "white",
        "axes.facecolor": "white",
        "savefig.facecolor": "white",
    })


def _find_student_indices(y: np.ndarray) -> dict[str, int]:
    """Trouve 3 indices d'eleves representatifs (faible / moyen / fort).

    Parameters
    ----------
    y : np.ndarray
        Scores finaux reels.

    Returns
    -------
    dict[str, int]
        Mapping {"faible": idx, "moyen": idx, "fort": idx}.
    """
    indices = {"faible": -1, "moyen": -1, "fort": -1}

    # Faible : score le plus bas
    weak_mask = y < 6
    if weak_mask.any():
        indices["faible"] = int(np.where(weak_mask)[0][0])

    # Moyen : score proche de 11
    medium_mask = (y >= 10) & (y < 13)
    if medium_mask.any():
        # Prendre le score le plus proche de 11
        diff = np.abs(y[medium_mask] - 11)
        idx_local = int(np.argmin(diff))
        indices["moyen"] = int(np.where(medium_mask)[0][idx_local])

    # Fort : score le plus eleve
    strong_mask = y >= 16
    if strong_mask.any():
        diff = np.abs(y[strong_mask] - 17)
        idx_local = int(np.argmin(diff))
        indices["fort"] = int(np.where(strong_mask)[0][idx_local])

    return indices


def analyze() -> None:
    """Calcule les SHAP values et genere tous les plots."""
    _setup_matplotlib()

    if not MODEL_PATH.exists():
        raise FileNotFoundError(
            f"Modele introuvable : {MODEL_PATH}. "
            "Lance d'abord : python train_score_predictor.py"
        )
    if not DATASET_PATH.exists():
        raise FileNotFoundError(
            f"Dataset introuvable : {DATASET_PATH}. "
            "Lance d'abord : python generate_synthetic_students.py"
        )

    # ─── Chargement ─────────────────────────────────────────────
    data = joblib.load(MODEL_PATH)
    model = data["model"]
    features = data["features"]

    df = pd.read_csv(DATASET_PATH)
    X = df[features]
    y = df["score_final"].values

    # ─── Calcul SHAP ────────────────────────────────────────────
    print("[shap] Construction du TreeExplainer...")
    explainer = shap.TreeExplainer(model)
    print("[shap] Calcul des SHAP values sur tout le dataset...")
    shap_values = explainer.shap_values(X)
    print(f"[shap] SHAP values shape : {shap_values.shape}")
    print(f"[shap] Base value (expected) : {explainer.expected_value:.3f}")

    # ─── Plot 1 : Summary plot (beeswarm) ──────────────────────
    plt.figure(figsize=(10, 7))
    shap.summary_plot(
        shap_values, X, show=False, max_display=10,
        color_bar=True, plot_type="dot",
    )
    plt.title("SHAP Summary - Top 10 features par impact")
    plt.tight_layout()
    plt.savefig(SUMMARY_PLOT_PATH, dpi=110, bbox_inches="tight")
    plt.close()
    print(f"[shap] Summary plot : {SUMMARY_PLOT_PATH}")

    # ─── Plot 2 : Bar plot (|SHAP| moyen) ──────────────────────
    plt.figure(figsize=(10, 7))
    shap.summary_plot(
        shap_values, X, show=False, max_display=14,
        plot_type="bar", color=TOGO_GREEN,
    )
    plt.title("SHAP - Importance moyenne (|SHAP|) par feature")
    plt.tight_layout()
    plt.savefig(BAR_PLOT_PATH, dpi=110, bbox_inches="tight")
    plt.close()
    print(f"[shap] Bar plot : {BAR_PLOT_PATH}")

    # ─── Plot 3 : Dependence plots pour top 3 features ─────────
    for feat in TOP_FEATURES_FOR_DEPENDENCE:
        if feat not in features:
            continue
        plt.figure(figsize=(9, 6))
        shap.dependence_plot(
            feat, shap_values, X, show=False,
            interaction_index="auto",
        )
        plt.title(f"SHAP Dependence - {feat}")
        plt.tight_layout()
        out_path = OUTPUT_DIR / f"shap_dependence_{feat}.png"
        plt.savefig(out_path, dpi=110, bbox_inches="tight")
        plt.close()
        print(f"[shap] Dependence plot : {out_path}")

    # ─── Plot 4 : Waterfall pour 3 eleves types ────────────────
    student_indices = _find_student_indices(y)
    print(f"[shap] Indices eleves types : {student_indices}")

    for student_type, description in STUDENT_TYPES:
        idx = student_indices.get(student_type, -1)
        if idx < 0:
            print(f"[shap] Aucun eleve '{student_type}' trouve, skip waterfall.")
            continue

        # Construction de l'objet Explanation pour waterfall
        explanation = shap.Explanation(
            values=shap_values[idx],
            base_values=float(explainer.expected_value),
            data=X.iloc[idx].values,
            feature_names=list(features),
        )

        plt.figure(figsize=(10, 7))
        shap.plots.waterfall(explanation, show=False, max_display=14)
        plt.title(f"SHAP Waterfall - {description} (score reel = {y[idx]:.2f}/20)")
        plt.tight_layout()
        out_path = OUTPUT_DIR / f"shap_waterfall_{student_type}.png"
        plt.savefig(out_path, dpi=110, bbox_inches="tight")
        plt.close()
        print(f"[shap] Waterfall plot : {out_path}")

    # ─── Resume texte ───────────────────────────────────────────
    mean_abs_shap = np.mean(np.abs(shap_values), axis=0)
    order = np.argsort(mean_abs_shap)[::-1]
    print()
    print("=" * 60)
    print("[shap] Importance SHAP moyenne (|SHAP|) :")
    for i in order:
        print(f"  {features[i]:<28s} {mean_abs_shap[i]:.4f}")
    print("=" * 60)


def main() -> None:
    """Point d'entree CLI."""
    analyze()


if __name__ == "__main__":
    main()
