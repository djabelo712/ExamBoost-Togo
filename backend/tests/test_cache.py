"""tests/test_cache.py — Tests du CacheService (Redis + fallback memoire).

Couverture :
    - set + get avec fallback memoire (Redis absent en CI/dev locale)
    - TTL expiration (cache memoire nettoie apres expiry)
    - Invalidation d'une cle precise
    - Invalidation par pattern (glob)
    - Helpers metier (questions, BKT user)
    - Robustesse : valeurs None, structures complexes (list/dict)
"""
from __future__ import annotations

import asyncio
import time
from typing import Any

import pytest

# On s'assure que le backend root est dans sys.path (conftest le fait aussi)
from cache_service import (
    CacheService,
    get_cached_questions,
    set_cached_questions,
    get_cached_user_bkt,
    set_cached_user_bkt,
    invalidate_user_cache,
    invalidate_questions_cache,
)
import redis_client


@pytest.fixture(autouse=True)
def _isolate_memory_cache():
    """Vide le cache memoire avant ET apres chaque test."""
    CacheService.clear_memory_cache()
    # Force Redis a None pour tester le fallback memoire de facon deterministe
    redis_client.reset_redis_client()
    yield
    CacheService.clear_memory_cache()
    redis_client.reset_redis_client()


def _run(coro: Any) -> Any:
    """Execute une coroutine de facon synchrone (compat pytest sync).

    On creer une nouvelle boucle a chaque appel pour eviter les conflits
    d'etat entre tests (les coroutines du CacheService ne font pas d'I/O
    reelle en mode fallback memoire, donc le cout est negligeable).
    """
    loop = asyncio.new_event_loop()
    try:
        return loop.run_until_complete(coro)
    finally:
        loop.close()


# ─── Tests de base : set / get / TTL ──────────────────────────────────


def test_set_then_get_returns_value():
    """Un set suivi d'un get renvoie la valeur stockee."""
    _run(CacheService.set("k1", {"a": 1, "b": [2, 3]}, ttl_seconds=60))
    value = _run(CacheService.get("k1"))
    assert value == {"a": 1, "b": [2, 3]}


def test_get_missing_key_returns_none():
    """Une cle absente renvoie None."""
    assert _run(CacheService.get("does-not-exist")) is None


def test_set_with_none_value_is_distinguishable():
    """set(None) puis get() — None est une valeur valide mais absente est None aussi.

    On verifie juste qu'on n'a pas d'exception.
    """
    _run(CacheService.set("knull", None, ttl_seconds=60))
    # En memoire, None est stocke tel quel ; en Redis, json.dumps(None) = "null"
    # On accepte les deux comportements : le contrat est juste "pas d'exception".
    result = _run(CacheService.get("knull"))
    assert result is None


def test_ttl_expiration_memory_cache():
    """Apres TTL ecoule, la cle memoire est consideree expiree."""
    _run(CacheService.set("short", "ephemere", ttl_seconds=1))
    assert _run(CacheService.get("short")) == "ephemere"
    # On simule l'ecoulement du temps en avancant l'expiry manuellement
    entry = CacheService._memory_cache["short"]
    # Deplace l'expiry dans le passe
    CacheService._memory_cache["short"] = (entry[0], time.time() - 1)
    assert _run(CacheService.get("short")) is None
    # Et la cle expiree est nettoyee du cache memoire
    assert "short" not in CacheService._memory_cache


def test_set_overwrites_existing_value():
    """Un second set sur la meme cle ecrase la precedente."""
    _run(CacheService.set("k", "v1", ttl_seconds=60))
    _run(CacheService.set("k", "v2", ttl_seconds=60))
    assert _run(CacheService.get("k")) == "v2"


# ─── Tests d'invalidation ─────────────────────────────────────────────


def test_invalidate_single_key():
    """invalidate() supprime une cle precise."""
    _run(CacheService.set("a", 1, ttl_seconds=60))
    _run(CacheService.set("b", 2, ttl_seconds=60))
    _run(CacheService.invalidate("a"))
    assert _run(CacheService.get("a")) is None
    assert _run(CacheService.get("b")) == 2


def test_invalidate_missing_key_is_noop():
    """invalidate() sur une cle absente ne leve pas."""
    _run(CacheService.invalidate("never-set"))


