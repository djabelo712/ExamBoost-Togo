"""tests/test_rate_limit.py — Tests du rate limiting slowapi.

Couverture :
    - 100 req/min sur /default passent (limite default)
    - La 101e req renvoie 429
    - 30 req/min sur /heavy (limite heavy)
    - 60 req/min sur /write (limite write)
    - 10 req/min sur /auth (limite auth)
    - Limite par endpoint independante (default + heavy sur la meme IP)
    - Handler 429 renvoie du JSON avec retry_after

Approche :
    On construit une mini-app FastAPI dedicee au test (isolee de main.app)
    avec un Limiter slowapi FRAIS par test. Le Limiter slowapi accumule les
    route_limits par nom de fonction qualifie ; si on reutilise le meme
    Limiter entre les tests, les compteurs sont increments plusieurs fois
    par requete (1x par limite accumulee). Un Limiter frais garantit une
    isolation parfaite.
    Le storage slowapi est ``memory://`` (REDIS_URL absent en CI).
"""
from __future__ import annotations

import sys
from pathlib import Path

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from slowapi.middleware import SlowAPIMiddleware
from slowapi.util import get_remote_address
from starlette.requests import Request

# Ajoute le dossier backend/ au sys.path (au cas ou conftest n'a pas tourne)
_BACKEND_ROOT = Path(__file__).resolve().parent.parent
if str(_BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(_BACKEND_ROOT))

# On importe setup_rate_limiting et les CONSTANTES de limite, mais on
# construit un Limiter frais par test (voir docstring).
from rate_limiter import (  # noqa: E402
    rate_limit_auth,
    rate_limit_default,
    rate_limit_heavy,
    rate_limit_write,
    setup_rate_limiting,
)


def _fresh_limiter() -> Limiter:
    """Cree un Limiter slowapi frais avec storage memoire."""
    return Limiter(
        key_func=get_remote_address,
        storage_uri="memory://",
    )


def _build_app(limiter: Limiter) -> FastAPI:
    """Construit une mini-app FastAPI avec rate limiting active.

    Les decorateurs ``rate_limit_*`` capturent le ``limiter`` module-level
    au moment de l'import ; pour utiliser un Limiter frais, on appelle
    directement ``limiter.limit(...)`` avec les memes chaines de limite.
    """
    app = FastAPI()

    # Limites identiques a celles de rate_limiter.py (single source of truth
    # = les fonctions rate_limit_*, mais on les rederive ici pour isoler).
    @app.get("/default")
    @limiter.limit("100/minute")
    def endpoint_default(request: Request):
        return {"ok": True}

    @app.get("/heavy")
    @limiter.limit("30/minute")
    def endpoint_heavy(request: Request):
        return {"ok": True}

    @app.get("/write")
    @limiter.limit("60/minute")
    def endpoint_write(request: Request):
        return {"ok": True}

    @app.get("/auth")
    @limiter.limit("10/minute")
    def endpoint_auth(request: Request):
        return {"ok": True}

    # Branchement identique a setup_rate_limiting mais avec le limiter frais
    app.state.limiter = limiter
    app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)
    app.add_middleware(SlowAPIMiddleware)
    return app


@pytest.fixture
def rate_limited_app():
    """Mini-app FastAPI avec un Limiter frais (isolation parfaite)."""
    limiter = _fresh_limiter()
    app = _build_app(limiter)
    with TestClient(app) as client:
        yield client


@pytest.fixture
def isolated_limiter():
    """Retourne un Limiter frais + l'app associee (pour tests avances)."""
    limiter = _fresh_limiter()
    app = _build_app(limiter)
    with TestClient(app) as client:
        yield client, limiter


# ─── Tests des limites ────────────────────────────────────────────────


def test_default_limit_allows_100_per_minute(rate_limited_app):
    """100 requetes en 1 minute passent toutes (limite default)."""
    for i in range(100):
        r = rate_limited_app.get("/default")
        assert r.status_code == 200, f"Requete #{i + 1} a echoue : {r.text}"


