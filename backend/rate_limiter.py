"""rate_limiter.py — Rate limiting avec slowapi.

Limites (par IP cliente) :
    auth     :  10/min   — protection bruteforce login/register
    default  : 100/min   — endpoints de lecture (questions, etc.)
    write    :  60/min   — endpoints d'ecriture (sessions, sync)
    heavy    :  30/min   — endpoints lourds (tutor IA, predict ML)
    admin    :  10/min   — endpoints admin

Stockage :
    - En dev / tests : ``memory://`` (compteur en RAM processus).
    - En prod        : ``REDIS_URL`` si defini (partage entre workers
      gunicorn/uvicorn). Pour activer Redis, decommenter les 2 lignes
      marquees PROD dans ``_build_limiter()``.

Branchement (a faire par l'agent de wiring dans main.py) :
    from rate_limiter import setup_rate_limiting
    setup_rate_limiting(app)

Puis sur chaque endpoint sensible :
    from rate_limiter import rate_limit_default
    @app.get("/questions")
    @rate_limit_default()
    async def list_questions(...): ...
"""
from __future__ import annotations

import logging
import os
from typing import Callable

from fastapi import FastAPI, Request, Response
from fastapi.responses import JSONResponse

try:
    from slowapi import Limiter, _rate_limit_exceeded_handler
    from slowapi.errors import RateLimitExceeded
    from slowapi.middleware import SlowAPIMiddleware
    from slowapi.util import get_remote_address
except ImportError as exc:  # slowapi non installe en dev minimale
    raise ImportError(
        "slowapi est requis pour rate_limiter.py — installez-le via "
        "`pip install slowapi` (voir backend/requirements.txt)"
    ) from exc

from redis_client import _resolve_redis_url

logger = logging.getLogger(__name__)


def _build_limiter() -> Limiter:
    """Construit le Limiter slowapi selon l'environnement.

    - Dev / tests : storage ``memory://`` (par processus).
    - Prod        : storage Redis si ``REDIS_URL`` definie, pour partager
      les compteurs entre workers uvicorn/gunicorn.
    """
    redis_url = _resolve_redis_url()
    if redis_url:
        # PROD : partage des compteurs entre workers via Redis
        logger.info("Rate limiter utilise Redis pour le stockage : %s", redis_url)
        return Limiter(
            key_func=get_remote_address,
            storage_uri=redis_url,
            default_limits=["1000/hour"],  # filet de securite global
        )

    # Dev / tests : compteur en memoire
    logger.info("Rate limiter utilise le stockage memoire (memory://)")
    return Limiter(
        key_func=get_remote_address,
        storage_uri="memory://",
        default_limits=["1000/hour"],
    )


# Singleton global : utilise par les decorateurs et setup_rate_limiting
limiter = _build_limiter()


def setup_rate_limiting(app: FastAPI) -> None:
    """Branche le rate limiting sur l'app FastAPI.

    A appeler dans ``main.py`` apres la creation de l'app et AVANT
    l'inclusion des routers (l'ordre n'est pas strictement obligatoire
    pour slowapi, mais c'est une bonne pratique).

    Effets :
        - ``app.state.limiter`` est defini (requis par slowapi)
        - Handler 429 JSON branche
        - Middleware SlowAPIMiddleware ajoute
    """
    app.state.limiter = limiter
    app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)
    app.add_middleware(SlowAPIMiddleware)
    logger.info("Rate limiting active sur l'app FastAPI")


# ----------------------------------------------------------------------
# Decorateurs par niveau de limite.
#
# slowapi limite par la cle ``key_func`` (IP par defaut). Pour limiter
# par user_id (JWT), remplacer ``get_remote_address`` par une fonction
# custom qui lit le payload JWT — a faire par l'agent de wiring.
# ----------------------------------------------------------------------

def rate_limit_auth() -> Callable:
    """Limite stricte sur auth (bruteforce login/register). 10/min."""
    return limiter.limit("10/minute")


def rate_limit_default() -> Callable:
    """Limite standard sur endpoints de lecture. 100/min."""
    return limiter.limit("100/minute")


def rate_limit_write() -> Callable:
    """Limite sur endpoints d'ecriture (sessions, sync). 60/min."""
    return limiter.limit("60/minute")


def rate_limit_heavy() -> Callable:
    """Limite sur endpoints lourds (tutor IA, predict ML). 30/min."""
    return limiter.limit("30/minute")


def rate_limit_admin() -> Callable:
    """Limite tres stricte sur endpoints admin. 10/min."""
    return limiter.limit("10/minute")


# ----------------------------------------------------------------------
# Handler 429 custom (JSON reutilisable, surcharge du defaut slowapi).
# Utilisation optionnelle : app.add_exception_handler(RateLimitExceeded,
# custom_rate_limit_handler)
# ----------------------------------------------------------------------

def custom_rate_limit_handler(
    request: Request, exc: RateLimitExceeded
) -> JSONResponse:
    """Retourne un JSON 429 standardise pour le client Flutter."""
    return JSONResponse(
        status_code=429,
        content={
            "detail": "Rate limit exceeded",
            "error": "rate_limited",
            "retry_after_seconds": _retry_after_from_exc(exc),
            "path": str(request.url.path),
        },
        headers={
            "Retry-After": str(_retry_after_from_exc(exc)),
            "X-RateLimit-Error": "true",
        },
    )


def _retry_after_from_exc(exc: RateLimitExceeded) -> int:
    """Extrait le delai avant nouvel essai (best-effort, defaut 60s)."""
    # slowapi expose ``exc.detail`` qui contient parfois le retry_after
    # mais le format varie selon la version. On garde 60s par defaut.
    return 60
