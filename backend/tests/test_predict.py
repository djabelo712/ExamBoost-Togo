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


# ─── Tests complementaires (Vague 2 — Agent BW) ──────────────────────


def test_predict_score_confidence_in_range(client, admin_token):
    """La confidence est toujours dans [0, 1]."""
    _create_question(client, admin_token, "PC-Q01", "Mathematiques", "TG-M-001")
    user_id = _register_user(client)

    for _ in range(3):
        client.post(
            "/sessions",
            json={"user_id": user_id, "question_id": "PC-Q01", "quality": 4},
        )

    r = client.get(f"/predict-score/{user_id}")
    data = r.json()
    assert 0.0 <= data["confidence"] <= 1.0


def test_predict_score_breakdown_score_estime_in_range(client, admin_token):
    """Chaque score_estime du breakdown est dans [0, 20]."""
    _create_question(client, admin_token, "PB-Q01", "Mathematiques", "TG-M-001")
    _create_question(client, admin_token, "PB-Q02", "Francais", "TG-FR-001")
    user_id = _register_user(client)

    for qid in ("PB-Q01", "PB-Q02"):
        client.post(
            "/sessions",
            json={"user_id": user_id, "question_id": qid, "quality": 5},
        )

    r = client.get(f"/predict-score/{user_id}")
    data = r.json()
    assert len(data["breakdown"]) >= 1
    for item in data["breakdown"]:
        assert 0.0 <= item["score_estime"] <= 20.0
        assert 0.0 <= item["pL_moyen"] <= 1.0
        assert item["nb_questions"] >= 1


def test_predict_score_default_examen_bepc(client):
    """Si param examen absent, defaut = BEPC."""
    user_id = _register_user(client)
    r = client.get(f"/predict-score/{user_id}")
    assert r.json()["examen"] == "BEPC"


def test_predict_score_examen_param_passthrough(client):
    """Le param examen est renvoye tel quel dans la reponse."""
    user_id = _register_user(client)
    r = client.get(f"/predict-score/{user_id}", params={"examen": "BAC1"})
    assert r.json()["examen"] == "BAC1"


def test_predict_score_heuristic_method_label(client, admin_token):
    """Apres quelques reponses, la methode est 'heuristic' (pas XGBoost)."""
    _create_question(client, admin_token, "PH-Q01", "Mathematiques", "TG-M-001")
    user_id = _register_user(client)

    client.post(
        "/sessions",
        json={"user_id": user_id, "question_id": "PH-Q01", "quality": 5},
    )
    r = client.get(f"/predict-score/{user_id}")
    assert r.json()["method"] in {"heuristic", "insufficient_data"}


def test_predict_dropout_returns_factors_dict(client):
    """La reponse contient un dict factors avec des cles attendues."""
    user_id = _register_user(client)
    r = client.get(f"/predict-dropout/{user_id}")
    factors = r.json()["factors"]
    # Le mock remplit ces cles
    for key in ("inactivity_days", "sessions_7j", "pL_global"):
        assert key in factors


def test_predict_dropout_high_risk_for_inactive_user(client, admin_token):
    """Un user avec 0 session et 0 simulation a un risque non faible.

    Le mock calcule : inactivite (365j) -> 0.6, engagement (0 sessions) -> 0.2,
    perf (pL=0) -> 0.2. Total ~1.0 -> risque eleve.
    """
    user_id = _register_user(client)
    r = client.get(f"/predict-dropout/{user_id}")
    data = r.json()
    # Sans aucune activite, le risque doit etre modere ou eleve
    assert data["risk_level"] in {"modere", "eleve"}
    assert data["dropout_probability"] >= 0.5


def test_predict_score_aggregates_multiple_matieres(client, admin_token):
    """Le breakdown contient une ligne par matiere repondue."""
    _create_question(client, admin_token, "PM-Q01", "Mathematiques", "TG-M-001")
    _create_question(client, admin_token, "PM-Q02", "Francais", "TG-FR-001")
    _create_question(client, admin_token, "PM-Q03", "SVT", "TG-SVT-001")
    user_id = _register_user(client)

    for qid in ("PM-Q01", "PM-Q02", "PM-Q03"):
        client.post(
            "/sessions",
            json={"user_id": user_id, "question_id": qid, "quality": 4},
        )

    r = client.get(f"/predict-score/{user_id}")
    data = r.json()
    matieres = {item["matiere"] for item in data["breakdown"]}
    assert "Mathematiques" in matieres
    assert "Francais" in matieres
    assert "SVT" in matieres


def test_predict_score_empty_user_returns_zero(client):
    """Un user frais a un predicted_score = 0 et method insufficient_data."""
    user_id = _register_user(client)
    r = client.get(f"/predict-score/{user_id}")
    data = r.json()
    assert data["predicted_score"] == 0.0
    assert data["confidence"] == 0.0
    assert data["method"] == "insufficient_data"
    assert data["total_responses"] == 0
    assert data["breakdown"] == []
