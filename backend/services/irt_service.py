"""services/irt_service.py — Item Response Theory (1PL/2PL/3PL).

Reproduit la formule IRT 3PL de ``lib/services/srs_service.dart`` :

    P(theta) = c + (1 - c) * 1 / (1 + exp(-1.7 * a * (theta - b)))

Inclut :
    - irt_probability        : calcul P(reponse correcte)
    - estimate_theta         : estimation du niveau theta par max de vraisemblance
    - calibrate_irt          : estimation de a, b, c depuis un DataFrame de reponses
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Iterable, List, Optional, Sequence, Tuple

import numpy as np


# Constante d'echelle standard pour IRT logistique (Birnbaum 3PL)
IRT_SCALE = 1.7


@dataclass
class IrtItemParams:
    """Parametres IRT pour une question : a, b, c."""

    a: float = 1.0
    b: float = 0.0
    c: float = 0.0


# ─── Probabilite ─────────────────────────────────────────────────────
def irt_probability(
    theta: float, a: float, b: float, c: float = 0.0
) -> float:
    """Calcul de la probabilite de reussite selon le modele IRT 3PL.

    P(theta) = c + (1 - c) * 1 / (1 + exp(-1.7 * a * (theta - b)))

    Parameters
    ----------
    theta:
        Niveau de l'eleve (typiquement entre -3 et +3).
    a:
        Discrimination de l'item (souvent 0.2 a 2.5).
    b:
        Difficulte de l'item (entre -3 et +3).
    c:
        Probabilite de deviner (pseudo-chance), entre 0 et 0.5.

    Returns
    -------
    float
        Probabilite dans [0, 1].
    """
    exponent = -IRT_SCALE * a * (theta - b)
    # Bornage pour eviter l'overflow numerique
    exponent = float(np.clip(exponent, -500.0, 500.0))
    p = c + (1.0 - c) * (1.0 / (1.0 + float(np.exp(exponent))))
    return float(np.clip(p, 0.0, 1.0))


# ─── Estimation de theta ─────────────────────────────────────────────
def estimate_theta(
    responses: Sequence[Tuple[float, float, float, float, int]],
    grid: Optional[Iterable[float]] = None,
) -> float:
    """Estime le niveau ``theta`` d'un eleve par maximum de vraisemblance.

    Parameters
    ----------
    responses:
        Liste de tuples ``(a, b, c, _, correct)`` ou :
            a, b, c : parametres IRT de la question
            _       : reserve (inutilise ici)
            correct : 1 si bonne reponse, 0 sinon
    grid:
        Grille de valeurs theta a tester. Defaut : np.linspace(-3, 3, 61).

    Returns
    -------
    float
        theta estime. Retourne 0.0 si la grille est vide.
    """
    if not responses:
        return 0.0

    thetas = np.array(list(grid)) if grid is not None else np.linspace(-3.0, 3.0, 61)

    log_likelihood = np.zeros_like(thetas, dtype=float)

    for a, b, c, _, correct in responses:
        p = np.array([irt_probability(t, a, b, c) for t in thetas])
        p = np.clip(p, 1e-6, 1.0 - 1e-6)
        if int(correct) == 1:
            log_likelihood += np.log(p)
        else:
            log_likelihood += np.log(1.0 - p)

    # Argmax de la vraisemblance
    idx = int(np.argmax(log_likelihood))
    return float(thetas[idx])


# ─── Calibration des items ───────────────────────────────────────────
@dataclass
class CalibratedItem:
    question_id: str
    a: float
    b: float
    c: float
    n_responses: int
    method: str


def _safe_inverse_norm(p: float) -> float:
    """Approximation simple de l'inverse de la CDF normale (probit).

    Utilisee comme fallback quand py-irt n'est pas disponible.
    """
    p = float(np.clip(p, 1e-4, 1.0 - 1e-4))
    # Approximation de Beasley-Springer-Moro (suffisante pour une demo)
    # On utilise scipy si dispo, sinon une approximation tabulaire.
    try:
        from scipy.stats import norm  # type: ignore

        return float(norm.ppf(p))
    except Exception:
        # Approximation rationnelle simple (Hastings)
        # Bonne entre p=0.01 et p=0.99
        t = 1.0 / (1.0 + 0.2316419 * abs(2.0 * p - 1.0))
        d = 0.3989423 * np.exp(-((2.0 * p - 1.0) ** 2) / (2.0 * 0.4579))
        x = t * (
            0.3193815
            + t * (-0.3565638 + t * (1.781478 + t * (-1.821256 + t * 1.330274)))
        )
        sign = 1.0 if p > 0.5 else -1.0
        return sign * (d / x) if x != 0 else 0.0


def calibrate_irt(responses_df, use_pyirt: bool = True) -> List[CalibratedItem]:
    """Calibre les parametres IRT de chaque item depuis un DataFrame.

    Le DataFrame doit contenir au minimum les colonnes :
        ``question_id``, ``user_id``, ``correct`` (0/1 ou bool).

    Parameters
    ----------
    responses_df:
        DataFrame pandas des reponses observees.
    use_pyirt:
        Si True, tente d'utiliser ``py-irt`` (peut echouer si non installe
        ou si trop peu de donnees). Fallback sur une estimation simple.

    Returns
    -------
    list[CalibratedItem]
        Parametres estimes pour chaque question.
    """
    import pandas as pd

    if responses_df is None or len(responses_df) == 0:
        return []

    df = responses_df.copy()
    df["correct"] = df["correct"].astype(int)

    # Tentative py-irt (optionnelle)
    if use_pyirt:
        try:
            return _calibrate_with_pyirt(df)  # type: ignore[arg-type]
        except Exception:
            pass  # Fallback

    # ─── Fallback : estimation simple par question ───────────────────
    # b ≈ -probit(taux de reussite) (echelle standard)
    # a ≈ 1.0 (discrimination moyenne par defaut)
    # c ≈ 0.0 (pas de guessing estime sans modele)
    results: List[CalibratedItem] = []
    for qid, group in df.groupby("question_id"):
        n = len(group)
        if n < 5:
            # Trop peu de donnees : on garde les valeurs par defaut
            results.append(
                CalibratedItem(
                    question_id=str(qid),
                    a=1.0,
                    b=0.0,
                    c=0.0,
                    n_responses=n,
                    method="default_insufficient_data",
                )
            )
            continue

        p_success = float(group["correct"].mean())
        # b = -inverse_norm(p)  (plus p est grand, plus b est negatif = item facile)
        b = -_safe_inverse_norm(p_success)
        results.append(
            CalibratedItem(
                question_id=str(qid),
                a=1.0,
                b=float(np.clip(b, -3.0, 3.0)),
                c=0.0,
                n_responses=n,
                method="probit_fallback",
            )
        )

    return results


def _calibrate_with_pyirt(df) -> List[CalibratedItem]:
    """Tente la calibration via py-irt (best effort)."""
    import pandas as pd
    import tempfile
    import os
    import json

    try:
        from py_irt import IRTModel  # type: ignore
        from py_irt.dataset import Dataset  # type: ignore
    except Exception as e:
        raise RuntimeError(f"py-irt non disponible: {e}") from e

    # py-irt attend un JSON au format {"item_subject_pairs": [...]}
    # On ecrit dans un fichier temporaire.
    pairs = []
    for _, row in df.iterrows():
        pairs.append([str(row["question_id"]), str(row["user_id"]), int(row["correct"])])

    with tempfile.NamedTemporaryFile(mode="w", suffix=".json", delete=False) as f:
        json.dump({"item_subject_pairs": pairs}, f)
        data_path = f.name

    try:
        dataset = Dataset.from_json(data_path)
        model = IRTModel(model_type="3pl")
        model.fit(dataset)

        items: List[CalibratedItem] = []
        # py-irt expose les parametres dans model._parameters
        params = getattr(model, "_parameters", {})
        a_params = params.get("disc", {})
        b_params = params.get("diff", {})
        c_params = params.get("guessing", {})

        for qid in df["question_id"].unique():
            qid_str = str(qid)
            n = int((df["question_id"] == qid).sum())
            items.append(
                CalibratedItem(
                    question_id=qid_str,
                    a=float(a_params.get(qid_str, 1.0)),
                    b=float(b_params.get(qid_str, 0.0)),
                    c=float(c_params.get(qid_str, 0.0)),
                    n_responses=n,
                    method="py-irt-3pl",
                )
            )
        return items
    finally:
        try:
            os.unlink(data_path)
        except OSError:
            pass


# ─── Helpers de selection adaptive ───────────────────────────────────
def select_best_item(
    theta: float,
    items: Sequence[Tuple[str, float, float, float]],
) -> Optional[str]:
    """Selectionne l'item qui maximise l'information de Fisher a ``theta``.

    Parameters
    ----------
    theta:
        Niveau estime de l'eleve.
    items:
        Liste de ``(question_id, a, b, c)``.

    Returns
    -------
    str | None
        Identifiant de la question la plus informative.
    """
    best_id: Optional[str] = None
    best_info = -1.0
    for qid, a, b, c in items:
        info = fisher_information(theta, a, b, c)
        if info > best_info:
            best_info = info
            best_id = qid
    return best_id


def fisher_information(theta: float, a: float, b: float, c: float = 0.0) -> float:
    """Information de Fisher d'un item 3PL au niveau ``theta``."""
    p = irt_probability(theta, a, b, c)
    if p <= c or p >= 1.0:
        return 0.0
    q = 1.0 - p
    num = (IRT_SCALE * a) ** 2 * (p - c) ** 2
    den = (1.0 - c) ** 2 * p * q
    if den <= 0:
        return 0.0
    return float(num / den)
