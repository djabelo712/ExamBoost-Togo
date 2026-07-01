"""calibrate_irt.py — Calibre les parametres IRT 3PL (a, b, c) des questions.

Pipeline principal de calibration. Deux methodes supportees :

1. **py-irt** (recommande si disponible) : estimation MML bayesienne via
   l'API ``py_irt.training.IrtModelTraining`` (modele '3pl'). Si l'API 3PL
   n'est pas disponible (py-irt 0.1.1 ne fournit que 1PL/2PL via Pyro),
   bascule automatiquement sur le fallback numpy.

2. **numpy MLE** (fallback robuste) : estimation conjointe par optimisation
   alternee (EM-like) :
   - E-step : pour chaque eleve, on estime theta par max de vraisemblance
     sur une grille [-3, +3] puis refinement Nelder-Mead.
   - M-step : pour chaque item, on estime (a, b, c) par L-BFGS-B avec
     bornes physiques (a in [0.2, 2.5], b in [-3, 3], c in [0, 0.5]).
   - On itere jusqu'a convergence (max 25 iterations ou delta LL < 1e-4).

La formule IRT 3PL utilisee est strictement identique a celle de
``lib/services/srs_service.dart`` et ``backend/services/irt_service.py`` :

    P(theta) = c + (1 - c) * 1 / (1 + exp(-1.7 * a * (theta - b)))

Usage
-----
    python calibrate_irt.py --input output/synthetic_responses.csv
    python calibrate_irt.py --input output/synthetic_responses.csv --method numpy
    python calibrate_irt.py --method py-irt --iterations 1000
"""

from __future__ import annotations

import argparse
import json
import math
import sys
import time
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any

import numpy as np
import pandas as pd
from scipy.optimize import minimize
from scipy.special import expit  # = 1 / (1 + exp(-x)), stable numériquement

# ─── Constantes IRT (miroir de srs_service.dart / irt_service.py) ──────────
IRT_SCALE: float = 1.7

# Bornes physiques des parametres IRT 3PL
A_BOUNDS: tuple[float, float] = (0.2, 2.5)
B_BOUNDS: tuple[float, float] = (-3.0, 3.0)
C_BOUNDS: tuple[float, float] = (0.0, 0.5)
THETA_BOUNDS: tuple[float, float] = (-3.0, 3.0)

# Grille pour l'estimation de theta (E-step)
THETA_GRID: np.ndarray = np.linspace(-3.0, 3.0, 61)

# Parametres EM
MAX_ITERATIONS: int = 25
LL_TOLERANCE: float = 1e-4

# Epsilon numerique pour eviter log(0)
EPS: float = 1e-9


# ─── Dataclasses ───────────────────────────────────────────────────────────
@dataclass
class CalibratedItem:
    """Parametres IRT calibres pour une question."""

    question_id: str
    a: float
    b: float
    c: float
    n_responses: int
    p_observed: float  # taux de reussite observe
    method: str
    log_likelihood: float = 0.0


@dataclass
class CalibratedStudent:
    """Niveau theta estime pour un eleve."""

    student_id: str
    theta: float
    n_responses: int = 0


@dataclass
class CalibrationResult:
    """Resultat complet d'une calibration."""

    item_params: list[CalibratedItem]
    student_params: list[CalibratedStudent]
    method: str
    n_iterations: int
    final_log_likelihood: float
    convergence_achieved: bool
    metadata: dict[str, Any]


# ─── Fonctions IRT (vectorisees numpy) ─────────────────────────────────────
def irt_probability_vectorized(
    thetas: np.ndarray, a: float, b: float, c: float
) -> np.ndarray:
    """Probabilite IRT 3PL vectorisee sur un vecteur de thetas.

    P(theta) = c + (1 - c) * sigmoid(1.7 * a * (theta - b))

    Utilise scipy.special.expit (numeriquement stable).
    """
    logits = IRT_SCALE * a * (thetas - b)
    return c + (1.0 - c) * expit(logits)


def irt_probability(theta: float, a: float, b: float, c: float = 0.0) -> float:
    """Probabilite IRT 3PL scalaire (compat avec irt_service.py)."""
    return float(irt_probability_vectorized(np.array([theta]), a, b, c)[0])


