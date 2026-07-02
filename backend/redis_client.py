"""redis_client.py — Singleton client Redis pour cache et rate limiting.

Lecture de la configuration :
    - ``settings.REDIS_URL`` si l'attribut a ete ajoute a ``config.Settings``
      (non present par defaut, a ajouter par l'agent de wiring).
    - Sinon, variable d'environnement ``REDIS_URL`` (dev .env / Railway).

Comportement :
    - Si Redis n'est pas configure OU indisponible, ``get_redis()`` renvoie
      ``None`` et les consommateurs (``cache_service``, ``rate_limiter``)
      doivent prevus un fallback memoire. Cela permet a l'app de demarrer
      meme sans Redis (cas typique en dev locale et en test).

Usage :
    from redis_client import get_redis
    r = get_redis()
    if r is not None:
        r.setex("key", 60, "value")
"""
from __future__ import annotations

import logging
import os
from typing import Optional

try:
    import redis  # type: ignore[import-not-found]
except ImportError:  # redis non installe en dev (prerequis optionnel)
    redis = None  # type: ignore[assignment]

from config import settings

logger = logging.getLogger(__name__)

# Client Redis global (singleton). ``None`` tant que Redis n'a pas ete
# initialise avec succes, ou s'il est absent/non configure.
_redis_client: "Optional[redis.Redis]" = None  # type: ignore[valid-type]
# Flag pour ne pas retenter une connexion echouee a chaque appel :
# on evite ainsi un log bruyant et un timeout a chaque get/set en cas
# de panne prolongee. ``reset_redis_client()`` permet de retester.
_redis_init_attempted: bool = False


def _resolve_redis_url() -> Optional[str]:
    """Resout l'URL Redis depuis ``settings`` puis l'environnement."""
    url = getattr(settings, "REDIS_URL", None)
    if not url:
        url = os.environ.get("REDIS_URL")
    if url:
        # Strip eventuels espaces + refus des valeurs sentinelles
        url = url.strip()
        if url.lower() in ("", "none", "null"):
            return None
    return url


def get_redis():  # type: ignore[no-untyped-def]
    """Retourne le client Redis, ou ``None`` si absent/indisponible.

    La connexion est tentee une seule fois (singleton paresseux). En cas
    d'echec, on log un warning et on renvoie ``None`` : le caller doit
    prevoir un fallback memoire. Utiliser ``reset_redis_client()`` pour
    forcer une nouvelle tentative (ex: apres redemarrage Redis en prod).
    """
    global _redis_client, _redis_init_attempted

    if _redis_client is not None:
        return _redis_client

    if _redis_init_attempted:
        # On a deja essaye et echoue : on ne recommence pas
        return None

    if redis is None:
        logger.info("Redis non installe (package redis absent) — fallback memoire")
        _redis_init_attempted = True
        return None

    url = _resolve_redis_url()
    if not url:
        logger.info("REDIS_URL non configure — fallback memoire")
        _redis_init_attempted = True
        return None

    try:
        client = redis.from_url(
            url,
            decode_responses=True,
            socket_connect_timeout=5,
            socket_timeout=5,
            retry_on_timeout=True,
            health_check_interval=30,
        )
        client.ping()  # test de connectivite
        _redis_client = client
        logger.info("Redis connecte avec succes")
    except Exception as exc:  # noqa: BLE001
        # On reste silencieux cote exception : Redis est optionnel
        logger.warning("Redis indisponible (%s) — fallback memoire", exc)

    _redis_init_attempted = True
    return _redis_client


def reset_redis_client() -> None:
    """Force une nouvelle tentative de connexion Redis.

    Utile dans les tests ou apres un redemarrage du service Redis en prod.
    """
    global _redis_client, _redis_init_attempted
    _redis_client = None
    _redis_init_attempted = False


def is_redis_available() -> bool:
    """Indique si Redis est actuellement utilisable (connecte)."""
    return get_redis() is not None
