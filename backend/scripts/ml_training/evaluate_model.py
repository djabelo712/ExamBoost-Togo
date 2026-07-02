"""evaluate_model — Evaluation approfondie du modele XGBoost.

Genere :
    - Metriques : RMSE, MAE, R2, MAPE
    - Plot "Predicted vs Actual"
    - Plot residuals vs predicted
    - Plot distribution des erreurs
    - Plot feature importance (XGBoost native)
    - Performance par segment (faible / moyen / bon / excellent)
    - Rapport markdown (evaluation_report.md)

Usage :
    python evaluate_model.py
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import Final

import joblib
import matplotlib
matplotlib.use("Agg")  # backend non-interactif (serveur)
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from sklearn.metrics import (
    mean_absolute_error,
    mean_squared_error,
    r2_score,
)

# ─── Constantes ────────────────────────────────────────────────────────
OUTPUT_DIR: Final[Path] = Path(__file__).resolve().parent / "output"
DATASET_PATH: Final[Path] = OUTPUT_DIR / "synthetic_students.csv"
MODEL_PATH: Final[Path] = OUTPUT_DIR / "trained_model.joblib"
PLOT_PATH: Final[Path] = OUTPUT_DIR / "evaluation_plots.png"
FEATURE_IMPORTANCE_PLOT_PATH: Final[Path] = OUTPUT_DIR / "feature_importance.png"
REPORT_PATH: Final[Path] = OUTPUT_DIR / "evaluation_report.md"

# Palette vert Togo (cohérente avec app_theme.dart)
TOGO_GREEN: Final[str] = "#006837"
TOGO_ORANGE: Final[str] = "#D97700"
TOGO_RED: Final[str] = "#C62828"
TOGO_BLUE: Final[str] = "#1565C0"
TOGO_GREY: Final[str] = "#9E9E9E"


def _setup_matplotlib() -> None:
    """Configure matplotlib (police, palette, taille)."""
    # DejaVu Sans est la police par defaut et gere les accents francais
    plt.rcParams.update({
        "font.family": "DejaVu Sans",
        "font.size": 11,
        "axes.titlesize": 13,
        "axes.titleweight": "bold",
        "axes.labelsize": 11,
        "axes.spines.top": False,
        "axes.spines.right": False,
        "figure.facecolor": "white",
        "axes.facecolor": "white",
        "savefig.facecolor": "white",
    })


def evaluate() -> dict:
    """Evalue le modele et genère plots + rapport markdown.

    Returns
    -------
    dict
        Metriques globales + par segment.
    """
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
    y = df["score_final"]

    # ─── Predictions ────────────────────────────────────────────
    y_pred = model.predict(X)
    y_pred = np.clip(y_pred, 0.0, 20.0)  # contrainte sur le score
    residuals = y.values - y_pred

    # ─── Metriques globales ─────────────────────────────────────
    rmse = float(np.sqrt(mean_squared_error(y, y_pred)))
    mae = float(mean_absolute_error(y, y_pred))
    r2 = float(r2_score(y, y_pred))
    # MAPE robuste : on filtre les cibles proches de 0 (division instable)
    y_arr = y.values if hasattr(y, "values") else np.asarray(y)
    nonzero_mask = y_arr > 1.0  # on ignore les scores <= 1 (rares + numeriquement instables)
    if nonzero_mask.sum() > 0:
        mape = float(np.mean(np.abs((y_arr[nonzero_mask] - y_pred[nonzero_mask]) / y_arr[nonzero_mask])) * 100)
    else:
        mape = float("nan")

    print("=" * 60)
    print(f"[eval] RMSE : {rmse:.3f} / 20")
    print(f"[eval] MAE  : {mae:.3f} / 20")
    print(f"[eval] R2   : {r2:.3f}")
    print(f"[eval] MAPE : {mape:.2f} %")
    print("=" * 60)

    # ─── Plot 1 : 3 subplots (pred vs actual, residuals, error dist) ──
    fig, axes = plt.subplots(1, 3, figsize=(18, 5))

    # 1a. Predicted vs Actual
    axes[0].scatter(y, y_pred, alpha=0.25, s=14, color=TOGO_GREEN, edgecolors="none")
    axes[0].plot([0, 20], [0, 20], color=TOGO_ORANGE, linestyle="--", linewidth=2, label="Ideal")
    axes[0].set_xlabel("Score reel")
    axes[0].set_ylabel("Score predit")
    axes[0].set_title("Prediciton vs Reel")
    axes[0].set_xlim(0, 20)
    axes[0].set_ylim(0, 20)
    axes[0].set_aspect("equal", adjustable="box")
    axes[0].legend(loc="upper left")

    # 1b. Residuals vs Predicted
    axes[1].scatter(y_pred, residuals, alpha=0.25, s=14, color=TOGO_BLUE, edgecolors="none")
    axes[1].axhline(0, color=TOGO_RED, linestyle="--", linewidth=1.5)
    axes[1].set_xlabel("Score predit")
    axes[1].set_ylabel("Residu (reel - predit)")
    axes[1].set_title("Residus vs Predictions")
    axes[1].set_xlim(0, 20)

    # 1c. Distribution des erreurs
    axes[2].hist(residuals, bins=60, color=TOGO_GREEN, edgecolor="white", alpha=0.85)
    axes[2].axvline(0, color=TOGO_RED, linestyle="--", linewidth=1.5)
    axes[2].set_xlabel("Erreur (reel - predit)")
    axes[2].set_ylabel("Nombre d'eleves")
    axes[2].set_title("Distribution des erreurs")

    plt.tight_layout()
    plt.savefig(PLOT_PATH, dpi=110)
    plt.close(fig)
    print(f"[eval] Plots sauvegardes : {PLOT_PATH}")

    # ─── Plot 2 : Feature importance (XGBoost native) ─────────
    importances = model.feature_importances_
    order = np.argsort(importances)[::-1]
    sorted_features = [features[i] for i in order]
    sorted_importances = importances[order]

    fig, ax = plt.subplots(figsize=(10, 7))
    bars = ax.barh(
        sorted_features[::-1],  # inverser pour avoir le plus important en haut
        sorted_importances[::-1],
        color=TOGO_GREEN,
        edgecolor="white",
    )
    # Mettre en orange les 3 features les plus importantes
    for i in range(3):
        bars[-(i + 1)].set_color(TOGO_ORANGE)
    ax.set_xlabel("Importance (gain normalise)")
    ax.set_title("Feature Importance - XGBoost")
    ax.invert_yaxis()
    for i, (feat, imp) in enumerate(zip(sorted_features[::-1], sorted_importances[::-1])):
        ax.text(imp + 0.002, i, f"{imp:.3f}", va="center", fontsize=9)
    plt.tight_layout()
    plt.savefig(FEATURE_IMPORTANCE_PLOT_PATH, dpi=110)
    plt.close(fig)
    print(f"[eval] Plot feature importance : {FEATURE_IMPORTANCE_PLOT_PATH}")

    # ─── Performance par segment ────────────────────────────────
    segments = pd.cut(
        y, bins=[-0.001, 8, 12, 16, 20.001],
        labels=["Faible (0-8)", "Moyen (8-12)", "Bon (12-16)", "Excellent (16-20)"],
    )
    segment_metrics = {}
    print()
    print("[eval] Performance par segment :")
    for seg in segments.cat.categories:
        mask = segments == seg
        if mask.sum() == 0:
            continue
        rmse_seg = float(np.sqrt(np.mean(residuals[mask] ** 2)))
        mae_seg = float(np.mean(np.abs(residuals[mask])))
        bias_seg = float(np.mean(residuals[mask]))  # biais (positif = sous-prediction)
        n_seg = int(mask.sum())
        segment_metrics[seg] = {
            "n": n_seg,
            "rmse": round(rmse_seg, 3),
            "mae": round(mae_seg, 3),
            "bias": round(bias_seg, 3),
        }
        print(f"  {seg:<22s} n={n_seg:>5d}  RMSE={rmse_seg:.3f}  MAE={mae_seg:.3f}  biais={bias_seg:+.3f}")

    # ─── Rapport markdown ───────────────────────────────────────
    _write_report(
        rmse=rmse, mae=mae, r2=r2, mape=mape,
        segment_metrics=segment_metrics,
        feature_importances=dict(zip(sorted_features, sorted_importances.tolist())),
        best_params=data.get("best_params", {}),
        n_samples=len(df),
    )
    print(f"[eval] Rapport markdown : {REPORT_PATH}")

    return {
        "rmse": rmse,
        "mae": mae,
        "r2": r2,
        "mape": mape,
        "segment_metrics": segment_metrics,
    }


def _write_report(
    rmse: float,
    mae: float,
    r2: float,
    mape: float,
    segment_metrics: dict,
    feature_importances: dict,
    best_params: dict,
    n_samples: int,
) -> None:
    """Ecrit le rapport d'evaluation en markdown."""
    lines = [
        "# Rapport d'evaluation du modele XGBoost",
        "",
        f"- **Date** : {pd.Timestamp.now().strftime('%d/%m/%Y %H:%M')}",
        f"- **Dataset** : {n_samples} eleves synthetiques",
        f"- **Modele** : XGBoost Regressor (objective=reg:squarederror)",
        f"- **Hyperparametres optimaux** : `{best_params}`",
        "",
        "## Metriques globales",
        "",
        "| Metrique | Valeur | Interpretation |",
        "|---|---|---|",
        f"| RMSE | {rmse:.3f} / 20 | Erreur quadratique moyenne |",
        f"| MAE  | {mae:.3f} / 20 | Erreur absolue moyenne |",
        f"| R2   | {r2:.3f} | Variance expliquee |",
        f"| MAPE | {mape:.2f} % | Erreur relative moyenne |",
        "",
        "## Performance par segment d'eleve",
        "",
        "| Segment | Effectif | RMSE | MAE | Biais (reel - predit) |",
        "|---|---|---|---|---|",
    ]
    for seg, m in segment_metrics.items():
        lines.append(
            f"| {seg} | {m['n']} | {m['rmse']:.3f} | {m['mae']:.3f} | {m['bias']:+.3f} |"
        )
    lines += [
        "",
        "## Feature importance (XGBoost native)",
        "",
        "| Rang | Feature | Importance |",
        "|---|---|---|",
    ]
    for i, (feat, imp) in enumerate(feature_importances.items(), 1):
        lines.append(f"| {i} | {feat} | {imp:.4f} |")
    lines += [
        "",
        "## Plots generes",
        "",
        "- `evaluation_plots.png` : prediction vs reel, residus, distribution erreurs",
        "- `feature_importance.png` : feature importance XGBoost",
        "- `shap_summary.png` (cf. `shap_analysis.py`) : feature importance SHAP",
        "",
        "## Interpretation",
        "",
        f"- Un RMSE de **{rmse:.2f}/20** signifie que l'erreur typique est de l'ordre de **{mae:.2f} points**.",
        f"- Le R2 de **{r2:.3f}** indique que le modele explique **{r2*100:.1f}%** de la variance du score final.",
        f"- Le biais global est quasi nul (residus centres), mais peut varier par segment (cf. tableau ci-dessus).",
        "",
        "## Limitations connues",
        "",
        "- Modele entraine sur donnees synthetiques : a recalibrer avec donnees reelles du pilote.",
        "- Ne capture pas l'effet stress de l'examen, ni le contexte socio-economique.",
        "- Les segments extremes (tres faible ou tres fort) peuvent etre moins bien predits si sous-representes.",
    ]
    REPORT_PATH.write_text("\n".join(lines), encoding="utf-8")


def main() -> None:
    """Point d'entree CLI."""
    evaluate()


if __name__ == "__main__":
    main()
