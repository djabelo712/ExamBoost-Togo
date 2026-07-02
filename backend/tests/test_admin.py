"""tests/test_admin.py — Tests du router /admin (gestion contenu).

Couverture :
    - GET    /admin/questions              : liste paginee + filtres
    - GET    /admin/questions/{id}         : detail
    - POST   /admin/questions              : creation
    - PUT    /admin/questions/{id}         : mise a jour
    - DELETE /admin/questions/{id}         : suppression
    - POST   /admin/questions/batch-import : import batch (JSON)
    - POST   /admin/questions/batch-export : export (JSON/CSV)
    - POST   /admin/questions/upload-json  : upload fichier JSON
    - GET    /admin/stats                  : stats contenu
    - GET    /admin/logs                   : logs actions admin
    - 403 si user non-admin, 401 si non authentifie
    - Validation metier : examen/serie, QCM, vraiFaux
"""

from __future__ import annotations

import io
import json


# ─── Helpers ──────────────────────────────────────────────────────────
def _auth(token: str) -> dict:
    return {"Authorization": f"Bearer {token}"}


def _register_student(client, email="student@examboost.tg"):
    """Inscrit un eleve NON admin (apres l'admin token fixture)."""
    r = client.post(
        "/auth/register",
        json={
            "email": email,
            "password": "password123",
            "nom": "Student",
            "prenom": "Test",
            "niveau_scolaire": "3eme",
        },
    )
    assert r.status_code == 201
    return r.json()["access_token"]


def _valid_question_payload(qid="TG-BEPC-MATHS-2024-Q01", **overrides) -> dict:
    """Retourne un payload de question valide pour /admin/questions."""
    base = {
        "id": qid,
        "enonce": "Calculer la somme de 25 et 17.",  # >= 10 chars
        "reponse": "42",
        "explication": "Addition elementaire.",
        "matiere": "Mathematiques",
        "chapitre": "Additions",
        "competence_id": "TG-MATHS-ADD-001",
        "examen": "BEPC",
        "type": "calcul",
        "points": 2,
        "irt_a": 1.0,
        "irt_b": -1.0,
        "irt_c": 0.0,
    }
    base.update(overrides)
    return base


# ─── 403 / 401 — Auth admin requise ───────────────────────────────────
def test_admin_endpoints_require_auth(client):
    """Sans token -> 401 sur tous les endpoints admin."""
    endpoints = [
        ("GET", "/admin/questions"),
        ("GET", "/admin/questions/SOME-ID"),
        ("POST", "/admin/questions"),
        ("PUT", "/admin/questions/SOME-ID"),
        ("DELETE", "/admin/questions/SOME-ID"),
        ("POST", "/admin/questions/batch-import"),
        ("POST", "/admin/questions/batch-export"),
        ("GET", "/admin/stats"),
        ("GET", "/admin/logs"),
    ]
    for method, path in endpoints:
        r = client.request(method, path, json={})
        assert r.status_code == 401, f"{method} {path} -> {r.status_code}"


def test_admin_endpoints_forbidden_for_student(client, admin_token):
    """Un eleve non-admin recoit 403 sur tous les endpoints admin."""
    student_token = _register_student(client)
    r = client.get("/admin/questions", headers=_auth(student_token))
    assert r.status_code == 403

    r = client.get("/admin/stats", headers=_auth(student_token))
    assert r.status_code == 403

    r = client.get("/admin/logs", headers=_auth(student_token))
    assert r.status_code == 403


# ─── POST /admin/questions — Creation ─────────────────────────────────
def test_admin_create_question_success(client, admin_token):
    """L'admin peut creer une question valide."""
    r = client.post(
        "/admin/questions",
        headers=_auth(admin_token),
        json=_valid_question_payload(),
    )
    assert r.status_code == 201, r.text
    data = r.json()
    assert data["id"] == "TG-BEPC-MATHS-2024-Q01"
    assert data["irt_a"] == 1.0
    assert data["irt_calibrated"] is False  # non calibre par defaut


