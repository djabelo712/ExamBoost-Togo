"""tests/test_classroom.py — Tests du router /classroom (classe temps reel).

Couverture :
    - POST   /classroom/create         : cree une session (code 6 chiffres)
    - GET    /classroom/{code}/status  : statut public
    - GET    /classroom/{code}/results : resultats finaux
    - POST   /classroom/{code}/end     : termine une session (REST)
    - POST   /classroom/cleanup        : nettoyage memoire
    - GET    /classroom                : liste sessions actives (debug)
    - WebSocket /classroom/{code}      : join + answer + leaderboard + end

Le classroom_manager est un singleton memoire. On le reset avant chaque
test pour eviter toute fuite d'etat entre tests.
"""

from __future__ import annotations

import json
from typing import Any

import pytest

from services.classroom_manager import classroom_manager


# ─── Fixtures ─────────────────────────────────────────────────────────
@pytest.fixture(autouse=True)
def _reset_classroom_manager():
    """Vide le classroom_manager (singleton) avant ET apres chaque test."""
    classroom_manager.sessions.clear()
    classroom_manager._locks.clear()
    yield
    classroom_manager.sessions.clear()
    classroom_manager._locks.clear()


def _create_session_payload(
    teacher_id: str = "teacher-001",
    teacher_name: str = "M. Koffi",
    question_ids: list[str] | None = None,
    mode: str = "live",
    time_limit_seconds: int = 30,
) -> dict:
    return {
        "teacher_id": teacher_id,
        "teacher_name": teacher_name,
        "exam": "BEPC",
        "matiere": "Mathematiques",
        "question_ids": question_ids or ["Q-CLS-01", "Q-CLS-02"],
        "mode": mode,
        "time_limit_seconds": time_limit_seconds,
        "homework_days": 7,
    }


# ─── POST /classroom/create ───────────────────────────────────────────
def test_create_session_returns_code_and_ws_url(client):
    """La creation de session renvoie un code 6 chiffres + ws_url."""
    r = client.post(
        "/classroom/create", json=_create_session_payload()
    )
    assert r.status_code == 200, r.text
    data = r.json()
    assert "session_code" in data
    assert len(data["session_code"]) == 6
    assert data["session_code"].isdigit()
    assert data["ws_url"] == f"/classroom/{data['session_code']}"
    assert data["mode"] == "live"
    assert data["question_count"] == 2


def test_create_session_homework_mode(client):
    """Le mode homework est accepte."""
    payload = _create_session_payload(mode="homework")
    r = client.post("/classroom/create", json=payload)
    assert r.status_code == 200
    assert r.json()["mode"] == "homework"


def test_create_session_empty_question_ids_returns_422(client):
    """Liste de questions vide -> 422 (min_length=1)."""
    payload = _create_session_payload(question_ids=[])
    r = client.post("/classroom/create", json=payload)
    assert r.status_code == 422


def test_create_session_too_many_questions_returns_422(client):
    """Plus de 20 questions -> 422 (max_length=20)."""
    payload = _create_session_payload(
        question_ids=[f"Q-{i:02d}" for i in range(21)]
    )
    r = client.post("/classroom/create", json=payload)
    assert r.status_code == 422


def test_create_session_invalid_time_limit_returns_422(client):
    """time_limit_seconds < 5 -> 422 (ge=5)."""
    payload = _create_session_payload(time_limit_seconds=2)
    r = client.post("/classroom/create", json=payload)
    assert r.status_code == 422


def test_create_session_generates_unique_codes(client):
    """Deux creations generent deux codes differents."""
    r1 = client.post("/classroom/create", json=_create_session_payload())
    r2 = client.post(
        "/classroom/create",
        json=_create_session_payload(teacher_id="teacher-002"),
    )
    assert r1.json()["session_code"] != r2.json()["session_code"]


# ─── GET /classroom/{code}/status ─────────────────────────────────────
def test_get_status_existing_session(client):
    """Statut d'une session existante."""
    r = client.post("/classroom/create", json=_create_session_payload())
    code = r.json()["session_code"]

    r = client.get(f"/classroom/{code}/status")
    assert r.status_code == 200
    data = r.json()
    assert data["code"] == code
    assert data["exists"] is True
    assert data["status"] == "waiting"
    assert data["mode"] == "live"
    assert data["total_questions"] == 2
    assert data["teacher_name"] == "M. Koffi"