def test_invalidate_pattern_memory():
    """invalidate_pattern supprime toutes les cles matchant un prefixe."""
    _run(CacheService.set("questions:maths:BEPC:20", [1, 2], ttl_seconds=60))
    _run(CacheService.set("questions:svt:BEPC:10", [3], ttl_seconds=60))
    _run(CacheService.set("user_bkt:u1", {"m": 0.5}, ttl_seconds=60))

    deleted = _run(CacheService.invalidate_pattern("questions:*"))
    assert deleted == 2
    assert _run(CacheService.get("questions:maths:BEPC:20")) is None
    assert _run(CacheService.get("questions:svt:BEPC:10")) is None
    # user_bkt reste intact
    assert _run(CacheService.get("user_bkt:u1")) == {"m": 0.5}


# ─── Tests des helpers metier ─────────────────────────────────────────


def test_cached_questions_helper_roundtrip():
    """Les helpers questions respectent la convention de cle."""
    _run(set_cached_questions("maths", "BEPC", 20, [{"id": "q1"}, {"id": "q2"}]))
    result = _run(get_cached_questions("maths", "BEPC", 20))
    assert result == [{"id": "q1"}, {"id": "q2"}]
    # La cle suit bien le format attendu
    assert "questions:maths:BEPC:20" in CacheService._memory_cache


def test_cached_user_bkt_helper_roundtrip():
    """Les helpers BKT utilisent un TTL court et la bonne cle."""
    _run(set_cached_user_bkt("user-xyz", {"maths": 0.42, "svt": 0.61}))
    result = _run(get_cached_user_bkt("user-xyz"))
    assert result == {"maths": 0.42, "svt": 0.61}


def test_invalidate_user_cache_clears_bkt_and_stats():
    """invalidate_user_cache supprime bkt + stats (mais pas questions)."""
    _run(set_cached_user_bkt("u1", {"m": 0.1}))
    _run(CacheService.set("user_stats:u1", {"sessions": 5}, ttl_seconds=60))
    _run(CacheService.set("questions:m:BEPC:10", [], ttl_seconds=60))

    deleted = _run(invalidate_user_cache("u1"))
    assert deleted >= 2
    assert _run(get_cached_user_bkt("u1")) is None
    assert _run(CacheService.get("user_stats:u1")) is None
    # Le cache questions reste intact
    assert _run(CacheService.get("questions:m:BEPC:10")) == []


def test_invalidate_questions_cache_clears_all_questions():
    """invalidate_questions_cache supprime toutes les cles questions:*."""
    _run(set_cached_questions("maths", "BEPC", 20, []))
    _run(set_cached_questions("svt", "BAC", 10, []))
    deleted = _run(invalidate_questions_cache())
    assert deleted == 2
    assert _run(get_cached_questions("maths", "BEPC", 20)) is None
    assert _run(get_cached_questions("svt", "BAC", 10)) is None


# ─── Tests de robustesse ──────────────────────────────────────────────


def test_set_with_complex_nested_structure():
    """Les structures arbitrairement imbriquees sont serialisables."""
    payload = {
        "questions": [
            {"id": "q1", "meta": {"tags": ["algebre", "geometrie"]}},
            {"id": "q2", "irt": {"a": 1.2, "b": -0.5, "c": 0.15}},
        ],
        "total": 2,
    }
    _run(CacheService.set("complex", payload, ttl_seconds=60))
    assert _run(CacheService.get("complex")) == payload


def test_memory_cache_size_tracks_entries():
    """memory_cache_size reflete le nombre d'entrees vivantes."""
    assert CacheService.memory_cache_size() == 0
    _run(CacheService.set("k1", 1, ttl_seconds=60))
    _run(CacheService.set("k2", 2, ttl_seconds=60))
    assert CacheService.memory_cache_size() == 2
    _run(CacheService.invalidate("k1"))
    assert CacheService.memory_cache_size() == 1


def test_redis_absent_falls_back_to_memory_silently():
    """Sans Redis configure, get/set utilisent le cache memoire sans erreur."""
    # redis_client retourne None (REDIS_URL non defini dans l'env de test)
    assert redis_client.get_redis() is None
    _run(CacheService.set("solo", "memory-only", ttl_seconds=60))
    assert _run(CacheService.get("solo")) == "memory-only"