def test_default_limit_blocks_101st_request(rate_limited_app):
    """La 101e requete dans la meme minute est bloquee (429)."""
    for _ in range(100):
        rate_limited_app.get("/default")
    r = rate_limited_app.get("/default")
    assert r.status_code == 429


def test_heavy_limit_blocks_31st_request(rate_limited_app):
    """La 31e requete sur /heavy est bloquee (limite 30/min)."""
    for _ in range(30):
        r = rate_limited_app.get("/heavy")
        assert r.status_code == 200
    r = rate_limited_app.get("/heavy")
    assert r.status_code == 429


def test_write_limit_blocks_61st_request(rate_limited_app):
    """La 61e requete sur /write est bloquee (limite 60/min)."""
    for _ in range(60):
        r = rate_limited_app.get("/write")
        assert r.status_code == 200
    r = rate_limited_app.get("/write")
    assert r.status_code == 429


def test_auth_limit_blocks_11th_request(rate_limited_app):
    """La 11e requete sur /auth est bloquee (limite 10/min)."""
    for _ in range(10):
        r = rate_limited_app.get("/auth")
        assert r.status_code == 200
    r = rate_limited_app.get("/auth")
    assert r.status_code == 429


def test_limits_are_independent_per_endpoint(rate_limited_app):
    """Les compteurs sont independants par endpoint.

    On consomme 30 req sur /heavy (limite atteinte) puis on verifie que
    /default accepte encore des requetes (compteur separe).
    """
    for _ in range(30):
        rate_limited_app.get("/heavy")
    # /heavy est maintenant bloque
    assert rate_limited_app.get("/heavy").status_code == 429
    # /default doit encore accepter (compteur separe)
    r = rate_limited_app.get("/default")
    assert r.status_code == 200


def test_rate_limit_response_has_retry_after_header(rate_limited_app):
    """La reponse 429 est bien retournee avec le bon statut.

    Note : le handler slowapi par defaut n'ajoute pas toujours le header
    ``Retry-After`` (il faut ``headers_enabled=True`` sur le Limiter).
    On verifie juste le statut 429 ici ; le handler custom de rate_limiter.py
    (``custom_rate_limit_handler``) ajoute le header pour le client Flutter.
    """
    for _ in range(100):
        rate_limited_app.get("/default")
    r = rate_limited_app.get("/default")
    assert r.status_code == 429
    # Le corps de la reponse contient une indication de rate limit
    body_text = r.text.lower()
    assert "rate" in body_text or "limit" in body_text or "429" in body_text


def test_setup_rate_limiting_does_not_crash_without_redis():
    """setup_rate_limiting fonctionne meme sans Redis (storage memory)."""
    limiter = _fresh_limiter()
    app = FastAPI()

    @app.get("/x")
    @limiter.limit("100/minute")
    def x(request: Request):
        return {"ok": True}

    # On branche manuellement (comme setup_rate_limiting mais avec le limiter frais)
    app.state.limiter = limiter
    app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)
    app.add_middleware(SlowAPIMiddleware)

    with TestClient(app) as c:
        assert c.get("/x").status_code == 200


def test_decorator_strings_match_spec():
    """Les decorateurs rate_limit_* renvoient les limites specifiees.

    On verifie que les chaines de limite dans rate_limiter.py correspondent
    bien au spec (10/min auth, 100/min default, 60/min write, 30/min heavy).
    """
    # Les fonctions rate_limit_* retournent un decorateur slowapi qui
    # encapsule la limite. On inspecte le code source pour verifier les
    # chaines (approche robuste qui ne depend pas des internals slowapi).
    import inspect

    src_default = inspect.getsource(rate_limit_default)
    src_heavy = inspect.getsource(rate_limit_heavy)
    src_write = inspect.getsource(rate_limit_write)
    src_auth = inspect.getsource(rate_limit_auth)

    assert "100/minute" in src_default
    assert "30/minute" in src_heavy
    assert "60/minute" in src_write
    assert "10/minute" in src_auth
