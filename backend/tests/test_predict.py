"""tests/test_predict.py — Tests du router /predict (score + dropout)."""

from __future__ import annotations


def _register_user(client, email="pred@test.tg"):
    r = client.post(
        "/auth/register",
        json={
            "email": email,
            "password": "password123",
            "nom": "Pred",
            "prenom": "Test",
            "niveau_scolaire": "Terminale",
            "serie": "C",
        },
    )
    assert r.status_code == 201
    return r.json()["user_id"]


def _create_question(client, admin_token, qid, matiere, comp):
    r = client.post(
        "/questions",
        headers={"Authorization": f"Bearer {admin_token}"},
        json={
            "id": qid,
            "enonce": f"Question {qid}",
            "reponse": "42",
            "matiere": matiere,
            "chapitre": "Test",
            "competence_id": comp,
            "examen": "BEPC",
        },
    )
    assert r.status_code == 201


def test_predict_score_insufficient_data(client):
    """Sans aucune reponse, la methode est 'insufficient_data'."""
    user_id = _register_user(client)
    r = client.get(f"/predict-score/{user_id}", params={"examen": "BEPC"})
    assert r.status_code == 200
    data = r.json()
    assert data["method"] == "insufficient_data"
    assert data["predicted_score"] == 0.0
    assert data["total_responses"] == 0
    assert data["breakdown"] == []


def test_predict_score_heuristic_after_responses(client, admin_token):
    """Avec quelques reponses, on bascule en heuristique."""
    _create_question(client, admin_token, "PRED-Q01", "Mathematiques", "TG-M-001")
    _create_question(client, admin_token, "PRED-Q02", "Mathematiques", "TG-M-001")
    user_id = _register_user(client)

    for qid in ("PRED-Q01", "PRED-Q02"):
        r = client.post(
            "/sessions",
            json={"user_id": user_id, "question_id": qid, "quality": 5},
        )
        assert r.status_code == 200

    r = client.get(f"/predict-score/{user_id}", params={"examen": "BEPC"})
    assert r.status_code == 200
    data = r.json()
    assert data["method"] == "heuristic"
    assert 0.0 <= data["predicted_score"] <= 20.0
    assert data["total_responses"] == 2
    assert len(data["breakdown"]) >= 1
    assert data["breakdown"][0]["matiere"] == "Mathematiques"


def test_predict_score_user_not_found(client):
    """404 si user_id inconnu."""
    r = client.get("/predict-score/user-inexistant")
    assert r.status_code == 404


def test_predict_dropout_returns_valid_risk(client):
    """Le risque est dans {faible, modere, eleve} et la proba dans [0, 1]."""
    user_id = _register_user(client)
    r = client.get(f"/predict-dropout/{user_id}")
    assert r.status_code == 200
    data = r.json()
    assert data["risk_level"] in {"faible", "modere", "eleve"}
    assert 0.0 <= data["dropout_probability"] <= 1.0
    assert "factors" in data
    assert isinstance(data["factors"], dict)


def test_predict_dropout_user_not_found(client):
    """404 si user_id inconnu."""
    r = client.get("/predict-dropout/user-inexistant")
    assert r.status_code == 404