def test_admin_create_qcm_with_4_choices(client, admin_token):
    """Un QCM valide (4 choix, reponse dans choix) est cree."""
    payload = _valid_question_payload(
        qid="TG-BEPC-MATHS-2024-Q02",
        enonce="Quelle est la racine carree de 16 ?",
        reponse="4",
        type="qcm",
        choix=["2", "4", "8", "16"],
    )
    r = client.post("/admin/questions", headers=_auth(admin_token), json=payload)
    assert r.status_code == 201
    assert r.json()["type"] == "qcm"
    assert r.json()["choix"] == ["2", "4", "8", "16"]


def test_admin_create_qcm_with_3_choices_returns_400(client, admin_token):
    """Un QCM avec seulement 3 choix -> 400 (validation metier)."""
    payload = _valid_question_payload(
        qid="TG-BEPC-MATHS-2024-Q03",
        enonce="Quelle est la racine carree de 16 ?",
        reponse="4",
        type="qcm",
        choix=["2", "4", "8"],  # seulement 3
    )
    r = client.post("/admin/questions", headers=_auth(admin_token), json=payload)
    assert r.status_code == 400


def test_admin_create_qcm_with_bad_answer_returns_400(client, admin_token):
    """Un QCM avec reponse absente des choix -> 400."""
    payload = _valid_question_payload(
        qid="TG-BEPC-MATHS-2024-Q04",
        enonce="Quelle est la racine carree de 16 ?",
        reponse="99",  # pas dans les choix
        type="qcm",
        choix=["2", "4", "8", "16"],
    )
    r = client.post("/admin/questions", headers=_auth(admin_token), json=payload)
    assert r.status_code == 400


def test_admin_create_vraifaux_valid(client, admin_token):
    """Un vraiFaux avec reponse 'Vrai' est accepte."""
    payload = _valid_question_payload(
        qid="TG-BEPC-SVT-2024-Q01",
        enonce="La Terre tourne autour du Soleil.",
        reponse="Vrai",
        type="vraiFaux",
        matiere="SVT",
        competence_id="TG-SVT-ASTRO-001",
    )
    r = client.post("/admin/questions", headers=_auth(admin_token), json=payload)
    assert r.status_code == 201


def test_admin_create_vraifaux_invalid_answer_returns_400(client, admin_token):
    """Un vraiFaux avec reponse non ('Vrai'/'Faux') -> 400."""
    payload = _valid_question_payload(
        qid="TG-BEPC-SVT-2024-Q02",
        enonce="La Terre tourne autour du Soleil.",
        reponse="Peut-etre",
        type="vraiFaux",
        matiere="SVT",
        competence_id="TG-SVT-ASTRO-002",
    )
    r = client.post("/admin/questions", headers=_auth(admin_token), json=payload)
    assert r.status_code == 400


def test_admin_create_bac_with_serie(client, admin_token):
    """Une question BAC1 avec serie C est valide."""
    payload = _valid_question_payload(
        qid="TG-BAC1-MATHS-2024-Q01",
        enonce="Resoudre l'equation differentielle y' + y = 0.",
        reponse="y = C * exp(-x)",
        type="calcul",
        examen="BAC1",
        serie="C",
    )
    r = client.post("/admin/questions", headers=_auth(admin_token), json=payload)
    assert r.status_code == 201


def test_admin_create_bac_without_serie_returns_400(client, admin_token):
    """Une question BAC1 sans serie -> 400 (serie obligatoire)."""
    payload = _valid_question_payload(
        qid="TG-BAC1-MATHS-2024-Q02",
        enonce="Resoudre l'equation differentielle.",
        reponse="y = C * exp(-x)",
        type="calcul",
        examen="BAC1",
        # pas de serie
    )
    r = client.post("/admin/questions", headers=_auth(admin_token), json=payload)
    assert r.status_code == 400


def test_admin_create_bepc_with_serie_returns_400(client, admin_token):
    """Une question BEPC avec serie -> 400 (BEPC n'a pas de serie)."""
    payload = _valid_question_payload(
        qid="TG-BEPC-MATHS-2024-Q05",
        enonce="Calculer 2 + 2.",
        reponse="4",
        type="calcul",
        examen="BEPC",
        serie="C",  # BEPC ne doit pas avoir de serie
    )
    r = client.post("/admin/questions", headers=_auth(admin_token), json=payload)
    assert r.status_code == 400