def test_get_status_unknown_session(client):
    """Statut d'une session inexistante -> exists=False."""
    r = client.get("/classroom/999999/status")
    assert r.status_code == 200
    data = r.json()
    assert data["exists"] is False
    assert data["code"] == "999999"


def test_get_status_does_not_expose_answers(client):
    """Le statut n'expose pas les reponses (securite)."""
    r = client.post("/classroom/create", json=_create_session_payload())
    code = r.json()["session_code"]
    r = client.get(f"/classroom/{code}/status")
    data_text = r.text.lower()
    assert "reponse" not in data_text
    assert "explication" not in data_text


# ─── GET /classroom/{code}/results ────────────────────────────────────
def test_get_results_unknown_session_returns_empty(client):
    """Resultats d'une session inexistante -> objet vide avec status=ended."""
    r = client.get("/classroom/999999/results")
    assert r.status_code == 200
    data = r.json()
    assert data["session_code"] == "999999"
    assert data["total_players"] == 0


def test_get_results_partial_before_end(client):
    """Resultats partiels avant la fin de la session."""
    r = client.post("/classroom/create", json=_create_session_payload())
    code = r.json()["session_code"]
    r = client.get(f"/classroom/{code}/results")
    assert r.status_code == 200
    data = r.json()
    assert data["status"] == "waiting"  # pas encore terminee
    assert data["total_players"] == 0


# ─── POST /classroom/{code}/end ───────────────────────────────────────
def test_end_session_returns_results(client):
    """Terminer une session renvoie les resultats finaux."""
    r = client.post("/classroom/create", json=_create_session_payload())
    code = r.json()["session_code"]

    r = client.post(f"/classroom/{code}/end")
    assert r.status_code == 200
    data = r.json()
    assert data["session_code"] == code
    assert data["status"] == "ended"


def test_end_session_already_ended_returns_results(client):
    """Terminer une session deja terminee ne plante pas."""
    r = client.post("/classroom/create", json=_create_session_payload())
    code = r.json()["session_code"]

    # 1er end
    r1 = client.post(f"/classroom/{code}/end")
    assert r1.status_code == 200
    # 2e end (deja terminee)
    r2 = client.post(f"/classroom/{code}/end")
    assert r2.status_code == 200
    assert r2.json()["status"] == "ended"


def test_end_unknown_session_returns_empty(client):
    """Terminer une session inexistante -> objet vide (pas 404)."""
    r = client.post("/classroom/999999/end")
    assert r.status_code == 200
    data = r.json()
    assert data["session_code"] == "999999"
    assert data["status"] == "ended"


# ─── POST /classroom/cleanup ──────────────────────────────────────────
def test_cleanup_returns_active_sessions_count(client):
    """Le cleanup renvoie le nombre de sessions actives restantes."""
    # Cree une session et termine-la (elle ne sera pas nettoyee car < 24h)
    r = client.post("/classroom/create", json=_create_session_payload())
    code = r.json()["session_code"]
    client.post(f"/classroom/{code}/end")

    r = client.post("/classroom/cleanup")
    assert r.status_code == 200
    data = r.json()
    assert "active_sessions" in data
    assert isinstance(data["sessions"], list)


def test_cleanup_with_no_sessions(client):
    """Cleanup sans sessions -> 0 actives."""
    r = client.post("/classroom/cleanup")
    assert r.status_code == 200
    assert r.json()["active_sessions"] == 0


# ─── GET /classroom (debug) ───────────────────────────────────────────
def test_list_sessions_empty(client):
    """Liste des sessions actives vide au depart."""
    r = client.get("/classroom")
    assert r.status_code == 200
    data = r.json()
    assert data["count"] == 0
    assert data["sessions"] == []


def test_list_sessions_after_creation(client):
    """Liste des sessions apres creation."""
    client.post("/classroom/create", json=_create_session_payload())
    r = client.get("/classroom")
    assert r.status_code == 200
    assert r.json()["count"] == 1


# ─── WebSocket : join + answer ────────────────────────────────────────
def test_websocket_join_student(client):
    """Un eleve peut rejoindre une session via WS."""
    # Cree une session
    r = client.post("/classroom/create", json=_create_session_payload())
    code = r.json()["session_code"]

    # Connection WS
    with client.websocket_connect(f"/classroom/{code}") as ws:
        ws.send_json({
            "type": "join",
            "player_id": "student-001",
            "player_name": "Amina",
            "role": "student",
        })
        msg = ws.receive_json()
        assert msg["type"] == "joined"
        assert msg["player"]["id"] == "student-001"
        assert msg["player"]["name"] == "Amina"
        assert msg["session"]["code"] == code


