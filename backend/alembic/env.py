"""Configuration de l'environnement Alembic pour ExamBoost Togo.

Ce module est appele par Alembic a chaque commande ``alembic``. Il branche
le moteur SQLAlchemy sur la meme URL que l'application (``config.settings``)
et expose ``Base.metadata`` comme cible d'autogeneration.

En dev : SQLite local (``./examboost.db``).
En prod : PostgreSQL Railway/Render via ``DATABASE_URL``.
"""
from __future__ import annotations

import os
import sys
from logging.config import fileConfig
from pathlib import Path

from alembic import context
from sqlalchemy import engine_from_config, pool

# Ajoute le dossier backend/ au sys.path pour permettre l'import
# ``from database import Base`` quelle que soit la sortie de alembic.ini.
_BACKEND_ROOT = Path(__file__).resolve().parent.parent
if str(_BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(_BACKEND_ROOT))

# Import des modeles pour qu'Alembic les voie dans Base.metadata
from database import Base  # noqa: E402
import models.db_models  # noqa: E402,F401  (enregistre les modeles sur Base)
from config import settings  # noqa: E402

# config Alembic (objet global fourni par Alembic lui-meme)
config = context.config

# Surcharge l'URL de l'ini si DATABASE_URL est definie dans l'environnement
# ou via config.settings. Permet de pointer vers PostgreSQL en prod sans
# modifier alembic.ini.
db_url = os.environ.get("DATABASE_URL") or settings.DATABASE_URL
if db_url:
    config.set_main_option("sqlalchemy.url", db_url)

# Configuration du logging si le fichier ini est present
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

# Metadata cible pour autogenerate
target_metadata = Base.metadata


def run_migrations_offline() -> None:
    """Mode offline : genere le SQL sans connexion DB.

    Utilise pour produire un script SQL a appliquer manuellement
    (ex: en production sans droit DDL direct).
    """
    url = config.get_main_option("sqlalchemy.url")
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
        compare_type=True,
    )
    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online() -> None:
    """Mode online : ouvre une connexion et applique les migrations."""
    connectable = engine_from_config(
        config.get_section(config.config_ini_section, {}),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )

    with connectable.connect() as connection:
        context.configure(
            connection=connection,
            target_metadata=target_metadata,
            compare_type=True,
        )
        with context.begin_transaction():
            context.run_migrations()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
