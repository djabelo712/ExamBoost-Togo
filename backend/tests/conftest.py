"""tests/conftest.py — Fixtures pytest partagees.

On isole une base SQLite par test en remplacant l'engine et le
SessionLocal du module ``database`` (sans reload, pour conserver la
meme classe ``Base`` que les modeles).
"""

from __future__ import annotations

import os
import sys
from pathlib import Path

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

# Ajoute le dossier backend au path pour les imports absolus
_BACKEND_ROOT = Path(__file__).resolve().parent.parent
if str(_BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(_BACKEND_ROOT))


@pytest.fixture(scope="function")
def client(tmp_path, monkeypatch):
    """Retourne un TestClient avec une base SQLite isolee par test."""
    db_file = tmp_path / "test.db"
    db_url = f"sqlite:///{db_file}"

    # Patche les settings AVANT import de l'app
    monkeypatch.setenv("DATABASE_URL", db_url)
    monkeypatch.setenv("SECRET_KEY", "test-secret-not-for-production-32c")
    monkeypatch.setenv("ACCESS_TOKEN_EXPIRE_MINUTES", "60")
    monkeypatch.setenv("CORS_ORIGINS", '["*"]')

    # Reset du cache settings pour prendre en compte l'env
    from config import get_settings

    get_settings.cache_clear()

    # Import des modules (premier import — prend en compte l'env)
    import database
    from models import db_models  # noqa: F401

    # Remplace l'engine et le SessionLocal par une base isolee
    engine = create_engine(
        db_url,
        connect_args={"check_same_thread": False},
        future=True,
    )
    test_sessionmaker = sessionmaker(
        bind=engine, autocommit=False, autoflush=False, future=True
    )

    # Monkeypatch des attributs du module database
    monkeypatch.setattr(database, "engine", engine)
    monkeypatch.setattr(database, "SessionLocal", test_sessionmaker)

    # Cree toutes les tables sur l'engine isole
    database.Base.metadata.create_all(bind=engine)

    # Import de l'app UNE seule fois (les routers referencent database
    # dynamiquement via Depends(get_db), qui lira database.SessionLocal)
    import main as main_module

    with TestClient(main_module.app) as c:
        yield c


@pytest.fixture
def auth_token(client):
    """Inscrit un utilisateur de test et retourne le token JWT."""
    response = client.post(
        "/auth/register",
        json={
            "email": "eleve@test.tg",
            "password": "password123",
            "nom": "Doe",
            "prenom": "Jean",
            "niveau_scolaire": "Terminale",
            "serie": "C",
        },
    )
    assert response.status_code in (200, 201), response.text
    return response.json()["access_token"]


@pytest.fixture
def admin_token(client):
    """Inscrit un admin (premier utilisateur => admin auto)."""
    response = client.post(
        "/auth/register",
        json={
            "email": "admin@test.tg",
            "password": "admin12345",
            "nom": "Admin",
            "prenom": "ExamBoost",
            "niveau_scolaire": "Terminale",
            "serie": "C",
        },
    )
    assert response.status_code in (200, 201), response.text
    return response.json()["access_token"]