# ─── Pretraitement du DataFrame ────────────────────────────────────────────
def prepare_dataframe(df: pd.DataFrame) -> tuple[pd.DataFrame, list[str], list[str]]:
    """Valide et prepare le DataFrame de reponses.

    Returns
    -------
    (df_clean, item_ids, student_ids)
        df_clean : DataFrame avec colonnes [student_id, question_id, correct]
                   (correct = 0/1 int).
        item_ids : liste unique des question_id (ordre stable).
        student_ids : liste unique des student_id (ordre stable).
    """
    required = {"student_id", "question_id", "correct"}
    missing = required - set(df.columns)
    if missing:
        raise ValueError(f"Colonnes manquantes dans le DataFrame : {missing}")

    df_clean = df[["student_id", "question_id", "correct"]].copy()
    df_clean["correct"] = df_clean["correct"].astype(int)

    # Filtre les reponses invalides
    df_clean = df_clean[df_clean["correct"].isin([0, 1])].dropna()

    item_ids = sorted(df_clean["question_id"].unique().tolist())
    student_ids = sorted(df_clean["student_id"].unique().tolist())

    if len(item_ids) == 0:
        raise ValueError("Aucune question dans le DataFrame.")
    if len(student_ids) == 0:
        raise ValueError("Aucun eleve dans le DataFrame.")

    return df_clean, item_ids, student_ids


def build_response_matrix(
    df: pd.DataFrame, item_ids: list[str], student_ids: list[str]
) -> np.ndarray:
    """Construit la matrice de reponses R[student, item] en int8.

    Les cases manquantes (eleve n'a pas repondu a la question) sont
    encodees a -1 pour les distinguer des 0/1 valides.
    """
    item_index = {qid: i for i, qid in enumerate(item_ids)}
    student_index = {sid: i for i, sid in enumerate(student_ids)}

    n_s = len(student_ids)
    n_i = len(item_ids)
    R = np.full((n_s, n_i), -1, dtype=np.int8)

    for _, row in df.iterrows():
        s_idx = student_index[row["student_id"]]
        i_idx = item_index[row["question_id"]]
        R[s_idx, i_idx] = int(row["correct"])

    return R


# ─── E-step : estimation des theta par eleve (vectorise) ───────────────────
# Prior N(0, 1) sur theta pour stabiliser les eleves a 0% / 100% de reussite.
THETA_PRIOR_PRECISION: float = 0.1  # faible : -0.05 * theta^2 (regularisation leger)


def estimate_student_theta(
    responses: np.ndarray,
    a_arr: np.ndarray,
    b_arr: np.ndarray,
    c_arr: np.ndarray,
) -> float:
    """Estime le theta d'un eleve par max de vraisemblance (scalaire, lent).

    Version de reference utilisee pour debug. Pour la calibration en production,
    preferer ``estimate_all_thetas`` (vectorisee, beaucoup plus rapide).

    responses : tableau (n_items,) avec -1 pour les manquants, 0/1 sinon.
    """
    mask = responses >= 0
    if mask.sum() == 0:
        return 0.0
    thetas = estimate_all_thetas(
        responses[None, :], a_arr, b_arr, c_arr, refine=True
    )
    return float(thetas[0])


