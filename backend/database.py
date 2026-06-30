"""database.py — Couche d'acces aux donnees (SQLAlchemy 2.x).

- SQLite en developpement (fichier local).
- PostgreSQL en production (URL fournie par Railway/Render).
"""

from __future__ import annotations

import os
from typing import Generator

from sqlalchemy import create_engine, event
from sqlalchemy.orm import DeclarativeBase, Session, sessionmaker

from config import settings


def _build_engine():
    """Construit le moteur SQLAlchemy selon l'URL configuree."""
    url = settings.DATABASE_URL

    # Detection SQLite pour activer les pragmas (FK + WAL)
    is_sqlite = url.startswith("sqlite")

    connect_args = {"check_same_thread": False} if is_sqlite else {}
    engine = create_engine(
        url,
        connect_args=connect_args,
        pool_pre_ping=True,
        future=True,
    )

    if is_sqlite:
        @event.listens_for(engine, "connect")
        def _set_sqlite_pragma(dbapi_conn, _):
            cursor = dbapi_conn.cursor()
            cursor.execute("PRAGMA foreign_keys=ON")
            cursor.execute("PRAGMA journal_mode=WAL")
            cursor.close()

    return engine


engine = _build_engine()

SessionLocal = sessionmaker(
    bind=engine,
    autocommit=False,
    autoflush=False,
    expire_on_commit=False,
    class_=Session,
    future=True,
)


class Base(DeclarativeBase):
    """Base declarative pour les modeles ORM."""
    pass


def get_db() -> Generator[Session, None, None]:
    """Dependance FastAPI : fournit une session DB par requete."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def init_db() -> None:
    """Cree toutes les tables declarees (a appeler au demarrage)."""
    # Import pour enregistrer les modeles sur Base.metadata
    from models import db_models  # noqa: F401

    Base.metadata.create_all(bind=engine)


# Chemin absolu du fichier SQLite local (utilise par les scripts de seed)
SQLITE_FILE_PATH = (
    settings.DATABASE_URL.replace("sqlite:///", "")
    if settings.DATABASE_URL.startswith("sqlite")
    else None
)
