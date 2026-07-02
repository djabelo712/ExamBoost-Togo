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


# ─── Tests complementaires (Vague 2 — Agent BW) ──────────────────────


def test_list_questions_pagination(client, admin_token):
    """La pagination limit/offset fonctionne."""
    for i in range(5):
        _seed_one_question(client, admin_token, qid=f"Q-PAGE-{i:02d}")

    # Page 1 (limit=2)
    r = client.get("/questions", params={"limit": 2, "offset": 0})
    assert r.status_code == 200
    data = r.json()
    assert data["total"] == 5
    assert len(data["items"]) == 2
    assert data["limit"] == 2
    assert data["offset"] == 0

    # Page 2
    r = client.get("/questions", params={"limit": 2, "offset": 2})
    data = r.json()
    assert len(data["items"]) == 2

    # Page 3 (dernier item)
    r = client.get("/questions", params={"limit": 2, "offset": 4})
    data = r.json()
    assert len(data["items"]) == 1


def test_list_questions_filter_by_examen(client, admin_token):
    """Filtre par examen."""
    # Une question BEPC + une BAC1
    _seed_one_question(client, admin_token, qid="Q-EXAM-BEPC")
    r = client.post(
        "/questions",
        headers={"Authorization": f"Bearer {admin_token}"},
        json={
            "id": "Q-EXAM-BAC1",
            "enonce": "Question BAC1",
            "reponse": "X",
            "matiere": "Mathematiques",
            "chapitre": "Y",
            "competence_id": "TG-M-BAC1-001",
            "examen": "BAC1",
            "serie": "C",
        },
    )
    assert r.status_code == 201

    r = client.get("/questions", params={"examen": "BAC1"})
    assert r.status_code == 200
    data = r.json()
    assert data["total"] == 1
    assert data["items"][0]["id"] == "Q-EXAM-BAC1"


def test_list_questions_filter_by_serie(client, admin_token):
    """Filtre par serie (BAC serie C)."""
    client.post(
        "/questions",
        headers={"Authorization": f"Bearer {admin_token}"},
        json={
            "id": "Q-SERIE-C",
            "enonce": "Question serie C",
            "reponse": "X",
            "matiere": "Mathematiques",
            "chapitre": "Y",
            "competence_id": "TG-M-C-001",
            "examen": "BAC1",
            "serie": "C",
        },
    )
    client.post(
        "/questions",
        headers={"Authorization": f"Bearer {admin_token}"},
        json={
            "id": "Q-SERIE-D",
            "enonce": "Question serie D",
            "reponse": "X",
            "matiere": "Mathematiques",
            "chapitre": "Y",
            "competence_id": "TG-M-D-001",
            "examen": "BAC1",
            "serie": "D",
        },
    )

    r = client.get("/questions", params={"serie": "D"})
    data = r.json()
    assert data["total"] == 1
    assert data["items"][0]["id"] == "Q-SERIE-D"


def test_list_questions_filter_by_competence(client, admin_token):
    """Filtre par competence_id."""
    _seed_one_question(client, admin_token, qid="Q-COMP-01")
    client.post(
        "/questions",
        headers={"Authorization": f"Bearer {admin_token}"},
        json={
            "id": "Q-COMP-02",
            "enonce": "Autre comp",
            "reponse": "X",
            "matiere": "Mathematiques",
            "chapitre": "Y",
            "competence_id": "TG-OTHER-COMP",
            "examen": "BEPC",
        },
    )
    r = client.get(
        "/questions",
        params={"competence_id": "TG-MATHS-ADD-001"},
    )
    data = r.json()
    assert data["total"] == 1
    assert data["items"][0]["id"] == "Q-COMP-01"


def test_list_questions_filter_by_chapitre(client, admin_token):
    """Filtre par chapitre."""
    _seed_one_question(client, admin_token, qid="Q-CHAP-01")
    client.post(
        "/questions",
        headers={"Authorization": f"Bearer {admin_token}"},
        json={
            "id": "Q-CHAP-02",
            "enonce": "Autre chapitre",
            "reponse": "X",
            "matiere": "Mathematiques",
            "chapitre": "Soustractions",
            "competence_id": "TG-MATHS-SOUS-001",
            "examen": "BEPC",
        },
    )
    r = client.get("/questions", params={"chapitre": "Additions"})
    data = r.json()
    assert data["total"] == 1
    assert data["items"][0]["id"] == "Q-CHAP-01"


