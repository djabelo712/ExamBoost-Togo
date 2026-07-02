"""analyze_calibration.py — Analyse les resultats de calibration IRT.

Genere :
1. **ICC curves** (Item Characteristic Curves) : 1 PNG par question, montrant
   P(reponse correcte) en fonction de theta, avec les parametres a, b, c
   affiches. Inclut aussi les points observes (taux de reussite par bin de
   theta) pour visualiser la qualite de l'ajustement.
2. **Distributions des parametres** : histogrammes de a, b, c sur tous les
   items, avec lignes verticales pour les seuils de qualite (a > 0.3, c < 0.4).
3. **Distribution des theta eleves** : histogramme + courbe normale de
   reference.
4. **Rapport markdown** : synthese complete avec stats, top/bottom questions,
   questions a retravailler, recommandations.

Usage
-----
    python analyze_calibration.py
    python analyze_calibration.py --params output/calibrated_params.json \\
                                  --responses output/synthetic_responses.csv
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any

import matplotlib
# Backend non-interactif (genere des fichiers PNG, n'ouvre pas de fenetre)
matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402
import numpy as np  # noqa: E402
import pandas as pd  # noqa: E402

# ─── Palette ExamBoost Togo (#006837 vert + #D97700 orange) ────────────────
COLOR_PRIMARY = "#006837"  # vert Togo
COLOR_ACCENT = "#D97700"   # orange Togo
COLOR_SECONDARY = "#1565C0"  # bleu info
COLOR_DANGER = "#C62828"   # rouge erreur
COLOR_MUTED = "#6B7280"    # gris
COLOR_FLOOR = "#D97700"    # pour ligne c (guessing)
COLOR_DIFF = "#006837"     # pour ligne b (difficulte)

# Police : Noto Sans SC si dispo (gere le francais + chinois), sinon DejaVu Sans
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


FONT_FAMILY = _resolve_font_family()
plt.rcParams["font.family"] = FONT_FAMILY
plt.rcParams["axes.unicode_minus"] = False
plt.rcParams["figure.dpi"] = 100
plt.rcParams["savefig.dpi"] = 100
plt.rcParams["savefig.bbox"] = "tight"

# ─── Constantes IRT (miroir de calibrate_irt.py) ──────────────────────────
IRT_SCALE: float = 1.7

# Seuils de qualite (cf. README.md)
A_GOOD_MIN: float = 0.3    # discrimination minimale acceptable
C_BAD_MAX: float = 0.4     # guessing maximal acceptable
B_EXTREME: float = 2.5     # |b| au-dela = question trop facile/difficile


# ─── Fonctions IRT (miroir) ────────────────────────────────────────────────
def irt_probability(theta: float | np.ndarray, a: float, b: float, c: float) -> np.ndarray:
    """P(theta) = c + (1 - c) * sigmoid(1.7 * a * (theta - b))."""
    theta = np.atleast_1d(theta).astype(float)
    logits = IRT_SCALE * a * (theta - b)
    return c + (1.0 - c) / (1.0 + np.exp(-logits))


# ─── 1. ICC curve par question ─────────────────────────────────────────────
def plot_icc_curve(
    question_id: str,
    a: float,
    b: float,
    c: float,
    output_path: Path,
    observed_points: np.ndarray | None = None,
    question_meta: dict[str, Any] | None = None,
) -> None:
    """Genere la ICC (Item Characteristic Curve) d'une question.

    Parameters
    ----------
    question_id:
        Identifiant de la question (pour le titre).
    a, b, c:
        Parametres IRT 3PL calibres.
    output_path:
        Fichier PNG de sortie.
    observed_points:
        Optionnel : tableau (n_bins, 3) avec colonnes [theta_bin, p_observed, n].
        Permet de superposer les points observes sur la courbe theorique.
    question_meta:
        Optionnel : {matiere, examen, type, points} pour enrichir le titre.
    """
    thetas = np.linspace(-3.0, 3.0, 200)
    probs = irt_probability(thetas, a, b, c)

    fig, ax = plt.subplots(figsize=(8, 5))

    # Courbe theorique
    ax.plot(thetas, probs, color=COLOR_PRIMARY, linewidth=2.5,
            label=f'P(theta) = {c:.2f} + (1-{c:.2f}) * sigmoid(1.7 * {a:.2f} * (theta - {b:.2f}))')

    # Lignes de reference : c (guessing floor) et b (difficulte)
    ax.axhline(y=c, color=COLOR_FLOOR, linestyle="--", alpha=0.6,
               label=f'c = {c:.2f} (guessing)')
    ax.axvline(x=b, color=COLOR_DIFF, linestyle="--", alpha=0.6,
               label=f'b = {b:.2f} (difficulte)')

    # Point d'inflexion a theta=b : P(b) = (1+c)/2
    p_at_b = (1.0 + c) / 2.0
    ax.plot(b, p_at_b, "o", color=COLOR_ACCENT, markersize=10,
            label=f'P(b) = {p_at_b:.2f} (point median)')
    ax.annotate(f'({b:.2f}, {p_at_b:.2f})',
                xy=(b, p_at_b), xytext=(b + 0.3, p_at_b - 0.1),
                fontsize=9, color=COLOR_ACCENT)

    # Points observes (optionnel)
    if observed_points is not None and len(observed_points) > 0:
        theta_bins = observed_points[:, 0]
        p_obs = observed_points[:, 1]
        weights = observed_points[:, 2]
        # Taille des points proportionnelle au nombre d'observations
        sizes = 20 + 80 * (weights / max(weights.max(), 1))
        ax.scatter(theta_bins, p_obs, s=sizes, color=COLOR_DANGER,
                   alpha=0.7, edgecolors="white", linewidth=1.2,
                   label='Taux de reussite observe (par bin de theta)',
                   zorder=5)

    # Decorations
    ax.set_xlabel("Theta (niveau de l'eleve)", fontsize=11)
    ax.set_ylabel("P(reponse correcte)", fontsize=11)

    # Titre enrichi avec metadonnees
    title = f"ICC - {question_id}"
    if question_meta:
        meta_parts = []
        if question_meta.get("matiere"):
            meta_parts.append(str(question_meta["matiere"]))
        if question_meta.get("examen"):
            meta_parts.append(str(question_meta["examen"]))
        if question_meta.get("type"):
            meta_parts.append(str(question_meta["type"]))
        if meta_parts:
            title += f"\n{' / '.join(meta_parts)}"
    title += f"\na = {a:.2f}  |  b = {b:.2f}  |  c = {c:.2f}"
    ax.set_title(title, fontsize=11, fontweight="bold")

    ax.legend(loc="upper left", fontsize=8, framealpha=0.95)
    ax.grid(True, alpha=0.3, linestyle=":")
    ax.set_xlim(-3.0, 3.0)
    ax.set_ylim(-0.05, 1.05)
    ax.set_xticks(np.arange(-3, 3.1, 1))
    ax.set_yticks(np.arange(0, 1.1, 0.2))

    # Indication visuelle de la qualite de discrimination
    quality_label = _quality_label(a, b, c)
    ax.text(0.98, 0.02, quality_label, transform=ax.transAxes,
            ha="right", va="bottom", fontsize=9,
            bbox=dict(boxstyle="round,pad=0.4", facecolor="white",
                      edgecolor=COLOR_MUTED, alpha=0.9))

    plt.tight_layout()
    fig.savefig(output_path)
    plt.close(fig)


def _quality_label(a: float, b: float, c: float) -> str:
    """Retourne un label court decrivant la qualite de la question."""
    issues = []
    if a < A_GOOD_MIN:
        issues.append(f"a faible ({a:.2f} < {A_GOOD_MIN})")
    if c > C_BAD_MAX:
        issues.append(f"c eleve ({c:.2f} > {C_BAD_MAX})")
    if abs(b) > B_EXTREME:
        issues.append(f"b extreme ({b:+.2f})")
    if not issues:
        return "OK : question de bonne qualite"
    return "A surveiller : " + " ; ".join(issues)


def compute_observed_points(
    df: pd.DataFrame, question_id: str, n_bins: int = 7
) -> np.ndarray | None:
    """Calcule les points observes (theta_bin, p_observed, n) pour une question.

    On regroupe les eleves en n_bins bins de theta_true (si disponible) ou
    theta estime (fallback), puis on calcule le taux de reussite moyen par bin.
    """
    qdf = df[df["question_id"] == question_id]
    if len(qdf) < 10:
        return None

    # Colonne theta : theta_true si dispo, sinon on ne peut pas
    theta_col = "theta_true" if "theta_true" in qdf.columns else None
    if theta_col is None:
        return None

    thetas = qdf[theta_col].values
    correct = qdf["correct"].values

    # Bins sur [-3, 3]
    bins = np.linspace(-3.0, 3.0, n_bins + 1)
    centers = 0.5 * (bins[:-1] + bins[1:])

    points = []
    for i in range(n_bins):
        mask = (thetas >= bins[i]) & (thetas < bins[i + 1])
        n = int(mask.sum())
        if n < 3:
            continue
        p_obs = float(correct[mask].mean())
        points.append([centers[i], p_obs, n])

    if not points:
        return None
    return np.array(points, dtype=float)


# ─── 2. Distributions des parametres ───────────────────────────────────────
def plot_parameter_distributions(
    item_params: list[dict[str, Any]],
    output_path: Path,
) -> None:
    """Genere 3 histogrammes (a, b, c) avec seuils de qualite."""
    a_values = np.array([p["a"] for p in item_params], dtype=float)
    b_values = np.array([p["b"] for p in item_params], dtype=float)
    c_values = np.array([p["c"] for p in item_params], dtype=float)

    fig, axes = plt.subplots(1, 3, figsize=(15, 5))

    # ─── a (discrimination) ────────────────────────────────────────────────
    axes[0].hist(a_values, bins=15, color=COLOR_PRIMARY, edgecolor="white",
                 alpha=0.85)
    mean_a = float(a_values.mean())
    axes[0].axvline(mean_a, color=COLOR_ACCENT, linestyle="--", linewidth=2,
                    label=f"Moyenne = {mean_a:.2f}")
    axes[0].axvline(A_GOOD_MIN, color=COLOR_DANGER, linestyle=":", linewidth=2,
                    label=f"Seuil mini = {A_GOOD_MIN}")
    axes[0].set_title(
        f"Distribution de a (discrimination)\n"
        f"n = {len(a_values)} | moy = {mean_a:.2f} | "
        f"{(a_values < A_GOOD_MIN).sum()} sous le seuil",
        fontsize=10, fontweight="bold",
    )
    axes[0].set_xlabel("a (discrimination)")
    axes[0].set_ylabel("Nombre de questions")
    axes[0].legend(fontsize=9)
    axes[0].grid(True, alpha=0.3, axis="y", linestyle=":")

    # ─── b (difficulte) ────────────────────────────────────────────────────
    axes[1].hist(b_values, bins=15, color=COLOR_SECONDARY, edgecolor="white",
                 alpha=0.85)
    mean_b = float(b_values.mean())
    axes[1].axvline(mean_b, color=COLOR_ACCENT, linestyle="--", linewidth=2,
                    label=f"Moyenne = {mean_b:.2f}")
    axes[1].axvline(0.0, color=COLOR_MUTED, linestyle=":", linewidth=1,
                    label="Difficulte moyenne (b=0)")
    axes[1].axvline(-B_EXTREME, color=COLOR_DANGER, linestyle=":", linewidth=2)
    axes[1].axvline(B_EXTREME, color=COLOR_DANGER, linestyle=":", linewidth=2,
                    label=f"Seuil extreme |b| = {B_EXTREME}")
    axes[1].set_title(
        f"Distribution de b (difficulte)\n"
        f"n = {len(b_values)} | moy = {mean_b:.2f} | "
        f"{(np.abs(b_values) > B_EXTREME).sum()} extremes",
        fontsize=10, fontweight="bold",
    )
    axes[1].set_xlabel("b (difficulte)")
    axes[1].legend(fontsize=9)
    axes[1].grid(True, alpha=0.3, axis="y", linestyle=":")

    # ─── c (guessing) ──────────────────────────────────────────────────────
    axes[2].hist(c_values, bins=15, color=COLOR_FLOOR, edgecolor="white",
                 alpha=0.85)
    mean_c = float(c_values.mean())
    axes[2].axvline(mean_c, color=COLOR_ACCENT, linestyle="--", linewidth=2,
                    label=f"Moyenne = {mean_c:.2f}")
    axes[2].axvline(C_BAD_MAX, color=COLOR_DANGER, linestyle=":", linewidth=2,
                    label=f"Seuil maxi = {C_BAD_MAX}")
    axes[2].set_title(
        f"Distribution de c (guessing)\n"
        f"n = {len(c_values)} | moy = {mean_c:.2f} | "
        f"{(c_values > C_BAD_MAX).sum()} au-dessus du seuil",
        fontsize=10, fontweight="bold",
    )
    axes[2].set_xlabel("c (guessing)")
    axes[2].legend(fontsize=9)
    axes[2].grid(True, alpha=0.3, axis="y", linestyle=":")

    plt.tight_layout()
    fig.savefig(output_path)
    plt.close(fig)


# ─── 3. Distribution des theta eleves ──────────────────────────────────────
def plot_theta_distribution(
    student_params: list[dict[str, Any]],
    output_path: Path,
) -> None:
    """Genere l'histogramme des theta eleves + courbe normale de reference."""
    thetas = np.array([s["theta"] for s in student_params], dtype=float)
    if len(thetas) == 0:
        return

    fig, ax = plt.subplots(figsize=(8, 5))
    ax.hist(thetas, bins=25, density=True, color=COLOR_PRIMARY, alpha=0.7,
            edgecolor="white", label=f"Theta estimes (n={len(thetas)})")

    # Courbe N(0, 1) de reference
    x = np.linspace(-3, 3, 200)
    pdf_ref = (1.0 / np.sqrt(2 * np.pi)) * np.exp(-0.5 * x ** 2)
    ax.plot(x, pdf_ref, color=COLOR_ACCENT, linewidth=2.5,
            label="N(0, 1) de reference")

    # Stats
    mean_t = float(thetas.mean())
    std_t = float(thetas.std())
    ax.axvline(mean_t, color=COLOR_DANGER, linestyle="--", linewidth=2,
               label=f"Moyenne = {mean_t:.2f}")

    ax.set_title(
        f"Distribution des theta eleves\n"
        f"moy = {mean_t:.2f} | ecart-type = {std_t:.2f} | "
        f"min = {thetas.min():.2f} | max = {thetas.max():.2f}",
        fontsize=11, fontweight="bold",
    )
    ax.set_xlabel("Theta (niveau de competence)")
    ax.set_ylabel("Densite")
    ax.set_xlim(-3.5, 3.5)
    ax.legend(fontsize=9)
    ax.grid(True, alpha=0.3, linestyle=":")

    plt.tight_layout()
    fig.savefig(output_path)
    plt.close(fig)


