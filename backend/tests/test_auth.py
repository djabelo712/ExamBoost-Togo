"""tests/test_auth.py — Tests du router /auth (register, login, me)."""

from __future__ import annotations

from services import auth_service


def test_register_success(client):
    """Inscription validee : 201 + token + user."""
    response = client.post(
        "/auth/register",
        json={
            "email": "eleve1@test.tg",
            "password": "password123",
            "nom": "Doe",
            "prenom": "Jean",
            "niveau_scolaire": "Terminale",
            "serie": "C",
        },
    )
    assert response.status_code == 201, response.text
    data = response.json()
    assert "access_token" in data
    assert data["token_type"] == "bearer"
    assert data["user_id"]
    assert data["user"]["email"] == "eleve1@test.tg"
    assert data["user"]["nom"] == "Doe"
    assert data["user"]["prenom"] == "Jean"


def test_register_duplicate_email(client):
    """Un meme email ne peut pas s'inscrire deux fois."""
    payload = {
        "email": "dup@test.tg",
        "password": "password123",
        "nom": "Dup",
        "prenom": "Jean",
        "niveau_scolaire": "Terminale",
        "serie": "C",
    }
    r1 = client.post("/auth/register", json=payload)
    assert r1.status_code == 201

    r2 = client.post("/auth/register", json=payload)
    assert r2.status_code == 409


def test_register_invalid_niveau(client):
    """niveau_scolaire invalide -> 422."""
    response = client.post(
        "/auth/register",
        json={
            "email": "bad@test.tg",
            "password": "password123",
            "nom": "Bad",
            "prenom": "Boy",
            "niveau_scolaire": "universite",  # interdit
        },
    )
    assert response.status_code == 422


def test_login_success(client):
    """Login valide : 200 + token."""
    # D'abord inscription
    client.post(
        "/auth/register",
        json={
            "email": "login@test.tg",
            "password": "password123",
            "nom": "Log",
            "prenom": "In",
            "niveau_scolaire": "3eme",
        },
    )
    # Puis login
    response = client.post(
        "/auth/login",
        json={"email": "login@test.tg", "password": "password123"},
    )
    assert response.status_code == 200, response.text
    data = response.json()
    assert "access_token" in data
    assert data["user"]["email"] == "login@test.tg"


def test_login_wrong_password(client):
    """Login avec mauvais mot de passe -> 401."""
    client.post(
        "/auth/register",
        json={
            "email": "wp@test.tg",
            "password": "password123",
            "nom": "Wp",
            "prenom": "Test",
            "niveau_scolaire": "3eme",
        },
    )
    response = client.post(
        "/auth/login",
        json={"email": "wp@test.tg", "password": "wrong"},
    )
    assert response.status_code == 401


def test_me_with_token(client, auth_token):
    """/auth/me avec un token valide retourne l'utilisateur."""
    response = client.get(
        "/auth/me",
        headers={"Authorization": f"Bearer {auth_token}"},
    )
    assert response.status_code == 200
    data = response.json()
    assert data["email"] == "eleve@test.tg"


def test_me_without_token(client):
    """/auth/me sans token -> 401."""
    response = client.get("/auth/me")
    assert response.status_code == 401


def test_me_with_invalid_token(client):
    """/auth/me avec un token invalide -> 401."""
    response = client.get(
        "/auth/me",
        headers={"Authorization": "Bearer invalid.token.here"},
    )
    assert response.status_code == 401


# ─── Tests complementaires (Vague 2 — Agent BW) ──────────────────────


def test_register_missing_required_field(client):
    """Inscription sans email -> 422 (validation Pydantic)."""
    r = client.post(
        "/auth/register",
        json={
            "password": "password123",
            "nom": "Doe",
            "prenom": "Jean",
            "niveau_scolaire": "3eme",
        },
    )
    assert r.status_code == 422


def test_register_short_password(client):
    """Mot de passe < 6 caracteres -> 422."""
    r = client.post(
        "/auth/register",
        json={
            "email": "short@test.tg",
            "password": "12345",  # trop court (min_length=6)
            "nom": "Short",
            "prenom": "Pwd",
            "niveau_scolaire": "3eme",
        },
    )
    assert r.status_code == 422


def test_register_invalid_email(client):
    """Email mal forme -> 422."""
    r = client.post(
        "/auth/register",
        json={
            "email": "not-an-email",
            "password": "password123",
            "nom": "Bad",
            "prenom": "Email",
            "niveau_scolaire": "3eme",
        },
    )
    assert r.status_code == 422


