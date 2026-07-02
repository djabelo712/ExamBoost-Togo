"""tests/test_migrations.py — Tests des migrations Alembic.

Couverture :
    - ``alembic upgrade head`` cree toutes les tables (001 + 002)
    - ``alembic downgrade base`` supprime toutes les tables
    - ``alembic upgrade 001`` s'arrete a la revision 001 (sans tutor tables)
    - ``alembic upgrade 002`` ajoute les tables tutor
    - ``alembic current`` renvoie la bonne revision

Approche :
    On utilise l'API Python d'Alembic (``alembic.config.Config`` +
    ``alembic.command``) avec une SQLite temporaire par test (tmp_path).
    Le module ``alembic/env.py`` lit ``DATABASE_URL`` et surcharge l'URL
    de l'ini, ce qui permet d'isoler chaque test.

Note technique (shadowing) :
    Le dossier ``backend/alembic/`` est un dossier de migrations Alembic
    (pas un package Python). Comme ``backend/`` est dans ``sys.path``
    (via conftest), Python peut le traiter comme un namespace package
    et masquer le package ``alembic`` installe. Pour eviter cela, on
    importe ``alembic.command`` et ``alembic.config`` en TETE de module,
    AVANT d'ajouter ``backend/`` au path. Une fois le module ``alembic``
    cache dans ``sys.modules``, les imports ulterieurs (y compris ceux
    faits par ``alembic/env.py`` au runtime) utilisent le bon package.
"""
from __future__ import annotations

import os
import sys
from pathlib import Path

# ─── IMPORT ALEMBIC AVANT D'AJOUTER backend/ AU PATH ──────────────────
# On retire temporairement backend/ du path pour garantir l'import du
# package alembic installe (et non le dossier backend/alembic/ qui est
# un namespace package par effet de bord).
_BACKEND_ROOT_PRE = Path(__file__).resolve().parent.parent
_saved_path = sys.path[:]
sys.path[:] = [
    p for p in sys.path
    if Path(p).resolve() != _BACKEND_ROOT_PRE.resolve()
]
# Purge d'un eventuel cache alembic* dans sys.modules (si conftest a importe)
for _key in list(sys.modules.keys()):
    if _key == "alembic" or _key.startswith("alembic."):
        del sys.modules[_key]

import alembic.command  # noqa: E402
import alembic.config  # noqa: E402
from alembic.runtime.migration import MigrationContext  # noqa: E402

# Restaure le path (alembic reste cache dans sys.modules — c'est voulu)
sys.path[:] = _saved_path
# ─── FIN IMPORT ALEMBIC ───────────────────────────────────────────────

import pytest  # noqa: E402
from sqlalchemy import create_engine, inspect  # noqa: E402

# Ajoute le dossier backend/ au sys.path (pour que env.py puisse importer
# database, models, config). Deja fait par conftest, on le reaffirme par
# prudence.
_BACKEND_ROOT = _BACKEND_ROOT_PRE
if str(_BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(_BACKEND_ROOT))

_ALEMBIC_INI = _BACKEND_ROOT / "alembic.ini"
_ALEMBIC_DIR = _BACKEND_ROOT / "alembic"


def _alembic_config_obj(db_url: str) -> "alembic.config.Config":
    """Construit une config Alembic pointant vers une DB isolee."""
    cfg = alembic.config.Config(str(_ALEMBIC_INI))
    cfg.set_main_option("script_location", str(_ALEMBIC_DIR))
    cfg.set_main_option("sqlalchemy.url", db_url)
    return cfg


def _apply_env(db_url: str, monkeypatch) -> None:
    """Positionne DATABASE_URL pour que alembic/env.py surcharge l'URL."""
    monkeypatch.setenv("DATABASE_URL", db_url)


def _table_names(db_url: str) -> set:
    """Retourne l'ensemble des noms de tables presentes dans la DB."""
    engine = create_engine(db_url)
    try:
        insp = inspect(engine)
        return set(insp.get_table_names())
    finally:
        engine.dispose()


# ─── Tests ────────────────────────────────────────────────────────────


def test_upgrade_head_creates_all_tables(tmp_path, monkeypatch):
    """``alembic upgrade head`` cree les 7 tables attendues."""
    db_file = tmp_path / "migrations.db"
    db_url = f"sqlite:///{db_file}"
    _apply_env(db_url, monkeypatch)

    cfg = _alembic_config_obj(db_url)
    alembic.command.upgrade(cfg, "head")

    tables = _table_names(db_url)
    expected = {
        "users",
        "questions",
        "review_cards",
        "responses",
        "simulations",
        "tutor_conversations",
        "tutor_messages",
        "alembic_version",  # table de suivi Alembic
    }
    missing = expected - tables
    assert not missing, f"Tables manquantes : {missing}. Presentes : {tables}"


