"""tests/test_sync.py — Tests du router /sync (sync cloud offline-first).

Couverture :
    - POST /sync/action   : reception d'une action unique
    - POST /sync/batch    : reception d'un batch (max 50)
    - GET  /sync/status   : statut de sync pour l'utilisateur courant
    - GET  /sync/pull     : recupere les mises a jour serveur depuis ``since``
    - Idempotence : un meme action_id renvoye deux fois ne re-applique pas
    - Resolution de conflits CRDT-like (Last-Write-Wins sur ReviewCard)
    - Auth requise (401 sans token)
    - Types d'actions : reviewAnswer, bktUpdate, simulationResult, userProgress,
      badgeUnlock, type inconnu
"""

from __future__ import annotations

import uuid
from datetime import datetime, timedelta, timezone


# ─── Helpers ──────────────────────────────────────────────────────────
def _register_user(client, email="sync@test.tg"):
    r = client.post(
        "/auth/register",
        json={
            "email": email,
            "password": "password123",
            "nom": "Sync",
            "prenom": "Test",
            "niveau_scolaire": "Terminale",
            "serie": "C",
        },
    )
    assert r.status_code == 201
    return r.json()["user_id"], r.json()["access_token"]


def _auth_headers(token: str) -> dict:
    return {"Authorization": f"Bearer {token}"}


def _create_question(client, admin_token, qid="SYNC-Q01"):
    r = client.post(
        "/questions",
        headers=_auth_headers(admin_token),
        json={
            "id": qid,
            "enonce": "Question sync",
            "reponse": "42",
            "matiere": "Mathematiques",
            "chapitre": "Sync",
            "competence_id": "TG-SYNC-001",
            "examen": "BEPC",
        },
    )
    assert r.status_code == 201


def _make_action(
    action_type: str = "reviewAnswer",
    action_id: str | None = None,
    payload: dict | None = None,
    created_at: datetime | None = None,
) -> dict:
    return {
        "action_id": action_id or str(uuid.uuid4()),
        "type": action_type,
        "payload": payload or {},
        "created_at": (created_at or datetime.now(timezone.utc)).isoformat(),
        "retry_count": 0,
    }


# ─── POST /sync/action ────────────────────────────────────────────────
def test_post_action_review_answer_applies(client, admin_token):
    """Une action reviewAnswer est appliquee et met a jour SM-2 + BKT."""
    _create_question(client, admin_token)
    user_id, token = _register_user(client)

    action = _make_action(
        action_type="reviewAnswer",
        payload={
            "question_id": "SYNC-Q01",
            "quality": 5,
            "time_spent_sec": 10,
        },
    )
    r = client.post("/sync/action", headers=_auth_headers(token), json=action)
    assert r.status_code == 200, r.text
    data = r.json()
    assert data["applied"] is True
    assert data["error"] is None
    assert data["result"]["question_id"] == "SYNC-Q01"
    assert data["result"]["quality"] == 5
    assert "bkt_update" in data["result"]


def test_post_action_requires_auth(client):
    """POST /sync/action sans token -> 401."""
    action = _make_action()
    r = client.post("/sync/action", json=action)
    assert r.status_code == 401


def test_post_action_idempotent_same_action_id(client, admin_token):
    """Le meme action_id envoye deux fois ne re-applique pas l'action."""
    _create_question(client, admin_token)
    user_id, token = _register_user(client)

    action_id = str(uuid.uuid4())
    action = _make_action(
        action_type="reviewAnswer",
        action_id=action_id,
        payload={"question_id": "SYNC-Q01", "quality": 5},
    )

    # 1er envoi : applique
    r1 = client.post("/sync/action", headers=_auth_headers(token), json=action)
    assert r1.status_code == 200
    assert r1.json()["applied"] is True

    # 2e envoi (meme action_id) : skip
    r2 = client.post("/sync/action", headers=_auth_headers(token), json=action)
    assert r2.status_code == 200
    assert r2.json()["applied"] is False


def test_post_action_unknown_type_returns_error(client, admin_token):
    """Type d'action inconnu -> applied=False avec message d'erreur."""
    _, token = _register_user(client)
    action = _make_action(action_type="unknownType")
    r = client.post("/sync/action", headers=_auth_headers(token), json=action)
    assert r.status_code == 200
    data = r.json()
    assert data["applied"] is False
    assert "inconnu" in (data["error"] or "").lower()


