"""services/bkt_service.py — Bayesian Knowledge Tracing.

Miroir exact de la methode ``updateBkt`` de ``lib/models/user.dart``.

Etant donne une probabilite a priori P(L) que l'eleve maitrise la
competence, on l'actualise apres observation d'une reponse (correcte
ou non) :

    Si correct :
        P(L|obs=1) = P(L) * (1 - P(S)) / (P(L) * (1 - P(S)) + (1 - P(L)) * P(G))

    Si incorrect :
        P(L|obs=0) = P(L) * P(S)     / (P(L) * P(S)     + (1 - P(L)) * (1 - P(G)))

    Puis transition d'apprentissage :
        P(L_next) = P(L|obs) + (1 - P(L|obs)) * P(T)

Parametres :
    P(T) = p_learn  : proba d'apprendre a chaque occasion
    P(S) = p_slip   : proba de se tromper malgre la maitrise
    P(G) = p_guess  : proba de deviner juste sans maitrise
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Optional


# Valeurs par defaut (identiques au code Flutter)
DEFAULT_P_LEARN = 0.20
DEFAULT_P_SLIP = 0.10
DEFAULT_P_GUESS = 0.20
DEFAULT_P_L_INIT = 0.10
MASTERY_THRESHOLD = 0.85


@dataclass
class BktResult:
    """Resultat d'une mise a jour BKT."""

    pL_before: float
    pL_after: float
    p_obs: float  # probabilite a priori de l'observation
    mastered: bool


def update_bkt(
    pL: float,
    correct: bool,
    p_learn: float = DEFAULT_P_LEARN,
    p_slip: float = DEFAULT_P_SLIP,
    p_guess: float = DEFAULT_P_GUESS,
) -> BktResult:
    """Met a jour P(L) apres observation d'une reponse.

    Parameters
    ----------
    pL:
        Probabilite a priori de maitrise (avant l'observation).
    correct:
        True si l'eleve a repondu correctement, False sinon.
    p_learn, p_slip, p_guess:
        Parametres BKT (P(T), P(S), P(G)).

    Returns
    -------
    BktResult
        Contient la nouvelle valeur de P(L) et metadonnees.
    """
    # Bornage securise
    pL = float(max(0.0, min(1.0, pL)))
    p_slip = float(max(0.0, min(1.0, p_slip)))
    p_guess = float(max(0.0, min(1.0, p_guess)))
    p_learn = float(max(0.0, min(1.0, p_learn)))

    if correct:
        # P(correct) = P(L)*(1-P(S)) + (1-P(L))*P(G)
        p_correct = pL * (1.0 - p_slip) + (1.0 - pL) * p_guess
        p_correct = max(p_correct, 1e-9)
        pL_given_obs = (pL * (1.0 - p_slip)) / p_correct
        p_obs = p_correct
    else:
        # P(incorrect) = P(L)*P(S) + (1-P(L))*(1-P(G))
        p_incorrect = pL * p_slip + (1.0 - pL) * (1.0 - p_guess)
        p_incorrect = max(p_incorrect, 1e-9)
        pL_given_obs = (pL * p_slip) / p_incorrect
        p_obs = p_incorrect

    # Transition d'apprentissage
    pL_next = pL_given_obs + (1.0 - pL_given_obs) * p_learn
    pL_next = float(max(0.0, min(1.0, pL_next)))

    return BktResult(
        pL_before=pL,
        pL_after=pL_next,
        p_obs=float(p_obs),
        mastered=is_mastered(pL_next),
    )


def is_mastered(pL: float, threshold: float = MASTERY_THRESHOLD) -> bool:
    """Renvoie True si la probabilite de maitrise depasse le seuil."""
    return float(pL) >= float(threshold)


def init_pL() -> float:
    """Probabilite initiale P(L) par defaut (avant tout apprentissage)."""
    return DEFAULT_P_L_INIT