def test_downgrade_base_drops_all_tables(tmp_path, monkeypatch):
    """``alembic downgrade base`` supprime toutes les tables metier."""
    db_file = tmp_path / "downgrade.db"
    db_url = f"sqlite:///{db_file}"
    _apply_env(db_url, monkeypatch)

    cfg = _alembic_config_obj(db_url)
    alembic.command.upgrade(cfg, "head")
    alembic.command.downgrade(cfg, "base")

    tables = _table_names(db_url)
    metier_tables = {
        "users",
        "questions",
        "review_cards",
        "responses",
        "simulations",
        "tutor_conversations",
        "tutor_messages",
    }
    leftover = metier_tables & tables
    assert not leftover, f"Tables metier non supprimees : {leftover}"


def test_upgrade_to_001_creates_initial_tables_only(tmp_path, monkeypatch):
    """``alembic upgrade 001`` s'arrete a la revision 001 (pas de tutor)."""
    db_file = tmp_path / "rev001.db"
    db_url = f"sqlite:///{db_file}"
    _apply_env(db_url, monkeypatch)

    cfg = _alembic_config_obj(db_url)
    alembic.command.upgrade(cfg, "001")

    tables = _table_names(db_url)
    for t in ("users", "questions", "review_cards", "responses", "simulations"):
        assert t in tables, f"Table {t} devrait exister apres upgrade 001"
    assert "tutor_conversations" not in tables
    assert "tutor_messages" not in tables


def test_upgrade_to_002_adds_tutor_tables(tmp_path, monkeypatch):
    """``alembic upgrade 002`` ajoute les tables tutor par dessus 001."""
    db_file = tmp_path / "rev002.db"
    db_url = f"sqlite:///{db_file}"
    _apply_env(db_url, monkeypatch)

    cfg = _alembic_config_obj(db_url)
    alembic.command.upgrade(cfg, "002")

    tables = _table_names(db_url)
    assert "tutor_conversations" in tables
    assert "tutor_messages" in tables
    assert "users" in tables
    assert "questions" in tables


def test_current_revision_after_upgrade_head(tmp_path, monkeypatch):
    """``alembic current`` renvoie '002' apres upgrade head."""
    db_file = tmp_path / "current.db"
    db_url = f"sqlite:///{db_file}"
    _apply_env(db_url, monkeypatch)

    cfg = _alembic_config_obj(db_url)
    alembic.command.upgrade(cfg, "head")

    engine = create_engine(db_url)
    try:
        with engine.connect() as conn:
            ctx = MigrationContext.configure(conn)
            current_rev = ctx.get_current_revision()
    finally:
        engine.dispose()

    assert current_rev == "002"


def test_downgrade_002_to_001_drops_tutor_tables(tmp_path, monkeypatch):
    """Downgrade de 002 vers 001 supprime les tables tutor."""
    db_file = tmp_path / "down002.db"
    db_url = f"sqlite:///{db_file}"
    _apply_env(db_url, monkeypatch)

    cfg = _alembic_config_obj(db_url)
    alembic.command.upgrade(cfg, "head")
    alembic.command.downgrade(cfg, "001")

    tables = _table_names(db_url)
    assert "tutor_conversations" not in tables
    assert "tutor_messages" not in tables
    assert "users" in tables
    assert "questions" in tables


def test_initial_schema_has_indexes(tmp_path, monkeypatch):
    """Les index prevus sont bien crees (verifie sur questions)."""
    db_file = tmp_path / "indexes.db"
    db_url = f"sqlite:///{db_file}"
    _apply_env(db_url, monkeypatch)

    cfg = _alembic_config_obj(db_url)
    alembic.command.upgrade(cfg, "head")

    engine = create_engine(db_url)
    try:
        insp = inspect(engine)
        question_indexes = {idx["name"] for idx in insp.get_indexes("questions")}
        assert "ix_questions_matiere" in question_indexes
        assert "ix_questions_examen" in question_indexes
        assert "ix_questions_matiere_examen" in question_indexes
        rc_indexes = {idx["name"] for idx in insp.get_indexes("review_cards")}
        assert "ix_review_cards_user_id" in rc_indexes
        assert "ix_review_cards_next_review_date" in rc_indexes
    finally:
        engine.dispose()


def test_foreign_keys_are_declared(tmp_path, monkeypatch):
    """Les FK sont bien declarees (verifie sur review_cards)."""
    db_file = tmp_path / "fk.db"
    db_url = f"sqlite:///{db_file}"
    _apply_env(db_url, monkeypatch)

    cfg = _alembic_config_obj(db_url)
    alembic.command.upgrade(cfg, "head")

    engine = create_engine(db_url)
    try:
        insp = inspect(engine)
        fks = insp.get_foreign_keys("review_cards")
        referenced = {fk["referred_table"] for fk in fks}
        assert "users" in referenced
        assert "questions" in referenced
        tutor_fks = insp.get_foreign_keys("tutor_messages")
        tutor_ref = {fk["referred_table"] for fk in tutor_fks}
        assert "tutor_conversations" in tutor_ref
    finally:
        engine.dispose()
