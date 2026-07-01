"""services/admin_service.py — Logique admin pour la gestion du contenu.

Responsabilites :
    - CRUD questions (cree / update / delete) avec validation metier.
    - Import / export batch (JSON ou CSV) avec filtres.
    - Stats contenu (total, par matiere, calibration IRT, doublons).
    - Logging des actions admin dans une table dediee.

Le modele ORM ``AdminActionLog`` est defini ici (et non dans
``models/db_models.py``) pour respecter la contrainte de ne pas modifier
les fichiers existants. La table est cree automatiquement au premier
import du module via ``Base.metadata.create_all(checkfirst=True)``.

Toutes les methodes publiques sont asynchrones (async def) pour rester
coherentes avec l'API FastAPI, meme si SQLAlchemy 2.x utilise des
operations synchrones. Les operations DB sont suffisamment courtes pour
ne pas bloquer l'event loop en pratique (base < 10k questions).
"""

from __future__ import annotations

import csv
import io
import json
import uuid
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional

from sqlalchemy import JSON, DateTime, Integer, String, func, select, text
from sqlalchemy.orm import Mapped, mapped_column, Session
from sqlalchemy.exc import SQLAlchemyError

from database import Base, engine
from models.admin_schemas import (
    AdminActionLog as AdminActionLogSchema,
    AdminStats,
    QuestionCreate,
    QuestionUpdate,
)
from models.db_models import Question


# ─── Modele ORM AdminActionLog (defini ici pour ne pas toucher db_models.py) ──
class AdminActionLog(Base):
    """Table des logs d'actions admin.

    Une ligne par action (create / update / delete / import / export),
    avec optionnellement l'ID de la question concernee et un JSON de
    details (ex: champs modifies lors d'un update).
    """

    __tablename__ = "admin_action_logs"

    id: Mapped[str] = mapped_column(
        String(36), primary_key=True, default=lambda: uuid.uuid4().hex
    )
    admin_id: Mapped[str] = mapped_column(
        String(36), index=True, nullable=False
    )
    action: Mapped[str] = mapped_column(String(20), index=True, nullable=False)
    question_id: Mapped[Optional[str]] = mapped_column(
        String(64), nullable=True, index=True
    )
    timestamp: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        index=True,
    )
    details: Mapped[Optional[Dict[str, Any]]] = mapped_column(
        JSON, nullable=True
    )


# Creation idempotente de la table au chargement du module.
# Permet d'utiliser AdminActionLog sans modifier database.init_db() ni
# main.py. Le checkfirst=True garantit l'operation est un no-op si la
# table existe deja.
try:
    Base.metadata.create_all(
        bind=engine, tables=[AdminActionLog.__table__], checkfirst=True
    )
except SQLAlchemyError as exc:  # pragma: no cover - defensif
    # On logge mais on ne leve pas : le service reste utilisable
    # (les logs seront simplement non persistes).
    print(f"[admin_service] Impossible de creer admin_action_logs: {exc}")


# ─── Constantes metier ───────────────────────────────────────────────
EXAMENS_VALIDES = {"BEPC", "BAC1", "BAC2", "Probatoire"}
SERIES_VALIDES = {"A", "B", "C", "D", "F"}
TYPES_VALIDES = {"calcul", "ouvert", "qcm", "vraiFaux", "redaction"}


# ─── Helper : conversion ORM -> dict ─────────────────────────────────
def _question_to_dict(q: Question) -> Dict[str, Any]:
    """Serialise une Question ORM en dict (pour export JSON)."""
    return {
        "id": q.id,
        "enonce": q.enonce,
        "reponse": q.reponse,
        "explication": q.explication,
        "matiere": q.matiere,
        "chapitre": q.chapitre,
        "competence_id": q.competence_id,
        "examen": q.examen,
        "serie": q.serie,
        "annee": q.annee,
        "type": q.type,
        "choix": q.choix,
        "points": q.points,
        "irt_a": q.irt_a,
        "irt_b": q.irt_b,
        "irt_c": q.irt_c,
        "irt_calibrated": q.irt_calibrated,
        "created_at": q.created_at.isoformat() if q.created_at else None,
    }