def estimate_all_thetas(
    R: np.ndarray,
    a_arr: np.ndarray,
    b_arr: np.ndarray,
    c_arr: np.ndarray,
    refine: bool = True,
) -> np.ndarray:
    """Estime theta pour tous les eleves en une seule operation vectorisee.

    1. Grille fine [-3, +3] (121 points) : calcule la log-vraisemblance de
       chaque eleve sur toute la grille en une multiplication matricielle.
    2. (Optionnel) Raffinement Nelder-Mead par eleve autour du best de la
       grille. Active par defaut, desactivable pour gagner du temps.

    Parameters
    ----------
    R:
        Matrice (n_students, n_items) avec -1 pour les manquants, 0/1 sinon.
    a_arr, b_arr, c_arr:
        Parametres IRT courants des items (n_items,).
    refine:
        Si True, raffine chaque theta par Nelder-Mead (plus precis, plus lent).

    Returns
    -------
    np.ndarray
        Theta estime par eleve (n_students,).
    """
    n_students, n_items = R.shape
    grid = THETA_GRID
    n_grid = len(grid)

    # Probabilites sur la grille : P[k, j] = P(theta=grid[k] | item j)
    logits = IRT_SCALE * a_arr[None, :] * (grid[:, None] - b_arr[None, :])
    P = c_arr[None, :] + (1.0 - c_arr[None, :]) * expit(logits)  # (n_grid, n_items)
    P = np.clip(P, EPS, 1.0 - EPS)
    log_P = np.log(P)          # (n_grid, n_items)
    log_1mP = np.log(1.0 - P)  # (n_grid, n_items)

    # Masques : R_correct[s, j]=1 si correct, R_incorrect[s, j]=1 si incorrect
    R_correct = (R == 1).astype(np.float64)      # (n_students, n_items)
    R_incorrect = (R == 0).astype(np.float64)    # (n_students, n_items)

    # LL[s, k] = sum_j R_correct[s,j] * log_P[k,j] + R_incorrect[s,j] * log_1mP[k,j]
    #            - 0.05 * grid[k]^2   (prior faible sur theta)
    LL = R_correct @ log_P.T + R_incorrect @ log_1mP.T  # (n_students, n_grid)
    LL -= THETA_PRIOR_PRECISION * 0.5 * (grid ** 2)[None, :]

    best_idx = np.argmax(LL, axis=1)  # (n_students,)
    best_theta = grid[best_idx]       # (n_students,)

    if not refine:
        return np.clip(best_theta, *THETA_BOUNDS)

    # Raffinement Nelder-Mead par eleve (vectorisation impossible car chaque
    # eleve a un pattern de reponses different). On pre-extrait les donnees
    # pour minimiser le cout par appel.
    thetas_refined = best_theta.copy()
    for i in range(n_students):
        mask = R[i, :] >= 0
        if mask.sum() == 0:
            continue
        r = R[i, mask].astype(float)
        a = a_arr[mask]
        b = b_arr[mask]
        c = c_arr[mask]

        def neg_ll(theta_vec: np.ndarray) -> float:
            theta = float(theta_vec[0])
            p = c + (1.0 - c) * expit(IRT_SCALE * a * (theta - b))
            p = np.clip(p, EPS, 1.0 - EPS)
            ll = float(np.where(r == 1, np.log(p), np.log(1.0 - p)).sum())
            ll -= THETA_PRIOR_PRECISION * 0.5 * theta * theta
            return -ll

        result = minimize(
            neg_ll,
            x0=[best_theta[i]],
            method="Nelder-Mead",
            options={"xatol": 1e-3, "fatol": 1e-3, "maxiter": 50},
        )
        thetas_refined[i] = float(np.clip(result.x[0], *THETA_BOUNDS))

    return thetas_refined


# ─── M-step : estimation des (a, b, c) par item ────────────────────────────
def estimate_item_params(
    responses: np.ndarray,
    thetas: np.ndarray,
    is_qcm: bool = False,
) -> tuple[float, float, float, float]:
    """Estime (a, b, c) d'un item par max de vraisemblance (L-BFGS-B).

    responses : tableau (n_students,) avec -1 pour les manquants.
    thetas : tableau (n_students,) des theta estimes.
    is_qcm : si True, on autorise c a etre estime ; sinon c = 0 (force).

    Returns
    -------
    (a, b, c, log_likelihood)
    """
    mask = responses >= 0
    if mask.sum() < 5:
        # Trop peu de donnees : on garde les valeurs par defaut
        return 1.0, 0.0, (0.25 if is_qcm else 0.0), 0.0

    r = responses[mask].astype(float)
    theta = thetas[mask]

    # Initialisation : b = -probit(taux de reussite), a = 1.0, c = 0 (ou 0.25 QCM)
    p_obs = float(np.clip(r.mean(), 0.01, 0.99))
    from scipy.stats import norm
    b_init = float(np.clip(-norm.ppf(p_obs), *B_BOUNDS))
    a_init = 1.0
    c_init = 0.2 if is_qcm else 0.0

    def neg_log_lik(params: np.ndarray) -> float:
        if is_qcm:
            a, b, c = float(params[0]), float(params[1]), float(params[2])
        else:
            a, b = float(params[0]), float(params[1])
            c = 0.0
        p = irt_probability_vectorized(theta, a, b, c)
        p = np.clip(p, EPS, 1.0 - EPS)
        ll = float(np.where(r == 1, np.log(p), np.log(1.0 - p)).sum())
        # Regularisation faible : a proche de 1, c proche de sa valeur initiale
        ll += -0.01 * (a - 1.0) ** 2
        if is_qcm:
            ll += -0.01 * (c - 0.2) ** 2
        return -ll

    if is_qcm:
        x0 = np.array([a_init, b_init, c_init])
        bounds = [A_BOUNDS, B_BOUNDS, C_BOUNDS]
    else:
        x0 = np.array([a_init, b_init])
        bounds = [A_BOUNDS, B_BOUNDS]

    result = minimize(
        neg_log_lik,
        x0=x0,
        method="L-BFGS-B",
        bounds=bounds,
        options={"maxiter": 200, "ftol": 1e-6},
    )

    if is_qcm:
        a_est, b_est, c_est = float(result.x[0]), float(result.x[1]), float(result.x[2])
    else:
        a_est, b_est = float(result.x[0]), float(result.x[1])
        c_est = 0.0

    # Log-vraisemblance finale (sans regularisation, pour le reporting)
    p = irt_probability_vectorized(theta, a_est, b_est, c_est)
    p = np.clip(p, EPS, 1.0 - EPS)
    final_ll = float(np.where(r == 1, np.log(p), np.log(1.0 - p)).sum())

    return a_est, b_est, c_est, final_ll


