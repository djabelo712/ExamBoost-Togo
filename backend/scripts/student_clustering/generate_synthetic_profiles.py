"""generate_synthetic_profiles — Genere 2000 profils eleves synthetiques.

Construit un dataset realiste de 2000 eleves avec leur probabilite de maitrise
P(L) (sortie du modele BKT, cf. ``lib/models/user.dart`` champ
``bktMaitrise``) sur les 6 matieres du programme togolais BEPC / BAC :

    - Mathematiques (pL_maths)
    - Francais      (pL_francais)
    - Sciences      (pL_sciences)
    - SVT           (pL_svt)
    - Histoire-Geo  (pL_histoire)
    - Anglais       (pL_anglais)

Cinq archetypes sont simules (avec bruit gaussien et correlations intra-groupe
pour rester realiste — un eleve fort en maths n'a pas 0.05 en sciences) :

    - Scientifique   (~25 %) : fort en Maths/Sciences/SVT, moyen en lettres
    - Litteraire     (~20 %) : fort en FR/Histoire/Anglais, moyen en sciences
    - Polyvalent     (~20 %) : equilibre partout, legerement au-dessus moyenne
    - En difficulte  (~20 %) : P(L) < 0.40 partout
    - Mixte atypique (~15 %) : fort dans 1-2 matieres, faible ailleurs

Le dataset est exporte dans ``output/profiles.csv`` avec colonnes :

    student_id, pL_maths, pL_francais, pL_sciences, pL_svt,
    pL_histoire, pL_anglais, archetype_true

Usage
-----
    python generate_synthetic_profiles.py
    python generate_synthetic_profiles.py --n 2000 --seed 42
"""

from __future__ import annotations

import argparse
from pathlib import Path
from typing import Final

import numpy as np
import pandas as pd

# ─── Constantes ────────────────────────────────────────────────────────
OUTPUT_DIR: Final[Path] = Path(__file__).resolve().parent / "output"
DEFAULT_N: Final[int] = 2000
DEFAULT_SEED: Final[int] = 42

# Ordre canonique des matieres (miroir des 6 features utilisees ailleurs
# dans le projet, cf. ``backend/scripts/ml_training/generate_synthetic_students.py``)
MATIERES: Final[list[str]] = [
    "pL_maths",
    "pL_francais",
    "pL_sciences",
    "pL_svt",
    "pL_histoire",
    "pL_anglais",
]

# Centroides des 5 archetypes (P(L) moyen par matiere)
# L'ordre des valeurs suit MATIERES (maths, fr, sciences, svt, histoire, anglais)
ARCHETYPE_CENTROIDS: Final[dict[str, np.ndarray]] = {
    # Scientifique : fort en sciences exactes, moyen en lettres
    "Scientifique":   np.array([0.78, 0.52, 0.75, 0.72, 0.48, 0.55]),
    # Litteraire : fort en lettres + langues, moyen en sciences
    "Litteraire":     np.array([0.50, 0.80, 0.45, 0.48, 0.78, 0.75]),
    # Polyvalent : equilibre legerement au-dessus de la moyenne
    "Polyvalent":     np.array([0.68, 0.70, 0.66, 0.65, 0.68, 0.67]),
    # En difficulte : tout bas (< 0.40)
    "En_difficulte":  np.array([0.30, 0.32, 0.28, 0.27, 0.30, 0.30]),
    # Mixte atypique : traite separement (centroide variable par eleve)
    "Mixte_atypique": np.array([0.50, 0.50, 0.50, 0.50, 0.50, 0.50]),  # placeholder
}

# Bruit gaussien (ecart-type) par archetype
ARCHETYPE_SIGMA: Final[dict[str, float]] = {
    "Scientifique": 0.08,
    "Litteraire": 0.08,
    "Polyvalent": 0.06,       # plus serre : profil equilibre
    "En_difficulte": 0.06,    # plus serre : tout reste < 0.40
    "Mixte_atypique": 0.10,   # plus large : diversite des combinaisons
}

# Repartition cible des archetypes (somme = 1.0)
ARCHETYPE_PROBS: Final[dict[str, float]] = {
    "Scientifique": 0.25,
    "Litteraire": 0.20,
    "Polyvalent": 0.20,
    "En_difficulte": 0.20,
    "Mixte_atypique": 0.15,
}


def _add_coherent_noise(
    centroid: np.ndarray,
    sigma: float,
    n: int,
    rng: np.random.Generator,
    correlation: float = 0.3,
) -> np.ndarray:
    """Ajoute un bruit gaussien avec correlation intra-profil.

    On combine un bruit global (facteur commun a toutes les matieres, qui
    reflete le niveau "general" de l'eleve) avec un bruit specifique par
    matiere. Cela evite les profils physiquement improbables
    (ex : 0.95 en Maths et 0.05 en Sciences pour un scientifique).

    Parameters
    ----------
    centroid : np.ndarray
        Profil moyen (shape ``(6,)``).
    sigma : float
        Ecart-type du bruit.
    n : int
        Nombre d'eleves a generer.
    rng : np.random.Generator
        Generateur aleatoire.
    correlation : float
        Poids du facteur commun (0 = bruit independant, 1 = parfaitement
        correle). Default 0.3.

    Returns
    -------
    np.ndarray
        Profils bruites, shape ``(n, 6)``, clips a [0, 1].
    """
    # Facteur commun (niveau global de l'eleve) — 1 dimension par eleve
    common = rng.normal(0.0, sigma * correlation, size=(n, 1))
    # Bruit specifique par matiere
    specific = rng.normal(0.0, sigma * np.sqrt(1.0 - correlation ** 2), size=(n, 6))
    noise = common + specific
    profiles = centroid[np.newaxis, :] + noise
    return np.clip(profiles, 0.0, 1.0)


