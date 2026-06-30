"""scripts/calibrate_irt.py — Calibre les parametres IRT (a, b, c) des questions.

Utilisation :
    python scripts/calibrate_irt.py

Etapes :
    1. Charge toutes les reponses enregistrees dans la table ``responses``.
    2. Tente la calibration via py-irt (3PL). Si py-irt absent ou trop peu
       de donnees, fallback sur une estimation simple (b = -probit(p_success)).
    3. Met a jour les colonnes ``irt_a``, ``irt_b``, ``irt_c`` et
       ``irt_calibrated`` de la table ``questions``.
"""

from __future__ import annotations

import sys
from pathlib import Path

import pandas as pd

_HERE = Path(__file__).resolve().parent
_BACKEND_ROOT = _HERE.parent
if str(_BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(_BACKEND_ROOT))

from sqlalchemy import select  # noqa: E402

from database import SessionLocal, init_db  # noqa: E402
from models.db_models import Question, Response  # noqa: E402
from services import irt_service  # noqa: E402


def load_responses_df() -> pd.DataFrame:
    db = SessionLocal()
    try:
        rows = db.execute(
            select(
                Response.user_id,
                Response.question_id,
                Response.correct,
            )
        ).all()
        return pd.DataFrame(rows, columns=["user_id", "question_id", "correct"])
    finally:
        db.close()


def update_questions(calibrated: list) -> int:
    """Persiste les parametres IRT en base. Retourne le nombre d'items MAJ."""
    if not calibrated:
        return 0
    db = SessionLocal()
    try:
        n = 0
        for item in calibrated:
            q = db.get(Question, item.question_id)
            if q is None:
                continue
            q.irt_a = float(item.a)
            q.irt_b = float(item.b)
            q.irt_c = float(item.c)
            q.irt_calibrated = item.method != "default_insufficient_data"
            n += 1
        db.commit()
        return n
    finally:
        db.close()


def main() -> None:
    init_db()
    print("[irt] Chargement des reponses...")
    df = load_responses_df()
    print(f"[irt] {len(df)} reponses chargees.")

    if df.empty:
        print("[irt] Aucune donnee. Rien a calibrer.")
        return

    # 1. Tentative py-irt (peut echouer / etre lent)
    print("[irt] Tentative de calibration via py-irt (3PL)...")
    calibrated = irt_service.calibrate_irt(df, use_pyirt=True)

    # 2. Fallback si py-irt n'a rien produit
    if not calibrated:
        print("[irt] py-irt indisponible ou vide. Fallback probit.")
        calibrated = irt_service.calibrate_irt(df, use_pyirt=False)

    # 3. Persistence
    n = update_questions(calibrated)
    print(f"[irt] {n} question(s) mises a jour.")

    # Affichage de quelques stats
    by_method = {}
    for c in calibrated:
        by_method[c.method] = by_method.get(c.method, 0) + 1
    print(f"[irt] Repartition par methode: {by_method}")


if __name__ == "__main__":
    main()