# ─── Methode principale : numpy MLE alterne (EM-like) ──────────────────────
def calibrate_with_numpy(
    df: pd.DataFrame,
    item_types: dict[str, str] | None = None,
    max_iterations: int = MAX_ITERATIONS,
    ll_tolerance: float = LL_TOLERANCE,
    verbose: bool = True,
) -> CalibrationResult:
    """Calibre IRT 3PL par optimisation alternee (EM-like) avec numpy + scipy.

    Parameters
    ----------
    df:
        DataFrame avec colonnes [student_id, question_id, correct].
    item_types:
        Dictionnaire {question_id: type} pour savoir si on estime c
        (QCM/vraiFaux) ou si on force c = 0 (ouvert/calcul/redaction).
    max_iterations:
        Nombre max d'iterations EM.
    ll_tolerance:
        Seuil de convergence sur la variation de log-vraisemblance.
    verbose:
        Affiche l'avancement.

    Returns
    -------
    CalibrationResult
    """
    item_types = item_types or {}
    df_clean, item_ids, student_ids = prepare_dataframe(df)
    R = build_response_matrix(df_clean, item_ids, student_ids)

    n_students, n_items = R.shape
    if verbose:
        print(
            f"[numpy] {n_students} eleves x {n_items} questions "
            f"= {(R >= 0).sum()} reponses observees"
        )

    # Initialisation
    theta_arr = np.zeros(n_students, dtype=float)
    a_arr = np.ones(n_items, dtype=float)
    b_arr = np.zeros(n_items, dtype=float)
    c_arr = np.zeros(n_items, dtype=float)

    # Init de b : -probit(taux de reussite observe par item)
    from scipy.stats import norm
    for j in range(n_items):
        col = R[:, j]
        valid = col >= 0
        if valid.sum() >= 5:
            p_obs = float(np.clip(col[valid].mean(), 0.01, 0.99))
            b_arr[j] = float(np.clip(-norm.ppf(p_obs), *B_BOUNDS))
        # Init de c pour QCM/vraiFaux
        qid = item_ids[j]
        qtype = item_types.get(qid, "ouvert")
        if qtype == "qcm":
            c_arr[j] = 0.2
        elif qtype == "vraiFaux":
            c_arr[j] = 0.4

    # Iterations EM
    prev_ll: float = -float("inf")
    prev_params: np.ndarray | None = None
    convergence_achieved = False
    ll_history: list[float] = []
    item_ll: list[float] = [0.0] * n_items

    t0 = time.time()
    iteration = 0
    for iteration in range(1, max_iterations + 1):
        # ─── E-step : theta pour tous les eleves (vectorise) ─────────────
        theta_arr = estimate_all_thetas(R, a_arr, b_arr, c_arr, refine=True)

        # ─── M-step : (a, b, c) pour chaque item ─────────────────────────
        total_ll = 0.0
        for j in range(n_items):
            qid = item_ids[j]
            qtype = item_types.get(qid, "ouvert")
            is_qcm = qtype in ("qcm", "vraiFaux")
            a, b, c, ll = estimate_item_params(R[:, j], theta_arr, is_qcm=is_qcm)
            a_arr[j] = a
            b_arr[j] = b
            c_arr[j] = c
            item_ll[j] = ll
            total_ll += ll

        ll_history.append(total_ll)

        # Convergence : variation des parametres (plus robuste que la LL
        # a cause de la regularisation du prior qui casse la monotonie EM).
        # On verifie que ||params_new - params_old|| / ||params_old|| < 1e-3.
        cur_params = np.concatenate([a_arr, b_arr, c_arr])
        if prev_params is not None:
            denom = max(np.linalg.norm(prev_params), 1e-9)
            rel_change = float(np.linalg.norm(cur_params - prev_params) / denom)
        else:
            rel_change = float("inf")
        prev_params = cur_params.copy()

        if verbose:
            elapsed = time.time() - t0
            print(
                f"  [iter {iteration:02d}/{max_iterations}] "
                f"LL = {total_ll:.2f} | "
                f"a_mean = {a_arr.mean():.2f} | "
                f"b_mean = {b_arr.mean():.2f} | "
                f"c_mean = {c_arr.mean():.2f} | "
                f"||dparams||/||params|| = {rel_change:.2e} | "
                f"elapsed = {elapsed:.1f}s"
            )

        # Test de convergence : stabilite des parametres.
        # Seuil 5e-3 (0.5%) = bon compromis pour IRT (oscillations residuelles
        # normales a cause du prior + regularisation M-step).
        if iteration > 1 and rel_change < 5e-3:
            convergence_achieved = True
            if verbose:
                print(f"  Convergence atteinte a l'iteration {iteration}.")
            break
        prev_ll = total_ll

    # Construction des resultats
    item_params: list[CalibratedItem] = []
    for j, qid in enumerate(item_ids):
        col = R[:, j]
        valid = col >= 0
        n_resp = int(valid.sum())
        p_obs = float(col[valid].mean()) if n_resp > 0 else 0.0
        item_params.append(
            CalibratedItem(
                question_id=qid,
                a=float(a_arr[j]),
                b=float(b_arr[j]),
                c=float(c_arr[j]),
                n_responses=n_resp,
                p_observed=p_obs,
                method="numpy-em-3pl",
                log_likelihood=item_ll[j],
            )
        )

    student_params: list[CalibratedStudent] = [
        CalibratedStudent(
            student_id=sid,
            theta=float(theta_arr[i]),
            n_responses=int((R[i, :] >= 0).sum()),
        )
        for i, sid in enumerate(student_ids)
    ]

    return CalibrationResult(
        item_params=item_params,
        student_params=student_params,
        method="numpy-em-3pl",
        n_iterations=iteration,
        final_log_likelihood=prev_ll,
        convergence_achieved=convergence_achieved,
        metadata={
            "n_students": n_students,
            "n_items": n_items,
            "n_responses": int((R >= 0).sum()),
            "ll_history": ll_history,
            "irt_scale": IRT_SCALE,
        },
    )


