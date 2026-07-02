"""cluster_students — Clusterise les eleves en K groupes via K-Means.

Méthode
-------
1. Charge les 2000 profils depuis ``output/profiles.csv``.
2. Standardise les features (``StandardScaler``) pour que chaque matiere
   contribue equitablement (meme echelle, moyenne 0 / variance 1).
3. Teste K = 3, 4, 5, 6 avec K-Means et garde le K qui maximise le
   **silhouette score** (et minimise le **Davies-Bouldin index**).
4. **Tiebreaker pedagogique** : si K=5 (valeur recommandee par la spec
   "4-5 profils types") a une silhouette >= 85 % du meilleur K strict,
   on preferre K=5. Cela evite qu'un K=3 trop grossier soit choisi
   uniquement sur la metric, au detriment de la granularite pedagogique.
5. Refit avec le meilleur K, sauve le modele dans ``output/cluster_model.joblib``
   (contient : modele KMeans + scaler + liste features + metrics + best_k).
6. Ajoute la colonne ``cluster`` au CSV ``output/profiles.csv``.
7. Calcule et sauve les statistiques par cluster dans
   ``output/cluster_stats.json``.

Le silhouette score est choisi comme critere principal car il mesure a la
fois la **cohesion** (intra-cluster) et la **separation** (inter-cluster),
contrairement a l'inertie qui baisse monotone avec K.

Usage
-----
    python cluster_students.py
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any, Final

import joblib
import numpy as np
import pandas as pd
from sklearn.cluster import KMeans
from sklearn.metrics import davies_bouldin_score, silhouette_score
from sklearn.preprocessing import StandardScaler

# ─── Constantes ────────────────────────────────────────────────────────
OUTPUT_DIR: Final[Path] = Path(__file__).resolve().parent / "output"
PROFILES_CSV: Final[Path] = OUTPUT_DIR / "profiles.csv"
MODEL_PATH: Final[Path] = OUTPUT_DIR / "cluster_model.joblib"
STATS_PATH: Final[Path] = OUTPUT_DIR / "cluster_stats.json"

# Les 6 matieres features (miroir de generate_synthetic_profiles.py)
FEATURES: Final[list[str]] = [
    "pL_maths",
    "pL_francais",
    "pL_sciences",
    "pL_svt",
    "pL_histoire",
    "pL_anglais",
]

# Valeurs de K a tester (K-Means suppose clusters spheriques)
K_CANDIDATES: Final[list[int]] = [3, 4, 5, 6]
# K par defaut recommande par la spec ("4-5 profils types"). Utilise comme
# preference en cas d'egalite statistique (silhouettes proches).
K_PREFERRED: Final[int] = 5
# Seuil de tolerance pour le tiebreaker : si K_PREFERRED a une silhouette
# >= TIEBREAK_THRESHOLD * best_silhouette, on le garde. Sinon, on prend le
# argmax strict. 0.85 = tolere un ecart de 15 % avec le meilleur K.
TIEBREAK_THRESHOLD: Final[float] = 0.85
RANDOM_STATE: Final[int] = 42
N_INIT: Final[int] = 10  # nombre de redemarrages K-Means (garde le meilleur)


def _evaluate_k(
    X_scaled: np.ndarray,
    k: int,
) -> dict[str, float]:
    """Calcule silhouette + Davies-Bouldin pour un K donne.

    Parameters
    ----------
    X_scaled : np.ndarray
        Features standardisees, shape ``(n_samples, n_features)``.
    k : int
        Nombre de clusters.

    Returns
    -------
    dict[str, float]
        ``{'silhouette': float, 'davies_bouldin': float, 'inertia': float}``.
    """
    km = KMeans(n_clusters=k, random_state=RANDOM_STATE, n_init=N_INIT)
    labels = km.fit_predict(X_scaled)
    sil = float(silhouette_score(X_scaled, labels))
    db = float(davies_bouldin_score(X_scaled, labels))
    return {
        "silhouette": sil,
        "davies_bouldin": db,
        "inertia": float(km.inertia_),
    }


def cluster(verbose: bool = True) -> dict[str, Any]:
    """Pipeline complet de clustering K-Means.

    Parameters
    ----------
    verbose : bool
        Si True, affiche les metriques pour chaque K teste. Default True.

    Returns
    -------
    dict[str, Any]
        Dictionnaire contenant : ``best_k``, ``metrics`` (par K),
        ``cluster_stats`` (par cluster), ``labels`` (np.ndarray).
    """
    # 1. Chargement des profils
    if not PROFILES_CSV.exists():
        raise FileNotFoundError(
            f"Profils introuvables : {PROFILES_CSV}. "
            "Lancer d'abord : python generate_synthetic_profiles.py"
        )
    df = pd.read_csv(PROFILES_CSV)
    X = df[FEATURES].values

    # 2. Standardisation
    scaler = StandardScaler()
    X_scaled = scaler.fit_transform(X)

    # 3. Test K = 3, 4, 5, 6 — garde le meilleur silhouette
    results: dict[int, dict[str, float]] = {}
    best_k_strict: int = 5
    best_silhouette: float = -1.0

    for k in K_CANDIDATES:
        metrics = _evaluate_k(X_scaled, k)
        results[k] = metrics
        if verbose:
            print(
                f"K={k}: silhouette={metrics['silhouette']:.3f}, "
                f"DB={metrics['davies_bouldin']:.3f}, "
                f"inertia={metrics['inertia']:.1f}"
            )
        if metrics["silhouette"] > best_silhouette:
            best_silhouette = metrics["silhouette"]
            best_k_strict = k

    # Tiebreaker : si K_PREFERRED (5) a une silhouette dans la tolerance
    # (>= 85 % du meilleur), on le garde pour honorer la spec "4-5 profils
    # types". Sinon, on prend le argmax strict.
    sil_preferred = results.get(K_PREFERRED, {}).get("silhouette", -1.0)
    if sil_preferred >= TIEBREAK_THRESHOLD * best_silhouette:
        best_k = K_PREFERRED
        tiebreak_note = (
            f" (K={K_PREFERRED} prefere : silhouette {sil_preferred:.3f} "
            f">= {TIEBREAK_THRESHOLD * 100:.0f}% du meilleur "
            f"{best_silhouette:.3f})"
        )
    else:
        best_k = best_k_strict
        tiebreak_note = (
            f" (K={K_PREFERRED} rejete : silhouette {sil_preferred:.3f} "
            f"< {TIEBREAK_THRESHOLD * 100:.0f}% du meilleur "
            f"{best_silhouette:.3f})"
        )

    if verbose:
        print(
            f"\n[cluster] Best K = {best_k} "
            f"(silhouette = {results[best_k]['silhouette']:.3f})"
            f"{tiebreak_note}"
        )

    # 4. Refit avec best_k (modele final)
    km = KMeans(n_clusters=best_k, random_state=RANDOM_STATE, n_init=N_INIT)
    labels = km.fit_predict(X_scaled)

    # 5. Sauvegarde du modele serialise (modele + scaler + features + metadonnees)
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    joblib.dump(
        {
            "model": km,
            "scaler": scaler,
            "features": FEATURES,
            "best_k": best_k,
            "best_k_strict": best_k_strict,
            "k_preferred": K_PREFERRED,
            "tiebreak_threshold": TIEBREAK_THRESHOLD,
            "tiebreak_applied": best_k == K_PREFERRED and best_k != best_k_strict,
            "metrics": results,
            "random_state": RANDOM_STATE,
        },
        MODEL_PATH,
    )
    if verbose:
        print(f"[cluster] Modele sauvegarde : {MODEL_PATH}")

    # 6. Ajoute la colonne cluster au CSV (reecriture)
    df["cluster"] = labels
    df.to_csv(PROFILES_CSV, index=False)
    if verbose:
        print(f"[cluster] Labels ajoutes a : {PROFILES_CSV}")

    # 7. Stats par cluster (taille, P(L) moyen, distribution des archetypes)
    cluster_stats: dict[int, dict[str, Any]] = {}
    for c in range(best_k):
        cluster_df = df[df["cluster"] == c]
        cluster_stats[int(c)] = {
            "size": int(len(cluster_df)),
            "pct": round(100.0 * len(cluster_df) / len(df), 2),
            "mean_pL": {
                f: round(float(cluster_df[f].mean()), 4) for f in FEATURES
            },
            "std_pL": {
                f: round(float(cluster_df[f].std()), 4) for f in FEATURES
            },
            "archetype_distribution": {
                a: int(n)
                for a, n in cluster_df["archetype_true"].value_counts().items()
            },
        }

    with STATS_PATH.open("w", encoding="utf-8") as f:
        json.dump(cluster_stats, f, indent=2, ensure_ascii=False)
    if verbose:
        print(f"[cluster] Stats par cluster sauvees : {STATS_PATH}")

    return {
        "best_k": best_k,
        "metrics": results,
        "cluster_stats": cluster_stats,
        "labels": labels,
    }


def main() -> None:
    """Point d'entree CLI."""
    cluster(verbose=True)


if __name__ == "__main__":
    main()
