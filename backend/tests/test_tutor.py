"""tests/test_tutor.py — Tests du router /tutor (tuteur IA Claude).

Couverture :
    - POST /tutor/ask      : pose une question (mode fallback mock si pas de cle API)
    - GET  /tutor/health   : healthcheck Anthropic + rate limit
    - Rate limiting : 30 req/h par user (429 au-dela)
    - Auth requise (401 sans token)
    - Validation payload : question vide, trop longue, role invalide
    - Suggestions de follow-up (heuristique par mots-cles)
    - Contexte pedagogique (matiere/chapitre/niveau)
"""

from __future__ import annotations

import pytest

from routers import tutor as _tutor_router


# ─── Helpers ──────────────────────────────────────────────────────────
def _register_user(client, email="tutor@test.tg"):
    r = client.post(
        "/auth/register",
        json={
            "email": email,
            "password": "password123",
            "nom": "Tutor",
            "prenom": "Test",
            "niveau_scolaire": "Terminale",
            "serie": "C",
        },
    )
    assert r.status_code == 201
    return r.json()["access_token"]


def _auth_headers(token: str) -> dict:
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture(autouse=True)
def _reset_rate_limiter():
    """Vide le rate limiter memoire avant ET apres chaque test.

    Le rate limiter de routers/tutor.py est un dict global
    ``_user_requests``. Sans reset, les tests s'influenceraient.
    """
    _tutor_router._user_requests.clear()
    yield
    _tutor_router._user_requests.clear()


# ─── POST /tutor/ask ──────────────────────────────────────────────────
def test_ask_returns_fallback_response(client, auth_token):
    """Sans cle API Anthropic, le tuteur repond en mode fallback (mock)."""
    r = client.post(
        "/tutor/ask",
        headers=_auth_headers(auth_token),
        json={"question": "Comment factoriser x^2 - 4 ?"},
    )
    assert r.status_code == 200, r.text
    data = r.json()
    assert "answer" in data
    assert len(data["answer"]) > 0
    assert data["fallback"] is True
    assert data["model"] == "fallback-mock"
    assert isinstance(data["suggested_followup"], list)
    assert len(data["suggested_followup"]) == 3


def test_ask_requires_auth(client):
    """POST /tutor/ask sans token -> 401."""
    r = client.post("/tutor/ask", json={"question": "Une question"})
    assert r.status_code == 401


def test_ask_empty_question_returns_422(client, auth_token):
    """Question vide -> 422 (min_length=1)."""
    r = client.post(
        "/tutor/ask",
        headers=_auth_headers(auth_token),
        json={"question": ""},
    )
    assert r.status_code == 422


def test_ask_question_too_long_returns_422(client, auth_token):
    """Question > 2000 caracteres -> 422 (max_length=2000)."""
    r = client.post(
        "/tutor/ask",
        headers=_auth_headers(auth_token),
        json={"question": "x" * 2001},
    )
    assert r.status_code == 422


def test_ask_with_context(client, auth_token):
    """Le contexte pedagogique est accepte (matiere/chapitre)."""
    r = client.post(
        "/tutor/ask",
        headers=_auth_headers(auth_token),
        json={
            "question": "Quelle est la formule de Pythagore ?",
            "context": {
                "matiere": "Mathematiques",
                "chapitre": "Geometrie",
                "niveau_scolaire": "3eme",
            },
        },
    )
    assert r.status_code == 200
    data = r.json()
    # Le fallback mentionne la matiere dans la reponse
    assert "Mathematiques" in data["answer"]


def test_ask_with_conversation_history(client, auth_token):
    """L'historique de conversation est accepte."""
    r = client.post(
        "/tutor/ask",
        headers=_auth_headers(auth_token),
        json={
            "question": "Et dans un triangle rectangle alors ?",
            "conversation_history": [
                {"role": "user", "content": "Qu'est-ce qu'un triangle ?"},
                {"role": "assistant", "content": "Un polygone a 3 cotes."},
            ],
        },
    )
    assert r.status_code == 200


def test_ask_invalid_role_in_history_returns_422(client, auth_token):
    """Un role invalide dans l'historique -> 422 (pattern user|assistant)."""
    r = client.post(
        "/tutor/ask",
        headers=_auth_headers(auth_token),
        json={
            "question": "Q",
            "conversation_history": [
                {"role": "system", "content": "invalid role"}
            ],
        },
    )
    assert r.status_code == 422


def test_ask_followups_geometry_keywords(client, auth_token):
    """Une question sur Pythagore genere des followups de geometrie."""
    r = client.post(
        "/tutor/ask",
        headers=_auth_headers(auth_token),
        json={"question": "Comment utiliser Pythagore ?"},
    )
    data = r.json()
    followups = data["suggested_followup"]
    assert any("exemple" in f.lower() or "demontrer" in f.lower() for f in followups)


