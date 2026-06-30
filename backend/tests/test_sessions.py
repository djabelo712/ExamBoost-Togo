"""tests/test_sessions.py — Tests du router /sessions (SM-2 + BKT end-to-end)."""

from __future__ import annotations


def _register_user(client, email="sess@test.tg"):
    r = client.post(
        "/auth/register",
        json={
            "email": email,
            "password": "password123",
            "nom": "Sess",
            "prenom": "Test",
            "niveau_scolaire": "Terminale",
            "serie": "C",
        },
    )
    assert r.status_code == 201
    return r.json()["user_id"], r.json()["access_token"]


def _create_admin_question(client, admin_token, qid="SESS-Q01"):
    r = client.post(
        "/questions",
        headers={"Authorization": f"Bearer {admin_token}"},
        json={
            "id": qid,
            "enonce": "Question pour test session",
            "reponse": "42",
            "matiere": "Mathematiques",
            "chapitre": "Test",
            "competence_id": "TG-TEST-001",
            "examen": "BEPC",
        },
    )
    assert r.status_code == 201


def test_session_correct_quality(client, admin_token):
    """Une session avec quality >= 3 est marquee correct."""
    _create_admin_question(client, admin_token)
    user_id, _ = _register_user(client)

    r = client.post(
        "/sessions",
        json={
            "user_id": user_id,
            "question_id": "SESS-Q01",
            "quality": 4,
            "time_spent_sec": 30,
        },
    )
    assert r.status_code == 200, r.text
    data = r.json()
    assert data["correct"] is True
    assert data["quality"] == 4
    assert data["interval_days"] == 1  # premiere reponse correcte
    assert data["bkt_update"]["pL_after"] > data["bkt_update"]["pL_before"]
    assert data["bkt_update"]["mastered"] is False  # pL < 0.85 apres 1 reponse


def test_session_incorrect_quality(client, admin_token):
    """Une session avec quality < 3 est marquee incorrecte.

    Note BKT : avec pL_init=0.1 et pT=0.2, meme une reponse incorrecte
    augmente legerement pL (a cause de la transition d'apprentissage).
    On verifie donc que la valeur correspond a la formule BKT, et non
    qu'elle baisse systematiquement.
    """
    _create_admin_question(client, admin_token)
    user_id, _ = _register_user(client)

    r = client.post(
        "/sessions",
        json={
            "user_id": user_id,
            "question_id": "SESS-Q01",
            "quality": 2,
            "time_spent_sec": 30,
        },
    )
    assert r.status_code == 200
    data = r.json()
    assert data["correct"] is False
    assert data["interval_days"] == 1

    # Verifie la valeur BKT exacte (pL_init=0.1, pT=0.2, pS=0.1, pG=0.2, incorrect)
    # P(incorrect) = 0.1*0.1 + 0.9*0.8 = 0.73
    # P(L|0) = 0.01 / 0.73 = 0.0137
    # P(L_next) = 0.0137 + 0.9863 * 0.2 = 0.2110
    expected = (0.1 * 0.1) / 0.73
    expected_next = expected + (1 - expected) * 0.2
    assert abs(data["bkt_update"]["pL_after"] - round(expected_next, 4)) < 0.01
    assert 0.0 <= data["bkt_update"]["pL_after"] <= 1.0


def test_session_explicit_correct_override(client, admin_token):
    """Si ``correct`` est fourni, il n'est pas derive de quality."""
    _create_admin_question(client, admin_token)
    user_id, _ = _register_user(client)

    r = client.post(
        "/sessions",
        json={
            "user_id": user_id,
            "question_id": "SESS-Q01",
            "quality": 2,  # incorrect normalement
            "time_spent_sec": 30,
            "correct": True,  # mais force a True
        },
    )
    assert r.status_code == 200
    data = r.json()
    assert data["correct"] is True


def test_due_and_stats_after_session(client, admin_token):
    """Apres une session, stats et dues sont coherentes."""
    _create_admin_question(client, admin_token)
    user_id, _ = _register_user(client)

    # Pas de carte au depart
    r_stats = client.get(f"/sessions/{user_id}/stats")
    assert r_stats.status_code == 200
    assert r_stats.json()["total_cards"] == 0

    # On enregistre une session
    r_sess = client.post(
        "/sessions",
        json={"user_id": user_id, "question_id": "SESS-Q01", "quality": 5},
    )
    assert r_sess.status_code == 200

    # Stats: 1 carte, 0 due (next_review = +1j)
    r_stats = client.get(f"/sessions/{user_id}/stats")
    data = r_stats.json()
    assert data["total_cards"] == 1
    assert data["due_today"] == 0  # prochaine revision dans 1 jour
    assert data["due_in_7_days"] == 1  # dans 7 jours c'est inclus


def test_session_user_not_found(client):
    """404 si user_id inconnu."""
    r = client.post(
        "/sessions",
        json={
            "user_id": "inexistant",
            "question_id": "whatever",
            "quality": 4,
        },
    )
    assert r.status_code == 404


def test_session_question_not_found(client):
    """404 si question_id inconnu."""
    user_id, _ = _register_user(client)
    r = client.post(
        "/sessions",
        json={
            "user_id": user_id,
            "question_id": "Q-DOES-NOT-EXIST",
            "quality": 4,
        },
    )
    assert r.status_code == 404
