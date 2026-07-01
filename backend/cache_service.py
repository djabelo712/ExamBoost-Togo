"""cache_service.py — Cache Redis avec fallback memoire transparent.

Objectifs :
    - Accelerer les lectures frequentes (banque de questions, params IRT,
      statistiques user) sans impeux de modification des routers.
    - Supporter un mode degrade sans Redis (dev locale, tests) grace a
      un cache memoire processus (TTL respecte).
    - Exposer des helpers metier : ``get_cached_questions``,
      ``set_cached_questions``, ``get_cached_user_bkt``, etc.

Contrats :
    - Toutes les methodes sont async (compatibles FastAPI / asyncio).
    - Les valeurs JSON-serialisables uniquement. Les types non
      serialisables sont convertis via ``default=str`` (best-effort).
    - TTL en secondes. Defaut 1h pour les questions, 5 min pour le BKT.
"""
from __future__ import annotations

import json
import logging
import time
from typing import Any, Dict, Optional, Tuple

from redis_client import get_redis

logger = logging.getLogger(__name__)


class CacheService:
    """Cache TTL avec Redis + fallback memoire."""

    # Cache memoire processus : cle -> (valeur, expiry_timestamp)
    _memory_cache: Dict[str, Tuple[Any, float]] = {}

    # ------------------------------------------------------------------
    # Operations de base
    # ------------------------------------------------------------------
    @classmethod
    async def get(cls, key: str) -> Optional[Any]:
        """Retourne la valeur cachee ou ``None`` si absente/expiree."""
        # 1) Tentative Redis
        redis = get_redis()
        if redis is not None:
            try:
                raw = redis.get(key)
                if raw is not None:
                    return json.loads(raw)
            except Exception as exc:  # noqa: BLE001
                logger.debug("Redis get failed pour %s : %s", key, exc)

        # 2) Fallback memoire
        entry = cls._memory_cache.get(key)
        if entry is None:
            return None
        value, expiry = entry
        if time.time() >= expiry:
            # Entree expiree : nettoyage
            cls._memory_cache.pop(key, None)
            return None
        return value

    @classmethod
    async def set(cls, key: str, value: Any, ttl_seconds: int = 3600) -> None:
        """Stocke ``value`` sous ``key`` avec un TTL (en secondes)."""
        # 1) Tentative Redis
        redis = get_redis()
        if redis is not None:
            try:
                redis.setex(key, ttl_seconds, json.dumps(value, default=str))
                return
            except Exception as exc:  # noqa: BLE001
                logger.debug("Redis set failed pour %s : %s", key, exc)

        # 2) Fallback memoire
        cls._memory_cache[key] = (value, time.time() + ttl_seconds)

    @classmethod
    async def invalidate(cls, key: str) -> None:
        """Invalide une cle precise."""
        redis = get_redis()
        if redis is not None:
            try:
                redis.delete(key)
            except Exception as exc:  # noqa: BLE001
                logger.debug("Redis delete failed pour %s : %s", key, exc)
        cls._memory_cache.pop(key, None)

    @classmethod
    async def invalidate_pattern(cls, pattern: str) -> int:
        """Invalide toutes les cles matchant un pattern (ex: ``questions:*``).

        Retourne le nombre de cles supprimees (best-effort).
        """
        deleted = 0

        # 1) Redis : SCAN + DELETE (evite KEYS qui bloque le serveur)
        redis = get_redis()
        if redis is not None:
            try:
                # scan_iter renvoie des cles correspondant au pattern glob
                for key in redis.scan_iter(match=pattern, count=200):
                    redis.delete(key)
                    deleted += 1
            except Exception as exc:  # noqa: BLE001
                logger.debug(
                    "Redis invalidate_pattern failed pour %s : %s", pattern, exc
                )

        # 2) Memoire : on convertit le glob en prefixe (suffisant pour nos
        #    cles metier qui suivent le format "ns:arg1:arg2:...")
        prefix = pattern.rstrip("*")
        keys_to_delete = [k for k in cls._memory_cache if k.startswith(prefix)]
        for k in keys_to_delete:
            cls._memory_cache.pop(k, None)
            deleted += 1

        return deleted

    @classmethod
    def clear_memory_cache(cls) -> None:
        """Vide le cache memoire (tests uniquement)."""
        cls._memory_cache.clear()

    @classmethod
    def memory_cache_size(cls) -> int:
        """Taille du cache memoire (debug/tests)."""
        return len(cls._memory_cache)


