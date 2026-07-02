"""generate_synthetic_data.py — Genere des donnees de reponses pour calibration IRT.

Pour la demonstration et les tests du pipeline, on simule un dataset realiste
de 500 eleves x 50+ questions = 25 000+ reponses. Chaque eleve a un niveau
theta tire depuis N(0, 1), et chaque reponse est generee selon la formule
IRT 3PL utilisee dans le reste du projet (cf. ``lib/services/srs_service.dart``
et ``backend/services/irt_service.py``) :

    P(correct | theta) = c + (1 - c) * 1 / (1 + exp(-1.7 * a * (theta - b)))

On ajoute egalement :
- 5% de bruit (reponses aleatoires) pour simuler les inattentions
- Un temps de reponse corrélé avec l'ecart |theta - b| (eleves bloques
  plus longtemps sur les questions loin de leur niveau)

Usage
-----
    python generate_synthetic_data.py
    python generate_synthetic_data.py --n-students 1000 --questions-file ../../assets/data/questions.json
"""

from __future__ import annotations

import argparse
import json
import math
import sys
from pathlib import Path
from typing import Any

import numpy as np
import pandas as pd

# ─── Constantes IRT (miroir de srs_service.dart / irt_service.py) ──────────
IRT_SCALE: float = 1.7  # constante d'echelle logistique de Birnbaum

# Reproducibilite : seed fixe pour pouvoir comparer les runs
DEFAULT_SEED: int = 42

# Bruuit : 5% de reponses aleatoires (inattentions, clics trompes)
NOISE_RATE: float = 0.05


# ─── Fonctions IRT (miroir exact de irt_service.py) ────────────────────────
def irt_probability(theta: float, a: float, b: float, c: float = 0.0) -> float:
    """Probabilite de reussite selon le modele IRT 3PL.

    P(theta) = c + (1 - c) * 1 / (1 + exp(-1.7 * a * (theta - b)))

    Bornage numerique de l'exposant pour eviter l'overflow.
    """
    exponent = -IRT_SCALE * a * (theta - b)
    exponent = float(np.clip(exponent, -500.0, 500.0))
    p = c + (1.0 - c) * (1.0 / (1.0 + math.exp(exponent)))
    return float(np.clip(p, 0.0, 1.0))


def _load_questions(questions_file: Path) -> list[dict[str, Any]]:
    """Charge questions.json et filtre celles qui ont un irt.b defini."""
    if not questions_file.exists():
        raise FileNotFoundError(
            f"Fichier questions introuvable : {questions_file}\n"
            f"Utilise --questions-file pour specifier un autre chemin."
        )
    with open(questions_file, "r", encoding="utf-8") as f:
        questions = json.load(f)

    # On garde les questions avec irt.b defini (seuil minimal pour calibrer)
    questions_with_irt = [
        q for q in questions if q.get("irt", {}).get("b") is not None
    ]
    if not questions_with_irt:
        raise ValueError(
            "Aucune question avec irt.b defini dans le fichier. "
            "Impossible de generer des donnees synthetiques."
        )
    return questions_with_irt


def _default_guessing(q: dict[str, Any]) -> float:
    """Estimation du guessing par defaut selon le type de question.

    - QCM avec k choix : c = 1/k (chance pure)
    - Vrai/Faux : c = 0.5
    - Ouvert / calcul / redaction : c = 0.0 (pas de chance)
    """
    qtype = q.get("type", "ouvert")
    if qtype == "qcm":
        choix = q.get("choix") or []
        return 1.0 / max(len(choix), 2) if choix else 0.25
    if qtype == "vraiFaux":
        return 0.5
    return 0.0


