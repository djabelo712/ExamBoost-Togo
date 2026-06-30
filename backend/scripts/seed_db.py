"""scripts/seed_db.py — Peuple la base avec ``data/questions_seed.json``.

Utilisation :
    python scripts/seed_db.py

Le script est idempotent : les questions existantes (meme ID) sont
ignorees. Il peut etre appele plusieurs fois sans effet de bord.
"""

from __future__ import annotations

import json
import os
import sys
from pathlib import Path
from typing import Any, Dict, List

# Permet l'execution en tant que script (pas besoin de package)
_HERE = Path(__file__).resolve().parent
_BACKEND_ROOT = _HERE.parent
if str(_BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(_BACKEND_ROOT))

from sqlalchemy import select  # noqa: E402

from database import SessionLocal, init_db  # noqa: E402
from models.db_models import Question, User  # noqa: E402
from services import auth_service  # noqa: E402


SEED_PATH = _BACKEND_ROOT / "data" / "questions_seed.json"


def _load_seed() -> List[Dict[str, Any]]:
    if not SEED_PATH.exists():
        print(f"[seed] Fichier introuvable: {SEED_PATH}")
        return []
    with open(SEED_PATH, "r", encoding="utf-8") as f:
        return json.load(f)


def _upsert_question(db, q: Dict[str, Any]) -> bool:
    qid = q.get("id")
    if not qid:
        return False

    existing = db.get(Question, qid)
    if existing is not None:
        return False  # ignore

    irt = q.get("irt") or {}
    db.add(
        Question(
            id=qid,
            enonce=q.get("enonce", ""),
            reponse=q.get("reponse", ""),
            explication=q.get("explication"),
            matiere=q.get("matiere", "Autre"),
            chapitre=q.get("chapitre", "Autre"),
            competence_id=q.get("competence_id", ""),
            examen=q.get("examen", "BEPC"),
            serie=q.get("serie"),
            annee=q.get("annee"),
            type=q.get("type", "ouvert"),
            choix=q.get("choix"),
            points=q.get("points"),
            irt_a=irt.get("a"),
            irt_b=irt.get("b"),
            irt_c=irt.get("c"),
            irt_calibrated=bool(irt.get("calibre", False)),
        )
    )
    return True


def _ensure_admin(db) -> User:
    """Cree un compte admin par defaut (utile pour tester POST /questions)."""
    from config import settings

    admin_email = settings.ADMIN_EMAIL.lower()
    admin = db.execute(select(User).where(User.email == admin_email)).scalar_one_or_none()
    if admin is None:
        admin = User(
            email=admin_email,
            password_hash=auth_service.hash_password("examboost-admin"),
            nom="Admin",
            prenom="ExamBoost",
            niveau_scolaire="Terminale",
            serie="C",
            is_admin=True,
            bkt_maitrise={},
        )
        db.add(admin)
    return admin


def seed_if_empty() -> int:
    """Peuple la base si elle est vide. Retourne le nombre d'items ajoutes."""
    init_db()
    items = _load_seed()
    if not items:
        return 0

    db = SessionLocal()
    try:
        added = 0
        for q in items:
            if _upsert_question(db, q):
                added += 1
        _ensure_admin(db)
        db.commit()
        return added
    except Exception as e:
        db.rollback()
        print(f"[seed] Erreur: {e}")
        return 0
    finally:
        db.close()


def main() -> None:
    print(f"[seed] Chargement depuis {SEED_PATH}")
    added = seed_if_empty()
    print(f"[seed] {added} question(s) ajoutee(s).")


if __name__ == "__main__":
    main()