# ─── 4. Log-vraisemblance au fil des iterations ────────────────────────────
def plot_ll_history(
    metadata: dict[str, Any],
    output_path: Path,
) -> None:
    """Trace l'evolution de la log-vraisemblance au fil des iterations EM."""
    ll_history = metadata.get("ll_history") or []
    if not ll_history:
        return

    fig, ax = plt.subplots(figsize=(8, 5))
    iters = np.arange(1, len(ll_history) + 1)
    ax.plot(iters, ll_history, color=COLOR_PRIMARY, linewidth=2.5,
            marker="o", markersize=7, label="Log-vraisemblance")
    ax.set_xlabel("Iteration EM")
    ax.set_ylabel("Log-vraisemblance (somme sur les items)")
    ax.set_title(
        f"Convergence de la calibration\n"
        f"Methode : {metadata.get('method', '?')} | "
        f"Iterations : {metadata.get('n_iterations', '?')} | "
        f"Converge : {metadata.get('convergence_achieved', '?')}",
        fontsize=11, fontweight="bold",
    )
    ax.grid(True, alpha=0.3, linestyle=":")
    ax.legend(fontsize=9)
    plt.tight_layout()
    fig.savefig(output_path)
    plt.close(fig)


# ─── 5. Rapport markdown ───────────────────────────────────────────────────
def generate_report(
    params: dict[str, Any],
    df: pd.DataFrame | None,
    output_path: Path,
) -> None:
    """Genere un rapport markdown complet de la calibration.

    Sections :
    - Synthese (effectifs, methode, iterations, convergence)
    - Distribution des parametres a/b/c (mean, median, min/max, % hors seuil)
    - Top 5 questions les plus discriminantes (a eleve)
    - Top 5 questions les plus difficiles (b eleve)
    - Top 5 questions les plus faciles (b faible)
    - Questions a retravailler (a < 0.3 OU c > 0.4 OU |b| > 2.5)
    - Distribution des theta eleves
    - Recommandations
    """
    metadata = params.get("metadata", {})
    item_params = params.get("item_params", [])
    student_params = params.get("student_params", [])

    a_values = np.array([p["a"] for p in item_params], dtype=float)
    b_values = np.array([p["b"] for p in item_params], dtype=float)
    c_values = np.array([p["c"] for p in item_params], dtype=float)
    p_obs = np.array([p.get("p_observed", 0) for p in item_params], dtype=float)
    thetas = np.array([s["theta"] for s in student_params], dtype=float)

    n_items = len(item_params)
    n_students = len(student_params)
    n_responses = int(metadata.get("n_responses", 0) or (df.shape[0] if df is not None else 0))

    # Top questions
    by_a = sorted(item_params, key=lambda p: p["a"], reverse=True)
    by_b_desc = sorted(item_params, key=lambda p: p["b"], reverse=True)
    by_b_asc = sorted(item_params, key=lambda p: p["b"])
    issues = [
        p for p in item_params
        if p["a"] < A_GOOD_MIN or p["c"] > C_BAD_MAX or abs(p["b"]) > B_EXTREME
    ]
    issues.sort(key=lambda p: (
        int(p["a"] < A_GOOD_MIN) + int(p["c"] > C_BAD_MAX) + int(abs(p["b"]) > B_EXTREME)
    ), reverse=True)

    # Stats
    a_mean = float(a_values.mean()) if n_items else 0.0
    a_med = float(np.median(a_values)) if n_items else 0.0
    a_min = float(a_values.min()) if n_items else 0.0
    a_max = float(a_values.max()) if n_items else 0.0
    a_low_pct = float((a_values < A_GOOD_MIN).mean() * 100) if n_items else 0.0

    b_mean = float(b_values.mean()) if n_items else 0.0
    b_med = float(np.median(b_values)) if n_items else 0.0
    b_min = float(b_values.min()) if n_items else 0.0
    b_max = float(b_values.max()) if n_items else 0.0
    b_extreme_pct = float((np.abs(b_values) > B_EXTREME).mean() * 100) if n_items else 0.0

    c_mean = float(c_values.mean()) if n_items else 0.0
    c_med = float(np.median(c_values)) if n_items else 0.0
    c_high_pct = float((c_values > C_BAD_MAX).mean() * 100) if n_items else 0.0

    t_mean = float(thetas.mean()) if n_students else 0.0
    t_std = float(thetas.std()) if n_students else 0.0

    # Construction du rapport
    lines: list[str] = []
    lines.append("# Rapport de calibration IRT 3PL")
    lines.append("")
    lines.append("> Genere automatiquement par `analyze_calibration.py`")
    lines.append("> ExamBoost Togo - backend/scripts/irt_calibration/")
    lines.append("")

    # ─── Synthese ──────────────────────────────────────────────────────────
    lines.append("## 1. Synthese")
    lines.append("")
    lines.append(f"- **Methode de calibration** : `{metadata.get('method', '?')}`")
    lines.append(f"- **Iterations EM** : {metadata.get('n_iterations', '?')}")
    lines.append(f"- **Convergence atteinte** : {metadata.get('convergence_achieved', '?')}")
    lines.append(f"- **Log-vraisemblance finale** : {metadata.get('final_log_likelihood', 0):.2f}")
    lines.append(f"- **Questions calibrees** : {n_items}")
    lines.append(f"- **Eleves dans l'echantillon** : {n_students}")
    lines.append(f"- **Reponses totales** : {n_responses}")
    lines.append(f"- **Constante d'echelle IRT** : {IRT_SCALE} (Birnbaum 3PL)")
    lines.append(f"- **Formule** : `P(theta) = c + (1-c) * 1 / (1 + exp(-1.7 * a * (theta - b)))`")
    lines.append("")

    # ─── Distribution des parametres ───────────────────────────────────────
    lines.append("## 2. Distribution des parametres IRT")
    lines.append("")
    lines.append("### 2.1 Discrimination (a)")
    lines.append("")
    lines.append(f"- Moyenne : **{a_mean:.3f}**")
    lines.append(f"- Mediane : {a_med:.3f}")
    lines.append(f"- Min / Max : {a_min:.3f} / {a_max:.3f}")
    lines.append(f"- Questions avec a < {A_GOOD_MIN} (a retravailler) : "
                 f"**{int((a_values < A_GOOD_MIN).sum())}** ({a_low_pct:.1f}%)")
    lines.append("")
    lines.append("### 2.2 Difficulte (b)")
    lines.append("")
    lines.append(f"- Moyenne : **{b_mean:.3f}**")
    lines.append(f"- Mediane : {b_med:.3f}")
    lines.append(f"- Min / Max : {b_min:.3f} / {b_max:.3f}")
    lines.append(f"- Questions extremes (|b| > {B_EXTREME}) : "
                 f"**{int((np.abs(b_values) > B_EXTREME).sum())}** ({b_extreme_pct:.1f}%)")
    lines.append("")
    lines.append("### 2.3 Guessing (c)")
    lines.append("")
    lines.append(f"- Moyenne : **{c_mean:.3f}**")
    lines.append(f"- Mediane : {c_med:.3f}")
    lines.append(f"- Questions avec c > {C_BAD_MAX} (trop de chance) : "
                 f"**{int((c_values > C_BAD_MAX).sum())}** ({c_high_pct:.1f}%)")
    lines.append("")

    # ─── Distribution des theta eleves ────────────────────────────────────
    lines.append("## 3. Distribution des theta eleves")
    lines.append("")
    lines.append(f"- Moyenne : **{t_mean:.3f}** (devrait etre proche de 0)")
    lines.append(f"- Ecart-type : **{t_std:.3f}** (devrait etre proche de 1)")
    if n_students:
        lines.append(f"- Min / Max : {thetas.min():.3f} / {thetas.max():.3f}")
    lines.append("")

    # ─── Top questions ────────────────────────────────────────────────────
    lines.append("## 4. Top 5 questions les plus discriminantes (a eleve)")
    lines.append("")
    lines.append("| Rang | Question | a | b | c | Taux de reussite observe |")
    lines.append("|------|----------|---|---|---|--------------------------|")
    for i, p in enumerate(by_a[:5], 1):
        lines.append(
            f"| {i} | `{p['question_id']}` | {p['a']:.3f} | {p['b']:.3f} | "
            f"{p['c']:.3f} | {p.get('p_observed', 0):.3f} |"
        )
    lines.append("")

    lines.append("## 5. Top 5 questions les plus difficiles (b eleve)")
    lines.append("")
    lines.append("| Rang | Question | a | b | c | Taux de reussite observe |")
    lines.append("|------|----------|---|---|---|--------------------------|")
    for i, p in enumerate(by_b_desc[:5], 1):
        lines.append(
            f"| {i} | `{p['question_id']}` | {p['a']:.3f} | {p['b']:.3f} | "
            f"{p['c']:.3f} | {p.get('p_observed', 0):.3f} |"
        )
    lines.append("")

    lines.append("## 6. Top 5 questions les plus faciles (b faible)")
    lines.append("")
    lines.append("| Rang | Question | a | b | c | Taux de reussite observe |")
    lines.append("|------|----------|---|---|---|--------------------------|")
    for i, p in enumerate(by_b_asc[:5], 1):
        lines.append(
            f"| {i} | `{p['question_id']}` | {p['a']:.3f} | {p['b']:.3f} | "
            f"{p['c']:.3f} | {p.get('p_observed', 0):.3f} |"
        )
    lines.append("")

    # ─── Questions a retravailler ─────────────────────────────────────────
    lines.append(f"## 7. Questions a retravailler ({len(issues)})")
    lines.append("")
    lines.append("_Criteres : a < 0.3 (peu discriminante) OU c > 0.4 (trop de chance) "
                 f"OU |b| > {B_EXTREME} (trop extreme)._")
    lines.append("")
    if issues:
        lines.append("| Question | a | b | c | Issue(s) |")
        lines.append("|----------|---|---|---|----------|")
        for p in issues:
            issue_flags = []
            if p["a"] < A_GOOD_MIN:
                issue_flags.append(f"a<{A_GOOD_MIN}")
            if p["c"] > C_BAD_MAX:
                issue_flags.append(f"c>{C_BAD_MAX}")
            if abs(p["b"]) > B_EXTREME:
                issue_flags.append(f"|b|>{B_EXTREME}")
            lines.append(
                f"| `{p['question_id']}` | {p['a']:.3f} | {p['b']:.3f} | "
                f"{p['c']:.3f} | {', '.join(issue_flags)} |"
            )
    else:
        lines.append("_Aucune question a retravailler : toutes les questions respectent "
                     "les seuils de qualite._")
    lines.append("")

    # ─── Recommandations ──────────────────────────────────────────────────
    lines.append("## 8. Recommandations")
    lines.append("")
    lines.append("1. **Retirer ou reviser les questions avec a < 0.3** "
                 f"({int((a_values < A_GOOD_MIN).sum())} question(s)) : "
                 "elles ne discriminant pas les eleves faibles des forts.")
    lines.append("2. **Reviser les questions avec c > 0.4** "
                 f"({int((c_values > C_BAD_MAX).sum())} question(s)) : "
                 "trop d'eleves reussissent par chance. Augmenter le nombre de "
                 "distracteurs ou la qualite des distracteurs QCM.")
    lines.append("3. **Equilibrer la distribution des b** : "
                 f"moyenne actuelle = {b_mean:.2f}. Si proche de 0, le set de "
                 "questions est bien centre. Sinon, ajouter des questions "
                 "faciles (b < 0) ou difficiles (b > 0) pour couvrir tous les "
                 "niveaux d'eleves.")
    lines.append("4. **Recalibration mensuelle** recommandee : 200+ eleves "
                 "par question pour une calibration fiable. Avec "
                 f"{n_students} eleves et {n_items} questions, "
                 f"soit {n_responses} reponses, l'echantillon "
                 f"{'est' if n_students >= 200 else "N'est PAS"} suffisant.")
    lines.append("5. **Surveiller la qualite d'ajustement** : comparer les "
                 "ICC theoriques aux points observes (cf. dossier "
                 "`output/icc_curves/`). Si les points observes s'eloignent "
                 "fortement de la courbe, le modele 3PL est peut-etre inadapte "
                 "pour cette question (effet de plafond, de plancher, etc.).")
    lines.append("")

    # ─── Fichiers generes ─────────────────────────────────────────────────
    lines.append("## 9. Fichiers generes")
    lines.append("")
    lines.append("- `output/icc_curves/<question_id>.png` : ICC curve par question")
    lines.append("- `output/parameter_distributions.png` : histogrammes de a, b, c")
    lines.append("- `output/theta_distribution.png` : distribution des theta eleves")
    lines.append("- `output/ll_history.png` : convergence de la log-vraisemblance")
    lines.append("- `output/calibration_report.md` : ce rapport")
    lines.append("")

    output_path.parent.mkdir(parents=True, exist_ok=True)
    with open(output_path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))