def generate_synthetic_responses(
    n_students: int = 500,
    questions_file: str | Path = "assets/data/questions.json",
    output_file: str | Path = "output/synthetic_responses.csv",
    seed: int = DEFAULT_SEED,
    noise_rate: float = NOISE_RATE,
    verbose: bool = True,
) -> pd.DataFrame:
    """Genere un DataFrame de reponses synthetiques.

    Parameters
    ----------
    n_students:
        Nombre d'eleves a simuler.
    questions_file:
        Chemin vers questions.json (contient les valeurs initiales de a, b, c).
    output_file:
        Fichier CSV de sortie. Cree les parents si necessaire.
    seed:
        Graine aleatoire pour reproducibilite.
    noise_rate:
        Proportion de reponses aleatoires (inattentions).
    verbose:
        Affiche l'avancement.

    Returns
    -------
    pandas.DataFrame
        Colonnes : [student_id, question_id, correct, theta_true,
                    time_spent, matiere, examen, type]
    """
    questions_file = Path(questions_file)
    output_file = Path(output_file)
    questions = _load_questions(questions_file)

    rng = np.random.default_rng(seed)

    # Tire theta pour chaque eleve : N(0, 1) tronque a [-3, 3]
    thetas = np.clip(rng.normal(0.0, 1.0, n_students), -3.0, 3.0)

    # Pre-extrait les params IRT reels des questions (pour la simulation)
    # Ces valeurs "vraies" seront comparees aux valeurs estimees par calibrate_irt.py
    q_params = []
    for q in questions:
        a = q["irt"].get("a") or 1.0  # discrimination par defaut = 1.0
        b = q["irt"].get("b")  # b est toujours defini (filtre _load_questions)
        c = q["irt"].get("c")
        if c is None:
            c = _default_guessing(q)
        q_params.append((q, float(a), float(b), float(c)))

    rows: list[dict[str, Any]] = []
    for student_idx, theta in enumerate(thetas):
        if verbose and student_idx % 100 == 0 and student_idx > 0:
            print(f"  ... {student_idx}/{n_students} eleves generes")
        for q, a, b, c in q_params:
            p_correct = irt_probability(float(theta), a, b, c)

            # Simulation de la reponse binaire
            if rng.random() < noise_rate:
                # Bruit : reponse aleatoire (independante de theta)
                correct = int(rng.random() < 0.5)
            else:
                correct = int(rng.random() < p_correct)

            # Temps de reponse : 15s de base + 10s par ecart |theta - b|
            # + bruit gaussien. Les eleves faibles passent plus de temps
            # sur les questions difficiles, et inversement.
            base_time = 15.0 + abs(b - theta) * 10.0
            time_spent = max(3.0, rng.normal(base_time, 5.0))

            rows.append(
                {
                    "student_id": f"synthetic_{student_idx:04d}",
                    "question_id": q["id"],
                    "correct": correct,
                    "theta_true": round(float(theta), 4),
                    "time_spent": round(float(time_spent), 1),
                    "matiere": q.get("matiere", ""),
                    "examen": q.get("examen", ""),
                    "type": q.get("type", "ouvert"),
                }
            )

    df = pd.DataFrame(rows)

    # Sauvegarde (cree le dossier parent si necessaire)
    output_file.parent.mkdir(parents=True, exist_ok=True)
    df.to_csv(output_file, index=False, encoding="utf-8")

    if verbose:
        print(
            f"[OK] {len(df)} reponses synthetiques generees "
            f"({n_students} eleves x {len(q_params)} questions)"
        )
        print(f"     Sauvegarde : {output_file}")
        print(
            f"     Taux de reussite moyen : {df['correct'].mean():.3f} | "
            f"theta moyen : {df['theta_true'].mean():.3f} | "
            f"temps moyen : {df['time_spent'].mean():.1f}s"
        )

    return df


def main() -> int:
    """Point d'entree CLI."""
    parser = argparse.ArgumentParser(
        description="Genere des donnees synthetiques pour calibration IRT.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=(
            "Exemple :\n"
            "  python generate_synthetic_data.py --n-students 500\n"
            "  python generate_synthetic_data.py --output output/synthetic.csv\n"
        ),
    )
    parser.add_argument(
        "--n-students",
        type=int,
        default=500,
        help="Nombre d'eleves a simuler (defaut: 500).",
    )
    parser.add_argument(
        "--questions-file",
        type=str,
        default="../../assets/data/questions.json",
        help=(
            "Chemin vers questions.json. Defaut : ../../assets/data/questions.json "
            "(relatif au dossier irt_calibration/)."
        ),
    )
    parser.add_argument(
        "--output",
        type=str,
        default="output/synthetic_responses.csv",
        help="Fichier CSV de sortie (defaut: output/synthetic_responses.csv).",
    )
    parser.add_argument(
        "--seed",
        type=int,
        default=DEFAULT_SEED,
        help=f"Graine aleatoire (defaut: {DEFAULT_SEED}).",
    )
    parser.add_argument(
        "--noise",
        type=float,
        default=NOISE_RATE,
        help=f"Taux de bruit (defaut: {NOISE_RATE}).",
    )
    parser.add_argument(
        "--quiet",
        action="store_true",
        help="Mode silencieux (pas d'avancement).",
    )
    args = parser.parse_args()

    # Resolution du chemin questions.json : relatif au script, pas au CWD
    script_dir = Path(__file__).resolve().parent
    questions_path = Path(args.questions_file)
    if not questions_path.is_absolute():
        # Essai 1 : relatif au CWD
        if not questions_path.exists():
            # Essai 2 : relatif au dossier du script
            questions_path = script_dir / args.questions_file
        # Essai 3 : relatif a la racine du projet (4 niveaux au-dessus)
        if not questions_path.exists():
            alt = script_dir.parent.parent.parent / args.questions_file.lstrip("../")
            if alt.exists():
                questions_path = alt

    try:
        generate_synthetic_responses(
            n_students=args.n_students,
            questions_file=questions_path,
            output_file=args.output,
            seed=args.seed,
            noise_rate=args.noise,
            verbose=not args.quiet,
        )
    except (FileNotFoundError, ValueError) as e:
        print(f"[ERREUR] {e}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
