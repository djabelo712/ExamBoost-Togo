"""
Estimation initiale des paramètres IRT (b = difficulté) pour chaque question.

Stratégie:
    - Si on dispose de données historiques de réponses (taux de réussite),
      on utilise la formule inverse de la probabilité du modèle 3PL (en
      négligeant a et c pour l'estimation initiale):
          b = inv_norm(1 - taux_reussite)
      (taux_reussite=0.8 -> b=-0.84 ; taux_reussite=0.5 -> b=0 ;
       taux_reussite=0.2 -> b=+0.84).
    - Sinon, on estime heuristiquement:
          b_base = {
              "calcul":  0.5  (questions longues),
              "qcm":     0.0,
              "ouvert":  0.3,
              "vraiFaux":-0.2,
              "redaction": 0.8,
          }
      Ajustements:
          + 0.3 si points == 5 (questions a fort enjeu)
          + 0.4 si examen commence par "BAC" (vs BEPC)
          + 0.2 si serie in {"C", "D"} (vs A, B, F)
          - 0.1 si explication absente (signal de question difficile a formuler)

Les paramètres a (discrimination) et c (chance) restent null tant que
la calibration réelle (via le backend py-irt) n'a pas tourné. Le champ
`calibre` reste False.

Usage:
    python estimate_irt.py
    python estimate_irt.py --history data/history_responses.csv
"""

from __future__ import annotations

import argparse
import csv
import logging
import math
import sys
from pathlib import Path
from typing import Dict, List, Optional

from config import PATHS
from utils.json_utils import load_questions, save_questions

logger = logging.getLogger("estimate_irt")


# ─── Heuristiques ─────────────────────────────────────────────────────────

BASE_B_BY_TYPE: Dict[str, float] = {
    "calcul": 0.5,
    "qcm": 0.0,
    "ouvert": 0.3,
    "vraiFaux": -0.2,
    "redaction": 0.8,
}

POINTS_BONUS_5: float = 0.3
BAC_BONUS: float = 0.4
SCIENTIFIC_SERIE_BONUS: float = 0.2
NO_EXPLANATION_PENALTY: float = -0.1

SCIENTIFIC_SERIES = {"C", "D"}


def inv_norm(p: float) -> float:
    """Inverse of the standard normal CDF (rational approximation).

    Args:
        p: probability in (0, 1) — clamped to avoid infinities.

    Returns:
        z such that P(Z <= z) = p.
    """
    p = max(min(p, 0.999), 0.001)
    # Beasley-Springer-Moro algorithm.
    a = [-3.969683028665376e+01, 2.209460984245205e+02,
         -2.759285104469687e+02, 1.383577518672690e+02,
         -3.066479806614716e+01, 2.506628277459239e+00]
    b = [-5.447609879822406e+01, 1.615858368580409e+02,
         -1.556989798598866e+02, 6.680131188771972e+01,
         -1.328068155288572e+01]
    c = [-7.784894002430293e-03, -3.223964580411365e-01,
         -2.400758277161838e+00, -2.549732539343734e+00,
         4.374664141464968e+00, 2.938163982698783e+00]
    d = [7.784695709041462e-03, 3.224671290700398e-01,
         2.445134137142996e+00, 3.754408661907416e+00]
    p_low = 0.02425
    p_high = 1 - p_low
    if p < p_low:
        q = math.sqrt(-2 * math.log(p))
        x = (((((c[0]*q + c[1])*q + c[2])*q + c[3])*q + c[4])*q + c[5]) / \
            ((((d[0]*q + d[1])*q + d[2])*q + d[3])*q + 1)
    elif p <= p_high:
        q = p - 0.5
        r = q * q
        x = (((((a[0]*r + a[1])*r + a[2])*r + a[3])*r + a[4])*r + a[5]) * q / \
            (((((b[0]*r + b[1])*r + b[2])*r + b[3])*r + b[4])*r + 1)
    else:
        q = math.sqrt(-2 * math.log(1 - p))
        x = -(((((c[0]*q + c[1])*q + c[2])*q + c[3])*q + c[4])*q + c[5]) / \
            ((((d[0]*q + d[1])*q + d[2])*q + d[3])*q + 1)
    return x


def estimate_b_heuristic(question: Dict) -> float:
    """Estimate the IRT difficulty parameter b from question metadata.

    Args:
        question: question dict.

    Returns:
        Estimated b in roughly [-2, +2].
    """
    qtype = question.get("type", "ouvert")
    b = BASE_B_BY_TYPE.get(qtype, 0.3)

    points = question.get("points")
    if points == 5:
        b += POINTS_BONUS_5

    examen = question.get("examen", "")
    if examen.startswith("BAC"):
        b += BAC_BONUS

    serie = question.get("serie")
    if serie in SCIENTIFIC_SERIES:
        b += SCIENTIFIC_SERIE_BONUS

    if not (question.get("explication") or "").strip():
        b += NO_EXPLANATION_PENALTY

    # Clamp final.
    return round(max(-3.0, min(3.0, b)), 3)


