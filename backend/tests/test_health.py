"""tests/test_health.py — Healthcheck & meta endpoints.

Couverture :
    - GET /                : racine de l'API (renvoie liens docs)
    - GET /health          : healthcheck simple (Railway/Render)
    - GET /sync/health     : healthcheck du module sync (tables idempotence)
    - GET /tutor/health    : healthcheck du tuteur IA (Anthropic + rate limit)
    - 404 sur route inexistante
    - /openapi.json accessible (Swagger)
"""

from __future__ import annotations


# ─── GET / ────────────────────────────────────────────────────────────
def test_root_returns_api_metadata(client):
    """La racine renvoie le nom de l'API et les liens vers la doc."""
    r = client.get("/")
    assert r.status_code == 200
    data = r.json()
    assert data["name"] == "ExamBoost Togo API"
    assert data["docs"] == "/docs"
    assert data["redoc"] == "/redoc"
    assert data["openapi"] == "/openapi.json"


# ─── GET /health ──────────────────────────────────────────────────────
def test_health_returns_ok(client):
    """Le healthcheck simple renvoie status=ok."""
    r = client.get("/health")
    assert r.status_code == 200
    data = r.json()
    assert data["status"] == "ok"
    assert data["service"] == "examboost-backend"
    assert "version" in data


def test_health_no_auth_required(client):
    """Le healthcheck est publique (pas de JWT requis)."""
    # On n'envoie pas d'Authorization header : doit reussir.
    r = client.get("/health")
    assert r.status_code == 200


# ─── GET /openapi.json ────────────────────────────────────────────────
def test_openapi_schema_accessible(client):
    """Le schema OpenAPI est servi sur /openapi.json."""
    r = client.get("/openapi.json")
    assert r.status_code == 200
    data = r.json()
    assert data["info"]["title"] == "ExamBoost Togo API"
    assert "paths" in data
    # Quelques paths cles doivent etre declares
    assert "/auth/register" in data["paths"]
    assert "/auth/login" in data["paths"]
    assert "/questions" in data["paths"]
    assert "/sessions" in data["paths"]
    assert "/predict-score/{user_id}" in data["paths"]
    assert "/sync/action" in data["paths"]


def test_swagger_ui_accessible(client):
    """La Swagger UI est servie sur /docs."""
    r = client.get("/docs")
    assert r.status_code == 200
    assert "text/html" in r.headers.get("content-type", "")


def test_redoc_accessible(client):
    """ReDoc est servie sur /redoc."""
    r = client.get("/redoc")
    assert r.status_code == 200
    assert "text/html" in r.headers.get("content-type", "")


# ─── GET /sync/health ─────────────────────────────────────────────────
def test_sync_health_returns_ok(client):
    """Le healthcheck du module sync verifie la table d'idempotence."""
    # Une premiere requete declenche la creation lazy de la table.
    r = client.get("/sync/health")
    assert r.status_code == 200
    data = r.json()
    assert data["status"] == "ok"
    assert data["tables"] == "ready"


def test_sync_health_is_public(client):
    """Le healthcheck /sync/health est public (pas d'auth requise)."""
    r = client.get("/sync/health")
    assert r.status_code == 200


# ─── GET /tutor/health ────────────────────────────────────────────────
def test_tutor_health_returns_status(client):
    """Le healthcheck du tuteur IA renvoie l'etat de la config Anthropic."""
    r = client.get("/tutor/health")
    assert r.status_code == 200
    data = r.json()
    assert data["status"] == "ok"
    assert "anthropic_configured" in data
    assert isinstance(data["anthropic_configured"], bool)
    assert "model" in data
    assert data["rate_limit_per_hour"] == 30


# ─── 404 ──────────────────────────────────────────────────────────────
def test_unknown_route_returns_404(client):
    """Une route inexistante renvoie 404."""
    r = client.get("/this-route-does-not-exist")
    assert r.status_code == 404