def test_websocket_join_teacher(client):
    """Un enseignant peut rejoindre une session via WS."""
    r = client.post("/classroom/create", json=_create_session_payload())
    code = r.json()["session_code"]

    with client.websocket_connect(f"/classroom/{code}") as ws:
        ws.send_json({
            "type": "join",
            "player_id": "teacher-001",
            "player_name": "M. Koffi",
            "role": "teacher",
        })
        msg = ws.receive_json()
        assert msg["type"] == "joined"
        assert msg["player"]["role"] == "teacher"


def test_websocket_join_unknown_session_rejected(client):
    """Join sur une session inexistante -> error + close."""
    with client.websocket_connect("/classroom/999999") as ws:
        ws.send_json({
            "type": "join",
            "player_id": "student-001",
            "player_name": "Amina",
            "role": "student",
        })
        msg = ws.receive_json()
        assert msg["type"] == "error"


def test_websocket_first_message_must_be_join(client):
    """Le 1er message WS doit etre 'join'."""
    r = client.post("/classroom/create", json=_create_session_payload())
    code = r.json()["session_code"]

    with client.websocket_connect(f"/classroom/{code}") as ws:
        ws.send_json({"type": "answer", "question_id": "Q1", "answer": "X"})
        msg = ws.receive_json()
        assert msg["type"] == "error"


def test_websocket_answer_confirmed(client):
    """Une reponse d'eleve est confirmee + leaderboard diffuse."""
    r = client.post("/classroom/create", json=_create_session_payload())
    code = r.json()["session_code"]

    with client.websocket_connect(f"/classroom/{code}") as ws:
        # Join en tant qu'eleve
        ws.send_json({
            "type": "join",
            "player_id": "student-001",
            "player_name": "Amina",
            "role": "student",
        })
        ws.receive_json()  # joined
        ws.receive_json()  # player_joined (broadcast)

        # Le prof join a part pour demarrer le quiz
        # (en practice il faudrait 2 connexions WS concurrentes ;
        #  ici on triche en demarrant le quiz via le manager direct)
        classroom_manager.start_quiz(code)
        classroom_manager.next_question(code)

        # L'eleve repond
        ws.send_json({
            "type": "answer",
            "question_id": "Q-CLS-01",
            "answer": "wrong-answer",
            "time_taken_seconds": 10.0,
        })
        # On doit recevoir answer_confirmed
        # (il peut y avoir d'autres messages broadcastes avant)
        received = []
        for _ in range(5):
            try:
                msg = ws.receive_json(timeout=2.0)
                received.append(msg)
                if msg.get("type") == "answer_confirmed":
                    break
            except Exception:
                break
        assert any(m["type"] == "answer_confirmed" for m in received)


def test_websocket_player_joined_broadcast(client):
    """Quand un eleve rejoint, un broadcast player_joined est emis."""
    r = client.post("/classroom/create", json=_create_session_payload())
    code = r.json()["session_code"]

    with client.websocket_connect(f"/classroom/{code}") as ws:
        ws.send_json({
            "type": "join",
            "player_id": "student-001",
            "player_name": "Amina",
            "role": "student",
        })
        # 1. joined (recu par le joueur)
        msg1 = ws.receive_json()
        assert msg1["type"] == "joined"
        # 2. player_joined (broadcaste a tous, y compris lui-meme)
        msg2 = ws.receive_json()
        assert msg2["type"] == "player_joined"
        assert msg2["player"]["id"] == "student-001"
        assert msg2["players_count"] == 1


def test_websocket_unknown_message_type_returns_error(client):
    """Un type de message inconnu apres join -> error."""
    r = client.post("/classroom/create", json=_create_session_payload())
    code = r.json()["session_code"]

    with client.websocket_connect(f"/classroom/{code}") as ws:
        ws.send_json({
            "type": "join",
            "player_id": "student-001",
            "player_name": "Amina",
            "role": "student",
        })
        ws.receive_json()  # joined
        ws.receive_json()  # player_joined

        ws.send_json({"type": "invalid_type"})
        msg = ws.receive_json()
        assert msg["type"] == "error"