def test_random_questions_with_filters(client, admin_token):
    """Tirage aleatoire avec filtres matiere + examen."""
    _seed_one_question(client, admin_token, qid="Q-RF-01")
    client.post(
        "/questions",
        headers={"Authorization": f"Bearer {admin_token}"},
        json={
            "id": "Q-RF-02",
            "enonce": "FR random",
            "reponse": "X",
            "matiere": "Francais",
            "chapitre": "Y",
            "competence_id": "TG-FR-RAND",
            "examen": "BEPC",
        },
    )
    r = client.get(
        "/questions/random/list",
        params={"n": 10, "matiere": "Francais", "examen": "BEPC"},
    )
    assert r.status_code == 200
    data = r.json()
    # On ne doit recevoir QUE des questions Francais
    for q in data:
        assert q["matiere"] == "Francais"


def test_create_question_duplicate_id_returns_409(client, admin_token):
    """Creation avec un ID deja existant -> 409."""
    _seed_one_question(client, admin_token, qid="Q-DUP-01")
    r = client.post(
        "/questions",
        headers={"Authorization": f"Bearer {admin_token}"},
        json={
            "id": "Q-DUP-01",  # deja pris
            "enonce": "Question dupliquee",
            "reponse": "X",
            "matiere": "Mathematiques",
            "chapitre": "Y",
            "competence_id": "TG-DUP",
            "examen": "BEPC",
        },
    )
    assert r.status_code == 409


def test_create_question_unauthenticated_returns_401(client):
    """Creation sans token -> 401."""
    r = client.post(
        "/questions",
        json={
            "id": "Q-NOAUTH",
            "enonce": "Sans auth",
            "reponse": "X",
            "matiere": "Mathematiques",
            "chapitre": "Y",
            "competence_id": "TG-NOAUTH",
            "examen": "BEPC",
        },
    )
    assert r.status_code == 401


def test_create_question_with_auto_id(client, admin_token):
    """Si l'ID n'est pas fourni, le serveur en genere un."""
    r = client.post(
        "/questions",
        headers={"Authorization": f"Bearer {admin_token}"},
        json={
            # pas d'ID
            "enonce": "Question avec ID auto",
            "reponse": "42",
            "matiere": "Mathematiques",
            "chapitre": "Auto",
            "competence_id": "TG-AUTO",
            "examen": "BEPC",
        },
    )
    assert r.status_code == 201
    qid = r.json()["id"]
    assert qid.startswith("TG-BEPC-MAT-")  # prefixe genere


def test_list_questions_invalid_limit_returns_422(client):
    """limit=0 -> 422 (ge=1)."""
    r = client.get("/questions", params={"limit": 0})
    assert r.status_code == 422


def test_list_questions_invalid_offset_returns_422(client):
    """offset=-1 -> 422 (ge=0)."""
    r = client.get("/questions", params={"offset": -1})
    assert r.status_code == 422


def test_random_questions_max_n_enforced(client):
    """n > 100 -> 422 (le=100)."""
    r = client.get("/questions/random/list", params={"n": 101})
    assert r.status_code == 422


def test_random_questions_empty_returns_empty_list(client):
    """Tirage aleatoire sur banque vide -> liste vide (pas d'erreur)."""
    r = client.get("/questions/random/list", params={"n": 5})
    assert r.status_code == 200
    assert r.json() == []


def test_get_question_irt_params_serialized(client, admin_token):
    """Les parametres IRT sont bien serialises dans la reponse."""
    _seed_one_question(client, admin_token, qid="Q-IRT-01")
    r = client.get("/questions/Q-IRT-01")
    data = r.json()
    assert data["irt"]["a"] == 1.0
    assert data["irt"]["b"] == -1.0
    assert data["irt"]["c"] == 0.0
    assert data["irt"]["calibre"] is True


def test_list_questions_returns_correct_total_count(client, admin_token):
    """Le total reflète le nombre de questions matchant les filtres."""
    for i in range(3):
        _seed_one_question(client, admin_token, qid=f"Q-COUNT-{i:02d}")
    # 3 questions en Mathematiques
    r = client.get("/questions", params={"matiere": "Mathematiques"})
    assert r.json()["total"] == 3
    # Filtre sur une matiere inexistante
    r = client.get("/questions", params={"matiere": "Sciences"})
    assert r.json()["total"] == 0
    assert r.json()["items"] == []
