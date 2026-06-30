"""tests/test_questions.py — Tests du router /questions."""

from __future__ import annotations


def _seed_one_question(client, admin_token, qid="TG-BEPC-MATHS-2024-Q01"):
    response = client.post(
        "/questions",
        headers={"Authorization": f"Bearer {admin_token}"},
        json={
            "id": qid,
            "enonce": "Combien font 2 + 2 ?",
            "reponse": "4",
            "explication": "Addition elementaire.",
            "matiere": "Mathematiques",
            "chapitre": "Additions",
            "competence_id": "TG-MATHS-ADD-001",
            "examen": "BEPC",
            "type": "calcul",
            "points": 2,
            "irt": {"a": 1.0, "b": -1.0, "c": 0.0, "calibre": True},
        },
    )
    return response


def test_create_question_admin(client, admin_token):
    """Admin peut creer une question."""
    response = _seed_one_question(client, admin_token)
    assert response.status_code == 201, response.text
    data = response.json()
    assert data["id"] == "TG-BEPC-MATHS-2024-Q01"
    assert data["matiere"] == "Mathematiques"
    assert data["irt"]["b"] == -1.0
    assert data["irt"]["calibre"] is True


def test_create_question_forbidden_for_student(client, admin_token):
    """Un eleve non-admin ne peut pas creer de question.

    On cree d'abord un admin (premier inscrit), puis un eleve normal.
    """
    # Inscription d'un eleve (le deuxieme inscrit n'est pas admin)
    r_student = client.post(
        "/auth/register",
        json={
            "email": "eleve2@test.tg",
            "password": "password123",
            "nom": "Eleve",
            "prenom": "Test",
            "niveau_scolaire": "3eme",
        },
    )
    assert r_student.status_code == 201
    student_token = r_student.json()["access_token"]

    # Tentative de creation -> 403 (l'eleve n'est pas admin)
    response = client.post(
        "/questions",
        headers={"Authorization": f"Bearer {student_token}"},
        json={
            "id": "FORBIDDEN-01",
            "enonce": "Question interdite pour un eleve",
            "reponse": "Y",
            "matiere": "Mathematiques",
            "chapitre": "X",
            "competence_id": "X",
            "examen": "BEPC",
        },
    )
    assert response.status_code == 403


def test_list_questions_empty(client):
    """Liste vide au depart."""
    response = client.get("/questions")
    assert response.status_code == 200
    data = response.json()
    assert data["items"] == []
    assert data["total"] == 0


def test_list_questions_with_filter(client, admin_token):
    """On filtre par matiere."""
    _seed_one_question(client, admin_token, qid="Q-MATHS-01")
    # Une deuxieme question dans une autre matiere
    client.post(
        "/questions",
        headers={"Authorization": f"Bearer {admin_token}"},
        json={
            "id": "Q-FR-01",
            "enonce": "Quelle figure de style ?",
            "reponse": "Metaphore",
            "matiere": "Francais",
            "chapitre": "Figures de style",
            "competence_id": "TG-FR-FIG-001",
            "examen": "BEPC",
        },
    )

    # Filtre maths
    r = client.get("/questions", params={"matiere": "Mathematiques"})
    assert r.status_code == 200
    data = r.json()
    assert data["total"] == 1
    assert data["items"][0]["id"] == "Q-MATHS-01"

    # Filtre francais
    r = client.get("/questions", params={"matiere": "Francais"})
    data = r.json()
    assert data["total"] == 1
    assert data["items"][0]["id"] == "Q-FR-01"


def test_get_question_by_id(client, admin_token):
    """Recuperation par ID."""
    _seed_one_question(client, admin_token, qid="Q-DETAIL-01")
    r = client.get("/questions/Q-DETAIL-01")
    assert r.status_code == 200
    assert r.json()["id"] == "Q-DETAIL-01"


def test_get_question_not_found(client):
    """404 si question inexistante."""
    r = client.get("/questions/DOES-NOT-EXIST")
    assert r.status_code == 404


def test_random_questions(client, admin_token):
    """Tirage aleatoire."""
    for i in range(5):
        _seed_one_question(client, admin_token, qid=f"Q-RAND-{i:02d}")
    r = client.get("/questions/random/list", params={"n": 3})
    assert r.status_code == 200
    data = r.json()
    assert len(data) <= 3
    assert len(data) >= 1