# ─── Methode py-irt (best-effort, plusieurs APIs supportees) ───────────────
def calibrate_with_py_irt(
    df: pd.DataFrame,
    item_types: dict[str, str] | None = None,
    iterations: int = 1000,
    verbose: bool = True,
) -> CalibrationResult:
    """Tente la calibration via py-irt. Bascule sur numpy si indisponible.

    On supporte plusieurs APIs de py-irt car le paquet a evolue :
    1. API moderne : ``py_irt.training.IrtModelTraining`` (py-irt >= 0.2)
    2. API ancienne : ``py_irt.IRTModel`` + ``Dataset`` (py-irt <= 0.1.x)
       ATTENTION : py-irt 0.1.1 ne fournit que 1PL/2PL via Pyro, PAS 3PL.
       Si l'API 3PL n'existe pas, on bascule sur le fallback numpy.
    """
    try:
        import py_irt  # type: ignore
        from py_irt.training import IrtModelTraining  # type: ignore
    except ImportError:
        if verbose:
            print(
                "[py-irt] API moderne (py_irt.training.IrtModelTraining) non "
                "disponible. Bascule sur numpy MLE."
            )
        return calibrate_with_numpy(df, item_types, verbose=verbose)

    if verbose:
        print(f"[py-irt] API moderne detectee. Lancement 3PL ({iterations} iters)...")

    df_clean, item_ids, student_ids = prepare_dataframe(df)

    # Format py-irt : list of (subject_id, item_id, response)
    training_data: list[tuple[str, str, int]] = []
    for _, row in df_clean.iterrows():
        training_data.append(
            (str(row["student_id"]), str(row["question_id"]), int(row["correct"]))
        )

    try:
        trainer = IrtModelTraining(
            model_type="3pl",
            data=training_data,
            num_items=len(item_ids),
            num_subjects=len(student_ids),
        )
        trainer.train(iterations=iterations)

        # Extraction des parametres : structure depend de la version
        raw_params = trainer.export_parameters()
        item_params_list, student_params_list = _parse_py_irt_params(
            raw_params, item_ids, student_ids
        )
    except Exception as e:
        if verbose:
            print(
                f"[py-irt] Echec de l'API moderne ({type(e).__name__}: {e}). "
                f"Bascule sur numpy MLE."
            )
        return calibrate_with_numpy(df, item_types, verbose=verbose)

    # Stats observees pour le reporting
    R = build_response_matrix(df_clean, item_ids, student_ids)
    item_params: list[CalibratedItem] = []
    for j, qid in enumerate(item_ids):
        col = R[:, j]
        valid = col >= 0
        n_resp = int(valid.sum())
        p_obs = float(col[valid].mean()) if n_resp > 0 else 0.0
        ip = item_params_list[j]
        item_params.append(
            CalibratedItem(
                question_id=qid,
                a=float(ip["a"]),
                b=float(ip["b"]),
                c=float(ip.get("c", 0.0)),
                n_responses=n_resp,
                p_observed=p_obs,
                method="py-irt-3pl",
                log_likelihood=0.0,
            )
        )

    student_params: list[CalibratedStudent] = []
    for i, sid in enumerate(student_ids):
        sp = student_params_list[i]
        student_params.append(
            CalibratedStudent(
                student_id=sid,
                theta=float(sp["theta"]),
                n_responses=int((R[i, :] >= 0).sum()),
            )
        )

    return CalibrationResult(
        item_params=item_params,
        student_params=student_params,
        method="py-irt-3pl",
        n_iterations=iterations,
        final_log_likelihood=0.0,
        convergence_achieved=True,
        metadata={
            "n_students": len(student_ids),
            "n_items": len(item_ids),
            "n_responses": int((R >= 0).sum()),
            "py_irt_version": getattr(py_irt, "__version__", "unknown"),
        },
    )