def test_admin_create_unknown_examen_returns_400(client, admin_token):
    """Un examen hors liste valide -> 400."""
    payload = _valid_question_payload(
        qid="TG-XXX-MATHS-2024-Q01",
        enonce="Question examen inexistant.",
        reponse="X",
        type="calcul",
        examen="XXX",
    )
    r = client.post("/admin/questions", headers=_auth(admin_token), json=payload)
    assert r.status_code == 400


def test_admin_create_unknown_type_returns_400(client, admin_token):
    """Un type hors liste valide -> 400."""
    payload = _valid_question_payload(
        qid="TG-BEPC-MATHS-2024-Q06",
        enonce="Question type invalide.",
        reponse="X",
        type="qcm_vrai",  # type inconnu
    )
    r = client.post("/admin/questions", headers=_auth(admin_token), json=payload)
    assert r.status_code == 400


def test_admin_create_duplicate_id_returns_400(client, admin_token):
    """Une question avec ID deja existant -> 400."""
    payload = _valid_question_payload()
    client.post("/admin/questions", headers=_auth(admin_token), json=payload)
    r = client.post("/admin/questions", headers=_auth(admin_token), json=payload)
    assert r.status_code == 400


def test_admin_create_short_enonce_returns_422(client, admin_token):
    """Enonce < 10 caracteres -> 422 (validation Pydantic)."""
    payload = _valid_question_payload(enonce="Court")  # 5 chars
    r = client.post("/admin/questions", headers=_auth(admin_token), json=payload)
    assert r.status_code == 422


# ─── GET /admin/questions — Liste ─────────────────────────────────────
def test_admin_list_questions_empty(client, admin_token):
    """Liste vide au depart."""
    r = client.get("/admin/questions", headers=_auth(admin_token))
    assert r.status_code == 200
    data = r.json()
    assert data["items"] == []
    assert data["total"] == 0


def test_admin_list_questions_with_filters(client, admin_token):
    """Filtre par matiere + examen."""
    client.post(
        "/admin/questions",
        headers=_auth(admin_token),
        json=_valid_question_payload(qid="ADM-Q01"),
    )
    client.post(
        "/admin/questions",
        headers=_auth(admin_token),
        json=_valid_question_payload(
            qid="ADM-Q02",
            enonce="Question sur les fractions",
            matiere="Francais",
            competence_id="TG-FR-FRAC-001",
        ),
    )

    r = client.get(
        "/admin/questions",
        headers=_auth(admin_token),
        params={"matiere": "Mathematiques"},
    )
    data = r.json()
    assert data["total"] == 1
    assert data["items"][0]["id"] == "ADM-Q01"


def test_admin_list_questions_with_recherche(client, admin_token):
    """Recherche full-text dans l'enonce."""
    client.post(
        "/admin/questions",
        headers=_auth(admin_token),
        json=_valid_question_payload(
            qid="ADM-SEARCH-01",
            enonce="Calculer l'aire d'un triangle rectangle.",
        ),
    )
    client.post(
        "/admin/questions",
        headers=_auth(admin_token),
        json=_valid_question_payload(
            qid="ADM-SEARCH-02",
            enonce="Quelle est la capitale du Togo ?",
            matiere="Histoire",
            competence_id="TG-HIST-CAP-001",
        ),
    )

    r = client.get(
        "/admin/questions",
        headers=_auth(admin_token),
        params={"recherche": "triangle"},
    )
    data = r.json()
    assert data["total"] == 1
    assert data["items"][0]["id"] == "ADM-SEARCH-01"


# ─── GET /admin/questions/{id} — Detail ───────────────────────────────
def test_admin_get_question_detail(client, admin_token):
    """Recuperation d'une question par ID."""
    client.post(
        "/admin/questions",
        headers=_auth(admin_token),
        json=_valid_question_payload(qid="ADM-DETAIL-01"),
    )
    r = client.get("/admin/questions/ADM-DETAIL-01", headers=_auth(admin_token))
    assert r.status_code == 200
    assert r.json()["id"] == "ADM-DETAIL-01"


def test_admin_get_question_not_found(client, admin_token):
    """404 si ID inexistant."""
    r = client.get("/admin/questions/UNKNOWN-ID", headers=_auth(admin_token))
    assert r.status_code == 404