# ----------------------------------------------------------------------
# Helpers metier : encodent les conventions de cles pour les domaines
# ExamBoost (questions, BKT, stats user).
# Convention : "<namespace>:<arg1>:<arg2>:..." avec TTL adapte au domaine.
# ----------------------------------------------------------------------

# TTL par domaine (en secondes)
TTL_QUESTIONS = 3600          # 1h : banque de questions (peu de changements)
TTL_IRT_PARAMS = 86400        # 24h : params IRT calibres (tres stables)
TTL_USER_BKT = 300            # 5 min : BKT evolue a chaque session
TTL_USER_STATS = 600          # 10 min : stats personelles
TTL_TUTOR_FOLLOWUPS = 86400   # 24h : suggestions de follow-ups (statiques)


async def get_cached_questions(
    matiere: str, examen: str, limit: int = 20
) -> Optional[Any]:
    """Recupere une page de questions cachee."""
    key = f"questions:{matiere}:{examen}:{limit}"
    return await CacheService.get(key)


async def set_cached_questions(
    matiere: str, examen: str, limit: int, questions: Any, ttl: int = TTL_QUESTIONS
) -> None:
    """Stocke une page de questions."""
    key = f"questions:{matiere}:{examen}:{limit}"
    await CacheService.set(key, questions, ttl)


async def invalidate_questions_cache() -> int:
    """Invalide tout le cache des questions (ex: apres seed ou edition)."""
    return await CacheService.invalidate_pattern("questions:*")


async def get_cached_irt_params(question_id: str) -> Optional[Any]:
    """Recupere les parametres IRT (a, b, c) d'une question."""
    key = f"irt:{question_id}"
    return await CacheService.get(key)


async def set_cached_irt_params(
    question_id: str, params: Any, ttl: int = TTL_IRT_PARAMS
) -> None:
    """Stocke les parametres IRT d'une question."""
    key = f"irt:{question_id}"
    await CacheService.set(key, params, ttl)


async def get_cached_user_bkt(user_id: str) -> Optional[Any]:
    """Recupere le vecteur BKT d'un utilisateur."""
    key = f"user_bkt:{user_id}"
    return await CacheService.get(key)


async def set_cached_user_bkt(
    user_id: str, bkt_data: Any, ttl: int = TTL_USER_BKT
) -> None:
    """Stocke le vecteur BKT d'un utilisateur (court TTL : evolue vite)."""
    key = f"user_bkt:{user_id}"
    await CacheService.set(key, bkt_data, ttl)


async def get_cached_user_stats(user_id: str) -> Optional[Any]:
    """Recupere les statistiques globales d'un utilisateur."""
    key = f"user_stats:{user_id}"
    return await CacheService.get(key)


async def set_cached_user_stats(
    user_id: str, stats: Any, ttl: int = TTL_USER_STATS
) -> None:
    """Stocke les statistiques globales d'un utilisateur."""
    key = f"user_stats:{user_id}"
    await CacheService.set(key, stats, ttl)


async def invalidate_user_cache(user_id: str) -> int:
    """Invalide tout le cache lie a un utilisateur (apres une session).

    A appeler dans le router ``/sessions`` apres chaque POST pour
    garantir que les prochaines lectures refletent la nouvelle mastered.
    """
    total = 0
    total += await CacheService.invalidate_pattern(f"user_bkt:{user_id}*")
    total += await CacheService.invalidate_pattern(f"user_stats:{user_id}*")
    return total