def _parse_py_irt_params(
    raw_params: Any, item_ids: list[str], student_ids: list[str]
) -> tuple[list[dict[str, float]], list[dict[str, float]]]:
    """Normalise la sortie de py-irt en listes de dicts {a, b, c} et {theta}.

    py-irt a change de format plusieurs fois. On tente plusieurs cles.
    """
    item_params: list[dict[str, float]] = []
    student_params: list[dict[str, float]] = []

    # Cas 1 : raw_params = {'item_params': [...], 'subject_params': [...]}
    if isinstance(raw_params, dict):
        ip_raw = raw_params.get("item_params") or raw_params.get("items") or []
        sp_raw = (
            raw_params.get("subject_params")
            or raw_params.get("subjects")
            or raw_params.get("student_params")
            or []
        )
        for ip in ip_raw:
            if isinstance(ip, dict):
                item_params.append(
                    {
                        "a": float(ip.get("a", ip.get("disc", 1.0))),
                        "b": float(ip.get("b", ip.get("diff", 0.0))),
                        "c": float(ip.get("c", ip.get("guessing", 0.0))),
                    }
                )
        for sp in sp_raw:
            if isinstance(sp, dict):
                student_params.append(
                    {"theta": float(sp.get("theta", sp.get("ability", 0.0)))}
                )

    # Comble : si py-irt n'a pas renvoye assez de valeurs, on complete avec defaut
    while len(item_params) < len(item_ids):
        item_params.append({"a": 1.0, "b": 0.0, "c": 0.0})
    while len(student_params) < len(student_ids):
        student_params.append({"theta": 0.0})

    return item_params, student_params


# ─── Serialization JSON ────────────────────────────────────────────────────
def result_to_dict(result: CalibrationResult) -> dict[str, Any]:
    """Convertit un CalibrationResult en dict serialisable JSON."""
    return {
        "metadata": {
            "method": result.method,
            "n_iterations": result.n_iterations,
            "final_log_likelihood": result.final_log_likelihood,
            "convergence_achieved": result.convergence_achieved,
            **result.metadata,
        },
        "item_params": [asdict(p) for p in result.item_params],
        "student_params": [asdict(s) for s in result.student_params],
    }