# ─── Pipeline complet ──────────────────────────────────────────────────────
def run_analysis(
    params_file: str | Path = "output/calibrated_params.json",
    responses_file: str | Path | None = "output/synthetic_responses.csv",
    questions_file: str | Path | None = None,
    output_dir: str | Path = "output",
    dpi: int = 100,
) -> None:
    """Execute toutes les analyses et genere tous les outputs.

    Parameters
    ----------
    params_file:
        JSON produit par calibrate_irt.py.
    responses_file:
        CSV des reponses (pour superposer les points observes sur les ICC).
        Optionnel : si None, les ICC seront sans points observes.
    questions_file:
        JSON des questions (pour recuperer matiere/examen/type et enrichir
        les titres des ICC).
    output_dir:
        Dossier de sortie (cree un sous-dossier icc_curves/).
    dpi:
        Resolution des PNG.
    """
    output_dir = Path(output_dir)
    icc_dir = output_dir / "icc_curves"
    icc_dir.mkdir(parents=True, exist_ok=True)

    plt.rcParams["savefig.dpi"] = dpi

    # Charge les parametres calibres
    params_file = Path(params_file)
    if not params_file.exists():
        raise FileNotFoundError(f"Fichier params introuvable : {params_file}")
    with open(params_file, "r", encoding="utf-8") as f:
        params = json.load(f)

    metadata = params.get("metadata", {})
    item_params = params.get("item_params", [])
    student_params = params.get("student_params", [])
    print(f"[analyze] {len(item_params)} items | {len(student_params)} eleves "
          f"| methode = {metadata.get('method', '?')}")

    # Charge les reponses (optionnel)
    df: pd.DataFrame | None = None
    if responses_file:
        responses_file = Path(responses_file)
        if responses_file.exists():
            df = pd.read_csv(responses_file)
            print(f"[analyze] {len(df)} reponses chargees pour les ICC observees")
        else:
            print(f"[analyze] WARN: {responses_file} introuvable, ICC sans points observes")

    # Charge les metadonnees questions (optionnel)
    q_meta: dict[str, dict[str, Any]] = {}
    if questions_file:
        questions_file = Path(questions_file)
        if questions_file.exists():
            with open(questions_file, "r", encoding="utf-8") as f:
                questions = json.load(f)
            q_meta = {
                q["id"]: {
                    "matiere": q.get("matiere", ""),
                    "examen": q.get("examen", ""),
                    "type": q.get("type", ""),
                    "points": q.get("points"),
                }
                for q in questions
            }
            print(f"[analyze] Metadonnees chargees pour {len(q_meta)} questions")

    # ─── 1. ICC curves (1 par question) ───────────────────────────────────
    print(f"[analyze] Generation de {len(item_params)} ICC curves...")
    for i, p in enumerate(item_params):
        qid = p["question_id"]
        out_png = icc_dir / f"{qid}.png"
        observed = compute_observed_points(df, qid) if df is not None else None
        plot_icc_curve(
            question_id=qid,
            a=float(p["a"]),
            b=float(p["b"]),
            c=float(p["c"]),
            output_path=out_png,
            observed_points=observed,
            question_meta=q_meta.get(qid),
        )
        if (i + 1) % 10 == 0:
            print(f"  ... {i + 1}/{len(item_params)} ICC generees")
    print(f"[analyze] ICC curves sauvees dans {icc_dir}")

    # ─── 2. Distributions des parametres ─────────────────────────────────
    dist_path = output_dir / "parameter_distributions.png"
    plot_parameter_distributions(item_params, dist_path)
    print(f"[analyze] Distributions sauvees : {dist_path}")

    # ─── 3. Distribution des theta eleves ────────────────────────────────
    theta_path = output_dir / "theta_distribution.png"
    plot_theta_distribution(student_params, theta_path)
    print(f"[analyze] Distribution theta sauvee : {theta_path}")

    # ─── 4. Historique de convergence LL ─────────────────────────────────
    ll_path = output_dir / "ll_history.png"
    plot_ll_history(metadata, ll_path)
    print(f"[analyze] Historique LL sauve : {ll_path}")

    # ─── 5. Rapport markdown ─────────────────────────────────────────────
    report_path = output_dir / "calibration_report.md"
    generate_report(params, df, report_path)
    print(f"[analyze] Rapport sauve : {report_path}")
    print()
    print("[OK] Analyse terminee.")
    print(f"     ICC curves      : {icc_dir} ({len(item_params)} PNG)")
    print(f"     Distributions   : {dist_path.name}")
    print(f"     Theta eleves    : {theta_path.name}")
    print(f"     Convergence LL  : {ll_path.name}")
    print(f"     Rapport markdown: {report_path.name}")