# ─── PUT /admin/questions/{id} — Update ───────────────────────────────
def test_admin_update_question(client, admin_token):
    """Mise a jour partielle d'une question."""
    client.post(
        "/admin/questions",
        headers=_auth(admin_token),
        json=_valid_question_payload(qid="ADM-UPD-01"),
    )
    r = client.put(
        "/admin/questions/ADM-UPD-01",
        headers=_auth(admin_token),
        json={"points": 4, "explication": "Nouvelle explication"},
    )
    assert r.status_code == 200
    data = r.json()
    assert data["points"] == 4
    assert data["explication"] == "Nouvelle explication"


def test_admin_update_question_not_found(client, admin_token):
    """Update d'une question inexistante -> 404."""
    r = client.put(
        "/admin/questions/UNKNOWN",
        headers=_auth(admin_token),
        json={"points": 4},
    )
    assert r.status_code == 404


def test_admin_update_irt_calibration_flag(client, admin_token):
    """Le flag irt_calibrated peut etre mis a jour."""
    client.post(
        "/admin/questions",
        headers=_auth(admin_token),
        json=_valid_question_payload(qid="ADM-IRT-01"),
    )
    r = client.put(
        "/admin/questions/ADM-IRT-01",
        headers=_auth(admin_token),
        json={"irt_calibrated": True, "irt_a": 1.5, "irt_b": 0.5, "irt_c": 0.15},
    )
    assert r.status_code == 200
    data = r.json()
    assert data["irt_calibrated"] is True
    assert data["irt_a"] == 1.5


# ─── DELETE /admin/questions/{id} ─────────────────────────────────────
def test_admin_delete_question(client, admin_token):
    """Suppression d'une question."""
    client.post(
        "/admin/questions",
        headers=_auth(admin_token),
        json=_valid_question_payload(qid="ADM-DEL-01"),
    )
    r = client.delete("/admin/questions/ADM-DEL-01", headers=_auth(admin_token))
    assert r.status_code == 200
    # La question n'existe plus
    r2 = client.get("/admin/questions/ADM-DEL-01", headers=_auth(admin_token))
    assert r2.status_code == 404


def test_admin_delete_question_not_found(client, admin_token):
    """Delete d'une question inexistante -> 404."""
    r = client.delete("/admin/questions/UNKNOWN", headers=_auth(admin_token))
    assert r.status_code == 404


# ─── POST /admin/questions/batch-import ───────────────────────────────
def test_admin_batch_import_creates_questions(client, admin_token):
    """Import batch de 2 questions."""
    questions = [
        _valid_question_payload(qid="ADM-BI-01"),
        _valid_question_payload(
            qid="ADM-BI-02",
            enonce="Question sur les fractions",
            matiere="Francais",
            competence_id="TG-FR-FRAC-001",
        ),
    ]
    r = client.post(
        "/admin/questions/batch-import",
        headers=_auth(admin_token),
        json={"questions": questions, "overwrite_existing": False},
    )
    assert r.status_code == 200
    data = r.json()
    assert data["created"] == 2
    assert data["updated"] == 0
    assert data["skipped"] == 0
    assert data["errors"] == []


def test_admin_batch_import_skips_existing(client, admin_token):
    """Import batch avec overwrite=False skip les existantes."""
    # Cree une 1ere fois
    client.post(
        "/admin/questions",
        headers=_auth(admin_token),
        json=_valid_question_payload(qid="ADM-BI-SKIP"),
    )
    # Tentative d'import de la meme
    r = client.post(
        "/admin/questions/batch-import",
        headers=_auth(admin_token),
        json={
            "questions": [_valid_question_payload(qid="ADM-BI-SKIP")],
            "overwrite_existing": False,
        },
    )
    data = r.json()
    assert data["created"] == 0
    assert data["skipped"] == 1


def test_admin_batch_import_overwrite_updates(client, admin_token):
    """Import batch avec overwrite=True met a jour les existantes."""
    client.post(
        "/admin/questions",
        headers=_auth(admin_token),
        json=_valid_question_payload(qid="ADM-BI-OW"),
    )
    r = client.post(
        "/admin/questions/batch-import",
        headers=_auth(admin_token),
        json={
            "questions": [
                _valid_question_payload(
                    qid="ADM-BI-OW",
                    enonce="Question mise a jour par import batch",
                )
            ],
            "overwrite_existing": True,
        },
    )
    data = r.json()
    assert data["updated"] == 1
    assert data["created"] == 0