def test_post_action_bkt_update(client, admin_token):
    """Une action bktUpdate isole met a jour P(L) BKT."""
    _, token = _register_user(client)
    action = _make_action(
        action_type="bktUpdate",
        payload={"competence_id": "TG-COMP-XYZ", "correct": True},
    )
    r = client.post("/sync/action", headers=_auth_headers(token), json=action)
    assert r.status_code == 200
    data = r.json()
    assert data["applied"] is True
    assert data["result"]["competence_id"] == "TG-COMP-XYZ"
    assert data["result"]["pL_after"] > data["result"]["pL_before"]


def test_post_action_bkt_update_missing_competence(client, admin_token):
    """bktUpdate sans competence_id -> erreur."""
    _, token = _register_user(client)
    action = _make_action(
        action_type="bktUpdate",
        payload={"correct": True},  # pas de competence_id
    )
    r = client.post("/sync/action", headers=_auth_headers(token), json=action)
    assert r.status_code == 200
    data = r.json()
    assert data["applied"] is False
    assert "competence_id" in (data["error"] or "")


def test_post_action_simulation_result(client, admin_token):
    """Une action simulationResult insere une Simulation."""
    _, token = _register_user(client)
    action = _make_action(
        action_type="simulationResult",
        payload={
            "examen": "BEPC",
            "score": 14.5,
            "duration_sec": 7200,
            "nb_questions": 40,
        },
    )
    r = client.post("/sync/action", headers=_auth_headers(token), json=action)
    assert r.status_code == 200
    data = r.json()
    assert data["applied"] is True
    assert data["result"]["examen"] == "BEPC"
    assert data["result"]["score"] == 14.5


def test_post_action_simulation_result_missing_examen(client, admin_token):
    """simulationResult sans examen -> erreur."""
    _, token = _register_user(client)
    action = _make_action(
        action_type="simulationResult",
        payload={"score": 10.0},  # pas d'examen
    )
    r = client.post("/sync/action", headers=_auth_headers(token), json=action)
    assert r.status_code == 200
    assert r.json()["applied"] is False


def test_post_action_user_progress_monotonic(client, admin_token):
    """userProgress met a jour les compteurs en max monotone."""
    _, token = _register_user(client)
    action = _make_action(
        action_type="userProgress",
        payload={"questions_answered": 42, "sessions_count": 10},
    )
    r = client.post("/sync/action", headers=_auth_headers(token), json=action)
    assert r.status_code == 200
    data = r.json()
    assert data["applied"] is True
    assert data["result"]["total_questions_answered"] == 42
    assert data["result"]["total_sessions"] == 10


def test_post_action_user_progress_max_kept(client, admin_token):
    """Si on envoie un compteur inferieur, le max local est conserve."""
    _, token = _register_user(client)
    # 1. Premier envoi : 42 questions
    a1 = _make_action(
        action_type="userProgress",
        payload={"questions_answered": 42, "sessions_count": 10},
    )
    client.post("/sync/action", headers=_auth_headers(token), json=a1)
    # 2. Second envoi : 10 questions (inferieur)
    a2 = _make_action(
        action_type="userProgress",
        payload={"questions_answered": 10, "sessions_count": 5},
    )
    r2 = client.post("/sync/action", headers=_auth_headers(token), json=a2)
    assert r2.status_code == 200
    # Le max (42) doit etre conserve
    assert r2.json()["result"]["total_questions_answered"] == 42


def test_post_action_badge_unlock(client, admin_token):
    """Une action badgeUnlock est enregistree (placeholder)."""
    _, token = _register_user(client)
    action = _make_action(
        action_type="badgeUnlock",
        payload={"badge_id": "first_quiz", "unlocked_at": "2026-07-01T00:00:00Z"},
    )
    r = client.post("/sync/action", headers=_auth_headers(token), json=action)
    assert r.status_code == 200
    data = r.json()
    assert data["applied"] is True
    assert data["result"]["badge_id"] == "first_quiz"


def test_post_action_badge_unlock_missing_id(client, admin_token):
    """badgeUnlock sans badge_id -> erreur."""
    _, token = _register_user(client)
    action = _make_action(action_type="badgeUnlock", payload={})
    r = client.post("/sync/action", headers=_auth_headers(token), json=action)
    assert r.status_code == 200
    assert r.json()["applied"] is False


def test_post_action_review_answer_unknown_question(client, admin_token):
    """reviewAnswer avec question_id inconnu -> erreur."""
    _, token = _register_user(client)
    action = _make_action(
        action_type="reviewAnswer",
        payload={"question_id": "UNKNOWN-Q", "quality": 5},
    )
    r = client.post("/sync/action", headers=_auth_headers(token), json=action)
    assert r.status_code == 200
    data = r.json()
    assert data["applied"] is False
    assert "introuvable" in (data["error"] or "").lower()