# ─── CLI ───────────────────────────────────────────────────────────────────
def main() -> int:
    """Point d'entree CLI."""
    parser = argparse.ArgumentParser(
        description="Analyse les resultats de calibration IRT + genere ICC + rapport.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "--params",
        type=str,
        default="output/calibrated_params.json",
        help="JSON de params calibres (defaut: output/calibrated_params.json).",
    )
    parser.add_argument(
        "--responses",
        type=str,
        default="output/synthetic_responses.csv",
        help="CSV des reponses (pour ICC observees). Mettre '' pour desactiver.",
    )
    parser.add_argument(
        "--questions-file",
        type=str,
        default="../../assets/data/questions.json",
        help="questions.json pour enrichir les ICC (matiere/examen/type).",
    )
    parser.add_argument(
        "--output-dir",
        type=str,
        default="output",
        help="Dossier de sortie (defaut: output).",
    )
    parser.add_argument(
        "--dpi",
        type=int,
        default=100,
        help="Resolution PNG (defaut: 100).",
    )
    args = parser.parse_args()

    # Resolution du chemin questions.json
    questions_path: Path | None = None
    if args.questions_file:
        questions_path = Path(args.questions_file)
        if not questions_path.is_absolute():
            script_dir = Path(__file__).resolve().parent
            candidates = [
                questions_path,
                script_dir / args.questions_file,
                script_dir.parent.parent.parent / args.questions_file.lstrip("../"),
            ]
            for c in candidates:
                if c.exists():
                    questions_path = c
                    break
            else:
                questions_path = None  # introuvable, on continue sans

    # Reponses optionnelles
    responses_path: Path | None = None
    if args.responses:
        responses_path = Path(args.responses)
        if not responses_path.exists():
            responses_path = None

    try:
        run_analysis(
            params_file=args.params,
            responses_file=responses_path,
            questions_file=questions_path,
            output_dir=args.output_dir,
            dpi=args.dpi,
        )
    except (FileNotFoundError, ValueError) as e:
        print(f"[ERREUR] {e}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