# ─── POST /admin/questions/batch-export ───────────────────────────────
def test_admin_batch_export_json(client, admin_token):
    """Export JSON de toutes les questions."""
    client.post(
        "/admin/questions",
        headers=_auth(admin_token),
        json=_valid_question_payload(qid="ADM-EXP-01"),
    )
    r = client.post(
        "/admin/questions/batch-export",
        headers=_auth(admin_token),
        json={"format": "json"},
    )
    assert r.status_code == 200
    data = r.json()
    assert data["format"] == "json"
    assert data["count"] >= 1
    # Le content est une string JSON valide
    parsed = json.loads(data["content"])
    assert isinstance(parsed, list)
    assert any(q["id"] == "ADM-EXP-01" for q in parsed)


def test_admin_batch_export_csv(client, admin_token):
    """Export CSV des questions."""
    client.post(
        "/admin/questions",
        headers=_auth(admin_token),
        json=_valid_question_payload(qid="ADM-EXP-CSV"),
    )
    r = client.post(
        "/admin/questions/batch-export",
        headers=_auth(admin_token),
        json={"format": "csv"},
    )
    assert r.status_code == 200
    data = r.json()
    assert data["format"] == "csv"
    assert data["count"] >= 1
    # Le content est du CSV (1ere ligne = header)
    lines = data["content"].strip().split("\n")
    assert "id" in lines[0].lower()


def test_admin_batch_export_invalid_format_returns_400(client, admin_token):
    """Format non supporte -> 400."""
    r = client.post(
        "/admin/questions/batch-export",
        headers=_auth(admin_token),
        json={"format": "xml"},
    )
    assert r.status_code == 400


def test_admin_batch_export_with_filters(client, admin_token):
    """Export avec filtres (matiere)."""
    client.post(
        "/admin/questions",
        headers=_auth(admin_token),
        json=_valid_question_payload(qid="ADM-EXP-F1"),
    )
    client.post(
        "/admin/questions",
        headers=_auth(admin_token),
        json=_valid_question_payload(
            qid="ADM-EXP-F2",
            enonce="Question en francais",
            matiere="Francais",
            competence_id="TG-FR-001",
        ),
    )
    r = client.post(
        "/admin/questions/batch-export",
        headers=_auth(admin_token),
        json={"format": "json", "filters": {"matiere": "Mathematiques"}},
    )
    data = r.json()
    assert data["count"] == 1
    parsed = json.loads(data["content"])
    assert parsed[0]["id"] == "ADM-EXP-F1"


# ─── POST /admin/questions/upload-json ────────────────────────────────
def test_admin_upload_json_file(client, admin_token):
    """Upload d'un fichier JSON de questions."""
    questions = [_valid_question_payload(qid="ADM-UP-01")]
    file_content = json.dumps(questions).encode("utf-8")
    r = client.post(
        "/admin/questions/upload-json",
        headers=_auth(admin_token),
        files={"file": ("questions.json", file_content, "application/json")},
    )
    assert r.status_code == 200
    data = r.json()
    assert data["created"] == 1


def test_admin_upload_json_invalid_extension(client, admin_token):
    """Upload d'un fichier non .json -> 400."""
    r = client.post(
        "/admin/questions/upload-json",
        headers=_auth(admin_token),
        files={"file": ("questions.txt", b"...", "text/plain")},
    )
    assert r.status_code == 400


def test_admin_upload_json_invalid_json(client, admin_token):
    """Upload d'un fichier JSON invalide -> 400."""
    r = client.post(
        "/admin/questions/upload-json",
        headers=_auth(admin_token),
        files={"file": ("bad.json", b"not json", "application/json")},
    )
    assert r.status_code == 400


def test_admin_upload_json_not_array(client, admin_token):
    """Upload d'un JSON qui n'est pas un tableau -> 400."""
    r = client.post(
        "/admin/questions/upload-json",
        headers=_auth(admin_token),
        files={"file": ("obj.json", b'{"key": "value"}', "application/json")},
    )
    assert r.status_code == 400