def test_register_first_user_becomes_admin(client):
    """Le premier utilisateur inscrit devient automatiquement admin."""
    r = client.post(
        "/auth/register",
        json={
            "email": "first@test.tg",
            "password": "password123",
            "nom": "First",
            "prenom": "User",
            "niveau_scolaire": "Terminale",
            "serie": "C",
        },
    )
    assert r.status_code == 201
    token = r.json()["access_token"]

    # On verifie via /auth/me que is_admin est bien True (reflete dans le token)
    me = client.get(
        "/auth/me", headers={"Authorization": f"Bearer {token}"}
    )
    assert me.status_code == 200
    # user.is_admin n'est pas expose dans UserOut, mais on peut verifier
    # que le token contient le claim is_admin=True en le decodant.
    payload = auth_service.decode_access_token(token)
    assert payload is not None
    assert payload.get("is_admin") is True


def test_login_unknown_email(client):
    """Login sur un email non inscrit -> 401 (pas 404, securite)."""
    r = client.post(
        "/auth/login",
        json={"email": "ghost@test.tg", "password": "password123"},
    )
    assert r.status_code == 401


def test_login_case_insensitive_email(client):
    """Le login est insensible a la casse sur l'email (lowercase cote serveur)."""
    client.post(
        "/auth/register",
        json={
            "email": "Case@TEST.tg",
            "password": "password123",
            "nom": "Case",
            "prenom": "Sensitive",
            "niveau_scolaire": "3eme",
        },
    )
    r = client.post(
        "/auth/login",
        json={"email": "case@test.tg", "password": "password123"},
    )
    assert r.status_code == 200
    assert r.json()["user"]["email"] == "case@test.tg"


def test_me_returns_full_profile(client, auth_token):
    """/auth/me renvoie tous les champs prevus par UserOut."""
    r = client.get(
        "/auth/me", headers={"Authorization": f"Bearer {auth_token}"}
    )
    assert r.status_code == 200
    data = r.json()
    # Champs obligatoires du schema UserOut
    for field in (
        "id", "email", "nom", "prenom", "niveau_scolaire",
        "date_inscription", "bkt_maitrise",
    ):
        assert field in data
    assert data["email"] == "eleve@test.tg"
    assert data["nom"] == "Doe"
    assert data["bkt_maitrise"] == {}  # vide au depart
    assert data["total_sessions"] == 0
    assert data["total_questions_answered"] == 0


def test_me_with_malformed_authorization_header(client):
    """Header Authorization sans 'Bearer ' -> 401."""
    r = client.get(
        "/auth/me", headers={"Authorization": "NotBearer abc.def.ghi"}
    )
    assert r.status_code == 401


def test_me_with_empty_bearer(client):
    """Header 'Bearer ' sans token -> 401."""
    r = client.get(
        "/auth/me", headers={"Authorization": "Bearer "}
    )
    assert r.status_code == 401


def test_token_expired_returns_401(client):
    """Un token expire est rejete avec 401.

    On genere un token avec expires_minutes=-1 (deja expire a l'emission).
    """
    # On inscrit d'abord un utilisateur pour avoir un sub valide
    r = client.post(
        "/auth/register",
        json={
            "email": "expire@test.tg",
            "password": "password123",
            "nom": "Expire",
            "prenom": "Token",
            "niveau_scolaire": "3eme",
        },
    )
    user_id = r.json()["user_id"]

    # Genere un token deja expire
    expired_token = auth_service.create_access_token(
        subject=user_id,
        extra_claims={"email": "expire@test.tg", "is_admin": False},
        expires_minutes=-1,
    )

    r = client.get(
        "/auth/me", headers={"Authorization": f"Bearer {expired_token}"}
    )
    assert r.status_code == 401


def test_token_with_unknown_user_returns_401(client):
    """Un token valide mais dont le user_id n'existe plus -> 401."""
    # Genere un token pour un user_id qui n'existe pas en base
    fake_token = auth_service.create_access_token(
        subject="nonexistent-user-id-12345",
        extra_claims={"email": "ghost@test.tg", "is_admin": False},
    )
    r = client.get(
        "/auth/me", headers={"Authorization": f"Bearer {fake_token}"}
    )
    assert r.status_code == 401


def test_register_normalizes_email_to_lowercase(client):
    """L'email est stocke en minuscules."""
    r = client.post(
        "/auth/register",
        json={
            "email": "MIXEDCase@TEST.tg",
            "password": "password123",
            "nom": "Mixed",
            "prenom": "Case",
            "niveau_scolaire": "3eme",
        },
    )
    assert r.status_code == 201
    token = r.json()["access_token"]
    me = client.get(
        "/auth/me", headers={"Authorization": f"Bearer {token}"}
    )
    assert me.json()["email"] == "mixedcase@test.tg"


def test_register_serie_optional_for_bepc(client):
    """L'inscription BEPC (niveau 3eme) n'exige pas de serie."""
    r = client.post(
        "/auth/register",
        json={
            "email": "bepc@test.tg",
            "password": "password123",
            "nom": "Bepc",
            "prenom": "Student",
            "niveau_scolaire": "3eme",
            # pas de serie
        },
    )
    assert r.status_code == 201
    assert r.json()["user"]["serie"] is None
