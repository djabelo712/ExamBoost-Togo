"""tests/test_auth.py — Tests du router /auth (register, login, me)."""

from __future__ import annotations


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