# ─── GET /admin/stats ─────────────────────────────────────────────────
def test_admin_stats_empty_db(client, admin_token):
    """Stats sur base vide : total=0, pas de doublons."""
    r = client.get("/admin/stats", headers=_auth(admin_token))
    assert r.status_code == 200
    data = r.json()
    assert data["total_questions"] == 0
    assert data["irt_calibrated_count"] == 0
    assert data["irt_calibrated_percent"] == 0.0
    assert data["questions_without_explanation"] == 0
    assert data["duplicate_warnings"] == []


def test_admin_stats_after_questions(client, admin_token):
    """Stats apres creation de questions."""
    client.post(
        "/admin/questions",
        headers=_auth(admin_token),
        json=_valid_question_payload(qid="ADM-STAT-01", explication=None),
    )
    client.post(
        "/admin/questions",
        headers=_auth(admin_token),
        json=_valid_question_payload(
            qid="ADM-STAT-02",
            enonce="Question en francais",
            matiere="Francais",
            competence_id="TG-FR-001",
        ),
    )
    r = client.get("/admin/stats", headers=_auth(admin_token))
    data = r.json()
    assert data["total_questions"] == 2
    assert "Mathematiques" in data["by_matiere"]
    assert "Francais" in data["by_matiere"]
    assert data["by_matiere"]["Mathematiques"] == 1
    assert data["by_matiere"]["Francais"] == 1
    assert "BEPC" in data["by_examen"]
    # 1 question sans explication (ADM-STAT-01)
    assert data["questions_without_explanation"] == 1


def test_admin_stats_calibrated_count(client, admin_token):
    """Le taux de calibration IRT est correct."""
    client.post(
        "/admin/questions",
        headers=_auth(admin_token),
        json=_valid_question_payload(qid="ADM-CAL-01"),
    )
    # Marque la question comme calibree
    client.put(
        "/admin/questions/ADM-CAL-01",
        headers=_auth(admin_token),
        json={"irt_calibrated": True},
    )
    r = client.get("/admin/stats", headers=_auth(admin_token))
    data = r.json()
    assert data["irt_calibrated_count"] == 1
    assert data["irt_calibrated_percent"] == 100.0


# ─── GET /admin/logs ──────────────────────────────────────────────────
def test_admin_logs_returns_list(client, admin_token):
    """GET /admin/logs renvoie une liste (vide au depart ou non)."""
    # Cree une question pour generer un log
    client.post(
        "/admin/questions",
        headers=_auth(admin_token),
        json=_valid_question_payload(qid="ADM-LOG-01"),
    )
    r = client.get("/admin/logs", headers=_auth(admin_token))
    assert r.status_code == 200
    data = r.json()
    assert isinstance(data, list)
    assert len(data) >= 1
    # Le 1er log devrait etre 'create'
    assert data[0]["action"] == "create"


def test_admin_logs_limit_param(client, admin_token):
    """Le param limit est respecte."""
    for i in range(5):
        client.post(
            "/admin/questions",
            headers=_auth(admin_token),
            json=_valid_question_payload(qid=f"ADM-LOG-{i:02d}"),
        )
    r = client.get(
        "/admin/logs", headers=_auth(admin_token), params={"limit": 2}
    )
    assert r.status_code == 200
    assert len(r.json()) == 2


def test_admin_logs_record_delete_action(client, admin_token):
    """La suppression d'une question genere un log 'delete'."""
    client.post(
        "/admin/questions",
        headers=_auth(admin_token),
        json=_valid_question_payload(qid="ADM-LOG-DEL"),
    )
    client.delete(
        "/admin/questions/ADM-LOG-DEL", headers=_auth(admin_token)
    )
    r = client.get("/admin/logs", headers=_auth(admin_token))
    actions = [log["action"] for log in r.json()]
    assert "delete" in actions


def test_admin_logs_record_import_action(client, admin_token):
    """Un import batch genere un log 'import'."""
    r = client.post(
        "/admin/questions/batch-import",
        headers=_auth(admin_token),
        json={
            "questions": [_valid_question_payload(qid="ADM-LOG-IMP")],
            "overwrite_existing": False,
        },
    )
    assert r.status_code == 200
    logs = client.get("/admin/logs", headers=_auth(admin_token)).json()
    actions = [log["action"] for log in logs]
    assert "import" in actions