def test_ask_followups_algebra_keywords(client, auth_token):
    """Une question sur factorisation genere des followups d'algebre."""
    r = client.post(
        "/tutor/ask",
        headers=_auth_headers(auth_token),
        json={"question": "Comment factoriser cette expression ?"},
    )
    data = r.json()
    followups = data["suggested_followup"]
    assert any("exemple" in f.lower() or "methode" in f.lower() for f in followups)


def test_ask_followups_french_keywords(client, auth_token):
    """Une question sur le subjonctif genere des followups de francais."""
    r = client.post(
        "/tutor/ask",
        headers=_auth_headers(auth_token),
        json={"question": "Quand utiliser le subjonctif ?"},
    )
    data = r.json()
    followups = data["suggested_followup"]
    assert any("exception" in f.lower() or "reconnaitre" in f.lower() for f in followups)


def test_ask_followups_physics_keywords(client, auth_token):
    """Une question sur la loi d'Ohm genere des followups de physique."""
    r = client.post(
        "/tutor/ask",
        headers=_auth_headers(auth_token),
        json={"question": "Comment appliquer la loi d'Ohm ?"},
    )
    data = r.json()
    followups = data["suggested_followup"]
    assert any("exemple" in f.lower() or "calcule" in f.lower() for f in followups)


def test_ask_followups_default_for_unknown(client, auth_token):
    """Une question hors categorie genere les followups par defaut."""
    r = client.post(
        "/tutor/ask",
        headers=_auth_headers(auth_token),
        json={"question": "Quel est le sens de la vie ?"},
    )
    data = r.json()
    followups = data["suggested_followup"]
    assert len(followups) == 3
    # Le 1er followup par defaut mentionne "exemple concret"
    assert any("exemple" in f.lower() for f in followups)


# ─── Rate limiting ────────────────────────────────────────────────────
def test_rate_limit_allows_30_per_hour(client, auth_token):
    """30 questions en une heure passent (limite = 30)."""
    for i in range(30):
        r = client.post(
            "/tutor/ask",
            headers=_auth_headers(auth_token),
            json={"question": f"Question {i}"},
        )
        assert r.status_code == 200, f"Requete #{i+1} a echoue : {r.text}"


def test_rate_limit_blocks_31st_request(client, auth_token):
    """La 31e question est bloquee (429)."""
    for _ in range(30):
        client.post(
            "/tutor/ask",
            headers=_auth_headers(auth_token),
            json={"question": "Q"},
        )
    r = client.post(
        "/tutor/ask",
        headers=_auth_headers(auth_token),
        json={"question": "31e question"},
    )
    assert r.status_code == 429
    # Le header Retry-After doit etre present
    assert "retry-after" in {k.lower() for k in r.headers.keys()}


def test_rate_limit_independent_per_user(client, admin_token):
    """Les compteurs sont independants par user.

    L'admin pose 30 questions (limite atteinte). Un autre user (eleve) peut
    encore poser des questions.
    """
    for _ in range(30):
        client.post(
            "/tutor/ask",
            headers=_auth_headers(admin_token),
            json={"question": "Q"},
        )
    # admin est bloque
    r_admin = client.post(
        "/tutor/ask",
        headers=_auth_headers(admin_token),
        json={"question": "31e"},
    )
    assert r_admin.status_code == 429

    # Un eleve peut encore poser
    student_token = _register_user(client, email="student@test.tg")
    r_student = client.post(
        "/tutor/ask",
        headers=_auth_headers(student_token),
        json={"question": "Q"},
    )
    assert r_student.status_code == 200


def test_rate_limit_429_response_has_retry_after_value(client, auth_token):
    """La reponse 429 contient un header Retry-After avec une valeur numerique."""
    for _ in range(30):
        client.post(
            "/tutor/ask",
            headers=_auth_headers(auth_token),
            json={"question": "Q"},
        )
    r = client.post(
        "/tutor/ask",
        headers=_auth_headers(auth_token),
        json={"question": "31e"},
    )
    assert r.status_code == 429
    retry_after = r.headers.get("retry-after")
    assert retry_after is not None
    assert int(retry_after) > 0


# ─── GET /tutor/health ────────────────────────────────────────────────
def test_tutor_health_returns_ok(client):
    """Le healthcheck du tuteur est publique et renvoie status=ok."""
    r = client.get("/tutor/health")
    assert r.status_code == 200
    data = r.json()
    assert data["status"] == "ok"
    assert "anthropic_configured" in data
    assert data["rate_limit_per_hour"] == 30


def test_tutor_health_no_auth_required(client):
    """GET /tutor/health est accessible sans token."""
    r = client.get("/tutor/health")
    assert r.status_code == 200