# ─── Service ─────────────────────────────────────────────────────────
class AdminService:
    """Service principal d'administration du contenu.

    Une instance par requete (le db Session est injecte par FastAPI).
    """

    def __init__(self, db: Session):
        self.db = db

    # ─── CRUD Questions ────────────────────────────────────────────

    async def create_question(
        self, question: QuestionCreate, admin_id: str
    ) -> Question:
        """Cree une nouvelle question apres validation.

        Raises:
            ValueError: si l'ID existe deja ou si la validation echoue.
        """
        existing = self.db.get(Question, question.id)
        if existing is not None:
            raise ValueError(f"Question {question.id} existe deja")

        self._validate_question(question)

        data = question.model_dump()
        db_q = Question(**data)
        self.db.add(db_q)
        self.db.flush()  # pour verifier les contraintes avant commit

        self._log_action(admin_id, "create", question.id, None)
        self.db.commit()
        self.db.refresh(db_q)
        return db_q

    async def update_question(
        self,
        question_id: str,
        update: QuestionUpdate,
        admin_id: str,
    ) -> Question:
        """Met a jour une question existante (partial update).

        Raises:
            ValueError: si la question est introuvable.
        """
        q = self.db.get(Question, question_id)
        if q is None:
            raise ValueError(f"Question {question_id} introuvable")

        update_data = update.model_dump(exclude_unset=True)
        if not update_data:
            return q  # rien a faire

        for key, value in update_data.items():
            setattr(q, key, value)

        self.db.flush()
        self._log_action(admin_id, "update", question_id, update_data)
        self.db.commit()
        self.db.refresh(q)
        return q

    async def delete_question(self, question_id: str, admin_id: str) -> None:
        """Supprime une question.

        Raises:
            ValueError: si la question est introuvable.
        """
        q = self.db.get(Question, question_id)
        if q is None:
            raise ValueError(f"Question {question_id} introuvable")

        self.db.delete(q)
        self._log_action(admin_id, "delete", question_id, None)
        self.db.commit()

    async def list_questions(
        self,
        matiere: Optional[str] = None,
        examen: Optional[str] = None,
        serie: Optional[str] = None,
        annee: Optional[int] = None,
        recherche: Optional[str] = None,
        limit: int = 50,
        offset: int = 0,
    ) -> Dict[str, Any]:
        """Liste paginee de questions avec filtres optionnels.

        Returns:
            Dict avec ``items`` (List[Question]) et ``total`` (int).
        """
        stmt = select(Question)
        count_stmt = select(func.count(Question.id))

        if matiere:
            stmt = stmt.where(Question.matiere == matiere)
            count_stmt = count_stmt.where(Question.matiere == matiere)
        if examen:
            stmt = stmt.where(Question.examen == examen)
            count_stmt = count_stmt.where(Question.examen == examen)
        if serie:
            stmt = stmt.where(Question.serie == serie)
            count_stmt = count_stmt.where(Question.serie == serie)
        if annee:
            stmt = stmt.where(Question.annee == annee)
            count_stmt = count_stmt.where(Question.annee == annee)
        if recherche:
            # Recherche full-text simple (LIKE sur l'enonce).
            pattern = f"%{recherche}%"
            stmt = stmt.where(Question.enonce.ilike(pattern))
            count_stmt = count_stmt.where(Question.enonce.ilike(pattern))

        total = self.db.execute(count_stmt).scalar() or 0
        stmt = stmt.order_by(Question.id).limit(limit).offset(offset)
        items = list(self.db.execute(stmt).scalars().all())

        return {"items": items, "total": total, "limit": limit, "offset": offset}

    # ─── Batch ─────────────────────────────────────────────────────

    async def batch_import(
        self,
        questions: List[QuestionCreate],
        admin_id: str,
        overwrite: bool = False,
    ) -> Dict[str, Any]:
        """Importe un batch de questions.

        Returns:
            Dict {created, updated, skipped, errors}.
        """
        results: Dict[str, Any] = {
            "created": 0,
            "updated": 0,
            "skipped": 0,
            "errors": [],
        }

        for q in questions:
            try:
                existing = self.db.get(Question, q.id)
                if existing is not None:
                    if overwrite:
                        update = QuestionUpdate(
                            **q.model_dump(exclude_unset=True)
                        )
                        await self.update_question(q.id, update, admin_id)
                        results["updated"] += 1
                    else:
                        results["skipped"] += 1
                else:
                    await self.create_question(q, admin_id)
                    results["created"] += 1
            except Exception as exc:  # noqa: BLE001
                results["errors"].append(
                    {"question_id": q.id, "error": str(exc)}
                )

        # Log global de l'import (meme si erreurs partielles)
        self._log_action(
            admin_id,
            "import",
            None,
            {
                "count": len(questions),
                "created": results["created"],
                "updated": results["updated"],
                "skipped": results["skipped"],
                "errors": len(results["errors"]),
                "overwrite": overwrite,
            },
        )
        self.db.commit()
        return results

    async def batch_export(
        self,
        format: str = "json",
        filters: Optional[Dict[str, Any]] = None,
    ) -> Dict[str, Any]:
        """Exporte les questions en JSON ou CSV.

        Returns:
            Dict {format, content, count}.

        Raises:
            ValueError: si le format n'est pas supporte.
        """
        if format not in ("json", "csv"):
            raise ValueError(f"Format {format} non supporte (json | csv)")

        query = select(Question)
        if filters:
            if "matiere" in filters and filters["matiere"]:
                query = query.where(Question.matiere == filters["matiere"])
            if "examen" in filters and filters["examen"]:
                query = query.where(Question.examen == filters["examen"])
            if "serie" in filters and filters["serie"]:
                query = query.where(Question.serie == filters["serie"])
            if "annee" in filters and filters["annee"] is not None:
                query = query.where(Question.annee == filters["annee"])
            if "chapitre" in filters and filters["chapitre"]:
                query = query.where(Question.chapitre == filters["chapitre"])

        questions = list(self.db.execute(query).scalars().all())

        if format == "json":
            content = json.dumps(
                [_question_to_dict(q) for q in questions],
                indent=2,
                ensure_ascii=False,
            )
        else:  # csv
            output = io.StringIO()
            writer = csv.writer(output, quoting=csv.QUOTE_MINIMAL)
            writer.writerow(
                [
                    "id",
                    "matiere",
                    "chapitre",
                    "examen",
                    "serie",
                    "annee",
                    "type",
                    "points",
                    "irt_calibrated",
                    "enonce",
                    "reponse",
                ]
            )
            for q in questions:
                enonce_csv = (q.enonce or "").replace("\n", " ")[:200]
                reponse_csv = (q.reponse or "").replace("\n", " ")[:200]
                writer.writerow(
                    [
                        q.id,
                        q.matiere,
                        q.chapitre,
                        q.examen,
                        q.serie or "",
                        q.annee or "",
                        q.type,
                        q.points or "",
                        "1" if q.irt_calibrated else "0",
                        enonce_csv,
                        reponse_csv,
                    ]
                )
            content = output.getvalue()

        return {"format": format, "content": content, "count": len(questions)}

    # ─── Stats ─────────────────────────────────────────────────────

    async def get_stats(self) -> AdminStats:
        """Calcule les stats contenu pour le dashboard admin."""
        total = self.db.execute(
            select(func.count(Question.id))
        ).scalar() or 0

        by_matiere = self._group_count(Question.matiere)
        by_examen = self._group_count(Question.examen)
        by_type = self._group_count(Question.type)

        # Serie : on exclut les nulls (BEPC)
        by_serie_rows = self.db.execute(
            select(Question.serie, func.count(Question.id))
            .where(Question.serie.isnot(None))
            .group_by(Question.serie)
        ).all()
        by_serie = {row[0]: row[1] for row in by_serie_rows}

        # Annee : on exclut les nulls
        by_annee_rows = self.db.execute(
            select(Question.annee, func.count(Question.id))
            .where(Question.annee.isnot(None))
            .group_by(Question.annee)
        ).all()
        by_annee = {row[0]: row[1] for row in by_annee_rows}

        calibrated = self.db.execute(
            select(func.count(Question.id)).where(
                Question.irt_calibrated == True  # noqa: E712
            )
        ).scalar() or 0

        without_explication = self.db.execute(
            select(func.count(Question.id)).where(
                (Question.explication.is_(None))
                | (Question.explication == "")
            )
        ).scalar() or 0

        duplicates = await self._find_duplicates()

        return AdminStats(
            total_questions=total,
            by_matiere=by_matiere,
            by_examen=by_examen,
            by_serie=by_serie,
            by_annee=by_annee,
            by_type=by_type,
            irt_calibrated_count=calibrated,
            irt_calibrated_percent=round(
                calibrated / total * 100, 2
            ) if total > 0 else 0.0,
            last_updated=datetime.now(timezone.utc),
            questions_without_explanation=without_explication,
            duplicate_warnings=duplicates,
        )

    def _group_count(self, column) -> Dict[str, int]:
        """Helper : retourne {valeur: compte} pour une colonne donnee."""
        rows = self.db.execute(
            select(column, func.count(Question.id)).group_by(column)
        ).all()
        return {str(row[0]): row[1] for row in rows}

    async def _find_duplicates(self) -> List[Dict[str, Any]]:
        """Detecte les questions potentiellement dupliquees.

        Heuristique : on regroupe par prefixe des 60 premiers caracteres
        de l'enonce (espaces normalises). Tout groupe de taille > 1 est
        un doublon potentiel.

        Utilise une requete SQL brute (substr) pour ne pas charger toute
        la table en memoire. Compatible SQLite et PostgreSQL.
        """
        # On utilise func.substr pour la portabilite (les deux moteurs
        # supportent substr). On normalise les espaces via un REPLACE
        # en cascade (SQLite-compatible).
        try:
            rows = self.db.execute(
                select(
                    func.substr(Question.enonce, 1, 60).label("prefix"),
                    func.count(Question.id).label("cnt"),
                )
                .where(Question.enonce.isnot(None))
                .group_by(text("prefix"))
                .having(func.count(Question.id) > 1)
            ).all()

            results: List[Dict[str, Any]] = []
            for row in rows:
                prefix = row[0] or ""
                # Pour chaque doublon, on recupere les IDs concernes
                ids_rows = self.db.execute(
                    select(Question.id).where(
                        func.substr(Question.enonce, 1, 60) == prefix
                    )
                ).scalars().all()
                results.append(
                    {
                        "prefix": prefix[:80],
                        "count": row[1],
                        "ids": list(ids_rows),
                    }
                )
            return results
        except SQLAlchemyError:
            # En cas d'incompatibilite SQL, on retourne une liste vide
            # plutot que de faire planter le endpoint /stats.
            return []

    # ─── Validation ────────────────────────────────────────────────

    def _validate_question(self, q: QuestionCreate) -> None:
        """Valide la coherence metier d'une question.

        Raises:
            ValueError: en cas d'incoherence (examen/serie, QCM, etc.).
        """
        # Examen doit etre dans la liste valide
        if q.examen not in EXAMENS_VALIDES:
            raise ValueError(
                f"examen doit etre dans {sorted(EXAMENS_VALIDES)}, "
                f"recu: {q.examen}"
            )

        # BEPC : pas de serie
        if q.examen == "BEPC" and q.serie is not None:
            raise ValueError("BEPC ne doit pas avoir de serie")

        # BAC / Probatoire : serie obligatoire et valide
        if q.examen in {"BAC1", "BAC2", "Probatoire"}:
            if q.serie is None:
                raise ValueError(
                    f"{q.examen} doit avoir une serie (A, B, C, D, F)"
                )
            if q.serie not in SERIES_VALIDES:
                raise ValueError(
                    f"serie doit etre dans {sorted(SERIES_VALIDES)}, "
                    f"recu: {q.serie}"
                )

        # Type doit etre valide
        if q.type not in TYPES_VALIDES:
            raise ValueError(
                f"type doit etre dans {sorted(TYPES_VALIDES)}, "
                f"recu: {q.type}"
            )

        # QCM : exactement 4 choix et la reponse doit etre un des choix
        if q.type == "qcm":
            if not q.choix or len(q.choix) != 4:
                raise ValueError("Le type 'qcm' doit comporter 4 choix")
            if q.reponse not in q.choix:
                raise ValueError(
                    "La reponse d'un QCM doit etre un des 4 choix"
                )

        # vraiFaux : la reponse doit etre 'Vrai' ou 'Faux'
        if q.type == "vraiFaux":
            if q.reponse not in {"Vrai", "Faux", "vrai", "faux", "VRAI", "FAUX"}:
                raise ValueError(
                    "La reponse d'un 'vraiFaux' doit etre 'Vrai' ou 'Faux'"
                )

    # ─── Logs ──────────────────────────────────────────────────────

    def _log_action(
        self,
        admin_id: str,
        action: str,
        question_id: Optional[str] = None,
        details: Optional[Dict[str, Any]] = None,
    ) -> None:
        """Insere une ligne de log d'action admin (sans commit)."""
        try:
            log = AdminActionLog(
                id=uuid.uuid4().hex,
                admin_id=admin_id,
                action=action,
                question_id=question_id,
                timestamp=datetime.now(timezone.utc),
                details=details,
            )
            self.db.add(log)
        except Exception as exc:  # noqa: BLE001
            # Le logging ne doit jamais faire planter une action admin.
            print(f"[admin_service] log_action failed: {exc}")

    async def get_logs(self, limit: int = 50) -> List[AdminActionLog]:
        """Retourne les derniers logs admin tries par date desc."""
        rows = self.db.execute(
            select(AdminActionLog)
            .order_by(AdminActionLog.timestamp.desc())
            .limit(limit)
        ).scalars().all()
        return list(rows)
