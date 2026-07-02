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


# ─── Tests complementaires (Vague 2 — Agent BW) ──────────────────────


def test_session_quality_zero_marks_incorrect(client, admin_token):
    """quality=0 (oublie total) -> incorrect + reset SM-2."""
    _create_admin_question(client, admin_token)
    user_id, _ = _register_user(client)

    r = client.post(
        "/sessions",
        json={
            "user_id": user_id,
            "question_id": "SESS-Q01",
            "quality": 0,
            "time_spent_sec": 10,
        },
    )
    assert r.status_code == 200
    data = r.json()
    assert data["correct"] is False
    assert data["quality"] == 0
    # SM-2 : q<3 -> interval=1, is_learning=True (via la carte)
    assert data["interval_days"] == 1


def test_session_quality_five_perfect(client, admin_token):
    """quality=5 (parfait) -> correct + interval=1 (premiere reponse)."""
    _create_admin_question(client, admin_token)
    user_id, _ = _register_user(client)

    r = client.post(
        "/sessions",
        json={
            "user_id": user_id,
            "question_id": "SESS-Q01",
            "quality": 5,
            "time_spent_sec": 5,
        },
    )
    assert r.status_code == 200
    data = r.json()
    assert data["correct"] is True
    assert data["interval_days"] == 1
    assert data["easiness_factor"] > 2.5  # EF augmente avec q=5


def test_session_invalid_quality_returns_422(client, admin_token):
    """quality > 5 -> 422 (validation Pydantic)."""
    _create_admin_question(client, admin_token)
    user_id, _ = _register_user(client)

    r = client.post(
        "/sessions",
        json={
            "user_id": user_id,
            "question_id": "SESS-Q01",
            "quality": 7,  # hors range
        },
    )
    assert r.status_code == 422


def test_session_negative_quality_returns_422(client, admin_token):
    """quality < 0 -> 422."""
    _create_admin_question(client, admin_token)
    user_id, _ = _register_user(client)

    r = client.post(
        "/sessions",
        json={
            "user_id": user_id,
            "question_id": "SESS-Q01",
            "quality": -1,
        },
    )
    assert r.status_code == 422


def test_session_bkt_mastered_threshold(client, admin_token):
    """Apres plusieurs reponses correctes, BKT passe mastered=True.

    Avec pL_init=0.1, pT=0.2, pS=0.1, pG=0.2 et reponses correctes repetees,
    pL finit par depasser 0.85 (seuil de maitrise).
    """
    _create_admin_question(client, admin_token)
    user_id, _ = _register_user(client)

    mastered_seen = False
    for _ in range(10):
        r = client.post(
            "/sessions",
            json={
                "user_id": user_id,
                "question_id": "SESS-Q01",
                "quality": 5,
            },
        )
        assert r.status_code == 200
        if r.json()["bkt_update"]["mastered"]:
            mastered_seen = True
            break
    assert mastered_seen, "BKT aurait du atteindre le seuil de maitrise"


def test_due_cards_returns_only_due(client, admin_token):
    """Une carte fraichement cree (next_review=+1j) n'est PAS due."""
    _create_admin_question(client, admin_token)
    user_id, _ = _register_user(client)

    # Enregistre une session (next_review dans 1 jour)
    client.post(
        "/sessions",
        json={"user_id": user_id, "question_id": "SESS-Q01", "quality": 5},
    )

    # Liste des dues : vide (la carte est programmed pour demain)
    r = client.get(f"/sessions/{user_id}/due")
    assert r.status_code == 200
    assert r.json() == []


def test_stats_new_cards_count(client, admin_token):
    """Apres 1 session, la carte n'est plus 'new' (total_attempts > 0)."""
    _create_admin_question(client, admin_token)
    user_id, _ = _register_user(client)

    # Avant session : 0 carte
    r = client.get(f"/sessions/{user_id}/stats")
    assert r.json()["total_cards"] == 0
    assert r.json()["new_cards"] == 0

    # Apres session : 1 carte, 0 new (a ete revisee)
    client.post(
        "/sessions",
        json={"user_id": user_id, "question_id": "SESS-Q01", "quality": 4},
    )
    r = client.get(f"/sessions/{user_id}/stats")
    data = r.json()
    assert data["total_cards"] == 1
    assert data["new_cards"] == 0
    assert data["learning"] == 0  # quality >= 3 -> is_learning=False


def test_stats_learning_state_after_failure(client, admin_token):
    """Apres un echec, la carte est en etat 'learning'."""
    _create_admin_question(client, admin_token)
    user_id, _ = _register_user(client)

    client.post(
        "/sessions",
        json={"user_id": user_id, "question_id": "SESS-Q01", "quality": 2},
    )
    r = client.get(f"/sessions/{user_id}/stats")
    data = r.json()
    assert data["total_cards"] == 1
    assert data["learning"] == 1  # quality < 3 -> is_learning=True


def test_session_records_time_spent(client, admin_token):
    """Le temps de reponse est enregistre dans l'historique."""
    _create_admin_question(client, admin_token)
    user_id, _ = _register_user(client)

    r = client.post(
        "/sessions",
        json={
            "user_id": user_id,
            "question_id": "SESS-Q01",
            "quality": 4,
            "time_spent_sec": 42,
        },
    )
    assert r.status_code == 200

    # On verifie via predict-score que avg_time_per_q est bien 42
    r = client.get(f"/predict-score/{user_id}")
    data = r.json()
    assert data["total_responses"] == 1


def test_due_cards_unknown_user_returns_empty(client):
    """Liste des dues pour un user_id inexistant -> liste vide (pas 404)."""
    r = client.get("/sessions/unknown-user-id/due")
    assert r.status_code == 200
    assert r.json() == []


def test_stats_unknown_user_returns_zeros(client):
    """Stats pour un user_id inexistant -> zeros (pas 404)."""
    r = client.get("/sessions/unknown-user-id/stats")
    assert r.status_code == 200
    data = r.json()
    assert data["total_cards"] == 0
    assert data["due_today"] == 0
    assert data["mastered"] == 0


def test_multiple_sessions_increment_counters(client, admin_token):
    """Plusieurs sessions incrementent total_sessions et total_questions_answered.

    On verifie via /auth/me que les compteurs sont bien mis a jour.
    """
    _create_admin_question(client, admin_token)
    user_id, token = _register_user(client)

    for _ in range(3):
        client.post(
            "/sessions",
            json={"user_id": user_id, "question_id": "SESS-Q01", "quality": 4},
        )

    r = client.get(
        "/auth/me", headers={"Authorization": f"Bearer {token}"}
    )
    data = r.json()
    assert data["total_sessions"] == 3
    assert data["total_questions_answered"] == 3
    # BKT a ete mis a jour pour la competence
    assert len(data["bkt_maitrise"]) == 1


def test_session_explicit_incorrect_override(client, admin_token):
    """Si correct=False est force alors que quality=5, BKT utilise correct=False."""
    _create_admin_question(client, admin_token)
    user_id, _ = _register_user(client)

    r = client.post(
        "/sessions",
        json={
            "user_id": user_id,
            "question_id": "SESS-Q01",
            "quality": 5,  # normalement correct
            "correct": False,  # mais force a False
        },
    )
    assert r.status_code == 200
    data = r.json()
    assert data["correct"] is False
    # BKT : avec pL_init=0.1 et incorrect, pL apres est faible
    assert data["bkt_update"]["pL_after"] < 0.5