# ─── POST /sync/batch ─────────────────────────────────────────────────
def test_post_batch_applies_all_actions(client, admin_token):
    """Un batch de 3 actions est applique integrallement."""
    _create_question(client, admin_token)
    _, token = _register_user(client)

    actions = [
        _make_action(
            action_type="reviewAnswer",
            payload={"question_id": "SYNC-Q01", "quality": 4},
        ),
        _make_action(
            action_type="bktUpdate",
            payload={"competence_id": "TG-X-001", "correct": True},
        ),
        _make_action(
            action_type="simulationResult",
            payload={"examen": "BEPC", "score": 12.0},
        ),
    ]
    r = client.post(
        "/sync/batch",
        headers=_auth_headers(token),
        json={"actions": actions},
    )
    assert r.status_code == 200
    data = r.json()
    assert data["total"] == 3
    assert data["applied"] == 3
    assert data["skipped"] == 0
    assert data["failed"] == 0
    assert len(data["results"]) == 3


def test_post_batch_max_50_actions_enforced(client, admin_token):
    """Un batch de 51 actions est rejete (422 validation Pydantic).

    Note : le schema Pydantic ``SyncBatchRequest`` impose ``max_length=50`` sur
    la liste d'actions. Le check 413 cote router est donc techniquement
    unreachable car Pydantic valide avant. On accepte les deux statuts.
    """
    _, token = _register_user(client)
    actions = [_make_action() for _ in range(51)]
    r = client.post(
        "/sync/batch",
        headers=_auth_headers(token),
        json={"actions": actions},
    )
    assert r.status_code in (413, 422)


def test_post_batch_idempotent_action_within_batch(client, admin_token):
    """Si une action du batch a deja ete appliquee, elle est skip."""
    _create_question(client, admin_token)
    _, token = _register_user(client)

    action_id = str(uuid.uuid4())
    action = _make_action(
        action_id=action_id,
        action_type="reviewAnswer",
        payload={"question_id": "SYNC-Q01", "quality": 5},
    )
    # Applique l'action seule d'abord
    client.post("/sync/action", headers=_auth_headers(token), json=action)
    # Puis l'envoie dans un batch
    r = client.post(
        "/sync/batch",
        headers=_auth_headers(token),
        json={"actions": [action]},
    )
    data = r.json()
    assert data["total"] == 1
    assert data["applied"] == 0
    assert data["skipped"] == 1


def test_post_batch_continues_on_error(client, admin_token):
    """Si une action echoue dans le batch, les autres sont quand meme appliquees."""
    _create_question(client, admin_token)
    _, token = _register_user(client)

    actions = [
        _make_action(
            action_type="reviewAnswer",
            payload={"question_id": "SYNC-Q01", "quality": 4},  # OK
        ),
        _make_action(
            action_type="reviewAnswer",
            payload={"question_id": "UNKNOWN-Q", "quality": 4},  # echec
        ),
        _make_action(
            action_type="bktUpdate",
            payload={"competence_id": "TG-OK-001", "correct": True},  # OK
        ),
    ]
    r = client.post(
        "/sync/batch",
        headers=_auth_headers(token),
        json={"actions": actions},
    )
    data = r.json()
    assert data["total"] == 3
    assert data["applied"] == 2
    assert data["failed"] == 1


def test_post_batch_requires_auth(client):
    """POST /sync/batch sans token -> 401."""
    r = client.post("/sync/batch", json={"actions": []})
    assert r.status_code == 401


def test_post_batch_empty_actions_list(client, auth_token):
    """Un batch vide est valide (0 actions)."""
    r = client.post(
        "/sync/batch",
        headers=_auth_headers(auth_token),
        json={"actions": []},
    )
    assert r.status_code == 200
    data = r.json()
    assert data["total"] == 0
    assert data["applied"] == 0


# ─── GET /sync/status ─────────────────────────────────────────────────
def test_get_status_returns_user_id_and_server_time(client, auth_token):
    """Le statut renvoie user_id + server_time, total_actions_applied=0 au depart."""
    r = client.get("/sync/status", headers=_auth_headers(auth_token))
    assert r.status_code == 200
    data = r.json()
    assert "user_id" in data
    assert "server_time" in data
    assert data["total_actions_applied"] == 0
    assert data["last_action_applied_at"] is None


def test_get_status_increments_after_action(client, admin_token):
    """Apres une action appliquee, total_actions_applied=1."""
    _create_question(client, admin_token)
    _, token = _register_user(client)
    action = _make_action(
        action_type="reviewAnswer",
        payload={"question_id": "SYNC-Q01", "quality": 5},
    )
    client.post("/sync/action", headers=_auth_headers(token), json=action)

    r = client.get("/sync/status", headers=_auth_headers(token))
    data = r.json()
    assert data["total_actions_applied"] == 1
    assert data["last_action_applied_at"] is not None