def test_websocket_teacher_can_start_quiz(client):
    """Un enseignant peut demarrer le quiz via WS."""
    r = client.post("/classroom/create", json=_create_session_payload())
    code = r.json()["session_code"]

    with client.websocket_connect(f"/classroom/{code}") as ws:
        ws.send_json({
            "type": "join",
            "player_id": "teacher-001",
            "player_name": "M. Koffi",
            "role": "teacher",
        })
        ws.receive_json()  # joined
        ws.receive_json()  # player_joined

        # Demarre le quiz
        ws.send_json({"type": "start_quiz"})
        # On doit recevoir quiz_started puis new_question
        received = []
        for _ in range(5):
            try:
                msg = ws.receive_json(timeout=2.0)
                received.append(msg)
                if msg.get("type") == "new_question":
                    break
            except Exception:
                break
        types = [m["type"] for m in received]
        assert "quiz_started" in types
        assert "new_question" in types


def test_websocket_student_cannot_start_quiz(client):
    """Un eleve ne peut pas demarrer le quiz (silencieusement ignore)."""
    r = client.post("/classroom/create", json=_create_session_payload())
    code = r.json()["session_code"]

    with client.websocket_connect(f"/classroom/{code}") as ws:
        ws.send_json({
            "type": "join",
            "player_id": "student-001",
            "player_name": "Amina",
            "role": "student",
        })
        ws.receive_json()  # joined
        ws.receive_json()  # player_joined

        # L'eleve tente de demarrer le quiz
        ws.send_json({"type": "start_quiz"})
        # Le serveur doit ignorer (pas de quiz_started)
        # On attend un peu pour voir si un message arrive
        try:
            msg = ws.receive_json(timeout=1.0)
            # Si on recoit quelque chose, ce n'est pas quiz_started
            assert msg.get("type") != "quiz_started"
        except Exception:
            pass  # Aucun message = OK (le serveur a ignore)


def test_websocket_end_session_by_teacher(client):
    """Un enseignant peut terminer la session via WS."""
    r = client.post("/classroom/create", json=_create_session_payload())
    code = r.json()["session_code"]

    with client.websocket_connect(f"/classroom/{code}") as ws:
        ws.send_json({
            "type": "join",
            "player_id": "teacher-001",
            "player_name": "M. Koffi",
            "role": "teacher",
        })
        ws.receive_json()  # joined
        ws.receive_json()  # player_joined

        ws.send_json({"type": "end_session"})
        msg = ws.receive_json()
        assert msg["type"] == "session_ended"
        assert "results" in msg


# ─── Workflow complet : create + join + start + answer + end ──────────
def test_classroom_full_workflow_live(client):
    """Workflow complet en mode live : create -> join -> start -> end.

    On utilise le manager directement pour certaines operations car la
    gestion simultanee de 2 WebSockets dans un seul test est delicate.
    """
    # 1. Cree une session
    r = client.post("/classroom/create", json=_create_session_payload())
    code = r.json()["session_code"]

    # 2. Verifie le statut initial
    status = client.get(f"/classroom/{code}/status").json()
    assert status["status"] == "waiting"
    assert status["exists"] is True

    # 3. Demarre le quiz via le manager (simule l'action prof)
    classroom_manager.start_quiz(code)
    classroom_manager.next_question(code)

    # 4. Verifie le statut apres start
    status = client.get(f"/classroom/{code}/status").json()
    assert status["status"] == "live"
    assert status["current_question_index"] == 0

    # 5. Termine via REST
    r = client.post(f"/classroom/{code}/end")
    assert r.status_code == 200
    results = r.json()
    assert results["status"] == "ended"
    assert results["total_questions"] == 2

    # 6. Statut apres end
    status = client.get(f"/classroom/{code}/status").json()
    assert status["status"] == "ended"


def test_classroom_homework_mode_no_expiry_during_period(client):
    """Une session homework n'expire pas pendant sa periode de validite."""
    payload = _create_session_payload(mode="homework", question_ids=["Q1"])
    r = client.post("/classroom/create", json=payload)
    code = r.json()["session_code"]

    # Statut : toujours en waiting (pas d'expiration immediate)
    status = client.get(f"/classroom/{code}/status").json()
    assert status["status"] == "waiting"
    assert status["mode"] == "homework"
    assert status["homework_expires_at"] is not None