def _generate_mixte_atypique(
    n: int,
    rng: np.random.Generator,
    sigma: float = 0.10,
) -> np.ndarray:
    """Genere des profils mixtes atypiques : 1-2 matieres fortes, le reste faible.

    Pour chaque eleve :
        1. Tire ``k`` (nombre de matieres fortes) dans {1, 2} avec P(2) = 0.6
        2. Selectionne ``k`` matieres parmi les 6 (uniformement)
        3. Fortes : ~0.78 + bruit ; Faibles : ~0.35 + bruit
        4. Clip [0, 1]

    Parameters
    ----------
    n : int
        Nombre d'eleves a generer.
    rng : np.random.Generator
        Generateur aleatoire.
    sigma : float
        Ecart-type du bruit gaussien. Default 0.10.

    Returns
    -------
    np.ndarray
        Profils shape ``(n, 6)`` dans [0, 1].
    """
    profiles = np.zeros((n, 6))
    for i in range(n):
        k = 1 if rng.random() < 0.4 else 2  # 40% : 1 forte ; 60% : 2 fortes
        strong_idx = rng.choice(6, size=k, replace=False)
        row = np.full(6, 0.35)  # base faible partout
        row[strong_idx] = 0.78  # matieres fortes
        # Bruit gaussien specifique par matiere
        row = row + rng.normal(0.0, sigma, size=6)
        profiles[i] = np.clip(row, 0.0, 1.0)
    return profiles


def generate_synthetic_profiles(
    n: int = DEFAULT_N,
    seed: int = DEFAULT_SEED,
) -> pd.DataFrame:
    """Genere ``n`` profils eleves synthetiques repartis en 5 archetypes.

    Parameters
    ----------
    n : int
        Nombre total d'eleves. Default 2000.
    seed : int
        Graine RNG pour reproductibilite. Default 42.

    Returns
    -------
    pd.DataFrame
        DataFrame de ``n`` lignes, 8 colonnes (student_id, 6 P(L), archetype_true).
    """
    rng = np.random.default_rng(seed)

    # Repartition du nombre d'eleves par archetype (arrondi, ajustage du reste)
    counts = {a: int(round(n * p)) for a, p in ARCHETYPE_PROBS.items()}
    # Ajuster pour que la somme fasse exactement n (limite les erreurs d'arrondi)
    diff = n - sum(counts.values())
    if diff != 0:
        # Reporter l'ecart sur le plus gros groupe (Scientifique)
        counts["Scientifique"] += diff

    rows: list[np.ndarray] = []
    labels: list[str] = []

    for archetype, count in counts.items():
        if count <= 0:
            continue
        if archetype == "Mixte_atypique":
            profiles = _generate_mixte_atypique(
                count, rng, sigma=ARCHETYPE_SIGMA[archetype]
            )
        else:
            profiles = _add_coherent_noise(
                centroid=ARCHETYPE_CENTROIDS[archetype],
                sigma=ARCHETYPE_SIGMA[archetype],
                n=count,
                rng=rng,
            )
        rows.append(profiles)
        labels.extend([archetype] * count)

    # Concatenation et melange (pour que l'ordre ne trahisse pas l'archetype)
    X = np.vstack(rows)
    shuffle_idx = rng.permutation(X.shape[0])
    X = X[shuffle_idx]
    labels = [labels[i] for i in shuffle_idx]

    df = pd.DataFrame(X, columns=MATIERES)
    df.insert(0, "student_id", [f"STU_{i:05d}" for i in range(n)])
    df["archetype_true"] = labels
    return df


def main() -> None:
    """Point d'entree CLI : genere le dataset et l'ecrit dans output/."""
    parser = argparse.ArgumentParser(
        description="Genere 2000 profils eleves synthetiques (5 archetypes)."
    )
    parser.add_argument(
        "--n", type=int, default=DEFAULT_N,
        help=f"Nombre d'eleves a generer (default {DEFAULT_N})"
    )
    parser.add_argument(
        "--seed", type=int, default=DEFAULT_SEED,
        help=f"Graine RNG (default {DEFAULT_SEED})"
    )
    args = parser.parse_args()

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    print(f"[generate] Generation de {args.n} profils eleves (seed={args.seed})...")
    df = generate_synthetic_profiles(n=args.n, seed=args.seed)

    output_path = OUTPUT_DIR / "profiles.csv"
    df.to_csv(output_path, index=False)
    print(f"[generate] Dataset sauvegarde : {output_path}")
    print(f"[generate] Shape : {df.shape}")
    print(f"[generate] Colonnes : {list(df.columns)}")
    print()
    print("[generate] Repartition par archetype :")
    print(df["archetype_true"].value_counts().to_string())
    print()
    print("[generate] Statistiques descriptives (P(L) par matiere) :")
    print(df[MATIERES].describe().round(3).to_string())
    print()
    # Sanity check : verifier que le profil moyen par archetype correspond aux centroïdes
    print("[generate] Profil moyen par archetype (verification) :")
    print(df.groupby("archetype_true")[MATIERES].mean().round(3).to_string())


if __name__ == "__main__":
    main()