def estimate_b_from_success_rate(success_rate: float) -> float:
    """Compute b from an observed success rate using the inverse normal CDF.

    For a learner of average ability (theta=0), the 1PL probability is:
        P(theta=0) = 1 / (1 + e^b)
    => b = ln( (1-P) / P )  =  -inv_norm(P) approximativement.

    We use the more standard convention b = inv_norm(1 - P) which is
    equivalent (since logistic approximates the normal CDF).

    Args:
        success_rate: observed proportion correct in (0, 1).

    Returns:
        Estimated b.
    """
    return round(inv_norm(1.0 - success_rate), 3)


# ─── Historique de reponses ───────────────────────────────────────────────


def load_history(csv_path: Path | str) -> Dict[str, float]:
    """Load a CSV of historical success rates per question id.

    Expected CSV format:
        question_id,n_attempts,n_correct
        TG-BEPC-MATHS-2022-Q01,100,72

    Args:
        csv_path: path to the CSV.

    Returns:
        Dict {question_id: success_rate}.
    """
    csv_path = Path(csv_path)
    if not csv_path.exists():
        logger.warning("Fichier historique absent: %s", csv_path)
        return {}
    out: Dict[str, float] = {}
    with csv_path.open("r", encoding="utf-8") as fh:
        reader = csv.DictReader(fh)
        for row in reader:
            qid = row.get("question_id") or row.get("id")
            try:
                n_a = int(row.get("n_attempts", 0))
                n_c = int(row.get("n_correct", 0))
                if n_a > 0:
                    out[qid] = n_c / n_a
            except (ValueError, TypeError):
                continue
    logger.info("Historique charge: %d entrees", len(out))
    return out


# ─── Estimation globale ───────────────────────────────────────────────────


def estimate_irt_for_questions(
    questions: List[Dict],
    history: Optional[Dict[str, float]] = None,
) -> List[Dict]:
    """Fill the irt.b field for every question lacking it.

    Args:
        questions: list of question dicts (mutated in-place and returned).
        history: optional {question_id: success_rate} mapping.

    Returns:
        The same list (mutated) with irt.b set on every question.
    """
    history = history or {}
    estimated = 0
    from_history = 0
    for q in questions:
        irt = q.get("irt")
        if not isinstance(irt, dict):
            irt = {"a": None, "b": None, "c": None, "calibre": False}
            q["irt"] = irt
        if irt.get("b") is not None:
            continue  # deja calibre ou estime manuellement

        qid = q.get("id", "")
        if qid in history:
            b = estimate_b_from_success_rate(history[qid])
            from_history += 1
        else:
            b = estimate_b_heuristic(q)
        irt["b"] = b
        estimated += 1

    logger.info(
        "IRT estime pour %d question(s) (%d depuis historique, %d heuristique).",
        estimated, from_history, estimated - from_history,
    )
    return questions


# ─── Driver ───────────────────────────────────────────────────────────────


def run(
    input_path: Optional[Path] = None,
    output_path: Optional[Path] = None,
    history_csv: Optional[Path] = None,
) -> int:
    """Load deduped questions, estimate IRT, save final questions.json.

    Args:
        input_path: defaults to PATHS.final / questions_dedup.json.
        output_path: defaults to PATHS.final / questions.json.
        history_csv: optional CSV of observed success rates.

    Returns:
        Number of questions in the final file.
    """
    input_path = input_path or (PATHS.final / "questions_dedup.json")
    output_path = output_path or (PATHS.final / "questions.json")

    if not input_path.exists():
        logger.error("Fichier d'entree manquant: %s (lancer deduplicate.py d'abord)", input_path)
        return 0

    questions = load_questions(input_path)
    history = load_history(history_csv) if history_csv else {}
    estimate_irt_for_questions(questions, history)
    save_questions(questions, output_path)
    logger.info("Final: %s (%d questions)", output_path, len(questions))
    return len(questions)


# ─── CLI ──────────────────────────────────────────────────────────────────


def main(argv: Optional[List[str]] = None) -> int:
    """CLI entry point."""
    parser = argparse.ArgumentParser(description="Estimation initiale IRT (parametre b).")
    parser.add_argument("--history", type=Path, help="CSV de taux de reussite observes.")
    args = parser.parse_args(argv)

    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s | %(levelname)-8s | %(name)s | %(message)s",
    )
    count = run(history_csv=args.history)
    print(f"questions.json final: {count} questions avec IRT estime.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