def test_get_status_requires_auth(client):
    """GET /sync/status sans token -> 401."""
    r = client.get("/sync/status")
    assert r.status_code == 401


# ─── GET /sync/pull ───────────────────────────────────────────────────
def test_get_pull_returns_review_cards(client, admin_token):
    """Pull recupere les ReviewCard modifiees depuis `since`."""
    _create_question(client, admin_token)
    _, token = _register_user(client)
    # Applique une action reviewAnswer
    action = _make_action(
        action_type="reviewAnswer",
        payload={"question_id": "SYNC-Q01", "quality": 5},
    )
    client.post("/sync/action", headers=_auth_headers(token), json=action)

    # Pull depuis 1 heure en arriere
    since = (datetime.now(timezone.utc) - timedelta(hours=1)).isoformat()
    r = client.get("/sync/pull", headers=_auth_headers(token), params={"since": since})
    assert r.status_code == 200
    data = r.json()
    assert "review_cards" in data
    assert "bkt_maitrise" in data
    assert "user_counters" in data
    assert len(data["review_cards"]) >= 1
    assert data["review_cards"][0]["question_id"] == "SYNC-Q01"


def test_get_pull_returns_bkt_state(client, admin_token):
    """Pull renvoie l'etat BKT actuel de l'utilisateur."""
    _create_question(client, admin_token)
    _, token = _register_user(client)
    action = _make_action(
        action_type="reviewAnswer",
        payload={"question_id": "SYNC-Q01", "quality": 5},
    )
    client.post("/sync/action", headers=_auth_headers(token), json=action)

    since = (datetime.now(timezone.utc) - timedelta(hours=1)).isoformat()
    r = client.get("/sync/pull", headers=_auth_headers(token), params={"since": since})
    data = r.json()
    # BKT doit contenir la competence TG-SYNC-001
    assert "TG-SYNC-001" in data["bkt_maitrise"]


def test_get_pull_returns_user_counters(client, auth_token):
    """Pull renvoie les compteurs utilisateur."""
    since = (datetime.now(timezone.utc) - timedelta(days=1)).isoformat()
    r = client.get("/sync/pull", headers=_auth_headers(auth_token), params={"since": since})
    assert r.status_code == 200
    counters = r.json()["user_counters"]
    assert "total_sessions" in counters
    assert "total_questions_answered" in counters
    assert "theta_irt" in counters


def test_get_pull_requires_auth(client):
    """GET /sync/pull sans token -> 401."""
    r = client.get("/sync/pull", params={"since": "2026-01-01T00:00:00Z"})
    assert r.status_code == 401


def test_get_pull_requires_since_param(client, auth_token):
    """GET /sync/pull sans param `since` -> 422."""
    r = client.get("/sync/pull", headers=_auth_headers(auth_token))
    assert r.status_code == 422


def test_get_pull_with_future_since_returns_empty(client, admin_token):
    """Pull avec since dans le futur -> review_cards vide."""
    _create_question(client, admin_token)
    _, token = _register_user(client)
    action = _make_action(
        action_type="reviewAnswer",
        payload={"question_id": "SYNC-Q01", "quality": 5},
    )
    client.post("/sync/action", headers=_auth_headers(token), json=action)

    future = (datetime.now(timezone.utc) + timedelta(days=10)).isoformat()
    r = client.get("/sync/pull", headers=_auth_headers(token), params={"since": future})
    assert r.status_code == 200
    assert r.json()["review_cards"] == []


# ─── Resolution de conflits (CRDT-like) ───────────────────────────────
def test_action_idempotence_preserves_bkt_value(client, admin_token):
    """Re-envoyer la meme action n'augmente pas pL une 2e fois."""
    _create_question(client, admin_token)
    _, token = _register_user(client)
    action_id = str(uuid.uuid4())
    action = _make_action(
        action_id=action_id,
        action_type="reviewAnswer",
        payload={"question_id": "SYNC-Q01", "quality": 5},
    )
    r1 = client.post("/sync/action", headers=_auth_headers(token), json=action)
    pL_after_1 = r1.json()["result"]["bkt_update"]["pL_after"]

    r2 = client.post("/sync/action", headers=_auth_headers(token), json=action)
    # Le 2e envoi est idempotent : on renvoie le result stocke
    assert r2.json()["applied"] is False
    pL_after_2 = r2.json()["result"]["result"]["bkt_update"]["pL_after"]
    assert pL_after_1 == pL_after_2