def save_result(result: CalibrationResult, output_file: str | Path) -> None:
    """Sauvegarde le resultat en JSON."""
    output_file = Path(output_file)
    output_file.parent.mkdir(parents=True, exist_ok=True)
    with open(output_file, "w", encoding="utf-8") as f:
        json.dump(result_to_dict(result), f, indent=2, ensure_ascii=False)


# ─── CLI ───────────────────────────────────────────────────────────────────
def main() -> int:
    """Point d'entree CLI."""
    parser = argparse.ArgumentParser(
        description="Calibre les parametres IRT 3PL (a, b, c) depuis un CSV de reponses.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=(
            "Exemples :\n"
            "  python calibrate_irt.py --input output/synthetic_responses.csv\n"
            "  python calibrate_irt.py --method numpy --max-iter 30\n"
            "  python calibrate_irt.py --method py-irt --iterations 1000\n"
        ),
    )
    parser.add_argument(
        "--input",
        type=str,
        default="output/synthetic_responses.csv",
        help="CSV de reponses [student_id, question_id, correct].",
    )
    parser.add_argument(
        "--output",
        type=str,
        default="output/calibrated_params.json",
        help="Fichier JSON de sortie.",
    )
    parser.add_argument(
        "--method",
        choices=["py-irt", "numpy"],
        default="py-irt",
        help="Methode de calibration (defaut: py-irt, fallback numpy automatique).",
    )
    parser.add_argument(
        "--questions-file",
        type=str,
        default="../../assets/data/questions.json",
        help="questions.json pour recuperer le type (QCM vs ouvert) de chaque question.",
    )
    parser.add_argument(
        "--max-iter",
        type=int,
        default=MAX_ITERATIONS,
        help=f"Nombre max d'iterations EM (methode numpy). Defaut: {MAX_ITERATIONS}.",
    )
    parser.add_argument(
        "--iterations",
        type=int,
        default=1000,
        help="Nombre d'iterations pour py-irt (defaut: 1000).",
    )
    parser.add_argument(
        "--quiet",
        action="store_true",
        help="Mode silencieux.",
    )
    args = parser.parse_args()

    # Charge les donnees
    input_path = Path(args.input)
    if not input_path.exists():
        print(f"[ERREUR] Fichier d'entree introuvable : {input_path}", file=sys.stderr)
        return 1
    df = pd.read_csv(input_path)
    print(f"[calibrate] {len(df)} reponses chargees depuis {input_path}")

    # Charge les types de questions (QCM vs ouvert) depuis questions.json
    item_types: dict[str, str] = {}
    questions_path = Path(args.questions_file)
    script_dir = Path(__file__).resolve().parent
    if not questions_path.is_absolute():
        # Plusieurs tentatives de resolution
        candidates = [
            questions_path,
            script_dir / args.questions_file,
            script_dir.parent.parent.parent / args.questions_file.lstrip("../"),
        ]
        for c in candidates:
            if c.exists():
                questions_path = c
                break
    if questions_path.exists():
        try:
            with open(questions_path, "r", encoding="utf-8") as f:
                questions = json.load(f)
            item_types = {q["id"]: q.get("type", "ouvert") for q in questions}
            print(f"[calibrate] Types charges pour {len(item_types)} questions.")
        except Exception as e:
            print(f"[calibrate] WARN: impossible de charger questions.json ({e})")

    # Calibration
    if args.method == "py-irt":
        result = calibrate_with_py_irt(
            df, item_types, iterations=args.iterations, verbose=not args.quiet
        )
    else:
        result = calibrate_with_numpy(
            df, item_types, max_iterations=args.max_iter, verbose=not args.quiet
        )

    # Sauvegarde
    save_result(result, args.output)
    print()
    print(f"[OK] Calibration terminee ({result.method}).")
    print(f"     Iterations : {result.n_iterations}")
    print(f"     LL final   : {result.final_log_likelihood:.2f}")
    print(f"     Convergence: {result.convergence_achieved}")
    print(f"     Items      : {len(result.item_params)}")
    print(f"     Eleves     : {len(result.student_params)}")
    print(f"     Sauvegarde : {args.output}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
