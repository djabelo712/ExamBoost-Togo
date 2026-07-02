"""analyze_clusters — Genere les visualisations des clusters K-Means.

Produit 2 fichiers PNG dans ``output/`` :

1. **cluster_visualization.png** — Projection PCA 2D des profils eleves,
   points colores par cluster, centroides affiches en gros marqueurs
   oranges. Permet de verifier visuellement la separation des clusters.
2. **cluster_profiles.png** — Grille 2x3 de radar charts (1 par cluster),
   chaque radar montre le P(L) moyen sur les 6 matieres. Permet
   d'interpreter pedagogiquement chaque cluster (forces / faiblesses).

Palette ExamBoost Togo : vert primaire ``#006837`` + orange accent ``#D97700``.

Usage
-----
    python analyze_clusters.py
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import Final

import joblib
import matplotlib
# Backend non-interactif (genere des fichiers PNG, n'ouvre pas de fenetre)
matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402
import numpy as np  # noqa: E402
import pandas as pd  # noqa: E402
from sklearn.decomposition import PCA  # noqa: E402

# ─── Palette ExamBoost Togo (#006837 vert + #D97700 orange) ────────────────
COLOR_PRIMARY: Final[str] = "#006837"  # vert Togo
COLOR_ACCENT: Final[str] = "#D97700"   # orange Togo
COLOR_MUTED: Final[str] = "#6B7280"    # gris
# Palette etendue pour distinguer jusqu'a 6 clusters
CLUSTER_PALETTE: Final[list[str]] = [
    "#006837",  # vert Togo
    "#D97700",  # orange Togo
    "#1565C0",  # bleu info
    "#C62828",  # rouge
    "#6A1B9A",  # violet
    "#00838F",  # turquoise
]

# ─── Constantes ────────────────────────────────────────────────────────
OUTPUT_DIR: Final[Path] = Path(__file__).resolve().parent / "output"
PROFILES_CSV: Final[Path] = OUTPUT_DIR / "profiles.csv"
MODEL_PATH: Final[Path] = OUTPUT_DIR / "cluster_model.joblib"
STATS_PATH: Final[Path] = OUTPUT_DIR / "cluster_stats.json"
VIZ_PATH: Final[Path] = OUTPUT_DIR / "cluster_visualization.png"
RADAR_PATH: Final[Path] = OUTPUT_DIR / "cluster_profiles.png"

FEATURES: Final[list[str]] = [
    "pL_maths", "pL_francais", "pL_sciences",
    "pL_svt", "pL_histoire", "pL_anglais",
]
# Noms affiches (lisibles) des matieres
MATIERE_LABELS: Final[list[str]] = [
    "Maths", "Francais", "Sciences", "SVT", "Histoire", "Anglais"
]


def _resolve_font_family() -> str:
    """Retourne une police matplotlib qui gere bien les accents francais."""
    try:
        from matplotlib import font_manager
        available = {f.name for f in font_manager.fontManager.ttflist}
        for candidate in ("Noto Sans SC", "Noto Sans CJK SC", "DejaVu Sans"):
            if candidate in available:
                return candidate
    except Exception:
        pass
    return "DejaVu Sans"


FONT_FAMILY: Final[str] = _resolve_font_family()
plt.rcParams["font.family"] = FONT_FAMILY
plt.rcParams["axes.unicode_minus"] = False
plt.rcParams["figure.dpi"] = 100
plt.rcParams["savefig.dpi"] = 120
plt.rcParams["savefig.bbox"] = "tight"


def _load_artifacts() -> tuple[pd.DataFrame, dict, dict]:
    """Charge profils CSV, modele K-Means et stats JSON.

    Returns
    -------
    tuple
        (df_profils, model_data, cluster_stats)
    """
    if not PROFILES_CSV.exists():
        raise FileNotFoundError(
            f"{PROFILES_CSV} manquant. Lancer generate_synthetic_profiles.py "
            "puis cluster_students.py avant."
        )
    if not MODEL_PATH.exists():
        raise FileNotFoundError(
            f"{MODEL_PATH} manquant. Lancer cluster_students.py avant."
        )
    df = pd.read_csv(PROFILES_CSV)
    model_data = joblib.load(MODEL_PATH)
    with STATS_PATH.open("r", encoding="utf-8") as f:
        cluster_stats = json.load(f)
    return df, model_data, cluster_stats


def plot_pca_visualization(
    df: pd.DataFrame,
    model_data: dict,
    cluster_stats: dict,
) -> None:
    """Genere ``cluster_visualization.png`` : PCA 2D + centroides.

    Parameters
    ----------
    df : pd.DataFrame
        Profils eleves avec colonne ``cluster``.
    model_data : dict
        Dictionnaire charge depuis ``cluster_model.joblib`` (contient
        ``model``, ``scaler``, ``features``).
    cluster_stats : dict
        Stats par cluster (pour les noms et tailles dans la legende).
    """
    model = model_data["model"]
    scaler = model_data["scaler"]
    features = model_data["features"]
    best_k = model_data["best_k"]

    X = df[features].values
    X_scaled = scaler.transform(X)

    # PCA 2D sur les features standardisees
    pca = PCA(n_components=2, random_state=42)
    X_pca = pca.fit_transform(X_scaled)
    centroids_pca = pca.transform(model.cluster_centers_)

    # Noms de clusters pour la legende (avec taille)
    cluster_labels = {}
    for c in range(best_k):
        size = cluster_stats[str(c)]["size"]
        cluster_labels[c] = f"Cluster {c} ({size} eleves)"

    fig, ax = plt.subplots(figsize=(11, 8))

    # Points colores par cluster (alpha faible car 2000 points)
    for c in range(best_k):
        mask = df["cluster"].values == c
        color = CLUSTER_PALETTE[c % len(CLUSTER_PALETTE)]
        ax.scatter(
            X_pca[mask, 0], X_pca[mask, 1],
            c=color, s=18, alpha=0.45, edgecolors="none",
            label=cluster_labels[c],
        )

    # Centroides en gros X orange
    ax.scatter(
        centroids_pca[:, 0], centroids_pca[:, 1],
        c=COLOR_ACCENT, marker="X", s=350, edgecolors="white",
        linewidths=2.0, zorder=5, label="Centroides",
    )
    # Annotation des centroides
    for c in range(best_k):
        ax.annotate(
            f"C{c}",
            (centroids_pca[c, 0], centroids_pca[c, 1]),
            textcoords="offset points",
            xytext=(8, 8),
            fontsize=11, fontweight="bold", color=COLOR_ACCENT,
        )

    var0 = pca.explained_variance_ratio_[0] * 100
    var1 = pca.explained_variance_ratio_[1] * 100
    ax.set_xlabel(f"PCA 1 ({var0:.1f}% variance)", fontsize=12)
    ax.set_ylabel(f"PCA 2 ({var1:.1f}% variance)", fontsize=12)
    ax.set_title(
        "Profils eleves — projection PCA 2D (K-Means, "
        f"K={best_k})",
        fontsize=14, fontweight="bold", color=COLOR_PRIMARY,
    )
    ax.legend(loc="best", fontsize=10, framealpha=0.92)
    ax.grid(True, alpha=0.25, linestyle="--")
    ax.axhline(0, color=COLOR_MUTED, linewidth=0.6, alpha=0.5)
    ax.axvline(0, color=COLOR_MUTED, linewidth=0.6, alpha=0.5)

    fig.tight_layout()
    fig.savefig(VIZ_PATH)
    plt.close(fig)
    print(f"[analyze] Visualisation PCA sauvee : {VIZ_PATH}")


def plot_radar_charts(
    df: pd.DataFrame,
    model_data: dict,
    cluster_stats: dict,
) -> None:
    """Genere ``cluster_profiles.png`` : radar charts 2x3 par cluster.

    Parameters
    ----------
    df : pd.DataFrame
        Profils eleves avec colonne ``cluster``.
    model_data : dict
        Dictionnaire charge depuis ``cluster_model.joblib``.
    cluster_stats : dict
        Stats par cluster (pour les tailles).
    """
    best_k = model_data["best_k"]
    features = model_data["features"]

    # Grille 2x3 (5 clusters => 1 case vide, masquee)
    n_rows, n_cols = 2, 3
    fig, axes = plt.subplots(
        n_rows, n_cols, figsize=(15, 10),
        subplot_kw=dict(polar=True),
    )
    axes_flat = axes.flatten()

    # Angles des 6 axes du radar
    n_axes = len(features)
    angles = np.linspace(0, 2 * np.pi, n_axes, endpoint=False).tolist()
    angles += angles[:1]  # ferme la boucle

    for c in range(best_k):
        ax = axes_flat[c]
        color = CLUSTER_PALETTE[c % len(CLUSTER_PALETTE)]
        size = cluster_stats[str(c)]["size"]
        pct = cluster_stats[str(c)]["pct"]

        # Profil moyen du cluster (P(L) moyen par matiere)
        cluster_df = df[df["cluster"] == c]
        mean_values = cluster_df[features].mean().values.tolist()
        mean_values += mean_values[:1]  # ferme la boucle

        # Remplissage
        ax.fill(angles, mean_values, color=color, alpha=0.30)
        ax.plot(angles, mean_values, color=color, linewidth=2.2, marker="o", markersize=6)

        # Cercle de reference a 0.5 (seuil de maitrise BKT)
        ref = [0.5] * (n_axes + 1)
        ax.plot(angles, ref, color=COLOR_MUTED, linewidth=1.0, linestyle="--", alpha=0.6)

        # Mise en forme
        ax.set_xticks(angles[:-1])
        ax.set_xticklabels(MATIERE_LABELS, fontsize=10)
        ax.set_ylim(0, 1)
        ax.set_yticks([0.2, 0.4, 0.6, 0.8])
        ax.set_yticklabels(["0.2", "0.4", "0.6", "0.8"], fontsize=8, color=COLOR_MUTED)
        ax.set_title(
            f"Cluster {c} — {size} eleves ({pct:.1f}%)",
            fontsize=12, fontweight="bold", color=color, pad=18,
        )
        ax.grid(True, alpha=0.4)

    # Masquer les subplots vides (si best_k < n_rows * n_cols)
    for c in range(best_k, n_rows * n_cols):
        axes_flat[c].set_visible(False)

    fig.suptitle(
        "Profils pedagogiques par cluster (P(L) moyen par matiere)",
        fontsize=15, fontweight="bold", color=COLOR_PRIMARY, y=1.02,
    )
    fig.tight_layout()
    fig.savefig(RADAR_PATH)
    plt.close(fig)
    print(f"[analyze] Radar charts sauves : {RADAR_PATH}")


def main() -> None:
    """Point d'entree CLI : genere les 2 visualisations."""
    df, model_data, cluster_stats = _load_artifacts()
    print(f"[analyze] {len(df)} profils charges, K={model_data['best_k']}")
    plot_pca_visualization(df, model_data, cluster_stats)
    plot_radar_charts(df, model_data, cluster_stats)
    print("[analyze] Visualisations terminees.")


if __name__ == "__main__":
    main()
